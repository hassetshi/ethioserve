// Digital payment webhook. This is the one legitimate place `payments` rows
// get written for card payments, per the table's own comment in
// 20260831000006_payments_subscriptions_ads.sql: "written... by Edge
// Functions using the service-role key, after verifying the payment
// provider's webhook/API response" — mirroring how record_cash_payment()
// is the sanctioned path for cash. Deployed with --no-verify-jwt since
// Stripe never sends a Supabase session; the Stripe-Signature header is
// verified manually below instead, which is the actual security boundary
// here (never trust an unverified webhook body).
import { createClient } from 'jsr:@supabase/supabase-js@2'

const STRIPE_WEBHOOK_SECRET = Deno.env.get('STRIPE_WEBHOOK_SECRET')!
const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

async function verifyStripeSignature(
  rawBody: string,
  signatureHeader: string,
  secret: string,
): Promise<boolean> {
  const parts = Object.fromEntries(
    signatureHeader.split(',').map((kv) => {
      const [k, v] = kv.split('=')
      return [k, v]
    }),
  )
  const timestamp = parts['t']
  const signature = parts['v1']
  if (!timestamp || !signature) return false

  const key = await crypto.subtle.importKey(
    'raw',
    new TextEncoder().encode(secret),
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign'],
  )
  const signatureBytes = await crypto.subtle.sign(
    'HMAC',
    key,
    new TextEncoder().encode(`${timestamp}.${rawBody}`),
  )
  const expectedSignature = Array.from(new Uint8Array(signatureBytes))
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('')

  return expectedSignature === signature
}

Deno.serve(async (req) => {
  if (req.method !== 'POST') {
    return new Response('POST only', { status: 405 })
  }

  const signatureHeader = req.headers.get('Stripe-Signature')
  const rawBody = await req.text()

  if (!signatureHeader || !(await verifyStripeSignature(rawBody, signatureHeader, STRIPE_WEBHOOK_SECRET))) {
    console.error('Stripe webhook signature verification failed')
    return new Response('Invalid signature', { status: 401 })
  }

  const event = JSON.parse(rawBody)

  if (event.type !== 'payment_intent.succeeded') {
    // Acknowledge everything else so Stripe stops retrying; only this one
    // event type drives payment recording.
    return new Response(JSON.stringify({ received: true }), { status: 200 })
  }

  const paymentIntent = event.data.object
  const bookingId = paymentIntent.metadata?.booking_id
  if (!bookingId) {
    console.error('payment_intent.succeeded with no booking_id metadata', paymentIntent.id)
    return new Response(JSON.stringify({ received: true }), { status: 200 })
  }

  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)

  const { data: existingPayment } = await supabase
    .from('payments')
    .select('id')
    .eq('booking_id', bookingId)
    .maybeSingle()
  if (existingPayment) {
    // Stripe can and does deliver the same webhook more than once - makes
    // this idempotent rather than erroring (or double-recording) on retry.
    return new Response(JSON.stringify({ received: true }), { status: 200 })
  }

  const { data: booking, error: bookingError } = await supabase
    .from('bookings')
    .select('customer_id, provider_id, final_price')
    .eq('id', bookingId)
    .maybeSingle()

  if (bookingError || !booking) {
    console.error('Booking not found for webhook', bookingId, bookingError)
    return new Response(JSON.stringify({ received: true }), { status: 200 })
  }

  const { data: commission, error: commissionError } = await supabase
    .rpc('calculate_commission', { p_amount: booking.final_price })
    .single()

  if (commissionError || !commission) {
    console.error('Commission calculation failed', commissionError)
    return new Response('Failed to process payment', { status: 500 })
  }

  const { platform_fee, provider_amount } = commission as {
    platform_fee: number
    provider_amount: number
  }

  const { error: insertError } = await supabase.from('payments').insert({
    booking_id: bookingId,
    customer_id: booking.customer_id,
    provider_id: booking.provider_id,
    amount: booking.final_price,
    platform_fee,
    provider_amount,
    currency: 'USD',
    payment_provider: 'stripe',
    transaction_reference: paymentIntent.id,
    status: 'completed',
    paid_at: new Date().toISOString(),
  })

  if (insertError) {
    console.error('Failed to insert payment row', insertError)
    return new Response('Failed to record payment', { status: 500 })
  }

  return new Response(JSON.stringify({ received: true }), { status: 200 })
})
