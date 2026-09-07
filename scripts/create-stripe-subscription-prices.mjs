#!/usr/bin/env node
// One-off setup script (spec: provider subscriptions need real Stripe Price
// objects to be genuinely testable end-to-end, not just wired up in theory).
// Creates a Stripe Product + recurring Price per plan in
// platform_settings.subscription_plan_* (price taken from there, not
// hard-coded here) and writes the resulting Price ID back, via PostgREST
// with the service-role key (which bypasses platform_settings_admin_only
// RLS by design - same as an Edge Function using the service-role key).
//
// Safe to re-run: a plan that already has a stripe_price_id is skipped.
//
// Usage (PowerShell):
//   $env:STRIPE_SECRET_KEY = "sk_test_..."
//   $env:SUPABASE_URL = "https://<ref>.supabase.co"
//   $env:SUPABASE_SERVICE_ROLE_KEY = "..."
//   node scripts/create-stripe-subscription-prices.mjs
const STRIPE_SECRET_KEY = process.env.STRIPE_SECRET_KEY;
const SUPABASE_URL = process.env.SUPABASE_URL;
const SUPABASE_SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;

for (const [name, value] of Object.entries({
  STRIPE_SECRET_KEY,
  SUPABASE_URL,
  SUPABASE_SERVICE_ROLE_KEY,
})) {
  if (!value) {
    console.error(`Set ${name} first.`);
    process.exit(1);
  }
}

const PLAN_KEYS = ['subscription_plan_professional', 'subscription_plan_premium'];

async function stripePost(path, body) {
  const response = await fetch(`https://api.stripe.com/v1/${path}`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${STRIPE_SECRET_KEY}`,
      'content-type': 'application/x-www-form-urlencoded',
    },
    body: new URLSearchParams(body),
  });
  if (!response.ok) {
    throw new Error(`Stripe ${path} failed (${response.status}): ${await response.text()}`);
  }
  return response.json();
}

async function fetchSetting(key) {
  const response = await fetch(
    `${SUPABASE_URL}/rest/v1/platform_settings?key=eq.${key}&select=key,value`,
    {
      headers: {
        apikey: SUPABASE_SERVICE_ROLE_KEY,
        Authorization: `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`,
      },
    },
  );
  if (!response.ok) {
    throw new Error(`Failed to read ${key}: ${response.status} ${await response.text()}`);
  }
  const rows = await response.json();
  if (!rows.length) throw new Error(`platform_settings row not found: ${key}`);
  return rows[0].value;
}

async function updateSetting(key, value) {
  const response = await fetch(`${SUPABASE_URL}/rest/v1/platform_settings?key=eq.${key}`, {
    method: 'PATCH',
    headers: {
      apikey: SUPABASE_SERVICE_ROLE_KEY,
      Authorization: `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`,
      'content-type': 'application/json',
      prefer: 'return=minimal',
    },
    body: JSON.stringify({ value }),
  });
  if (!response.ok) {
    throw new Error(`Failed to update ${key}: ${response.status} ${await response.text()}`);
  }
}

for (const key of PLAN_KEYS) {
  const value = await fetchSetting(key);
  if (value.stripe_price_id) {
    console.log(`${key}: already has stripe_price_id=${value.stripe_price_id}, skipping.`);
    continue;
  }

  const planName = key.replace('subscription_plan_', '');
  const product = await stripePost('products', {
    name: `EthioServe ${planName[0].toUpperCase()}${planName.slice(1)} Listing`,
    'metadata[plan]': planName,
  });
  const price = await stripePost('prices', {
    product: product.id,
    currency: 'usd',
    unit_amount: String(Math.round(value.price_usd * 100)),
    'recurring[interval]': value.interval ?? 'month',
  });

  await updateSetting(key, { ...value, stripe_price_id: price.id });
  console.log(`${key}: created ${product.id} / ${price.id} ($${value.price_usd}/${value.interval})`);
}

console.log('Done.');
