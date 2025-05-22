import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:gemini_landscaping_app/models/equipment_model.dart';
import 'package:gemini_landscaping_app/models/schedule_model.dart';
import 'package:gemini_landscaping_app/models/site_info.dart';
import 'package:gemini_landscaping_app/screens/schedule/components/add_site_dialog.dart';
import 'package:gemini_landscaping_app/screens/schedule/components/time_column.dart';
import 'package:gemini_landscaping_app/screens/schedule/components/truck_column.dart';
import 'package:gemini_landscaping_app/screens/schedule/components/truck_manager_dialog.dart';
import 'package:gemini_landscaping_app/screens/schedule/week_view_screen.dart';
import 'package:gemini_landscaping_app/services/schedule_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconify_flutter/icons/fontisto.dart';
import 'package:iconify_flutter/icons/material_symbols.dart';
import 'package:intl/intl.dart';
import 'package:iconify_flutter/iconify_flutter.dart';

class ScheduleScreen extends StatefulWidget {
  @override
  _ScheduleScreenState createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final ScheduleService _service = ScheduleService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<ScheduleEntry> schedule = [];
  List<SiteInfo> activeSites = [];
  List<Equipment> activeTrucks = [];
  List<Equipment> allTrucks = [];
  DateTime selectedDate = DateTime.now();
  int? _hoveredSlotIndex;
  final ScrollController _verticalScrollController = ScrollController();
  final ScrollController _horizontalScrollController = ScrollController();
  String? userRole;

  // Controllers for the Add Site Dialog
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserRole();
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
    _nameController.dispose(); // Dispose controllers here
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadUserRole() async {
    final user = _auth.currentUser;
    if (user != null) {
      final snapshot = await FirebaseFirestore.instance
          .collection('Users')
          .doc(user.uid)
          .get();
      if (snapshot.exists) {
        setState(() {
          userRole = snapshot.data()?['role'] as String? ?? 'user';
        });
      } else {
        setState(() {
          userRole = 'user'; // Default to user if not found
        });
        // Optionally create a new user document with default role
        await FirebaseFirestore.instance.collection('Users').doc(user.uid).set({
          'email': user.email,
          'role': 'user',
        });
      }
    }
  }

