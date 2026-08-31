/// Mirrors the `bookings.status` check constraint and the state machine
/// enforced server-side in `validate_booking_status_transition()` — the
/// client never decides what's a legal transition, it just attempts one and
/// surfaces the server's rejection if it wasn't (spec section 9).
enum BookingStatus {
  requested,
  accepted,
  onTheWay,
  inProgress,
  completed,
  declined,
  cancelled;

  static BookingStatus fromValue(String value) => switch (value) {
        'accepted' => BookingStatus.accepted,
        'on_the_way' => BookingStatus.onTheWay,
        'in_progress' => BookingStatus.inProgress,
        'completed' => BookingStatus.completed,
        'declined' => BookingStatus.declined,
        'cancelled' => BookingStatus.cancelled,
        _ => BookingStatus.requested,
      };

  String get value => switch (this) {
        BookingStatus.requested => 'requested',
        BookingStatus.accepted => 'accepted',
        BookingStatus.onTheWay => 'on_the_way',
        BookingStatus.inProgress => 'in_progress',
        BookingStatus.completed => 'completed',
        BookingStatus.declined => 'declined',
        BookingStatus.cancelled => 'cancelled',
      };

  bool get isTerminal =>
      this == BookingStatus.completed ||
      this == BookingStatus.declined ||
      this == BookingStatus.cancelled;

  String get displayLabel => switch (this) {
        BookingStatus.requested => 'Requested',
        BookingStatus.accepted => 'Accepted',
        BookingStatus.onTheWay => 'On the way',
        BookingStatus.inProgress => 'In progress',
        BookingStatus.completed => 'Completed',
        BookingStatus.declined => 'Declined',
        BookingStatus.cancelled => 'Cancelled',
      };
}
