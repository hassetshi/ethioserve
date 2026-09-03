// Shared by every Edge Function invoked directly from the Flutter app via
// `functions.invoke()`. Native Android/iOS builds never hit CORS (it's a
// browser-only mechanism), which is exactly why this gap went unnoticed
// until manual testing on the web target — every prior live verification of
// these functions was a direct server-to-server fetch/curl call, never an
// actual browser request. stripe-webhook doesn't need this: Stripe calls it
// server-to-server, not from a browser.
export const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

export function handleCorsPreflight(req: Request): Response | null {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }
  return null
}
