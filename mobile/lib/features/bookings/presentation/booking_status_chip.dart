import 'package:flutter/material.dart';

import '../domain/booking_status.dart';

class BookingStatusChip extends StatelessWidget {
  const BookingStatusChip({required this.status, super.key});

  final BookingStatus status;

  Color _color(BuildContext context) => switch (status) {
        BookingStatus.requested => Colors.orange,
        BookingStatus.accepted || BookingStatus.onTheWay => Colors.blue,
        BookingStatus.inProgress => Colors.indigo,
        BookingStatus.completed => Colors.green,
        BookingStatus.declined || BookingStatus.cancelled => Colors.grey,
      };

  @override
  Widget build(BuildContext context) {
    final color = _color(context);
    return Chip(
      label: Text(status.displayLabel, style: TextStyle(color: color)),
      backgroundColor: color.withValues(alpha: 0.12),
      side: BorderSide(color: color.withValues(alpha: 0.4)),
      visualDensity: VisualDensity.compact,
    );
  }
}
