// Digital payment (spec section 20), Stripe implementation. Deployed WITH
// JWT verification (unlike ai-search) — Supabase rejects the request before
// this code runs unless the caller has a valid session, and the
// Authorization header is then forwarded into an RLS-scoped Supabase client
// below so the booking lookup can only ever see the caller's own bookings.
// Ownership is enforced by Postgres RLS, not re-implemented here.
import { createClient } from 'jsr:@supabase/supabase-js@2'

const STRIPE_SECRET_KEY = Deno.env.get('STRIPE_SECRET_KEY')!
const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!
const SUPABASE_ANON_KEY = Deno.env.get('SUPABASE_ANON_KEY')!

Deno.serve(async (req) => {
  if (req.method !== 'POST') {
    return new Response(JSON.stringify({ error: 'POST only' }), { status: 405 })
  }

  const authHeader = req.headers.get('Authorization')
  if (!authHeader) {
    return new Response(JSON.stringify({ error: 'Missing Authorization header' }), { status: 401 })
  }

  let bookingId: string
  try {
    const body = await req.json()
    bookingId = String(body.bookingId ?? '')
  } catch {
    return new Response(JSON.stringify({ error: 'Invalid JSON body' }), { status: 400 })
  }
  if (!bookingId) {
    return new Response(JSON.stringify({ error: 'bookingId is required' }), { status: 400 })
  }

  const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
    global: { headers: { Authorization: authHeader } },
  })

  const { data: userData, error: userError } = await supabase.auth.getUser()
  if (userError || !userData.user) {
    return new Response(JSON.stringify({ error: 'Invalid session' }), { status: 401 })
  }

  const { data: booking, error: bookingError } = await supabase
    .from('bookings')
    .select('id, customer_id, status, final_price')
    .eq('id', bookingId)
    .maybeSingle()

  if (bookingError) {
    console.error('Booking lookup failed', bookingError)
    return new Response(JSON.stringify({ error: 'Failed to look up booking' }), { status: 500 })
  }
  if (!booking) {
    return new Response(JSON.stringify({ error: 'Booking not found' }), { status: 404 })
  }
  if (booking.customer_id !== userData.user.id) {
    return new Response(
      JSON.stringify({ error: 'Only the customer can pay for this booking' }),
      { status: 403 },
    )
  }
  if (booking.status !== 'completed') {
    return new Response(JSON.stringify({ error: 'Booking is not completed yet' }), { status: 400 })
  }
  if (booking.final_price == null) {
    return new Response(JSON.stringify({ error: 'Booking has no final price set' }), { status: 400 })
  }

  const { data: existingPayment } = await supabase
    .from('payments')
    .select('id')
    .eq('booking_id', bookingId)
    .maybeSingle()
  if (existingPayment) {
    return new Response(
      JSON.stringify({ error: 'This booking already has a payment record' }),
      { status: 400 },
    )
  }

  const amountCents = Math.round(Number(booking.final_price) * 100)

  const stripeResponse = await fetch('https://api.stripe.com/v1/payment_intents', {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${STRIPE_SECRET_KEY}`,
      'content-type': 'application/x-www-form-urlencoded',
    },
    body: new URLSearchParams({
      amount: String(amountCents),
      currency: 'usd',
      'metadata[booking_id]': bookingId,
      'automatic_payment_methods[enabled]': 'true',
    }),
  })

  if (!stripeResponse.ok) {
    const detail = await stripeResponse.text()
    console.error('Stripe PaymentIntent creation failed', stripeResponse.status, detail)
    return new Response(JSON.stringify({ error: 'Payment provider error' }), { status: 502 })
  }

  const paymentIntent = await stripeResponse.json()

  return new Response(JSON.stringify({ clientSecret: paymentIntent.client_secret }), {
    headers: { 'content-type': 'application/json' },
  })
})
