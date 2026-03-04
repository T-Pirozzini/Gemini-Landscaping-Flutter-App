import 'dart:async';

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
import 'package:gemini_landscaping_app/screens/schedule/components/truck_manager_dialog.dart';
import 'package:gemini_landscaping_app/screens/schedule/week_view_screen.dart';
import 'package:gemini_landscaping_app/services/schedule_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconify_flutter/icons/fontisto.dart';
import 'package:iconify_flutter/icons/material_symbols.dart';
import 'package:intl/intl.dart';
import 'package:iconify_flutter/iconify_flutter.dart';

class ScheduleScreen extends StatefulWidget {
  final DateTime? initialDate;

  const ScheduleScreen({super.key, this.initialDate});

  @override
  _ScheduleScreenState createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  static const _darkGreen = Color.fromARGB(255, 59, 82, 73);
  static const double _timeColumnWidth = 50.0;

  final ScheduleService _service = ScheduleService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<ScheduleEntry> schedule = [];
  List<SiteInfo> activeSites = [];
  List<Equipment> activeTrucks = [];
  List<Equipment> allTrucks = [];
  late DateTime selectedDate;
  int? _hoveredSlotIndex;
  final ScrollController _verticalScrollController = ScrollController();
  String? userRole;
  bool _showAllTrucks = false;
  DateTime _now = DateTime.now();
  Timer? _clockTimer;
  bool _hasAutoScrolled = false;
  bool _showWeekView = false;
  late DateTime _currentMonday;
  final _weekViewKey = GlobalKey<WeekViewBodyState>();

