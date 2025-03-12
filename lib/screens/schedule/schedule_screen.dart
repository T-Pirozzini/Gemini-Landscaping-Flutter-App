import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:gemini_landscaping_app/models/equipment_model.dart';
import 'package:gemini_landscaping_app/models/schedule_model.dart';
import 'package:gemini_landscaping_app/models/site_info.dart';
import 'package:gemini_landscaping_app/screens/schedule/week_view_screen.dart';
import 'package:gemini_landscaping_app/services/schedule_service.dart';
import 'package:intl/intl.dart';

class ScheduleScreen extends StatefulWidget {
  @override
  _ScheduleScreenState createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final ScheduleService _service = ScheduleService();
  List<ScheduleEntry> schedule = [];
  List<SiteInfo> activeSites = [];
  List<Equipment> trucks = [];
  DateTime selectedDate = DateTime.now();
  int? _hoveredSlotIndex;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    activeSites = await _service.fetchActiveSites();
    trucks = await _service.fetchTrucks();
    print('Loaded trucks: ${trucks.length}');
    trucks.forEach((truck) => print('Truck: ${truck.name}, ${truck.id}'));
    schedule = await _service.fetchSchedules(selectedDate);
    setState(() {});
  }

  void _changeDate(int days) {
    setState(() {
      selectedDate = selectedDate.add(Duration(days: days));
      _loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    const double timeSlotHeight = 40.0;
    const int slotsPerDay = 20;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            IconButton(
              icon: Icon(Icons.arrow_left),
              onPressed: () => _changeDate(-1),
            ),
            Text(
                'Schedule - ${DateFormat('MMM d, yyyy').format(selectedDate)}'),
            IconButton(
              icon: Icon(Icons.arrow_right),
              onPressed: () => _changeDate(1),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.local_shipping),
            onPressed: () => _showTruckManager(context),
          ),
          IconButton(
            icon: Icon(Icons.calendar_view_week),
            onPressed: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => WeekViewScreen())),
          ),
        ],
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 40,
                  color: Colors.grey[200],
                  child: Center(
                      child: Text('Time', style: TextStyle(fontSize: 12))),
                ),
                ...trucks.map((truck) => Container(
                      width: 150,
                      height: 40,
                      color: truck.color.withOpacity(0.2),
                      child: Center(
                          child:
                              Text(truck.name, style: TextStyle(fontSize: 12))),
                    )),
              ],
            ),
            // Schedule Grid
            Expanded(
              child: SingleChildScrollView(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 80,
                      child: TimeColumn(hoveredSlotIndex: _hoveredSlotIndex),
                    ),
                    ...trucks.map((truck) => TruckColumn(
                          truck: truck,
                          schedule: schedule
                              .where((entry) => entry.truckId == truck.id)
                              .toList(),
                          onHover: (index) =>
                              setState(() => _hoveredSlotIndex = index),
                          onDrop: (entry, slotTime) =>
                              _updateScheduleEntry(entry, slotTime, truck.id),
                          selectedDate: selectedDate,
                        )),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showSitePicker(context),
        child: Icon(Icons.add),
      ),
    );
  }

  void _addScheduleEntry(
      SiteInfo site, DateTime start, DateTime end, Equipment? truck) async {
    final entry = ScheduleEntry(
      site: site,
      startTime: start,
      endTime: end,
      truckId: truck?.id,
    );
    await _service.addScheduleEntry(entry);
    await _loadData();
  }

  void _updateScheduleEntry(
      ScheduleEntry entry, DateTime newStart, String newTruckId) async {
    final duration = entry.endTime.difference(entry.startTime);
    final newEnd = newStart.add(duration);
    final updatedEntry = ScheduleEntry(
      id: entry.id,
      site: entry.site,
      startTime: newStart,
      endTime: newEnd,
      truckId: newTruckId,
      notes: entry.notes,
    );
    await _service.updateScheduleEntry(updatedEntry);
    await _loadData();
  }

  void _showSitePicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        SiteInfo? selectedSite;
        TimeOfDay? startTime = TimeOfDay(hour: 7, minute: 0);
        TimeOfDay? endTime = TimeOfDay(hour: 9, minute: 30);
        Equipment? selectedTruck;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Add Site to Schedule'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButton<SiteInfo>(
                      hint: Text('Select a Site'),
                      value: selectedSite,
                      onChanged: (SiteInfo? value) =>
                          setDialogState(() => selectedSite = value),
                      items: activeSites.map((site) {
                        return DropdownMenuItem(
                            value: site, child: Text(site.name));
                      }).toList(),
                    ),
                    SizedBox(height: 16),
                    DropdownButton<Equipment>(
                      hint: Text('Select a Truck'),
                      value: selectedTruck,
                      onChanged: (Equipment? value) =>
                          setDialogState(() => selectedTruck = value),
                      items: trucks.map((truck) {
                        return DropdownMenuItem(
                          value: truck,
                          child: Row(
                            children: [
                              Container(
                                  width: 16, height: 16, color: truck.color),
                              SizedBox(width: 8),
                              Text(truck.name),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                            'Start: ${startTime?.format(context) ?? 'Not set'}'),
                        ElevatedButton(
                          onPressed: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: startTime ?? TimeOfDay.now(),
                            );
                            if (picked != null)
                              setDialogState(() => startTime = picked);
                          },
                          child: Text('Pick Start'),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('End: ${endTime?.format(context) ?? 'Not set'}'),
                        ElevatedButton(
                          onPressed: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: endTime ?? TimeOfDay.now(),
                            );
                            if (picked != null)
                              setDialogState(() => endTime = picked);
                          },
                          child: Text('Pick End'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel')),
                TextButton(
                  onPressed: () {
                    if (selectedSite != null &&
                        startTime != null &&
                        endTime != null &&
                        selectedTruck != null) {
                      final start = DateTime(
                          selectedDate.year,
                          selectedDate.month,
                          selectedDate.day,
                          startTime!.hour,
                          startTime!.minute);
                      final end = DateTime(
                          selectedDate.year,
                          selectedDate.month,
                          selectedDate.day,
                          endTime!.hour,
                          endTime!.minute);
                      if (end.isAfter(start)) {
                        _addScheduleEntry(
                            selectedSite!, start, end, selectedTruck);
                        Navigator.pop(context);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content:
                                  Text('End time must be after start time')),
                        );
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text('Please select a site and truck')),
                      );
                    }
                  },
                  child: Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showTruckManager(BuildContext context) {
    String truckName = '';
    int truckYear = DateTime.now().year;
    String serialNumber = '';
    Color truckColor = Colors.blue;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Add Truck'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      decoration: InputDecoration(labelText: 'Truck Name'),
                      onChanged: (value) => truckName = value,
                    ),
                    TextField(
                      decoration: InputDecoration(labelText: 'Year'),
                      keyboardType: TextInputType.number,
                      onChanged: (value) =>
                          truckYear = int.tryParse(value) ?? truckYear,
                    ),
                    TextField(
                      decoration: InputDecoration(labelText: 'Serial Number'),
                      onChanged: (value) => serialNumber = value,
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Text('Color: '),
                        GestureDetector(
                          onTap: () async {
                            final picked = await showDialog<Color>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text('Pick a Color'),
                                content: SingleChildScrollView(
                                  child: BlockPicker(
                                    pickerColor: truckColor,
                                    onColorChanged: (color) => setDialogState(
                                        () => truckColor = color),
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, truckColor),
                                    child: Text('Select'),
                                  ),
                                ],
                              ),
                            );
                            if (picked != null)
                              setDialogState(() => truckColor = picked);
                          },
                          child: Container(
                              width: 24, height: 24, color: truckColor),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel')),
                TextButton(
                  onPressed: () async {
                    if (truckName.isNotEmpty && serialNumber.isNotEmpty) {
                      await _service.addTruck(
                          truckName, truckYear, serialNumber, truckColor);
                      await _loadData();
                      Navigator.pop(context);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Please fill in all fields')),
                      );
                    }
                  },
                  child: Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class TimeColumn extends StatelessWidget {
  final int? hoveredSlotIndex;
  const TimeColumn({required this.hoveredSlotIndex});

  @override
  Widget build(BuildContext context) {
    const double timeSlotHeight = 40.0;
    const int slotsPerDay = 20;

    return Column(
      children: List.generate(slotsPerDay, (index) {
        final hour = 7 + (index ~/ 2);
        final minute = (index % 2) * 30;
        final time = DateTime.now()
            .copyWith(hour: hour, minute: minute, second: 0, millisecond: 0);
        return Container(
          height: timeSlotHeight,
          width: 80,
          color: hoveredSlotIndex == index
              ? Colors.green.withOpacity(0.3)
              : Colors.transparent,
          child: Center(
            child: Text(
              DateFormat('h:mm a').format(time),
              style: const TextStyle(fontSize: 12),
            ),
          ),
        );
      }),
    );
  }
}

class TruckColumn extends StatelessWidget {
  final Equipment truck;
  final List<ScheduleEntry> schedule;
  final Function(int?) onHover;
  final Function(ScheduleEntry, DateTime) onDrop;
  final DateTime selectedDate;

  const TruckColumn({
    required this.truck,
    required this.schedule,
    required this.onHover,
    required this.onDrop,
    required this.selectedDate,
  });

  @override
  Widget build(BuildContext context) {
    const double timeSlotHeight = 40.0;
    const int slotsPerDay = 20;

    return SizedBox(
      width: 150,
      child: Column(
        children: [
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
                    child: DragTarget<ScheduleEntry>(
                      onWillAcceptWithDetails: (details) {
                        onHover(index);
                        return true;
                      },
                      onLeave: (_) => onHover(null),
                      onAcceptWithDetails: (details) =>
                          onDrop(details.data, slotTime),
                      builder: (context, candidateData, rejectedData) =>
                          Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: Colors.grey.withOpacity(0.2), width: 1),
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
                    child: Draggable<ScheduleEntry>(
                      data: entry,
                      feedback: Material(
                        elevation: 4,
                        child: Container(
                          width: 150,
                          height: durationSlots * timeSlotHeight,
                          color: truck.color.withOpacity(0.8),
                          child: Center(child: Text(entry.site.name)),
                        ),
                      ),
                      childWhenDragging: const SizedBox.shrink(),
                      child: Container(
                        color: truck.color.withOpacity(0.5),
                        child: Center(child: Text(entry.site.name)),
                      ),
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
