# Local development

## Toolchain status (this machine)

| Tool | Status |
|---|---|
| Git | Installed (`git --version`) |
| Node.js LTS + npm | Installed |
| Flutter SDK (stable, cloned to `C:\flutter`) | Installed, `flutter analyze`/`flutter test` verified working |
| Supabase CLI | Installed as a repo devDependency (`npx supabase --version`) |
| Docker | **Not installed** — needed for `npx supabase start` (local Postgres/Auth/Storage stack) |
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
flutter run -d edge      # runs in Microsoft Edge (web target)
flutter run -d windows   # runs as a Windows desktop app
```

The app boots with backend features disabled (a warning is logged) until a real
Supabase project is connected — see below.

## Connecting a real Supabase dev project

1. Create a Supabase project (the *development* one — keep it separate from
   staging/production, per spec section 24).
2. Copy `mobile/env/development.example.json` to `mobile/env/development.json`
   and fill in `SUPABASE_URL` / `SUPABASE_ANON_KEY` from the project's API
   settings. This file is gitignored.
3. Push the schema:
   ```powershell
   npx supabase login
   npx supabase link --project-ref <your-project-ref>
   npx supabase db push
   ```
4. Run the app with the dev config compiled in:
   ```powershell
   flutter run -d edge --dart-define-from-file=env/development.json
   ```

## Running the full local stack instead (optional, needs Docker)

If you'd rather develop against a fully local Postgres (no cloud project, no
network dependency) install Docker Desktop, then:

```powershell
npx supabase start   # spins up local Postgres, Auth, Storage, Studio
npx supabase db reset  # applies all migrations + seed data fresh
```

`supabase start` prints a local `API URL` and `anon key` to put in
`mobile/env/development.json`.

## Getting the Android SDK working

Building/running on Android needs Android Studio (which bundles the SDK) or the
standalone command-line tools. Once installed:

```powershell
flutter config --android-sdk "<path-to-sdk>"
flutter doctor --android-licenses
flutter doctor
```
