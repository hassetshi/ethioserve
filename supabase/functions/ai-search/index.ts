// AI search interpretation (spec section 15).
//
// Architecture: user text -> this function -> Claude, constrained to pick
// ONE category/service from the platform's *actual* current list -> we
// verify the returned id genuinely exists in that list (never trust the
// model's output blindly) -> structured, validated result back to the
// client, which feeds it into the existing search_providers() RPC. The AI
// never sees or writes SQL, and never invents a category/service that
// doesn't exist — it can only pick from what we handed it, or ask for
// clarification.
//
// Runs server-side because it needs ANTHROPIC_API_KEY, which must never
// reach the Flutter app (same reasoning as the Supabase service-role key).
import { createClient } from 'jsr:@supabase/supabase-js@2'
import { corsHeaders, handleCorsPreflight } from '../_shared/cors.ts'

const ANTHROPIC_API_KEY = Deno.env.get('ANTHROPIC_API_KEY')!
const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!
const SUPABASE_ANON_KEY = Deno.env.get('SUPABASE_ANON_KEY')!

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'content-type': 'application/json' },
  })
}

const CLASSIFY_TOOL = {
  name: 'classify_search_query',
  description:
    "Match the user's service search query to one of the platform's known categories/services, or ask a clarifying question if it can't be confidently determined.",
  input_schema: {
    type: 'object',
    properties: {
      matched: { type: 'boolean', description: 'true if a confident match was found' },
      category_id: { type: ['string', 'null'], description: 'The matched category id, or null' },
      service_id: { type: ['string', 'null'], description: 'The matched service id, or null' },
      clarification_question: {
        type: ['string', 'null'],
        description:
          'If matched is false, a short clarifying question in the SAME language as the user query (Amharic or English). Otherwise null.',
      },
    },
    required: ['matched', 'category_id', 'service_id', 'clarification_question'],
  },
}

Deno.serve(async (req) => {
  const preflight = handleCorsPreflight(req)
  if (preflight) return preflight

  if (req.method !== 'POST') {
    return json({ error: 'POST only' }, 405)
  }

  let query: string
  try {
    const body = await req.json()
    query = String(body.query ?? '').trim()
  } catch {
    return json({ error: 'Invalid JSON body' }, 400)
  }

  if (!query) {
    return json({ error: 'query is required' }, 400)
  }
  if (query.length > 500) {
    return json({ error: 'query too long' }, 400)
  }

  const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY)

  const [{ data: categories, error: categoriesError }, { data: services, error: servicesError }] =
    await Promise.all([
      supabase.from('categories').select('id, name_en, name_am').eq('is_active', true),
      supabase.from('services').select('id, category_id, name_en, name_am').eq('is_active', true),
    ])

  if (categoriesError || servicesError) {
    return json({ error: 'Failed to load catalog' }, 500)
  }

  const catalogText = [
    'Categories:',
    ...(categories ?? []).map((c) => `- id=${c.id} name_en="${c.name_en}" name_am="${c.name_am}"`),
    'Services:',
    ...(services ?? []).map(
      (s) => `- id=${s.id} category_id=${s.category_id} name_en="${s.name_en}" name_am="${s.name_am}"`,
    ),
  ].join('\n')

  const anthropicResponse = await fetch('https://api.anthropic.com/v1/messages', {
    method: 'POST',
    headers: {
      'x-api-key': ANTHROPIC_API_KEY,
      'anthropic-version': '2023-06-01',
      'content-type': 'application/json',
    },
    body: JSON.stringify({
      model: 'claude-sonnet-5',
      max_tokens: 500,
      tools: [CLASSIFY_TOOL],
      tool_choice: { type: 'tool', name: 'classify_search_query' },
      messages: [
        {
          role: 'user',
          content:
            `A customer of a services marketplace for Ethiopian-American businesses in the US ` +
            `typed this search (it may be in ` +
            `English or Amharic): "${query}"\n\n` +
            `Here is the platform's current catalog:\n${catalogText}\n\n` +
            `Pick the single best-matching category and, if identifiable, service, using ONLY the ` +
            `ids listed above. If nothing in the catalog plausibly matches, or the query is too ` +
            `vague to pick one confidently, set matched to false and ask one short clarifying ` +
            `question in the same language the customer used.`,
        },
      ],
    }),
  })

  if (!anthropicResponse.ok) {
    const detail = await anthropicResponse.text()
    console.error('Anthropic API error', anthropicResponse.status, detail)
    return json({ error: 'AI service unavailable' }, 502)
  }

  const anthropicResult = await anthropicResponse.json()
  const toolUse = anthropicResult.content?.find((block: { type: string }) => block.type === 'tool_use')

  if (!toolUse) {
    return json({ error: 'AI did not return a structured result' }, 502)
  }

  const raw = toolUse.input as {
    matched: boolean
    category_id: string | null
    service_id: string | null
    clarification_question: string | null
  }

  // Never trust the model's ids blindly — confirm each one actually exists
  // in the catalog we just fetched before handing anything back to the
  // client. This is the "validate AI output before using it" step from
  // spec section 15.
  const validCategoryIds = new Set((categories ?? []).map((c) => c.id))
  const validServiceIds = new Set((services ?? []).map((s) => s.id))

  const categoryId = raw.category_id && validCategoryIds.has(raw.category_id) ? raw.category_id : null
  const serviceId = raw.service_id && validServiceIds.has(raw.service_id) ? raw.service_id : null
  const matched = raw.matched === true && (categoryId !== null || serviceId !== null)

  const result = matched
    ? { matched: true, categoryId, serviceId }
    : {
        matched: false,
        clarificationQuestion:
          raw.clarification_question ?? 'Could you describe what service you need?',
      }

  return json(result)
})
