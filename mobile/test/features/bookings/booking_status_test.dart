import 'package:ethioserve/features/bookings/domain/booking_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BookingStatus.fromValue / value round-trip', () {
    for (final status in BookingStatus.values) {
      test('${status.name} round-trips through its string value', () {
        expect(BookingStatus.fromValue(status.value), status);
      });
    }
  });

  test('isTerminal is true only for completed, declined, cancelled', () {
    expect(BookingStatus.completed.isTerminal, isTrue);
    expect(BookingStatus.declined.isTerminal, isTrue);
    expect(BookingStatus.cancelled.isTerminal, isTrue);
    expect(BookingStatus.requested.isTerminal, isFalse);
    expect(BookingStatus.accepted.isTerminal, isFalse);
    expect(BookingStatus.onTheWay.isTerminal, isFalse);
    expect(BookingStatus.inProgress.isTerminal, isFalse);
  });
}
