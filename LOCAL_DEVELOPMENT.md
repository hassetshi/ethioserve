# Local development

## Toolchain status (this machine)

| Tool | Status |
|---|---|
| Git | Installed (`git --version`) |
| Node.js LTS + npm | Installed |
| Flutter SDK (stable, cloned to `C:\flutter`) | Installed, `flutter analyze`/`flutter test` verified working |
| Supabase CLI | Installed as a repo devDependency (`npx supabase --version`) |
| Dev Supabase project | **Live** — `xvcwqkghhkuwvtdrmcey.supabase.co`, all migrations applied via `supabase db push --db-url ...` |
| Docker | Not installed — only needed if you want a fully local Postgres too (`npx supabase start`); not required now that a real dev project exists |
| Android SDK / Android Studio | **Not installed** — needed to build/run on Android, the primary target platform |
| Xcode | N/A (Windows machine) — iOS builds require a Mac regardless |

If `flutter\bin` isn't already on your `PATH` in a given shell, prefix commands
with a PATH refresh (Windows PowerShell doesn't persist PATH changes made by an
installer to already-open shells):

```powershell
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
```

## Running the mobile app today

Without Docker or a real Supabase project, and without the Android SDK, you can
still develop and verify most of the app:

```powershell
cd mobile
flutter pub get
flutter analyze
flutter test
flutter run -d edge --dart-define-from-file=env/development.json    # Microsoft Edge (web target)
flutter run -d windows --dart-define-from-file=env/development.json # Windows desktop app
```

`mobile/env/development.json` already points at the live dev Supabase project
(gitignored — ask whoever set it up for a copy, or follow the steps below to
create your own). Without `--dart-define-from-file`, the app still boots but
logs a warning and runs with backend features disabled.

## Connecting a real Supabase dev project (already done once — for reference/reset)

1. Create a Supabase project (the *development* one — keep it separate from
   staging/production, per spec section 24).
2. Copy `mobile/env/development.example.json` to `mobile/env/development.json`
   and fill in `SUPABASE_URL` / `SUPABASE_ANON_KEY` from the project's API
   settings. This file is gitignored.
3. Push the schema (CLI login via OAuth doesn't work in a non-interactive
   shell, so push straight via connection string instead of `link`):
   ```powershell
   npx supabase db push --db-url "postgresql://postgres:<url-encoded-password>@db.<project-ref>.supabase.co:5432/postgres"
   ```
4. Enable **Phone** under Authentication → Providers (Phase 2 uses phone OTP).
   An SMS provider (e.g. Twilio) still needs to be configured there before real
   OTP codes can be sent.

## Running the full local stack instead (optional, needs Docker)

If you'd rather develop against a fully local Postgres (no cloud project, no
network dependency) install Docker Desktop, then:

```powershell
npx supabase start   # spins up local Postgres, Auth, Storage, Studio
npx supabase db reset  # applies all migrations + seed data fresh
```

`supabase start` prints a local `API URL` and `anon key` to put in
`mobile/env/development.json`.

## Direct database access (`scripts/dev-db.mjs`)

For anything that doesn't fit the migration workflow — ad-hoc inspection,
seeding throwaway test data — `scripts/dev-db.mjs` connects straight to
Postgres as the `postgres` role (bypasses RLS entirely, so **never** point it
at staging/production):

```powershell
$env:DEV_DATABASE_URL = "postgresql://postgres:<url-encoded-password>@db.<project-ref>.supabase.co:5432/postgres"
node scripts/dev-db.mjs "select * from categories limit 5"
node scripts/dev-db.mjs --file scripts/dev-seed-sample-provider.sql
```

`scripts/dev-seed-sample-provider.sql` promotes the test user created by the
Phase 2 OTP smoke test (`251912345678`) into a verified provider with a
seeded service, so the Phase 3 browse flow (categories → services →
providers → profile) has real data to look at without needing Phase 4's
provider registration flow to exist yet. Dev/test data only — never run
against staging or production.

## Getting the Android SDK working

Building/running on Android needs Android Studio (which bundles the SDK) or the
standalone command-line tools. Once installed:

```powershell
flutter config --android-sdk "<path-to-sdk>"
flutter doctor --android-licenses
flutter doctor
```
