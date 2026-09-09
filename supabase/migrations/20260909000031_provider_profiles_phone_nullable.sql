-- The mobile domain model (ProviderDetail.phone, provider_repository.dart)
-- has always treated phone as optional (`String? phone`, and
-- provider_profile_screen.dart already only renders the Call button
-- `if (provider.phone != null)`) - the DB's `not null` was stricter than
-- the app ever actually required. This surfaced for real importing the DC
-- lead list (scripts/import-dc-lead-list.mjs): 22 of 73 real businesses
-- have no phone number in the source data, and forcing a placeholder value
-- would have made a fake number look real (and dialable) in the app.
alter table public.provider_profiles alter column phone drop not null;
