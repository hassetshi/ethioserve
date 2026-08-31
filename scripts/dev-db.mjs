#!/usr/bin/env node
// Direct Postgres access to the dev database, for local development tasks
// that don't fit the migration workflow (ad-hoc inspection, seeding
// throwaway test data). Connects as the `postgres` role, which bypasses RLS
// entirely — never point this at staging/production.
//
// Usage:
//   node scripts/dev-db.mjs "select * from categories limit 5"
//   node scripts/dev-db.mjs --file some-script.sql
//
// Reads the connection string from DEV_DATABASE_URL (percent-encoded
// password), so the password never needs to be typed into a command line
// that ends up in shell history.
import { readFileSync } from 'node:fs';
import pg from 'pg';

const dbUrl = process.env.DEV_DATABASE_URL;
if (!dbUrl) {
  console.error('Set DEV_DATABASE_URL first, e.g.:');
  console.error('  $env:DEV_DATABASE_URL = "postgresql://postgres:<url-encoded-password>@db.<ref>.supabase.co:5432/postgres"');
  process.exit(1);
}

const args = process.argv.slice(2);
const sql = args[0] === '--file' ? readFileSync(args[1], 'utf8') : args[0];

if (!sql) {
  console.error('Usage: node scripts/dev-db.mjs "<sql>"  OR  node scripts/dev-db.mjs --file <path.sql>');
  process.exit(1);
}

const client = new pg.Client({ connectionString: dbUrl });
await client.connect();
try {
  const result = await client.query(sql);
  if (Array.isArray(result)) {
    for (const r of result) console.log(r.rows);
  } else {
    console.log(result.rows);
  }
} finally {
  await client.end();
}
