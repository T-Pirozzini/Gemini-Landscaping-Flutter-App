import 'package:flutter/material.dart';
import 'package:gemini_landscaping_app/models/equipment_model.dart';
import 'package:gemini_landscaping_app/models/schedule_model.dart';
import 'package:gemini_landscaping_app/services/schedule_service.dart';
import 'package:intl/intl.dart';

class WeekViewScreen extends StatefulWidget {
  @override
  _WeekViewScreenState createState() => _WeekViewScreenState();
}

class _WeekViewScreenState extends State<WeekViewScreen> {
  final ScheduleService _service = ScheduleService();
  late List<DateTime> currentWeekDays; // Monday to Friday
  Map<DateTime, List<ScheduleEntry>> weekSchedules = {};
  List<Equipment> activeTrucks = []; // List of all active trucks
  Equipment? selectedTruck; // Currently selected truck
  static const double timeSlotHeight = 20.0; // Reduced height for smaller boxes
  static const int slotsPerDay =
      20; // 7:00 AM to 5:00 PM (10 hours × 2 slots/hour)
  static const double timeColumnWidth = 50.0; // Width for time column

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final monday = now.subtract(
        Duration(days: now.weekday - 1)); // Start of current week (Monday)
    currentWeekDays = List.generate(
        5, (i) => monday.add(Duration(days: i))); // Monday to Friday
    _loadWeekData();
  }

  Future<void> _loadWeekData() async {
    activeTrucks = await _service.fetchActiveTrucks();
    if (activeTrucks.isNotEmpty) {
      selectedTruck = activeTrucks.first; // Default to first truck
      for (var day in [
        ...currentWeekDays
            .map((day) => day.subtract(Duration(days: 7))), // Previous week
        ...currentWeekDays, // Current week
        ...currentWeekDays
            .map((day) => day.add(Duration(days: 7))), // Following week
      ]) {
        weekSchedules[day] = await _service.fetchSchedules(day);
      }
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final appBarHeight = AppBar().preferredSize.height;
    final availableHeight = screenHeight -
        appBarHeight -
        MediaQuery.of(context).padding.top -
        MediaQuery.of(context).padding.bottom;
    final availableWidth = screenWidth - timeColumnWidth;
    final columnWidth =
        availableWidth / currentWeekDays.length; // Width per day (5 days)

    // Total height for 3 weeks (previous, current, next)
    final totalHeight = timeSlotHeight *
        (slotsPerDay + 1) *
        3; // 3 weeks × (20 slots + 1 header)

    return Scaffold(
      appBar: AppBar(
        title: Text('3-Week Schedule: Mon-Fri'),
        actions: [
          // Truck selection dropdown
          if (activeTrucks.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: DropdownButton<Equipment>(
                value: selectedTruck,
                hint: Text('Select Truck'),
                onChanged: (Equipment? newTruck) {
                  if (newTruck != null) {
                    setState(() {
                      selectedTruck = newTruck;
                    });
                  }
                },
                items: activeTrucks.map((Equipment truck) {
                  return DropdownMenuItem<Equipment>(
                    value: truck,
                    child: Text(
                      truck.name, // Assuming Equipment has a 'name' property
                      style: TextStyle(fontSize: 14),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
      body: selectedTruck == null
          ? Center(child: Text('Searching for active schedules...'))
          : SizedBox(
              height: totalHeight.clamp(
                  0.0, availableHeight), // Cap height to screen
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Previous Week
                    _buildWeekSection(
                      currentWeekDays
                          .map((day) => day.subtract(Duration(days: 7)))
                          .toList(),
                      'Previous Week',
                      columnWidth,
                    ),
                    // Current Week
                    _buildWeekSection(
                        currentWeekDays, 'Current Week', columnWidth),
                    // Following Week
                    _buildWeekSection(
                      currentWeekDays
                          .map((day) => day.add(Duration(days: 7)))
                          .toList(),
                      'Following Week',
                      columnWidth,
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildWeekSection(
      List<DateTime> weekDays, String weekLabel, double columnWidth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Text(
            weekLabel,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Time Column
            SizedBox(
              width: timeColumnWidth,
              child: Column(
                children: [
                  Container(
                    height: timeSlotHeight,
                    color: Colors.grey[200],
                    child: Center(
                      child: Text(
                        'Time',
                        style: TextStyle(fontSize: 10),
                      ),
                    ),
                  ),
                  ...List.generate(slotsPerDay, (index) {
                    final hour24 = 7 + (index ~/ 2);
                    final minute = (index % 2) * 30;
                    final hour12 =
                        hour24 > 12 ? hour24 - 12 : (hour24 == 0 ? 12 : hour24);
                    final period = hour24 >= 12 ? 'PM' : 'AM';

                    return Container(
                      height: timeSlotHeight,
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: Colors.grey.withOpacity(0.2), width: 1),
                      ),
                      child: Center(
                        child: Text(
                          minute == 0
                              ? '$hour12:00 $period'
                              : '$hour12:30 $period',
                          style: TextStyle(
                              fontSize: 6), // Smaller font for smaller height
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
            // Days and Schedules
            Expanded(
              child: Row(
                children: weekDays.map((day) {
                  final schedulesForDay = (weekSchedules[day] ?? [])
                      .where((entry) =>
                          entry.truckId ==
                          selectedTruck!.id) // Use selected truck
                      .toList();

                  return Column(
                    children: [
                      // Day Header
                      Container(
                        height: timeSlotHeight,
                        width: columnWidth,
                        color: Colors.grey[200],
                        child: Center(
                          child: Text(
                            DateFormat('MMM d, E').format(day),
                            style: TextStyle(fontSize: 8),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      // Schedule Slots
                      SizedBox(
                        width: columnWidth,
                        height: timeSlotHeight * slotsPerDay,
                        child: Stack(
                          children: schedulesForDay.map((entry) {
                            final startMinutes = entry.startTime.hour * 60 +
                                entry.startTime.minute;
                            final endMinutes =
                                entry.endTime.hour * 60 + entry.endTime.minute;
                            final startOffset = (startMinutes - 7 * 60) / 30;
                            final durationSlots =
                                (endMinutes - startMinutes) / 30;

                            return Positioned(
                              top: startOffset * timeSlotHeight,
                              left: 0,
                              right: 0,
                              height: durationSlots * timeSlotHeight,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: selectedTruck!.color.withOpacity(
                                      0.5), // Use selected truck's color
                                  border: Border.all(
                                      color: Colors.grey.withOpacity(0.2)),
                                ),
                                child: Center(
                                  child: Text(
                                    entry.site.name,
                                    style: TextStyle(fontSize: 6),
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
