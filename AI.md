# AI search

Built in Phase 11. Placeholder for now — recording the architecture constraints
from the spec so they aren't lost before then:

- Pipeline: user input (typed or spoken, Amharic or English) → AI
  interpretation → **JSON schema validation** → backend search → PostgreSQL →
  provider results. The AI never generates SQL directly (spec section 15).
- If the AI can't confidently determine a service, the app asks a
  clarification question rather than guessing.
- Voice: `SpeechToTextService`, `TextToSpeechService`, `AIService` are defined
  as interfaces so the underlying vendor (initially Amharic STT) can be
  swapped without touching call sites (spec section 16).
- The validated AI output feeds into the same `search_providers()` RPC used by
  manual search (see [API.md](API.md)), not a separate code path — this keeps
  "don't trust AI output" and "don't duplicate search logic" satisfied
  simultaneously.
