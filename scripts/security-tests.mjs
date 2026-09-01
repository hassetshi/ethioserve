#!/usr/bin/env node
// Formalized, repeatable version of the RLS/authorization checks that were
// verified ad-hoc throughout development (spec section 28: "Security tests
// ... Verify: RLS, Authorization, API access, Role separation"). Safe to
// re-run any time — the trigger-level tests create their own disposable
// bookings and clean up after themselves.
//
// Usage:
//   node scripts/security-tests.mjs
//   $env:DEV_DATABASE_URL = "postgresql://postgres:<url-encoded-password>@db.<ref>.supabase.co:5432/postgres"
//     (optional — without it, only the REST/RPC-level tests run; the
//     trigger-level actor-authorization tests need a direct DB connection
//     to simulate different users via the request.jwt.claim.sub GUC)
import pg from 'pg';

const SUPABASE_URL = 'https://xvcwqkghhkuwvtdrmcey.supabase.co';
const ANON_KEY = 'sb_publishable_7WU-tvendCOEWQq2QQ7kLg_7P7vQkhW';
const DB_URL = process.env.DEV_DATABASE_URL;

// Fixed dev identities from scripts/dev-seed-sample-provider.sql and
// scripts/dev-seed-second-test-user.sql.
const CUSTOMER_ID = '6318f730-9442-450d-a299-5fe2e9e75b39';
const PROVIDER_USER_ID = 'c93bd671-9168-471a-973a-6b93722ffeb7';
const PROVIDER_ID = 'f4e3860a-ab67-4b38-977d-80e240c6d18e';
const SERVICE_ID = '8246d401-4690-458b-ad26-c03984450c0d';

let passed = 0;
let failed = 0;

async function test(name, fn) {
  try {
    await fn();
    console.log(`  ok   ${name}`);
    passed++;
  } catch (e) {
    console.log(`FAIL   ${name}`);
    console.log(`       ${e.message}`);
    failed++;
  }
}

function assert(condition, message) {
  if (!condition) throw new Error(message ?? 'assertion failed');
}

async function restGet(path) {
  const res = await fetch(`${SUPABASE_URL}/rest/v1/${path}`, {
    headers: { apikey: ANON_KEY },
  });
  return { status: res.status, body: await res.json().catch(() => null) };
}

async function restPost(path, body, extraHeaders = {}) {
  const res = await fetch(`${SUPABASE_URL}/rest/v1/${path}`, {
    method: 'POST',
    headers: { apikey: ANON_KEY, 'content-type': 'application/json', ...extraHeaders },
    body: JSON.stringify(body),
  });
  return { status: res.status, body: await res.json().catch(() => null) };
}

console.log('--- Unauthenticated REST/RPC access ---');

await test('unauthenticated read of bookings returns zero rows', async () => {
  const { body } = await restGet('bookings?select=id&limit=5');
  assert(Array.isArray(body) && body.length === 0, `expected [], got ${JSON.stringify(body)}`);
});

await test('unauthenticated read of messages returns zero rows', async () => {
  const { body } = await restGet('messages?select=id&limit=5');
  assert(Array.isArray(body) && body.length === 0, `expected [], got ${JSON.stringify(body)}`);
});

await test('unauthenticated insert into messages (spoofing another user) is rejected', async () => {
  const { status } = await restPost('messages', {
    booking_id: '00000000-0000-0000-0000-000000000000',
    sender_id: CUSTOMER_ID,
    receiver_id: PROVIDER_USER_ID,
    message: 'spoofed',
    message_type: 'text',
  });
  assert(status === 401, `expected 401, got ${status}`);
});

await test('unauthenticated insert into categories (admin-only table) is rejected', async () => {
  const { status } = await restPost(
    'categories',
    { name_en: 'Hacked', name_am: 'Hacked' },
    { prefer: 'return=representation' },
  );
  assert(status === 401, `expected 401, got ${status}`);
});