  Future<void> _loadData() async {
    activeSites = await _service.fetchActiveSites();
    activeTrucks = await _service.fetchActiveTrucks();
    allTrucks = await _service.fetchAllTrucks();
    print('Loaded trucks: ${activeTrucks.length}');
    activeTrucks.forEach((truck) => print('Truck: ${truck.name}, ${truck.id}'));
    schedule = await _service.fetchSchedules(selectedDate);
    final activeTruckIds = activeTrucks.map((truck) => truck.id).toSet();
    schedule = schedule
        .where((entry) =>
            entry.truckId == null || activeTruckIds.contains(entry.truckId!))
        .toList();
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
    if (userRole != 'admin') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Only admins can add schedule entries.')),
      );
      return;
    }
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
                      items: activeTrucks.map((truck) {
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
    if (userRole != 'admin') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Only admins can add schedule entries.')),
      );
      return;
    }
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
    if (userRole != 'admin') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Only admins can add trucks.')),
      );
      return;
    }

    String truckName = '';
    int truckYear = DateTime.now().year;
    String serialNumber = '';
    Color truckColor = Colors.blue;

    showDialog(
      context: context,
      builder: (context) {
        bool isActive = true;
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Active:', style: GoogleFonts.roboto()),
                        Switch(
                          value: isActive,
                          onChanged: (value) =>
                              setDialogState(() => isActive = value),
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
                    if (truckName.isNotEmpty) {
                      await _service.addTruck(
                          truckName, truckYear, serialNumber, truckColor,
                          isActive: isActive);
                      await _loadData();
                      Navigator.pop(context);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text('Please fill in the Truck Name')),
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

  void _showTruckManagerDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => TruckManagerDialog(
        trucks: allTrucks,
        service: _service,
        onDataUpdated: _loadData,
        userRole: userRole,
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

  void _showAddSiteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AddSiteDialog(
        nameController: _nameController,
        addressController: _addressController,
        onSuccess: () {
          _loadData();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 59, 82, 73),
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
                      style: GoogleFonts.montserrat(
                        fontSize: 18,
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
          child: IntrinsicWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Horizontal scroll indicator
                Container(
                  height: 15,
                  color: Colors.black,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Left arrow icon
                      Icon(
                        Icons.arrow_back_ios,
                        color: Colors.white,
                        size: 12,
                      ),
                      // Scroll text
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
                          'Scroll to view trucks',
                          style: TextStyle(
                            color: Colors.grey[200],
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                      // Right arrow icon
                      Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white,
                        size: 12,
                      ),
                    ],
                  ),
                ),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        width: 15,
                        color: Colors.black,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Up arrow icon
                            Icon(
                              Icons.expand_less,
                              color: Colors.white,
                              size: 14,
                            ),

                            // Scroll text
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8.0),
                              child: RotatedBox(
                                quarterTurns:
                                    3, // Rotate text 90 degrees counterclockwise
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    'Scroll to view times',
                                    style: TextStyle(
                                      color: Colors.grey[200],
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // Down arrow icon
                            Icon(
                              Icons.expand_more,
                              color: Colors.white,
                              size: 14,
                            ),
                          ],
                        ),
                      ),
                      // TimeColumn with "Time" as the top slot
                      SizedBox(
                        width: 50,
                        child: TimeColumn(
                          hoveredSlotIndex: _hoveredSlotIndex,
                          includeTimeTitle: true, // Add "Time" as the top slot
                        ),
                      ),
                      // TruckColumns with integrated truck titles
                      Row(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: activeTrucks
                                .map((truck) => TruckColumn(
                                      truck: truck,
                                      schedule: schedule
                                          .where((entry) =>
                                              entry.truckId == truck.id)
                                          .toList(),
                                      onHover: _updateHoveredSlotIndex,
                                      onDrop: (entry, slotTime) =>
                                          _updateScheduleEntry(
                                              entry, slotTime, truck.id),
                                      onTapSlot: (index) =>
                                          _showSitePickerForSlot(
                                              context, truck, index),
                                      onResize: (entry, newEndTime) =>
                                          _updateScheduleEntryWithNewEndTime(
                                              entry, newEndTime, truck.id),
                                      onResizeHover: _updateHoveredSlotIndex,
                                      selectedDate: selectedDate,
                                      includeTruckTitle: true,
                                      onRefresh: _loadData,
                                      userRole: userRole,
                                    ))
                                .toList(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: SpeedDial(
        animatedIcon:
            AnimatedIcons.menu_close, // Menu icon that animates to close
        backgroundColor: const Color.fromARGB(255, 59, 82, 73),
        foregroundColor: Colors.white,
        children: [
          if (userRole == 'admin')
            SpeedDialChild(
              child: Iconify(
                MaterialSymbols.today_outline,
                size: 24,
                color: Colors.white,
              ),
              label: 'Add Schedule Entry',
              backgroundColor: const Color.fromARGB(255, 59, 82, 73),
              foregroundColor: Colors.white,
              onTap: () => _showSitePicker(context),
            ),
          if (userRole == 'admin')
            SpeedDialChild(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Iconify(
                    Fontisto.truck,
                    color: Colors.white,
                    size: 24,
                  ),
                  Positioned(
                    top: -8,
                    right: -8,
                    child: Container(
                      padding: EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade800,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.settings,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              label: 'Truck Settings',
              backgroundColor: const Color.fromARGB(255, 59, 82, 73),
              foregroundColor: Colors.white,
              onTap: () => _showTruckManagerDialog(context),
            ),
          if (userRole == 'admin')
            SpeedDialChild(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Iconify(
                    Fontisto.truck,
                    color: Colors.white,
                    size: 24,
                  ),
                  Positioned(
                    top: -8,
                    right: -8,
                    child: Container(
                      padding: EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade800,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.add,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              label: 'Add a Truck',
              backgroundColor: const Color.fromARGB(255, 59, 82, 73),
              foregroundColor: Colors.white,
              onTap: () => _showTruckManager(context),
            ),
          SpeedDialChild(
            child: Icon(Icons.location_city, size: 24),
            label: 'Add New Site',
            backgroundColor: const Color.fromARGB(255, 59, 82, 73),
            foregroundColor: Colors.white,
            onTap: () => _showAddSiteDialog(context),
          ),
        ],
      ),
    );
  }
}
