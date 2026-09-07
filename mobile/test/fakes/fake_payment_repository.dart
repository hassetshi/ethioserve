import 'package:ethioserve/features/payments/domain/payment.dart';
import 'package:ethioserve/features/payments/domain/payment_repository.dart';

class FakePaymentRepository implements PaymentRepository {
  Payment? payment;

  @override
  Future<Payment> recordCashPayment(String bookingId) async {
    payment = Payment(
      id: 'payment-1',
      bookingId: bookingId,
      amount: 1000,
      platformFee: 100,
      providerAmount: 900,
      currency: 'USD',
      paymentProvider: 'cash',
      status: 'completed',
      paidAt: DateTime.now(),
    );
    return payment!;
  }

  @override
  Future<Payment> initializeDigitalPayment(String bookingId) async {
    payment = Payment(
      id: 'payment-1',
      bookingId: bookingId,
      amount: 1000,
      platformFee: 100,
      providerAmount: 900,
      currency: 'USD',
      paymentProvider: 'stripe',
      status: 'completed',
      paidAt: DateTime.now(),
    );
    return payment!;
  }

  @override
  Future<Payment?> getPaymentForBooking(String bookingId) async => payment;
}
