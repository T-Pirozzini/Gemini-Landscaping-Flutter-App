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

    return SizedBox(
      width: 50.0,
      child: Column(
        children: [
          if (includeTimeTitle)
            Container(
              height: timeSlotHeight,
              width: double.infinity,
              color: Colors.grey[50],
              child: Center(
                child: Text(
                  'Time',
                  style: GoogleFonts.montserrat(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ),
          ...List.generate(slotsPerDay, (index) {
            final hour24 = 7 + (index ~/ 2);
            final minute = (index % 2) * 30;
            final hour12 =
                hour24 > 12 ? hour24 - 12 : (hour24 == 0 ? 12 : hour24);
            final isHovered = hoveredSlotIndex == index;
            final isFullHour = index % 2 == 0;

            return Container(
              height: timeSlotHeight,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              decoration: BoxDecoration(
                color: isHovered
                    ? Colors.orange.withValues(alpha: 0.08)
                    : Colors.grey[50],
                border: Border(
                  top: BorderSide(
                    color: isFullHour
                        ? Colors.grey[300]!
                        : Colors.grey.withValues(alpha: 0.15),
                    width: isFullHour ? 1.0 : 0.5,
                  ),
                  right: BorderSide(
                    color: Colors.grey[300]!,
                    width: 1.0,
                  ),
                ),
              ),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  minute == 0 ? '$hour12:00' : '$hour12:30',
                  style: GoogleFonts.montserrat(
                    fontSize: 10,
                    fontWeight: isFullHour ? FontWeight.w600 : FontWeight.w400,
                    color: isHovered
                        ? Colors.orange[800]
                        : isFullHour
                            ? Colors.grey[700]
                            : Colors.grey[400],
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
