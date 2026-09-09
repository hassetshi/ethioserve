#!/usr/bin/env node
// One-off import of the DC-area Ethiopian business lead list as pre-seeded,
// unclaimed provider listings (see supabase/migrations/20260909000030_provider_claims.sql
// for the schema this depends on: nullable provider_profiles.user_id,
// provider_claim_requests, provider_leads). Real business data, not a
// throwaway dev fixture — unlike scripts/dev-db.mjs this reads from
// IMPORT_DATABASE_URL (a distinct env var name on purpose, so pointing this
// at production is always a deliberate choice, never a habit).
//
// Usage:
//   node scripts/import-dc-lead-list.mjs
//   node scripts/import-dc-lead-list.mjs --file scripts/data/dc-lead-list.csv
//
// Safe to re-run: each row's business_name+phone forms an idempotency key
// (provider_leads.source_row_ref) that's checked before any insert.
import { readFileSync } from 'node:fs';
import pg from 'pg';

const dbUrl = process.env.IMPORT_DATABASE_URL;
if (!dbUrl) {
  console.error('Set IMPORT_DATABASE_URL first, e.g.:');
  console.error('  $env:IMPORT_DATABASE_URL = "postgresql://postgres:<url-encoded-password>@db.<ref>.supabase.co:5432/postgres"');
  process.exit(1);
}

const args = process.argv.slice(2);
const fileFlagIndex = args.indexOf('--file');
const csvPath = fileFlagIndex === -1 ? 'scripts/data/dc-lead-list.csv' : args[fileFlagIndex + 1];
const SOURCE = 'dc_lead_list_2026';

// Deterministic rule: split the raw category on '/', take the first
// segment, map via this dictionary. Covers all 73 rows in the current
// lead list with zero fallback (verified against the real file) — kept as
// a fallback for future imports whose categories don't fit this list.
const CATEGORY_MAP = {
  restaurant: 'Restaurant',
  grocery: 'Grocery',
  'coffee shop': 'Coffee Shop & Bakery',
  bakery: 'Coffee Shop & Bakery',
  beauty: 'Beauty & Salon',
  immigration: 'Legal & Immigration Services',
  accounting: 'Accounting & Tax',
  'driving school': 'Driving School',
  'travel agency': 'Travel Agency',
  'real estate': 'Real Estate',
  catering: 'Catering',
  insurance: 'Insurance',
  'ethiopian products': 'Ethiopian Products & Home Goods',
};
const FALLBACK_CATEGORY = 'Other Services';

function resolveCategory(rawCategory) {
  const firstSegment = (rawCategory || '').split('/')[0].trim().toLowerCase();
  return CATEGORY_MAP[firstSegment] ?? null;
}

function parseCsv(text) {
  const lines = text.split(/\r?\n/).filter((line) => line.length > 0);
  const header = lines[0].split(',');
  return lines.slice(1).map((line) => {
    const cells = line.split(',');
    const row = {};
    header.forEach((key, i) => {
      row[key.trim()] = (cells[i] ?? '').trim();
    });
    return row;
  });
}

function sourceRowRef(businessName, phone) {
  const normalizedPhone = (phone || '').replace(/\D/g, '');
  return `${businessName.trim().toLowerCase()}|${normalizedPhone}`;
}

const csvText = readFileSync(csvPath, 'utf8');
const rows = parseCsv(csvText);

const client = new pg.Client({ connectionString: dbUrl });
await client.connect();

const summary = { imported: 0, duplicate: 0, skippedCity: [], skippedCategory: [] };

