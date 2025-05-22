import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
      width: 50.0,
      child: Column(
        children: [
          if (includeTimeTitle)
            Container(
              height: timeSlotHeight,
              width: double.infinity,
              color: Colors.white,
              child: Center(
                  child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('Time', style: TextStyle(fontSize: 12)))),
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
              padding: const EdgeInsets.all(4.0),
              decoration: BoxDecoration(
                color: isCurrentTime
                    ? Colors.greenAccent
                        .withOpacity(0.6) // Highlight current time
                    : isHovered
                        ? Colors.orangeAccent.withOpacity(0.6)
                        : Color.fromARGB(255, 59, 82, 73).withValues(
                            alpha: 0.6,
                          ),
                border:
                    Border.all(color: Colors.grey.withOpacity(0.2), width: 1),
              ),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    minute == 0 ? '$hour12:00 $period' : '$hour12:30 $period',
                    style: GoogleFonts.montserrat(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isHovered || isCurrentTime
                          ? Colors.black
                          : Colors.white,
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
