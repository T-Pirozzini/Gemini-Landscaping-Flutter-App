import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:gemini_landscaping_app/models/equipment_model.dart';
import 'package:gemini_landscaping_app/models/schedule_model.dart';
import 'package:gemini_landscaping_app/models/site_info.dart';
import 'package:gemini_landscaping_app/screens/schedule/components/time_column.dart';
import 'package:gemini_landscaping_app/screens/schedule/components/truck_column.dart';
import 'package:gemini_landscaping_app/screens/schedule/week_view_screen.dart';
import 'package:gemini_landscaping_app/services/schedule_service.dart';
import 'package:intl/intl.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/fa6_solid.dart';

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
  final ScrollController _verticalScrollController = ScrollController();
  final ScrollController _horizontalScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadData();
    // Ensure initial scroll position is at the top
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _verticalScrollController.jumpTo(0);
    });
  }

  @override
  void dispose() {
    _verticalScrollController.dispose();
    _horizontalScrollController.dispose();
    super.dispose();
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

  void _updateHoveredSlotIndex(int? slotIndex) {
    setState(() {
      _hoveredSlotIndex = slotIndex;
    });
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

    setState(() {
      final index = schedule.indexOf(entry);
      if (index != -1) {
        schedule[index] = updatedEntry;
      }
    });

    print(
        'Updated entry startTime: ${updatedEntry.startTime}, endTime: ${updatedEntry.endTime}');
    await _loadData();
  }

  void _updateScheduleEntryWithNewEndTime(
      ScheduleEntry entry, DateTime newEndTime, String truckId) async {
    final updatedEntry = ScheduleEntry(
      id: entry.id,
      site: entry.site,
      startTime: entry.startTime,
      endTime: newEndTime,
      truckId: truckId,
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

  void _showSitePickerForSlot(
      BuildContext context, Equipment truck, int slotIndex) {
    showDialog(
      context: context,
      builder: (context) {
        SiteInfo? selectedSite;
        TimeOfDay startTime =
            TimeOfDay(hour: 7 + (slotIndex ~/ 2), minute: (slotIndex % 2) * 30);
        TimeOfDay? endTime =
            TimeOfDay(hour: 9, minute: 30); // Default end time, user can change
        Equipment? selectedTruck = truck;

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
                    // Truck dropdown is prefilled and disabled
                    DropdownButton<Equipment>(
                      hint: Text('Truck'),
                      value: selectedTruck,
                      onChanged: null, // Disable changing truck
                      items: [
                        DropdownMenuItem(
                          value: selectedTruck,
                          child: Row(
                            children: [
                              Container(
                                  width: 16,
                                  height: 16,
                                  color: selectedTruck!.color),
                              SizedBox(width: 8),
                              Text(selectedTruck.name),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                            'Start: ${startTime.format(context)}'), // Prefilled and read-only
                        ElevatedButton(
                          onPressed: null, // Disable changing start time
                          child: Text('Pick Start',
                              style: TextStyle(color: Colors.grey)),
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
                    if (selectedSite != null && endTime != null) {
                      final start = DateTime(
                          selectedDate.year,
                          selectedDate.month,
                          selectedDate.day,
                          startTime.hour,
                          startTime.minute);
                      final end = DateTime(
                        selectedDate.year,
                        selectedDate.month,
                        selectedDate.day,
                        endTime!.hour,
                        endTime!.minute,
                      );
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
                            content: Text('Please select a site and end time')),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            IconButton(
              icon: Icon(Icons.arrow_left),
              onPressed: () => _changeDate(-1),
            ),
            Expanded(
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: DateFormat('EEEE').format(selectedDate),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    TextSpan(
                      text: ' (${DateFormat('MMM d').format(selectedDate)})',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.arrow_right),
              onPressed: () => _changeDate(1),
            ),
          ],
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: Stack(
                  clipBehavior: Clip
                      .none, 
                  children: [
                   
                    Iconify(
                      Fa6Solid.truck_pickup,
                      color: Colors.white,
                      size: 24, 
                    ),                    
                    Positioned(
                      top: -4,
                      right: -4, 
                      child: Icon(
                        Icons.add_circle, 
                        color: Colors.black54,
                        size: 18, 
                        shadows: [
                          Shadow(
                            color: Colors.black26, 
                            offset: Offset(1, 1),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                onPressed: () => _showTruckManager(context),
              ),
            ],
          ),
          IconButton(
            icon: Icon(Icons.calendar_view_week),
            onPressed: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => WeekViewScreen())),
          ),
        ],
      ),
      body: SingleChildScrollView(
        controller: _verticalScrollController,
        scrollDirection: Axis.vertical,
        child: SingleChildScrollView(
          controller: _horizontalScrollController,
          scrollDirection: Axis.horizontal,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // TimeColumn with "Time" as the top slot
              SizedBox(
                width: 80,
                child: TimeColumn(
                  hoveredSlotIndex: _hoveredSlotIndex,
                  includeTimeTitle: true, // Add "Time" as the top slot
                ),
              ),
              // TruckColumns with integrated truck titles
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: trucks
                    .map((truck) => TruckColumn(
                          truck: truck,
                          schedule: schedule
                              .where((entry) => entry.truckId == truck.id)
                              .toList(),
                          onHover: _updateHoveredSlotIndex,
                          onDrop: (entry, slotTime) =>
                              _updateScheduleEntry(entry, slotTime, truck.id),
                          onTapSlot: (index) =>
                              _showSitePickerForSlot(context, truck, index),
                          onResize: (entry, newEndTime) =>
                              _updateScheduleEntryWithNewEndTime(
                                  entry, newEndTime, truck.id),
                          onResizeHover: _updateHoveredSlotIndex,
                          selectedDate: selectedDate,
                          includeTruckTitle:
                              true, // Add truck title as the top slot
                        ))
                    .toList(),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showSitePicker(context),
        child: Icon(Icons.add),
      ),
    );
  }
}
