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
  late DateTime currentMonday; // Start of the current week
  Map<DateTime, List<DateTime>> weekDates = {}; // Maps week start to its days
  Map<DateTime, Map<DateTime, List<ScheduleEntry>>> weekSchedules =
      {}; // Nested map for weeks and days
  List<Equipment> trucks = [];
  static const double timeSlotHeight = 40.0;
  static const int slotsPerDay = 20;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    currentMonday = now.subtract(
        Duration(days: now.weekday - 1)); // Start of current week (Monday)
    _loadWeekData();
  }

  Future<void> _loadWeekData() async {
    trucks = await _service.fetchActiveTrucks();

    // Define the three weeks: previous, current, next
    final previousMonday = currentMonday.subtract(Duration(days: 7));
    final nextMonday = currentMonday.add(Duration(days: 7));

    // Map each week's start date to its 5 days (Mon-Fri)
    weekDates = {
      previousMonday:
          List.generate(5, (i) => previousMonday.add(Duration(days: i))),
      currentMonday:
          List.generate(5, (i) => currentMonday.add(Duration(days: i))),
      nextMonday: List.generate(5, (i) => nextMonday.add(Duration(days: i))),
    };

    // Load schedules for all days in the three weeks
    weekSchedules = {
      previousMonday: {
        for (var day in weekDates[previousMonday]!)
          day: await _service.fetchSchedules(day)
      },
      currentMonday: {
        for (var day in weekDates[currentMonday]!)
          day: await _service.fetchSchedules(day)
      },
      nextMonday: {
        for (var day in weekDates[nextMonday]!)
          day: await _service.fetchSchedules(day)
      },
    };

    setState(() {});
  }

  void _navigateWeek(bool forward) {
    setState(() {
      currentMonday = forward
          ? currentMonday.add(Duration(days: 7))
          : currentMonday.subtract(Duration(days: 7));
      _loadWeekData(); // Reload data for the new week range
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Week View: 3 Weeks'),
        actions: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios),
            onPressed: () => _navigateWeek(false),
          ),
          IconButton(
            icon: Icon(Icons.arrow_forward_ios),
            onPressed: () => _navigateWeek(true),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Previous Week
            _buildWeekSection(
                currentMonday.subtract(Duration(days: 7)), 'Previous Week'),
            // Current Week
            _buildWeekSection(currentMonday, 'Current Week'),
            // Next Week
            _buildWeekSection(
                currentMonday.add(Duration(days: 7)), 'Next Week'),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekSection(DateTime weekStart, String weekLabel) {
    final weekDays = List.generate(5, (i) => weekStart.add(Duration(days: i)));
    final schedulesForWeek = weekSchedules[weekStart] ?? {};

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(weekLabel,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
        SizedBox(
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
                          child: Center(
                              child: Text(DateFormat('MMM d').format(day))),
                        ),
                        Row(
                          children: trucks
                              .map((truck) => SizedBox(
                                    width: 150,
                                    height: timeSlotHeight * slotsPerDay,
                                    child: Stack(
                                      children: (schedulesForWeek[day] ?? [])
                                              .where((entry) =>
                                                  entry.truckId == truck.id)
                                              .map((entry) {
                                            final startMinutes =
                                                entry.startTime.hour * 60 +
                                                    entry.startTime.minute;
                                            final endMinutes =
                                                entry.endTime.hour * 60 +
                                                    entry.endTime.minute;
                                            final startOffset =
                                                (startMinutes - 7 * 60) / 30;
                                            final durationSlots =
                                                (endMinutes - startMinutes) /
                                                    30;

                                            return Positioned(
                                              top: startOffset * timeSlotHeight,
                                              left: 0,
                                              right: 0,
                                              height: durationSlots *
                                                  timeSlotHeight,
                                              child: Container(
                                                color: truck.color
                                                    .withOpacity(0.5),
                                                child: Center(
                                                    child:
                                                        Text(entry.site.name)),
                                              ),
                                            );
                                          }).toList() ??
                                          [],
                                    ),
                                  ))
                              .toList(),
                        ),
                      ],
                    )),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