  // Controllers for the Add Site Dialog
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    selectedDate = widget.initialDate ?? DateTime.now();
    _currentMonday = _computeMonday(selectedDate);
    _loadUserRole();
    _loadData();
    // Update current time every minute for the time indicator line
    _clockTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _verticalScrollController.dispose();
    _nameController.dispose();
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
          userRole = 'user';
        });
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

  DateTime _computeMonday(DateTime date) {
    final d = date.subtract(Duration(days: date.weekday - 1));
    return DateTime(d.year, d.month, d.day);
  }

  void _switchToWeekView() {
    setState(() {
      _showWeekView = true;
      _currentMonday = _computeMonday(selectedDate);
    });
  }

  void _switchToDailyView(DateTime date) {
    setState(() {
      selectedDate = date;
      _showWeekView = false;
    });
    _loadData();
  }

  void _changeWeek(int weeks) {
    setState(() {
      _currentMonday = _currentMonday.add(Duration(days: 7 * weeks));
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
        _loadData();
      });
    }
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

  /// Trucks sorted: those with entries first, empty trucks to the right.
  /// When "Show All" is off, empty trucks are hidden entirely.
  List<Equipment> get _visibleTrucks {
    final truckIdsWithEntries =
        schedule.map((e) => e.truckId).whereType<String>().toSet();

    if (_showAllTrucks) {
      // Sort: trucks with entries first, empty trucks last
      return [...activeTrucks]..sort((a, b) {
          final aHas = truckIdsWithEntries.contains(a.id) ? 0 : 1;
          final bHas = truckIdsWithEntries.contains(b.id) ? 0 : 1;
          return aHas.compareTo(bHas);
        });
    }

    final visible =
        activeTrucks.where((t) => truckIdsWithEntries.contains(t.id)).toList();
    // Show all trucks if none have entries (empty day)
    return visible.isEmpty ? activeTrucks : visible;
  }

  // --- Add entry dialogs ---

  void _showSitePicker(BuildContext context) {
    if (userRole != 'admin') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Only admins can add schedule entries.')),
      );
      return;
    }
    _showScheduleEntryDialog(context);
  }

  void _showScheduleEntryDialog(
    BuildContext context, {
    Equipment? preselectedTruck,
    TimeOfDay? preselectedStart,
    bool lockTruck = false,
    bool lockStart = false,
  }) {
    SiteInfo? selectedSite;
    TimeOfDay startTime =
        preselectedStart ?? const TimeOfDay(hour: 7, minute: 0);
    TimeOfDay endTime = const TimeOfDay(hour: 9, minute: 30);
    Equipment? selectedTruck = preselectedTruck;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Widget buildTimeTile(
              String label,
              IconData icon,
              TimeOfDay time,
              bool locked,
              ValueChanged<TimeOfDay> onPicked,
            ) {
              return GestureDetector(
                onTap: locked
                    ? null
                    : () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: time,
                        );
                        if (picked != null) onPicked(picked);
                      },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(icon,
                          color: locked
                              ? Colors.grey[400]
                              : const Color.fromARGB(255, 31, 182, 77),
                          size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(label,
                            style: GoogleFonts.montserrat(
                                fontSize: 13, color: Colors.grey[600])),
                      ),
                      Text(
                        time.format(context),
                        style: GoogleFonts.montserrat(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: _darkGreen,
                        ),
                      ),
                      if (!locked) ...[
                        const SizedBox(width: 4),
                        Icon(Icons.chevron_right,
                            color: Colors.grey[400], size: 20),
                      ],
                    ],
                  ),
                ),
              );
            }

            return Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
                    decoration: const BoxDecoration(
                      color: _darkGreen,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.event_note,
                            color: Colors.white, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Add Schedule Entry',
                                style: GoogleFonts.montserrat(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                DateFormat('EEEE, MMM d').format(selectedDate),
                                style: GoogleFonts.montserrat(
                                  fontSize: 12,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white70),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),

                  // Form
                  SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Site dropdown
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 6),
                          child: Text('SITE',
                              style: GoogleFonts.montserrat(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[500],
                                letterSpacing: 1.2,
                              )),
                        ),
                        DropdownButtonFormField<SiteInfo>(
                          value: selectedSite,
                          hint: Text('Select a site',
                              style: GoogleFonts.montserrat(
                                  fontSize: 14, color: Colors.grey[400])),
                          onChanged: (value) =>
                              setDialogState(() => selectedSite = value),
                          items: activeSites.map((site) {
                            return DropdownMenuItem(
                              value: site,
                              child: Text(site.name,
                                  style: GoogleFonts.montserrat(fontSize: 14)),
                            );
                          }).toList(),
                          decoration: InputDecoration(
                            prefixIcon: Icon(Icons.location_on_outlined,
                                color: const Color.fromARGB(255, 31, 182, 77),
                                size: 20),
                            filled: true,
                            fillColor: Colors.grey[100],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                  color: Color.fromARGB(255, 31, 182, 77),
                                  width: 2),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 14),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Truck dropdown
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 6),
                          child: Text('TRUCK',
                              style: GoogleFonts.montserrat(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[500],
                                letterSpacing: 1.2,
                              )),
                        ),
                        DropdownButtonFormField<Equipment>(
                          value: selectedTruck,
                          hint: Text('Select a truck',
                              style: GoogleFonts.montserrat(
                                  fontSize: 14, color: Colors.grey[400])),
                          onChanged: lockTruck
                              ? null
                              : (value) =>
                                  setDialogState(() => selectedTruck = value),
                          items: activeTrucks.map((truck) {
                            return DropdownMenuItem(
                              value: truck,
                              child: Row(
                                children: [
                                  Container(
                                    width: 14,
                                    height: 14,
                                    decoration: BoxDecoration(
                                      color: truck.color,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(truck.name,
                                      style:
                                          GoogleFonts.montserrat(fontSize: 14)),
                                ],
                              ),
                            );
                          }).toList(),
                          decoration: InputDecoration(
                            prefixIcon: Icon(Icons.local_shipping_outlined,
                                color: const Color.fromARGB(255, 31, 182, 77),
                                size: 20),
                            filled: true,
                            fillColor: Colors.grey[100],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                  color: Color.fromARGB(255, 31, 182, 77),
                                  width: 2),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 14),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Time section
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 6),
                          child: Text('TIME',
                              style: GoogleFonts.montserrat(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[500],
                                letterSpacing: 1.2,
                              )),
                        ),
                        buildTimeTile(
                          'Start',
                          Icons.schedule,
                          startTime,
                          lockStart,
                          (picked) => setDialogState(() => startTime = picked),
                        ),
                        const SizedBox(height: 8),
                        buildTimeTile(
                          'End',
                          Icons.schedule,
                          endTime,
                          false,
                          (picked) => setDialogState(() => endTime = picked),
                        ),
                      ],
                    ),
                  ),

                  // Actions
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.grey[600],
                              side: BorderSide(color: Colors.grey[300]!),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: Text('Cancel',
                                style: GoogleFonts.montserrat(
                                    fontWeight: FontWeight.w500)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: () {
                              if (selectedSite != null &&
                                  selectedTruck != null) {
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
                                    endTime.hour,
                                    endTime.minute);
                                if (end.isAfter(start)) {
                                  _addScheduleEntry(
                                      selectedSite!, start, end, selectedTruck);
                                  Navigator.pop(context);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(
                                            'End time must be after start time')),
                                  );
                                }
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          'Please select a site and truck')),
                                );
                              }
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: _darkGreen,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: Text('Add Entry',
                                style: GoogleFonts.montserrat(
                                    fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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
    final startTime =
        TimeOfDay(hour: 7 + (slotIndex ~/ 2), minute: (slotIndex % 2) * 30);
    _showScheduleEntryDialog(
      context,
      preselectedTruck: truck,
      preselectedStart: startTime,
      lockTruck: true,
      lockStart: true,
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
    bool isActive = true;
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            InputDecoration styledInput(String label, IconData icon) {
              return InputDecoration(
                labelText: label,
                labelStyle: GoogleFonts.montserrat(
                    fontSize: 14, color: Colors.grey[600]),
                prefixIcon: Icon(icon,
                    color: const Color.fromARGB(255, 31, 182, 77), size: 20),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: Color.fromARGB(255, 31, 182, 77), width: 2),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              );
            }

            return Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
                    decoration: const BoxDecoration(
                      color: _darkGreen,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.add_circle_outline,
                            color: Colors.white, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Add Truck',
                            style: GoogleFonts.montserrat(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white70),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),

                  // Form
                  SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          style: GoogleFonts.montserrat(),
                          decoration: styledInput(
                              'Truck Name', Icons.local_shipping_outlined),
                          onChanged: (value) => truckName = value,
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          style: GoogleFonts.montserrat(),
                          decoration: styledInput('Year', Icons.calendar_today),
                          keyboardType: TextInputType.number,
                          onChanged: (value) =>
                              truckYear = int.tryParse(value) ?? truckYear,
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          style: GoogleFonts.montserrat(),
                          decoration: styledInput('Serial Number', Icons.tag),
                          onChanged: (value) => serialNumber = value,
                        ),
                        const SizedBox(height: 16),

                        // Color picker row
                        GestureDetector(
                          onTap: () async {
                            Color tempColor = truckColor;
                            final picked = await showDialog<Color>(
                              context: context,
                              builder: (context) => AlertDialog(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16)),
                                title: Text('Pick a Color',
                                    style: GoogleFonts.montserrat(
                                        fontWeight: FontWeight.w600)),
                                content: SingleChildScrollView(
                                  child: BlockPicker(
                                    pickerColor: truckColor,
                                    onColorChanged: (color) =>
                                        tempColor = color,
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: Text('Cancel',
                                        style: GoogleFonts.montserrat(
                                            color: Colors.grey[600])),
                                  ),
                                  FilledButton(
                                    onPressed: () =>
                                        Navigator.pop(context, tempColor),
                                    style: FilledButton.styleFrom(
                                        backgroundColor: _darkGreen),
                                    child: Text('Select',
                                        style: GoogleFonts.montserrat()),
                                  ),
                                ],
                              ),
                            );
                            if (picked != null) {
                              setDialogState(() => truckColor = picked);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.palette,
                                    color:
                                        const Color.fromARGB(255, 31, 182, 77),
                                    size: 20),
                                const SizedBox(width: 12),
                                Text('Truck Color',
                                    style: GoogleFonts.montserrat(
                                        fontSize: 14, color: Colors.grey[600])),
                                const Spacer(),
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: truckColor,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: Colors.black
                                            .withValues(alpha: 0.1)),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(Icons.chevron_right,
                                    color: Colors.grey[400], size: 20),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Active toggle
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isActive
                                    ? Icons.check_circle_outline
                                    : Icons.cancel_outlined,
                                color: isActive
                                    ? const Color.fromARGB(255, 31, 182, 77)
                                    : Colors.grey[400],
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Text('Active',
                                  style: GoogleFonts.montserrat(
                                      fontSize: 14, color: Colors.grey[600])),
                              const Spacer(),
                              Switch.adaptive(
                                value: isActive,
                                activeTrackColor:
                                    const Color.fromARGB(255, 31, 182, 77),
                                onChanged: (value) =>
                                    setDialogState(() => isActive = value),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Actions
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.grey[600],
                              side: BorderSide(color: Colors.grey[300]!),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: Text('Cancel',
                                style: GoogleFonts.montserrat(
                                    fontWeight: FontWeight.w500)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: isSubmitting
                                ? null
                                : () async {
                                    if (truckName.isNotEmpty) {
                                      setDialogState(() => isSubmitting = true);
                                      await _service.addTruck(truckName,
                                          truckYear, serialNumber, truckColor,
                                          isActive: isActive);
                                      await _loadData();
                                      if (context.mounted) {
                                        Navigator.pop(context);
                                      }
                                    } else {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                            content: Text(
                                                'Please fill in the Truck Name')),
                                      );
                                    }
                                  },
                            style: FilledButton.styleFrom(
                              backgroundColor: _darkGreen,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: isSubmitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white))
                                : Text('Add Truck',
                                    style: GoogleFonts.montserrat(
                                        fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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

  @override
  Widget build(BuildContext context) {
    if (_showWeekView) return _buildWeekScaffold();
    return _buildDailyScaffold();
  }

  Widget _buildDailyScaffold() {
    final screenWidth = MediaQuery.of(context).size.width;
    final trucks = _visibleTrucks;

    // Dynamic column width: fill screen, clamp 120-200px
    final availableWidth = screenWidth - _timeColumnWidth;
    final columnWidth = trucks.isNotEmpty
        ? (availableWidth / trucks.length).clamp(120.0, 200.0)
        : 130.0;

    // Horizontal scroll only when columns exceed screen width
    final totalColumnsWidth = columnWidth * trucks.length;
    final needsHorizontalScroll = totalColumnsWidth > availableWidth;

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (needsHorizontalScroll) return;
        if (details.primaryVelocity != null) {
          if (details.primaryVelocity! < -200) {
            _changeDate(1);
          } else if (details.primaryVelocity! > 200) {
            _changeDate(-1);
          }
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: _darkGreen,
          toolbarHeight: 44,
          title: Row(
            children: [
              IconButton(
                icon: Icon(Icons.chevron_left, size: 28),
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(),
                onPressed: () => _changeDate(-1),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: _pickDate,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        DateFormat('EEEE').format(selectedDate),
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        DateFormat('MMM d, yyyy').format(selectedDate),
                        style: GoogleFonts.montserrat(
                          fontSize: 11,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.chevron_right, size: 28),
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(),
                onPressed: () => _changeDate(1),
              ),
            ],
          ),
          actions: [
            // Show All toggle (admin only)
            if (userRole == 'admin')
              Center(
                child: GestureDetector(
                  onTap: () => setState(() => _showAllTrucks = !_showAllTrucks),
                  child: Container(
                    margin: EdgeInsets.only(right: 4),
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _showAllTrucks
                          ? Colors.white.withValues(alpha: 0.2)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      'All',
                      style: GoogleFonts.montserrat(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            // Week view toggle
            IconButton(
              icon: Icon(Icons.calendar_view_week, size: 22),
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(),
              onPressed: _switchToWeekView,
            ),
            SizedBox(width: 8),
          ],
        ),
        body: _buildScheduleGrid(trucks, columnWidth, needsHorizontalScroll),
        floatingActionButton: _buildFab(),
      ),
    );
  }

  Widget _buildWeekScaffold() {
    final friday = _currentMonday.add(const Duration(days: 4));
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: _darkGreen,
        toolbarHeight: 44,
        title: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left, size: 28),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () => _changeWeek(-1),
            ),
            Expanded(
              child: Text(
                '${DateFormat('MMM d').format(_currentMonday)} – ${DateFormat('MMM d').format(friday)}',
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right, size: 28),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () => _changeWeek(1),
            ),
          ],
        ),
        actions: [
          // Daily view toggle
          IconButton(
            icon: const Icon(Icons.calendar_view_day, size: 22),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => setState(() => _showWeekView = false),
          ),
          // Copy menu (admin only)
          if (userRole == 'admin')
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, size: 22),
              onSelected: (value) {
                final weekState = _weekViewKey.currentState;
                if (value == 'copy_week') weekState?.copyWeekToNext();
                if (value == 'copy_day') weekState?.copySelectedDay();
              },
              itemBuilder: (context) {
                final weekState = _weekViewKey.currentState;
                final selectedDayLabel = weekState?.selectedDay != null
                    ? DateFormat('EEEE').format(weekState!.selectedDay!)
                    : 'Day';
                return [
                  PopupMenuItem(
                    value: 'copy_day',
                    child: Row(
                      children: [
                        Icon(Icons.content_copy, size: 18, color: _darkGreen),
                        const SizedBox(width: 8),
                        Text('Copy $selectedDayLabel to...'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'copy_week',
                    child: Row(
                      children: [
                        Icon(Icons.copy_all, size: 18, color: _darkGreen),
                        const SizedBox(width: 8),
                        const Text('Copy Week to Next Week'),
                      ],
                    ),
                  ),
                ];
              },
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: WeekViewBody(
        key: _weekViewKey,
        monday: _currentMonday,
        userRole: userRole,
        onSwitchToDailyView: _switchToDailyView,
        onWeekChanged: (offset) => _changeWeek(offset),
      ),
    );
  }

  /// Whether today is the selected date (for showing current time line).
  bool get _isToday {
    return selectedDate.year == _now.year &&
        selectedDate.month == _now.month &&
        selectedDate.day == _now.day;
  }

  /// Current time position in pixels from top of the grid.
  double get _currentTimeOffset {
    const double timeSlotHeight = 40.0;
    final minutesSince7AM = (_now.hour - 7) * 60 + _now.minute;
    return (minutesSince7AM / 30) * timeSlotHeight;
  }

  void _autoScrollToCurrentTime() {
    if (_hasAutoScrolled || !_isToday) return;
    _hasAutoScrolled = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_verticalScrollController.hasClients) return;
      final targetOffset = (_currentTimeOffset - 200).clamp(
        0.0,
        _verticalScrollController.position.maxScrollExtent,
      );
      _verticalScrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
      );
    });
  }

  Widget _buildScheduleGrid(
      List<Equipment> trucks, double columnWidth, bool needsHorizontalScroll) {
    const double timeSlotHeight = 40.0;
    const int slotsPerDay = 22;
    const double headerHeight = timeSlotHeight; // truck title row
    final double gridHeight = timeSlotHeight * slotsPerDay;
    final double totalGridWidth =
        _timeColumnWidth + (columnWidth * trucks.length);

    // Auto-scroll to current time on first build
    _autoScrollToCurrentTime();

    final gridContent = SizedBox(
      width: needsHorizontalScroll ? totalGridWidth : null,
      height: headerHeight + gridHeight,
      child: Stack(
        children: [
          // The row of time column + truck columns
          Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: _timeColumnWidth,
                child: TimeColumn(
                  hoveredSlotIndex: _hoveredSlotIndex,
                  includeTimeTitle: true,
                ),
              ),
              ...trucks.map((truck) => TruckColumn(
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
                    columnWidth: columnWidth,
                  )),
            ],
          ),
          // Current time indicator line
          if (_isToday &&
              _currentTimeOffset >= 0 &&
              _currentTimeOffset <= gridHeight)
            Positioned(
              top: headerHeight + _currentTimeOffset,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: Row(
                  children: [
                    // Circle anchor on the time column edge
                    Container(
                      width: 10,
                      height: 10,
                      margin: EdgeInsets.only(left: _timeColumnWidth - 5),
                      decoration: const BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    // Line across all truck columns
                    Expanded(
                      child: Container(
                        height: 2,
                        color: Colors.redAccent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );

    if (needsHorizontalScroll) {
      return SingleChildScrollView(
        controller: _verticalScrollController,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: gridContent,
        ),
      );
    }

    return SingleChildScrollView(
      controller: _verticalScrollController,
      child: gridContent,
    );
  }

  Widget _buildFab() {
    return SpeedDial(
      animatedIcon: AnimatedIcons.menu_close,
      backgroundColor: _darkGreen,
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
            backgroundColor: _darkGreen,
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
                    child: Icon(Icons.settings, size: 14, color: Colors.white),
                  ),
                ),
              ],
            ),
            label: 'Truck Settings',
            backgroundColor: _darkGreen,
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
                    child: Icon(Icons.add, size: 14, color: Colors.white),
                  ),
                ),
              ],
            ),
            label: 'Add a Truck',
            backgroundColor: _darkGreen,
            foregroundColor: Colors.white,
            onTap: () => _showTruckManager(context),
          ),
      ],
    );
  }
}
