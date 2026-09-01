import 'payment.dart';

/// Spec section 20's PaymentService, adapted to what a client legitimately
/// does: `verifyPayment()` and `handleWebhook()` are server-only concerns
/// (a webhook is inbound from the payment provider to our backend; a client
/// confirming its own payment is exactly what "never trust payment
/// confirmation from the mobile client" forbids) and so have no client-side
/// method here — they belong to a future Edge Function, not this interface.
abstract class PaymentRepository {
  /// Cash collected in person, recorded by the provider after completing
  /// the job. Amount and commission split are computed server-side from the
  /// booking's final_price — the client cannot set either.
  Future<Payment> recordCashPayment(String bookingId);

  /// Not yet available: no digital payment provider (Chapa/Telebirr/etc.)
  /// is configured. Throws a [ValidationException]-style error with a
  /// message safe to show the user. Exists now so a real implementation
  /// swaps in later without touching call sites (spec section 20: "Do not
  /// hard-code one Ethiopian payment provider").
  Future<Payment> initializeDigitalPayment(String bookingId);

  Future<Payment?> getPaymentForBooking(String bookingId);
}
