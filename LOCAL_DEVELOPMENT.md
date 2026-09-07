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
| Android SDK / emulator | **Installed** (Phase 17) — see "Getting the Android SDK working" below |
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
provider registration flow to exist yet.

`scripts/dev-seed-second-test-user.sql` creates a second identity directly in
`auth.users` (a customer, `251922345678`) — not something real signup ever
does, but necessary to test anything involving two distinct participants
(booking accept/decline, cancellation rules, later messaging/reviews)
without needing a second real phone number. To act as a specific user when
testing RLS/trigger logic directly over the `postgres` connection, simulate
their session with the same GUC Supabase's `auth.uid()` reads:
```sql
set local request.jwt.claim.sub = '<user-id>';
-- now auth.uid() returns that user's id for the rest of this transaction
```
Note this only affects what `auth.uid()` returns — it does **not** turn on
RLS enforcement, since the `postgres` role bypasses RLS entirely regardless.
It's useful for testing trigger logic (which fires regardless of RLS), not
for testing RLS policies themselves.

All of the above is dev/test data and dev-only technique — never run against
staging or production.

## Getting the Android SDK working

Installed via the standalone command-line tools (no Android Studio GUI needed),
entirely from PowerShell:

```powershell
# 1. JDK 17+ (the Android cmdline-tools need it; Gradle needs it too)
winget install --id Microsoft.OpenJDK.17 --source winget

# 2. Download + extract the command-line tools into the right nested folder -
#    "cmdline-tools\latest\" specifically, or sdkmanager complains about the
#    tools being in the wrong location.
#    Get the current download URL + SHA-256 from https://developer.android.com/studio
#    ("Command line tools only" section) rather than hard-coding a build number here.
Expand-Archive commandlinetools-win-<BUILD>_latest.zip -DestinationPath C:\Android\_tmp
Move-Item C:\Android\_tmp\cmdline-tools C:\Android\sdk\cmdline-tools\latest

# 3. Env vars (User-level, persists across shells)
[System.Environment]::SetEnvironmentVariable("ANDROID_HOME", "C:\Android\sdk", "User")
[System.Environment]::SetEnvironmentVariable("ANDROID_SDK_ROOT", "C:\Android\sdk", "User")
# then add cmdline-tools\latest\bin, platform-tools, and emulator to User PATH

# 4. Install packages. This SDK version's tooling actually ships a newer unified
#    "android" CLI that replaces sdkmanager/avdmanager (same folder, cmdline-tools\latest\bin\android.exe) -
#    `android sdk install` takes the classic package ids:
android sdk install --sdk="C:\Android\sdk" platform-tools "platforms/android-36" "build-tools/36.0.0" emulator "system-images/android-36/google_apis/x86_64"

# 5. Accept licenses headlessly (no interactive shell available) by writing the
#    known license-hash files directly instead of running `sdkmanager --licenses`
#    (which needs interactive y/n input and doesn't work in this environment):
#    C:\Android\sdk\licenses\android-sdk-license containing the three standard
#    accepted hashes (8933bad161af4178b1185d1a37fbf41ea5269c55,
#    d56f5187479451eabf01fb78af6dfcb131a6481e,
#    24333f8a63b6825ea9c5514f83c2829b004d1fee), plus
#    android-sdk-preview-license, intel-android-extra-license, and
#    android-sdk-arm-dbt-license with their own single known hashes.

# 6. Point Flutter at it and create/start an emulator
flutter config --android-sdk "C:\Android\sdk"
flutter doctor   # should show "All Android licenses accepted."
android emulator create medium_phone --sdk="C:\Android\sdk"
android emulator start medium_phone --sdk="C:\Android\sdk"
flutter run -d emulator-5554 --dart-define-from-file=env/development.json
```

### Known gotchas (all hit and fixed during Phase 17's first real Android run)

- **Gradle/Java can't download anything, SSL errors during the first build**:
  a fresh JDK's own bundled `cacerts` can be incomplete. Fix: `[System.Environment]::SetEnvironmentVariable("JAVA_TOOL_OPTIONS", "-Djavax.net.ssl.trustStoreType=Windows-ROOT", "User")`
  makes the JVM use Windows' own certificate store instead.
- **`flutter_stripe` crashes on launch** with "MainActivity is not a subclass
  of FlutterFragmentActivity" — Stripe's native Android PaymentSheet needs a
  Fragment host. Fix is one line in
  `android/app/src/main/kotlin/.../MainActivity.kt`: extend
  `FlutterFragmentActivity` instead of `FlutterActivity`.
- **Release builds would have zero network access** — check
  `android/app/src/main/AndroidManifest.xml` has
  `<uses-permission android:name="android.permission.INTERNET"/>`. Missing
  entirely was a real, previously-undetected gap in this repo (only caught
  once the app actually ran on Android for the first time), but it's easy
  to miss the impact: `flutter run` debug builds won't show any symptom,
  because Flutter's own project template already grants this permission
  separately in `android/app/src/debug/AndroidManifest.xml`, which only
  merges into debug builds. Only a release build (or manually removing the
  debug-only fragment) actually exposes the gap in the main manifest — so
  don't treat a clean debug run as proof this permission isn't needed there
  too.
- **`HandshakeException: CERTIFICATE_VERIFY_FAILED: unable to get local
  issuer certificate`** on every HTTPS call, even after the INTERNET
  permission fix: this means something on the host machine is intercepting
  HTTPS system-wide (antivirus "SSL scanning"/"Web Shield" features are the
  common cause — Norton's did exactly this on the machine this was built on).
  Diagnose by checking what certificate a plain host-side HTTPS request
  actually receives:
  ```powershell
  $req = [System.Net.WebRequest]::Create("https://your-project.supabase.co")
  try { $req.GetResponse() } catch {}
  $cert = [System.Security.Cryptography.X509Certificates.X509Certificate2]::new($req.ServicePoint.Certificate)
  $chain = New-Object System.Security.Cryptography.X509Certificates.X509Chain
  $chain.Build($cert) | Out-Null
  $chain.ChainElements | ForEach-Object { $_.Certificate.Subject }
  ```
  If the chain ends in something other than a recognizable public CA (e.g.
  "generated by Norton Antivirus for SSL/TLS scanning"), that's the
  culprit — Windows trusts it (the AV installs its root into Windows' store),
  but the emulator's isolated Android OS has no idea what it is. The
  project's `android/app/src/debug/res/xml/network_security_config.xml`
  (debug builds only, never release) is set up to trust user-installed CAs
  for exactly this scenario, but the AV's interception still has to
  actually stop for a given connection — toggling one feature in the AV's
  UI (e.g. "SSL man-in-the-middle attacks" or "Auto-Protect") is not
  guaranteed to be the specific control that does it; re-run the diagnostic
  above after each change, and a full restart may be required since some AV
  network filter drivers don't unload on a UI toggle alone.
