# Troubleshooting

## PATH doesn't include `git`/`flutter`/`node` in a new shell

On Windows, an installer updating the machine/user `PATH` doesn't propagate to
already-open shells. Refresh it per-session:

```powershell
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
```

## `flutter pub get` fails with an `intl` version conflict

`flutter_localizations` pins a specific `intl` version per Flutter release.
If you see `version solving failed` mentioning `intl`, set the `intl` version
in `mobile/pubspec.yaml` to whatever the error message says
`flutter_localizations` requires, not an arbitrary version.

## App boots but logs "Supabase is not configured"

Expected until a real Supabase project is connected — see
[LOCAL_DEVELOPMENT.md](LOCAL_DEVELOPMENT.md#connecting-a-real-supabase-dev-project).
The UI still runs so screens/navigation/localization can be built without a
backend.

## `npx supabase start` / `supabase db push` isn't available

Needs Docker (for `start`) or a linked real project (for `push`) — neither is
set up by default. See [LOCAL_DEVELOPMENT.md](LOCAL_DEVELOPMENT.md).

## admin-web: login loops back to the login screen / console floods with TOKEN_REFRESHED

Check your system clock against real time first (e.g. compare
`Get-Date` (UTC) against the `Date` response header from any Supabase API
call). Supabase's client checks token freshness using the local machine's
clock with no skew tolerance — if the machine's clock is off by more than
about 90 seconds, every token looks already-expired the instant it's
issued, and the client refreshes in an infinite loop until Supabase's rate
limiter forces a sign-out. Fix: Settings → Time & Language → Date & Time →
Sync now. See ARCHITECTURE.md's Phase 10 section for the full debugging
story (several other things were suspected and ruled out first).

## More entries added here as they come up during development.
