import 'package:flutter/material.dart';
import 'package:gemini_landscaping_app/models/equipment_model.dart';
import 'package:gemini_landscaping_app/models/schedule_model.dart';
import 'package:gemini_landscaping_app/screens/schedule/components/draggable_schedule_entry.dart';

class TruckColumn extends StatelessWidget {
  final Equipment truck;
  final List<ScheduleEntry> schedule;
  final Function(int?) onHover;
  final Function(ScheduleEntry, DateTime) onDrop;
  final Function(int) onTapSlot;
  final Function(ScheduleEntry, DateTime) onResize;
  final Function(int?) onResizeHover;
  final DateTime selectedDate;
  final bool includeTruckTitle; // New parameter to include the truck title

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
  });

  @override
  Widget build(BuildContext context) {
    const double timeSlotHeight = 40.0;
    const int slotsPerDay = 22;

    return SizedBox(
      width: 150,
      child: Column(
        children: [
          if (includeTruckTitle)
            Container(
              height: timeSlotHeight,
              width: double.infinity,
              color: truck.color.withOpacity(0.2),
              child: Center(
                  child: Text(truck.name,
                      style: TextStyle(
                        fontSize: 12,
                      ))),
            ),
          Container(
            height: timeSlotHeight * slotsPerDay,
            child: Stack(
              children: [
                ...List.generate(slotsPerDay, (index) {
                  final hour = 7 + (index ~/ 2);
                  final minute = (index % 2) * 30;
                  final slotTime = DateTime(selectedDate.year,
                      selectedDate.month, selectedDate.day, hour, minute);
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

                          print(
                              'Hover: localPosition.dy=${localPosition.dy}, topSlotIndex=$topSlotIndex');
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
                          print(
                              'Drop: localPosition.dy=${localPosition.dy}, topSlotIndex=$topSlotIndex, slotTime=$slotTime');
                          onDrop(details.data, slotTime);
                        },
                        builder: (context, candidateData, rejectedData) =>
                            Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: Colors.grey.withOpacity(0.2), width: 1),
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

                  print(
                      'Entry: ${entry.site.name}, startTime=${entry.startTime}, startOffset=$startOffset, durationSlots=$durationSlots');
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
