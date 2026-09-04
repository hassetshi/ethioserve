-- DEV/TEST DATA ONLY. Never run against production.
-- After 20260901000025_provider_subscriptions.sql, search_providers()
-- requires an active paid subscription in addition to verification -- any
-- provider seeded before this migration (e.g. dev-seed-sample-provider.sql's
-- "Addis Plumbing Experts") has no subscriptions row at all and silently
-- drops out of search results. This backfills one active Professional
-- subscription per verified provider that doesn't already have one, purely
-- so search has real data to show while testing.
insert into public.subscriptions (provider_id, plan, price, status, current_period_end)
select
  p.id,
  'professional',
  29,
  'active',
  now() + interval '30 days'
from public.provider_profiles p
where p.verification_status = 'verified'
  and not exists (
    select 1 from public.subscriptions s
    where s.provider_id = p.id and s.status = 'active'
  );