try {
  for (const row of rows) {
    const businessName = row['Business Name'];
    const rawCategory = row['Category'];
    const cityState = `${row['City']}, ${row['State']}`;
    const phone = row['Phone'] || null;
    const rowRef = sourceRowRef(businessName, phone);

    const existing = await client.query(
      'select 1 from provider_leads where source_row_ref = $1',
      [rowRef],
    );
    if (existing.rowCount > 0) {
      console.log(`Skipping (already imported): ${businessName}`);
      summary.duplicate++;
      continue;
    }

    const cityResult = await client.query(
      'select id from cities where lower(name_en) = lower($1)',
      [cityState],
    );
    if (cityResult.rowCount === 0) {
      console.log(`Skipping (no matching city "${cityState}"): ${businessName}`);
      summary.skippedCity.push({ businessName, cityState });
      continue;
    }
    const cityId = cityResult.rows[0].id;

    const categoryName = resolveCategory(rawCategory);
    if (categoryName === null) {
      console.log(`No category mapping for "${rawCategory}" (${businessName}), using fallback "${FALLBACK_CATEGORY}"`);
      summary.skippedCategory.push({ businessName, rawCategory });
    }
    const resolvedCategoryName = categoryName ?? FALLBACK_CATEGORY;

    const serviceResult = await client.query(
      `select s.id from services s
       join categories c on c.id = s.category_id
       where c.name_en = $1 and s.name_en = 'General ' || c.name_en || ' Services'`,
      [resolvedCategoryName],
    );
    if (serviceResult.rowCount === 0) {
      throw new Error(
        `No placeholder service found for category "${resolvedCategoryName}" — run the 20260909000029 migration first.`,
      );
    }
    const serviceId = serviceResult.rows[0].id;

    await client.query('begin');
    try {
      const promoResult = await client.query(
        "select (value->>'promo_ends_at')::timestamptz as promo_ends_at from platform_settings where key = 'subscription_plan_free'",
      );
      const promoEndsAt = promoResult.rows[0]?.promo_ends_at;
      if (!promoEndsAt) {
        throw new Error('subscription_plan_free.promo_ends_at not found — run the 20260909000027 migration first.');
      }

      const providerResult = await client.query(
        `insert into provider_profiles
           (user_id, business_name, phone, city_id, verification_status, verification_date, is_active)
         values (null, $1, $2, $3, 'verified', now(), true)
         returning id`,
        [businessName, phone, cityId],
      );
      const providerId = providerResult.rows[0].id;

      await client.query(
        `insert into provider_services (provider_id, service_id, pricing_type)
         values ($1, $2, 'quote')`,
        [providerId, serviceId],
      );

      await client.query(
        `insert into subscriptions (provider_id, plan, price, status, current_period_end)
         values ($1, 'free', 0, 'active', $2)`,
        [providerId, promoEndsAt],
      );

      await client.query(
        `insert into provider_leads
           (provider_id, source, source_row_ref, lead_category, lead_score, suggested_offer, ownership_evidence, raw_data)
         values ($1, $2, $3, $4, $5, $6, $7, $8)`,
        [
          providerId,
          SOURCE,
          rowRef,
          rawCategory,
          row['Lead Score'] ? Number(row['Lead Score']) : null,
          row['Suggested Offer'] || null,
          row['Ethiopian Ownership/Affiliation Evidence'] || null,
          JSON.stringify(row),
        ],
      );

      await client.query('commit');
      console.log(`Imported: ${businessName} (${cityState}, ${resolvedCategoryName})`);
      summary.imported++;
    } catch (err) {
      await client.query('rollback');
      throw err;
    }
  }
} finally {
  await client.end();
}

console.log('\n=== Import summary ===');
console.log(`Imported: ${summary.imported}`);
console.log(`Already imported (skipped): ${summary.duplicate}`);
console.log(`Skipped — no matching city: ${summary.skippedCity.length}`);
for (const s of summary.skippedCity) console.log(`  - ${s.businessName}: "${s.cityState}"`);
console.log(`Fell back to "${FALLBACK_CATEGORY}": ${summary.skippedCategory.length}`);
for (const s of summary.skippedCategory) console.log(`  - ${s.businessName}: "${s.rawCategory}"`);
