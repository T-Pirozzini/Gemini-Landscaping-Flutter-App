import 'package:flutter/material.dart';
import 'package:gemini_landscaping_app/models/equipment_model.dart';
import 'package:gemini_landscaping_app/models/schedule_model.dart';
import 'package:gemini_landscaping_app/screens/schedule/components/draggable_schedule_entry.dart';
import 'package:google_fonts/google_fonts.dart';

class TruckColumn extends StatelessWidget {
  final Equipment truck;
  final List<ScheduleEntry> schedule;
  final Function(int?) onHover;
  final Function(ScheduleEntry, DateTime) onDrop;
  final Function(int) onTapSlot;
  final Function(ScheduleEntry, DateTime) onResize;
  final Function(int?) onResizeHover;
  final DateTime selectedDate;
  final bool includeTruckTitle;
  final VoidCallback onRefresh;
  final String? userRole;
  final double columnWidth;

  const TruckColumn({
    required this.truck,
    required this.schedule,
    required this.onHover,
    required this.onDrop,
    required this.onTapSlot,
    required this.onResize,
    required this.onResizeHover,
    required this.selectedDate,
    this.includeTruckTitle = false,
    required this.onRefresh,
    this.userRole,
    this.columnWidth = 130,
  });

  @override
  Widget build(BuildContext context) {
    const double timeSlotHeight = 40.0;
    const int slotsPerDay = 22;

    return SizedBox(
      width: columnWidth,
      child: Column(
        children: [
          if (includeTruckTitle)
            Container(
              height: timeSlotHeight,
              width: double.infinity,
              decoration: BoxDecoration(
                color: truck.color.withValues(alpha: 0.15),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(8)),
              ),
              child: Center(
                child: Text(
                  truck.name,
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: truck.color,
                  ),
                ),
              ),
            ),
          Container(
            height: timeSlotHeight * slotsPerDay,
            child: Stack(
              children: [
                ...List.generate(slotsPerDay, (index) {
                  final isFullHour = index % 2 == 0;
                  return Positioned(
                    top: index * timeSlotHeight,
                    left: 0,
                    right: 0,
                    height: timeSlotHeight,
                    child: GestureDetector(
                      onTap: () => onTapSlot(index),
                      child: DragTarget<ScheduleEntry>(
                        onWillAcceptWithDetails: (details) {
                          final RenderBox renderBox =
                              context.findRenderObject() as RenderBox;
                          final localPosition =
                              renderBox.globalToLocal(details.offset);

                          final topSlotIndex =
                              (localPosition.dy / timeSlotHeight)
                                  .floor()
                                  .clamp(0, slotsPerDay - 1);

                          onHover(topSlotIndex);
                          return true;
                        },
                        onLeave: (_) => onHover(null),
                        onAcceptWithDetails: (details) {
                          final RenderBox renderBox =
                              context.findRenderObject() as RenderBox;
                          final localPosition =
                              renderBox.globalToLocal(details.offset);

                          final topSlotIndex =
                              (localPosition.dy / timeSlotHeight)
                                  .floor()
                                  .clamp(0, slotsPerDay - 1);
                          final slotTime = DateTime(
                            selectedDate.year,
                            selectedDate.month,
                            selectedDate.day,
                            7 + (topSlotIndex ~/ 2),
                            (topSlotIndex % 2) * 30,
                          );
                          onDrop(details.data, slotTime);
                        },
                        builder: (context, candidateData, rejectedData) =>
                            Container(
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(
                                color: isFullHour
                                    ? Colors.grey[300]!
                                    : Colors.grey.withValues(alpha: 0.15),
                                width: isFullHour ? 1.0 : 0.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
                ...schedule.map((entry) {
                  final startMinutes =
                      entry.startTime.hour * 60 + entry.startTime.minute;
                  final endMinutes =
                      entry.endTime.hour * 60 + entry.endTime.minute;
                  final startOffset = (startMinutes - 7 * 60) / 30;
                  final durationSlots = (endMinutes - startMinutes) / 30;

                  return Positioned(
                    top: startOffset * timeSlotHeight,
                    left: 0,
                    right: 0,
                    height: durationSlots * timeSlotHeight,
                    child: DraggableScheduleEntry(
                      entry: entry,
                      truck: truck,
                      startOffset: startOffset,
                      durationSlots: durationSlots,
                      onResize: onResize,
                      onResizeHover: onResizeHover,
                      selectedDate: selectedDate,
                      onRefresh: onRefresh,
                      userRole: userRole,
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
