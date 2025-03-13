import 'package:flutter/material.dart';

class TimeColumn extends StatelessWidget {
  final int? hoveredSlotIndex;
  final bool includeTimeTitle; // Parameter to include the "Time" title

  const TimeColumn({
    required this.hoveredSlotIndex,
    this.includeTimeTitle = false,
  });

  @override
  Widget build(BuildContext context) {
    const double timeSlotHeight = 40.0;
    const int slotsPerDay = 22;

    return Column(
      children: [
        if (includeTimeTitle)
          Container(
            height: timeSlotHeight,
            width: double.infinity,
            color: Colors.grey[200],
            child: Center(child: Text('Time', style: TextStyle(fontSize: 12))),
          ),
        ...List.generate(slotsPerDay, (index) {
          // Calculate the hour in 24-hour format
          final hour24 = 7 + (index ~/ 2);
          final minute = (index % 2) * 30;

          // Convert to 12-hour format
          final hour12 =
              hour24 > 12 ? hour24 - 12 : (hour24 == 0 ? 12 : hour24);
          final period = hour24 >= 12 ? 'PM' : 'AM';
          final isHovered = hoveredSlotIndex == index;

          return Container(
            height: timeSlotHeight,
            width: double.infinity,
            decoration: BoxDecoration(
              color:
                  isHovered ? Colors.blue.withOpacity(0.2) : Colors.transparent,
              border: Border.all(color: Colors.grey.withOpacity(0.2), width: 1),
            ),
            child: Center(
              child: Text(
                minute == 0 ? '$hour12:00 $period' : '$hour12:30 $period',
                style: TextStyle(fontSize: 12),
              ),
            ),
          );
        }),
      ],
    );
  }
}
