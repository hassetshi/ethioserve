# EthioServe Admin

Separate web application for platform administrators (spec section 13 — admin
functionality never lives in the customer/provider mobile app). React +
TypeScript + Vite, Tailwind for styling, `@supabase/supabase-js` talking
directly to the same Supabase project as the mobile app, `@tanstack/react-query`
for data fetching, `react-router-dom` for routing.

## Why this stack

Not mandated by the spec (only the mobile app's stack is), so decided and
documented here the same way `mobile/`'s Riverpod choice was: React+Vite is a
fast, unopinionated baseline for an internal CRUD-heavy dashboard; TanStack
Query removes the boilerplate every list/mutation page in here would
otherwise repeat by hand.

## Running locally

```powershell
cd admin-web
npm install
copy .env.example .env.development   # fill in VITE_SUPABASE_URL / VITE_SUPABASE_ANON_KEY
npm run dev
```

There's no self-service admin signup. The first admin account must be
created via the Supabase Dashboard (Authentication → Users → Add User), then
promoted with:

```sql
update public.users set role = 'admin' where email = '<their email>';
```

## Real authorization boundary

Every admin-only capability is enforced by RLS (`is_admin()` policies) on the
database side, same as the mobile app's role checks. The client-side
`ProtectedRoute` check here only decides what the UI *shows* a non-admin
user (a plain "not an administrator" screen) — it is never the actual
security boundary (spec section 43).

## A hard-won lesson: `lib/supabase.ts`'s auth config

`autoRefreshToken` and `persistSession` are both off. This isn't a style
preference — see the comment in that file and ARCHITECTURE.md's Phase 10
section for the full story, but in short: `supabase-js`'s session-refresh
logic checks token freshness using the browser's own clock, with no
tolerance for clock skew between the client machine and Supabase's servers.
On a machine with a skewed system clock, every token (even a freshly issued
one) looks expired, triggering an immediate refresh, which looks expired
too, forever — until Supabase's rate limiter forces a sign-out. Disabling
persistence/auto-refresh doesn't fix clock skew, but it stops this app from
being the thing that turns it into a broken login loop.
