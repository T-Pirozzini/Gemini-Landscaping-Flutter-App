import 'package:flutter/material.dart';
import 'package:gemini_landscaping_app/models/equipment_model.dart';
import 'package:gemini_landscaping_app/models/schedule_model.dart';
import 'package:gemini_landscaping_app/screens/schedule/components/time_column.dart';
import 'package:gemini_landscaping_app/services/schedule_service.dart';
import 'package:intl/intl.dart';

class WeekViewScreen extends StatefulWidget {
  @override
  _WeekViewScreenState createState() => _WeekViewScreenState();
}

class _WeekViewScreenState extends State<WeekViewScreen> {
  final ScheduleService _service = ScheduleService();
  late List<DateTime> weekDays;
  Map<DateTime, List<ScheduleEntry>> weekSchedules = {};
  List<Equipment> trucks = [];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    weekDays = List.generate(5, (i) => monday.add(Duration(days: i)));
    _loadWeekData();
  }

  Future<void> _loadWeekData() async {
    trucks = await _service.fetchTrucks();
    for (var day in weekDays) {
      weekSchedules[day] = await _service.fetchSchedules(day);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    const double timeSlotHeight = 40.0;
    const int slotsPerDay = 20;

    return Scaffold(
      appBar: AppBar(title: Text('Week View: Mon-Fri')),
      body: SingleChildScrollView(
        child: SizedBox(
          height: timeSlotHeight * slotsPerDay + 40,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                TimeColumn(hoveredSlotIndex: null), // No dragging in week view
                ...weekDays.map((day) => Column(
                      children: [
                        Container(
                          height: 40,
                          width: trucks.length * 150.0,
                          child: Center(child: Text(DateFormat('MMM d').format(day))),
                        ),
                        Row(
                          children: trucks.map((truck) => SizedBox(
                                width: 150,
                                height: timeSlotHeight * slotsPerDay,
                                child: Stack(
                                  children: weekSchedules[day]
                                          ?.where((entry) => entry.truckId == truck.id)
                                          .map((entry) {
                                    final startMinutes = entry.startTime.hour * 60 + entry.startTime.minute;
                                    final endMinutes = entry.endTime.hour * 60 + entry.endTime.minute;
                                    final startOffset = (startMinutes - 7 * 60) / 30;
                                    final durationSlots = (endMinutes - startMinutes) / 30;

                                    return Positioned(
                                      top: startOffset * timeSlotHeight,
                                      left: 0,
                                      right: 0,
                                      height: durationSlots * timeSlotHeight,
                                      child: Container(
                                        color: truck.color.withOpacity(0.5),
                                        child: Center(child: Text(entry.site.name)),
                                      ),
                                    );
                                  }).toList() ??
                                      [],
                                ),
                              )).toList(),
                        ),
                      ],
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}