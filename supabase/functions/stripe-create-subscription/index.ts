// Provider listing subscription (spec: "Paid registration/subscription
// fee"). Same trust model as stripe-create-payment-intent: deployed WITH JWT
// verification, and the Authorization header is forwarded into an
// RLS-scoped Supabase client so the provider-ownership check is enforced by
// Postgres, not re-implemented here. The service-role client is used only
// for the parts RLS deliberately blocks a provider from doing themselves —
// reading platform_settings-derived plan prices and writing the
// subscriptions row — exactly like stripe-webhook does for payments.
import { createClient } from 'jsr:@supabase/supabase-js@2'
import { corsHeaders, handleCorsPreflight } from '../_shared/cors.ts'

const STRIPE_SECRET_KEY = Deno.env.get('STRIPE_SECRET_KEY')!
const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!
const SUPABASE_ANON_KEY = Deno.env.get('SUPABASE_ANON_KEY')!
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

const VALID_PLANS = new Set(['professional', 'premium'])

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'content-type': 'application/json' },
  })
}

async function stripePost(path: string, body: URLSearchParams) {
  return fetch(`https://api.stripe.com/v1/${path}`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${STRIPE_SECRET_KEY}`,
      'content-type': 'application/x-www-form-urlencoded',
    },
    body,
  })
}

Deno.serve(async (req) => {
  const preflight = handleCorsPreflight(req)
  if (preflight) return preflight

  if (req.method !== 'POST') {
    return json({ error: 'POST only' }, 405)
  }

  const authHeader = req.headers.get('Authorization')
  if (!authHeader) {
    return json({ error: 'Missing Authorization header' }, 401)
  }

  let providerId: string
  let plan: string
  try {
    const body = await req.json()
    providerId = String(body.providerId ?? '')
    plan = String(body.plan ?? '')
  } catch {
    return json({ error: 'Invalid JSON body' }, 400)
  }
  if (!providerId || !VALID_PLANS.has(plan)) {
    return json({ error: 'providerId and a valid plan are required' }, 400)
  }

  const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
    global: { headers: { Authorization: authHeader } },
  })

  const { data: userData, error: userError } = await supabase.auth.getUser()
  if (userError || !userData.user) {
    return json({ error: 'Invalid session' }, 401)
  }

  const { data: provider, error: providerError } = await supabase
    .from('provider_profiles')
    .select('id, user_id, business_name')
    .eq('id', providerId)
    .maybeSingle()

  if (providerError) {
    console.error('Provider lookup failed', providerError)
    return json({ error: 'Failed to look up provider' }, 500)
  }
  if (!provider) {
    return json({ error: 'Provider not found' }, 404)
  }
  if (provider.user_id !== userData.user.id) {
    return json({ error: 'Only the provider owner can subscribe' }, 403)
  }

  const { data: plans, error: plansError } = await supabase.rpc(
    'get_subscription_plans',
  )
  if (plansError || !plans) {
    console.error('Failed to load subscription plans', plansError)
    return json({ error: 'Failed to load subscription plans' }, 500)
  }
  const planRow = (
    plans as { plan: string; price_usd: number; stripe_price_id: string | null }[]
  ).find((p) => p.plan === plan)
  if (!planRow?.stripe_price_id) {
    return json({ error: 'This plan is not available yet' }, 400)
  }

  // subscriptions writes (and the plan-price read above's underlying table)
  // are deliberately not directly writable/readable by an authenticated
  // client via RLS — see subscriptions_admin_write and
  // platform_settings_admin_only. The service-role client is the sanctioned
  // path here, same as stripe-webhook's payments writes.
  const admin = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)

  const { data: existingActive } = await admin
    .from('subscriptions')
    .select('id')
    .eq('provider_id', providerId)
    .eq('status', 'active')
    .maybeSingle()
  if (existingActive) {
    return json(
      { error: 'This provider already has an active subscription' },
      400,
    )
  }

  const { data: priorSub } = await admin
    .from('subscriptions')
    .select('stripe_customer_id')
    .eq('provider_id', providerId)
    .not('stripe_customer_id', 'is', null)
    .order('created_at', { ascending: false })
    .limit(1)
    .maybeSingle()

  let customerId = priorSub?.stripe_customer_id as string | undefined

  if (!customerId) {
    const customerResponse = await stripePost(
      'customers',
      new URLSearchParams({
        name: provider.business_name,
        'metadata[provider_id]': providerId,
      }),
    )
    if (!customerResponse.ok) {
      const detail = await customerResponse.text()
      console.error(
        'Stripe customer creation failed',
        customerResponse.status,
        detail,
      )
      return json({ error: 'Payment provider error' }, 502)
    }
    customerId = (await customerResponse.json()).id
  }

  const subscriptionResponse = await stripePost(
    'subscriptions',
    new URLSearchParams({
      customer: customerId!,
      'items[0][price]': planRow.stripe_price_id,
      payment_behavior: 'default_incomplete',
      'expand[0]': 'latest_invoice.confirmation_secret',
      'metadata[provider_id]': providerId,
    }),
  )

  if (!subscriptionResponse.ok) {
    const detail = await subscriptionResponse.text()
    console.error(
      'Stripe subscription creation failed',
      subscriptionResponse.status,
      detail,
    )
    return json({ error: 'Payment provider error' }, 502)
  }

  const subscription = await subscriptionResponse.json()
  // Stripe invoices no longer carry a `payment_intent` field on this
  // account's API version - confirmed live (the real response had
  // `latest_invoice.confirmation_secret`, not `.payment_intent`, so the
  // old field name always read as undefined here). `confirmation_secret`
  // is the replacement and still has `type: 'payment_intent'` /
  // `client_secret`, which is all initPaymentSheet needs.
  const clientSecret = subscription.latest_invoice?.confirmation_secret?.client_secret
  if (!clientSecret) {
    console.error(
      'Stripe subscription has no confirmation_secret client_secret',
      subscription.id,
    )
    return json({ error: 'Payment provider error' }, 502)
  }

  const { error: insertError } = await admin.from('subscriptions').insert({
    provider_id: providerId,
    plan,
    price: planRow.price_usd,
    status: 'pending',
    stripe_customer_id: customerId,
    stripe_subscription_id: subscription.id,
  })
  if (insertError) {
    console.error('Failed to record pending subscription', insertError)
    return json({ error: 'Failed to record subscription' }, 500)
  }

  return json({ clientSecret })
})
