import 'package:flutter/material.dart';

class TimeColumn extends StatelessWidget {
  final int? hoveredSlotIndex;
  final bool includeTimeTitle; // New parameter to include the "Time" title

  const TimeColumn({
    required this.hoveredSlotIndex,
    this.includeTimeTitle = false,
  });

  @override
  Widget build(BuildContext context) {
    const double timeSlotHeight = 40.0;
    const int slotsPerDay = 20;

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
          final hour = 7 + (index ~/ 2);
          final minute = (index % 2) * 30;
          final isHovered = hoveredSlotIndex == index;

          return Container(
            height: timeSlotHeight,
            width: double.infinity,
            decoration: BoxDecoration(
              color: isHovered ? Colors.blue.withOpacity(0.2) : Colors.transparent,
              border: Border.all(color: Colors.grey.withOpacity(0.2), width: 1),
            ),
            child: Center(
              child: Text(
                minute == 0 ? '$hour:00' : '$hour:30',
                style: TextStyle(fontSize: 12),
              ),
            ),
          );
        }),
      ],
    );
  }
}
