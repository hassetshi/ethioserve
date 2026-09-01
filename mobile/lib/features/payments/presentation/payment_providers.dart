import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/supabase_payment_repository.dart';
import '../domain/payment.dart';
import '../domain/payment_repository.dart';

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return SupabasePaymentRepository(Supabase.instance.client);
});

final paymentForBookingProvider =
    FutureProvider.autoDispose.family<Payment?, String>((ref, bookingId) {
  return ref.watch(paymentRepositoryProvider).getPaymentForBooking(bookingId);
});