await test('active categories ARE publicly readable (positive control)', async () => {
  const { status, body } = await restGet('categories?select=id&is_active=eq.true&limit=1');
  assert(status === 200 && body.length === 1, `expected 1 row, got status ${status}`);
});

await test('search_providers RPC is callable unauthenticated (public search)', async () => {
  const { status } = await restPost('rpc/search_providers', {});
  assert(status === 200, `expected 200, got ${status}`);
});

await test('register_as_provider rejects an unauthenticated caller', async () => {
  const { status } = await restPost('rpc/register_as_provider', {
    p_business_name: 'x',
    p_description_en: null,
    p_description_am: null,
    p_phone: 'x',
    p_address: null,
    p_city_id: null,
    p_latitude: null,
    p_longitude: null,
  });
  assert(status === 400, `expected 400, got ${status}`);
});

await test('log_admin_action RPC rejects an unauthenticated caller', async () => {
  // Postgres grants EXECUTE to PUBLIC by default, so `grant ... to
  // authenticated` (20260901000022_admin_audit_log_rpc.sql) doesn't
  // actually block anon at the grant level - the real rejection is the
  // function body's own is_admin() check, surfaced as a plain Postgres
  // exception (400/P0001), not a permission-denied error.
  const { status, body } = await restPost('rpc/log_admin_action', {
    p_action: 'test.probe',
    p_entity_type: 'users',
  });
  assert(status === 400, `expected 400, got ${status}`);
  assert(
    /Only admins may write audit log entries/.test(body?.message ?? ''),
    `expected the is_admin rejection message, got ${JSON.stringify(body)}`,
  );
});

