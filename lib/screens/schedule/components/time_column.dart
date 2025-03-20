import 'package:flutter/material.dart';

class TimeColumn extends StatelessWidget {
  final int? hoveredSlotIndex;
  final bool includeTimeTitle;

  const TimeColumn({
    required this.hoveredSlotIndex,
    this.includeTimeTitle = false,
  });

  @override
  Widget build(BuildContext context) {
    const double timeSlotHeight = 40.0;
    const int slotsPerDay = 22;

    // Get current time
    final now = DateTime.now();
    final currentHour = now.hour;
    final currentMinute = now.minute;

    // Calculate the current slot index (7:00 AM = slot 0)
    final minutesSince7AM = (currentHour - 7) * 60 + currentMinute;
    final currentSlotIndex =
        (minutesSince7AM / 30).floor(); // 30-min increments

    return SizedBox(
      width: 60.0,
      child: Column(
        children: [
          if (includeTimeTitle)
            Container(
              height: timeSlotHeight,
              width: double.infinity,
              color: Colors.grey[200],
              child:
                  Center(child: Text('Time', style: TextStyle(fontSize: 12))),
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
            final isCurrentTime = index == currentSlotIndex &&
                now.day == DateTime.now().day; // Ensure same day

            return Container(
              height: timeSlotHeight,
              width: double.infinity,
              decoration: BoxDecoration(
                color: isCurrentTime
                    ? Colors.greenAccent
                        .withOpacity(0.3) // Highlight current time
                    : isHovered
                        ? Colors.orangeAccent.withOpacity(0.2)
                        : Colors.transparent,
                border:
                    Border.all(color: Colors.grey.withOpacity(0.2), width: 1),
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
      ),
    );
  }
}
