import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TimeColumn extends StatelessWidget {
  final int? hoveredSlotIndex;
  const TimeColumn({required this.hoveredSlotIndex});

  @override
  Widget build(BuildContext context) {
    const double timeSlotHeight = 40.0;
    const int slotsPerDay = 20;

    return Column(
      children: List.generate(slotsPerDay, (index) {
        final hour = 7 + (index ~/ 2);
        final minute = (index % 2) * 30;
        final time = DateTime.now()
            .copyWith(hour: hour, minute: minute, second: 0, millisecond: 0);
        return Container(
          height: timeSlotHeight,
          width: 80,
          color: hoveredSlotIndex == index
              ? Colors.green.withOpacity(0.3)
              : Colors.transparent,
          child: Center(
            child: Text(
              DateFormat('h:mm a').format(time),
              style: const TextStyle(fontSize: 12),
            ),
          ),
        );
      }),
    );
  }
}