if (!DB_URL) {
  console.log('\nDEV_DATABASE_URL not set — skipping trigger-level actor-authorization tests.');
} else {
  console.log('\n--- Trigger-level actor authorization (direct DB connection) ---');

  const client = new pg.Client({ connectionString: DB_URL });
  await client.connect();

  async function asUser(userId, sql, params = []) {
    await client.query('begin');
    try {
      await client.query(`set local request.jwt.claim.sub = '${userId}'`);
      return await client.query(sql, params);
    } finally {
      await client.query('commit');
    }
  }

  async function expectRejection(fn, pattern) {
    try {
      await fn();
    } catch (e) {
      assert(pattern.test(e.message), `wrong rejection reason: ${e.message}`);
      return;
    }
    throw new Error('expected rejection, but the operation succeeded');
  }

  let bookingId;
  await test('setup: create a fresh disposable test booking', async () => {
    const { rows } = await client.query(
      `insert into public.bookings (customer_id, provider_id, service_id, scheduled_date, scheduled_time, address)
       values ($1, $2, $3, current_date + 1, '09:00', 'Security test address') returning id`,
      [CUSTOMER_ID, PROVIDER_ID, SERVICE_ID],
    );
    bookingId = rows[0].id;
  });

  await test('customer cannot accept their own booking', () =>
    expectRejection(
      () => asUser(CUSTOMER_ID, `update public.bookings set status = 'accepted' where id = $1`, [bookingId]),
      /Only the assigned provider/,
    ));

  await test('the assigned provider CAN accept the booking', async () => {
    await asUser(PROVIDER_USER_ID, `update public.bookings set status = 'accepted' where id = $1`, [bookingId]);
    const { rows } = await client.query('select status from public.bookings where id = $1', [bookingId]);
    assert(rows[0].status === 'accepted', `expected accepted, got ${rows[0].status}`);
  });

  await test('the customer CAN cancel an accepted booking', async () => {
    await asUser(CUSTOMER_ID, `update public.bookings set status = 'cancelled' where id = $1`, [bookingId]);
    const { rows } = await client.query('select status from public.bookings where id = $1', [bookingId]);
    assert(rows[0].status === 'cancelled', `expected cancelled, got ${rows[0].status}`);
  });

  await test('an invalid status transition is rejected regardless of actor', () =>
    expectRejection(
      () => asUser(PROVIDER_USER_ID, `update public.bookings set status = 'completed' where id = $1`, [bookingId]),
      /Invalid booking status transition/,
    ));

  await test('cleanup: remove the test booking', async () => {
    await client.query('delete from public.bookings where id = $1', [bookingId]);
  });

  console.log('\n--- Payment authorization ---');

  let paidBookingId;
  await test('setup: create + complete a fresh booking for payment tests', async () => {
    const { rows } = await client.query(
      `insert into public.bookings (customer_id, provider_id, service_id, scheduled_date, scheduled_time, address, final_price)
       values ($1, $2, $3, current_date + 1, '09:00', 'Security test address', 500) returning id`,
      [CUSTOMER_ID, PROVIDER_ID, SERVICE_ID],
    );
    paidBookingId = rows[0].id;
    for (const status of ['accepted', 'on_the_way', 'in_progress', 'completed']) {
      await asUser(PROVIDER_USER_ID, `update public.bookings set status = $2 where id = $1`, [paidBookingId, status]);
    }
  });

  await test('customer cannot record a cash payment for their own booking', () =>
    expectRejection(
      () => asUser(CUSTOMER_ID, `select public.record_cash_payment($1)`, [paidBookingId]),
      /Only the assigned provider/,
    ));

  await test('the assigned provider CAN record the cash payment, with the correct commission split', async () => {
    await asUser(PROVIDER_USER_ID, `select public.record_cash_payment($1)`, [paidBookingId]);
    const { rows } = await client.query(
      'select platform_fee, provider_amount from public.payments where booking_id = $1',
      [paidBookingId],
    );
    assert(rows.length === 1, 'expected exactly one payment row');
    assert(Number(rows[0].platform_fee) === 50, `expected platform_fee 50, got ${rows[0].platform_fee}`);
    assert(Number(rows[0].provider_amount) === 450, `expected provider_amount 450, got ${rows[0].provider_amount}`);
  });

  await test('a duplicate cash payment on the same booking is rejected', () =>
    expectRejection(
      () => asUser(PROVIDER_USER_ID, `select public.record_cash_payment($1)`, [paidBookingId]),
      /already has a payment record/,
    ));

  await test('cleanup: remove the payment test booking', async () => {
    await client.query('delete from public.payments where booking_id = $1', [paidBookingId]);
    await client.query('delete from public.bookings where id = $1', [paidBookingId]);
  });

  console.log('\n--- Admin audit logging ---');

  await test('a non-admin cannot write an audit log entry', () =>
    expectRejection(
      () => asUser(CUSTOMER_ID, `select public.log_admin_action('test.probe', 'users', null, null)`),
      /Only admins may write audit log entries/,
    ));

  await test('an admin can write an audit log entry, correctly attributed', async () => {
    const { rows: adminRows } = await client.query(
      `select id from public.users where role = 'admin' limit 1`,
    );
    if (adminRows.length === 0) {
      throw new Error('no admin user found in this database - cannot test the positive path');
    }
    const adminId = adminRows[0].id;
    const result = await asUser(
      adminId,
      `select public.log_admin_action('test.probe', 'users', $1, null) as id`,
      [CUSTOMER_ID],
    );
    const logId = result.rows[0].id;
    const { rows: logRows } = await client.query(
      'select user_id, action, entity_type, entity_id from public.audit_logs where id = $1',
      [logId],
    );
    assert(logRows[0].user_id === adminId, 'audit log user_id should be the calling admin');
    assert(logRows[0].action === 'test.probe', 'action should match what was passed in');
    assert(logRows[0].entity_id === CUSTOMER_ID, 'entity_id should match what was passed in');
    await client.query('delete from public.audit_logs where id = $1', [logId]);
  });

  await client.end();
}

console.log(`\n${passed} passed, ${failed} failed`);
process.exit(failed > 0 ? 1 : 0);
