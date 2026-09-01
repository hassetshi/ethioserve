# AI search

Built in Phase 11. Pipeline (spec section 15):

```
user text (English or Amharic)
  -> POST supabase/functions/ai-search (Edge Function)
  -> fetches the platform's current active categories/services
  -> Claude (tool-use, forced to output category_id/service_id or ask for clarification)
  -> Edge Function verifies every id Claude returned against the catalog it just fetched
  -> validated { matched, categoryId, serviceId } | { matched: false, clarificationQuestion }
  -> client calls the SAME search_providers() RPC used by manual/category search
```

The AI never sees or writes SQL, and can only pick from a closed list of
real ids handed to it in the prompt — it can't invent a category/service
that doesn't exist. The Edge Function re-checks every returned id against
the catalog before trusting it, so even a malformed or hallucinated model
response can't reach the database query layer.

## Why an Edge Function, not a direct client call

The Anthropic API key is a secret and must never ship in the Flutter app
(same reasoning as the Supabase service-role key — spec sections 7, 25, 31).
It lives only as a Supabase Edge Function secret
(`supabase secrets set ANTHROPIC_API_KEY=...`), set via the CLI using a
personal access token that was used transiently for this one deployment,
never committed anywhere.

## Files

- `supabase/functions/ai-search/index.ts` — the Edge Function itself.
- `mobile/lib/features/ai_search/domain/ai_service.dart` — the vendor-agnostic
  `AIService` interface (spec section 16's "use an abstraction" applies to
  AI providers the same way it applies to push notifications).
- `mobile/lib/features/ai_search/data/supabase_ai_service.dart` — calls the
  Edge Function via `supabase.functions.invoke`.
- `mobile/lib/features/ai_search/presentation/ai_search_screen.dart` — the
  "Ask EthioServe" screen, reached from Home.

## Voice (spec section 16)

`SpeechToTextService` / `TextToSpeechService` interfaces exist
(`mobile/lib/core/speech/`) with `Noop*` defaults, satisfying the
architectural requirement ("create interfaces... so speech providers can be
replaced") without committing to a specific STT/TTS vendor yet. Deliberately
not wired to a real provider in Phase 11 — on-device Amharic speech
recognition quality is genuinely uncertain and worth validating against real
users before investing in a specific vendor integration, unlike text search
which was straightforward to get working end-to-end now.

## Verified live

Tested directly against the deployed function with the spec's own two
example queries:
- `"I need a plumber near me today."` → matched Plumbing category + Pipe
  Repair service.
- `"በአካባቢዬ የቧንቧ ባለሙያ ፈልግልኝ"` (Amharic for the same request) → matched
  Plumbing category (service left unmatched — a reasonable reading of a
  slightly less specific phrasing than the English version; not a bug).
- A deliberately vague query (`"I need help with something"`) correctly
  returned `matched: false` with a sensible clarifying question.
