-- The Stripe subscription flow (20260901000025) writes a `pending` row
-- immediately after creating the Stripe Subscription + PaymentIntent, before
-- the customer has actually confirmed payment in the PaymentSheet -
-- stripe-webhook then flips it to 'active' once Stripe confirms (or leaves
-- it to expire/get cleaned up otherwise). The original status check
-- constraint (20260831000008_rls_policies.sql) predates this flow and only
-- allowed active/expired/cancelled, so every real subscribe attempt failed
-- at this insert with a CHECK violation - confirmed live via an actual
-- end-to-end subscribe attempt (Stripe side succeeded; the DB write didn't).
alter table public.subscriptions drop constraint subscriptions_status_check;
alter table public.subscriptions add constraint subscriptions_status_check
  check (status = any (array['pending', 'active', 'expired', 'cancelled']));
