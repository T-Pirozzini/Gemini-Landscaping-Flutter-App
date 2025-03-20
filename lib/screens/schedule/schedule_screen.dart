import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:gemini_landscaping_app/models/equipment_model.dart';
import 'package:gemini_landscaping_app/models/schedule_model.dart';
import 'package:gemini_landscaping_app/models/site_info.dart';
import 'package:gemini_landscaping_app/screens/schedule/components/time_column.dart';
import 'package:gemini_landscaping_app/screens/schedule/components/truck_column.dart';
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

  void _showTruckManagerDialog(BuildContext context) async {
    if (userRole != 'admin') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Only admins can manage trucks.')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        List<Equipment> localTrucks = List.from(allTrucks);

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Manage Trucks', style: GoogleFonts.roboto()),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: localTrucks.asMap().entries.map((entry) {
                    int index = entry.key;
                    Equipment truck = entry.value;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              // Color Picker
                              GestureDetector(
                                onTap: () async {
                                  Color currentColor = localTrucks[index].color;
                                  Color? selectedColor = currentColor;

                                  final picked = await showDialog<Color>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: Text('Pick a Color',
                                          style: GoogleFonts.roboto()),
                                      content: SingleChildScrollView(
                                        child: BlockPicker(
                                          pickerColor: currentColor,
                                          onColorChanged: (color) {
                                            setDialogState(() {
                                              localTrucks[index] =
                                                  localTrucks[index]
                                                      .copyWith(color: color);
                                              selectedColor = color;
                                            });
                                          },
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(
                                              context, selectedColor),
                                          child: Text('Select',
                                              style: GoogleFonts.roboto()),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (picked != null &&
                                      picked.value != currentColor.value) {
                                    setDialogState(() {
                                      localTrucks[index] = localTrucks[index]
                                          .copyWith(color: picked);
                                    });
                                    print(
                                        'Attempting to update truck with id: ${localTrucks[index].id}, active: ${localTrucks[index].active}, color: ${picked.value.toRadixString(16).padLeft(8, '0')}');
                                    await _service.updateTruck(
                                        localTrucks[index].id,
                                        localTrucks[index].active,
                                        picked);
                                    await _loadData();
                                  } else {
                                    print(
                                        'No color change detected: picked = ${picked?.value.toRadixString(16).padLeft(8, '0')}, current = ${currentColor.value.toRadixString(16).padLeft(8, '0')}');
                                    setDialogState(() {
                                      localTrucks[index] = localTrucks[index]
                                          .copyWith(color: currentColor);
                                    });
                                  }
                                },
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  margin: EdgeInsets.only(right: 16.0),
                                  decoration: BoxDecoration(
                                    color: localTrucks[index].color,
                                    border: Border.all(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(4.0),
                                  ),
                                ),
                              ),
                              // Truck Name (as text, clickable to edit)
                              Expanded(
                                child: GestureDetector(
                                  onTap: () async {
                                    TextEditingController nameController =
                                        TextEditingController(
                                            text: localTrucks[index].name);
                                    String? newName = await showDialog<String>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: Text('Edit Truck Name',
                                            style: GoogleFonts.roboto()),
                                        content: TextField(
                                          controller: nameController,
                                          decoration: InputDecoration(
                                            hintText: 'Enter new truck name',
                                            border: OutlineInputBorder(),
                                          ),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context),
                                            child: Text('Cancel',
                                                style: GoogleFonts.roboto()),
                                          ),
                                          TextButton(
                                            onPressed: () => Navigator.pop(
                                                context, nameController.text),
                                            child: Text('Save',
                                                style: GoogleFonts.roboto()),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (newName != null &&
                                        newName.isNotEmpty &&
                                        newName != localTrucks[index].name) {
                                      setDialogState(() {
                                        localTrucks[index] = localTrucks[index]
                                            .copyWith(name: newName);
                                      });
                                      await _service.updateTruckName(
                                          localTrucks[index].id, newName);
                                      await _loadData();
                                    } else if (newName != null &&
                                        newName.isEmpty) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                            content: Text(
                                                'Truck name cannot be empty')),
                                      );
                                    }
                                  },
                                  child: Text(
                                    localTrucks[index].name,
                                    style: GoogleFonts.roboto(fontSize: 16),
                                  ),
                                ),
                              ),
                              // Active Switch
                              Switch(
                                value: localTrucks[index].active,
                                onChanged: (value) async {
                                  setDialogState(() {
                                    localTrucks[index] = localTrucks[index]
                                        .copyWith(active: value);
                                  });
                                  await _service.updateTruck(
                                      localTrucks[index].id,
                                      value,
                                      localTrucks[index].color);
                                  await _loadData();
                                },
                              ),
                              // Delete Button
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () async {
                                  bool? confirmDelete = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: Text('Delete Truck',
                                          style: GoogleFonts.roboto()),
                                      content: Text(
                                          'Are you sure you want to delete ${localTrucks[index].name}?',
                                          style: GoogleFonts.roboto()),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, false),
                                          child: Text('Cancel',
                                              style: GoogleFonts.roboto()),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, true),
                                          child: Text('Delete',
                                              style: GoogleFonts.roboto()),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (confirmDelete == true) {
                                    await _service
                                        .deleteTruck(localTrucks[index].id);
                                    setDialogState(() {
                                      localTrucks.removeAt(index);
                                    });
                                    await _loadData();
                                  }
                                },
                              ),
                            ],
                          ),
                          Divider(),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Close', style: GoogleFonts.roboto()),
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

  void _showAddSiteDialog(BuildContext context) {
    final _formKey = GlobalKey<FormState>(); // For form validation

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Add New Site',
            style: GoogleFonts.montserrat(),
          ),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Name field (mandatory)
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Site Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a site name';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 10),
                  // Address field (optional)
                  TextFormField(
                    controller: _addressController,
                    decoration: InputDecoration(
                      labelText: 'Address (Optional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
              },
              child: Text('Cancel', style: GoogleFonts.roboto()),
            ),
            TextButton(
              onPressed: () async {
                // Validate the form
                if (_formKey.currentState!.validate()) {
                  try {
                    // Create a reference to the SiteList collection
                    final siteRef =
                        FirebaseFirestore.instance.collection('SiteList');

                    // Generate a new document ID
                    final newDocRef = siteRef.doc(); // Auto-generate ID

                    // Create a new SiteInfo instance with default values
                    final newSite = SiteInfo(
                      address: _addressController.text.trim().isEmpty
                          ? ""
                          : _addressController.text
                              .trim(), // Default to "" if empty
                      imageUrl: "", // Default value
                      management: "", // Default value
                      name: _nameController.text.trim(),
                      status: true, // Default to true
                      target: 0.0, // Default value
                      id: newDocRef.id, // Use the generated ID
                    );

                    // Save to Firestore
                    await newDocRef.set(newSite.toMap());

                    // Show success message
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Site added successfully!')),
                    );

                    // Clear controllers after successful save
                    _nameController.clear();
                    _addressController.clear();

                    // Close the dialog
                    Navigator.pop(context);
                  } catch (e) {
                    // Show error message
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to add site: $e')),
                    );
                  }
                }
              },
              child: Text('Save', style: GoogleFonts.roboto()),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade200,
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
                children: activeTrucks
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
                          includeTruckTitle: true,
                          onRefresh: _loadData,
                          userRole: userRole,
                        ))
                    .toList(),
              ),
            ],
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
