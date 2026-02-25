import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gemini_landscaping_app/models/site_info.dart';
import 'package:gemini_landscaping_app/providers/site_list_provider.dart';
import 'package:gemini_landscaping_app/screens/add_report/add_new_site.dart';
import 'package:gemini_landscaping_app/screens/add_report/date_picker.dart';
import 'package:gemini_landscaping_app/screens/add_report/disposal_section.dart';
import 'package:gemini_landscaping_app/screens/add_report/employee_times.dart';
import 'package:gemini_landscaping_app/screens/add_report/material.dart';
import 'package:gemini_landscaping_app/screens/add_report/notes_section.dart';
import 'package:gemini_landscaping_app/screens/add_report/service_list.dart';
import 'package:gemini_landscaping_app/screens/add_report/service_type.dart';
import 'package:gemini_landscaping_app/screens/add_report/site_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class AddSiteReport extends ConsumerStatefulWidget {
  final SiteInfo? prefilledSite;
  final DateTime? prefilledDate;
  final DateTime? prefilledEndTime;

  const AddSiteReport({
    super.key,
    this.prefilledSite,
    this.prefilledDate,
    this.prefilledEndTime,
  });

  @override
  _AddSiteReportState createState() => _AddSiteReportState();
}

class _AddSiteReportState extends ConsumerState<AddSiteReport> {
  // Section keys for floating nav
  final _siteKey = GlobalKey();
  final _employeesKey = GlobalKey();
  final _servicesKey = GlobalKey();
  final _disposalKey = GlobalKey();
  final _materialsKey = GlobalKey();
  final _notesKey = GlobalKey();
  final _scrollController = ScrollController();

  // Service type
  bool isRegularMaintenance = true;

  // Date picker
  TextEditingController dateController = TextEditingController();

  // Site picker
  String? dropdownValue;
  SiteInfo? selectedSite;
  String address = '';

  // Employee times — now uses selectedName instead of nameController
  List<Map<String, dynamic>> employeeTimes = [];

  // Services
  List<String> garbage = ['grassed areas', 'garden beds', 'walkways'];
  List<String> _selectedGarbage = [];
  List<String> debris = ['grassed areas', 'garden beds', 'tree wells'];
  List<String> _selectedDebris = [];
  List<String> lawn = ['mow', 'trim', 'edge', 'lime', 'aerate', 'fertilize'];
  List<String> _selectedLawn = [];
  List<String> garden = ['blow debris', 'weed', 'prune', 'fertilize'];
  List<String> _selectedGarden = [];
  List<String> tree = ['< 8ft', '> 8ft'];
  List<String> _selectedTree = [];
  List<String> blow = ['parking curbs', 'drain basins', 'walkways'];
  List<String> _selectedBlow = [];

  // Disposal
  bool _hasDisposal = false;
  final _disposalLocationController = TextEditingController();
  final _disposalCostController = TextEditingController();

  // Materials
  List<Map<String, dynamic>> materials = [];
  bool _showMaterials = false;

  // Notes
  List<String> _selectedNoteTags = [];
  final _notesController = TextEditingController();

  final currentUser = FirebaseAuth.instance.currentUser!;
  final reportRef = FirebaseFirestore.instance.collection('SiteReports');

  @override
  void initState() {
    super.initState();
    String formattedDate = widget.prefilledDate != null
        ? DateFormat('MMMM d, yyyy').format(widget.prefilledDate!)
        : DateFormat('MMMM d, yyyy').format(DateTime.now());
    dateController = TextEditingController(text: formattedDate);

    if (widget.prefilledSite != null) {
      selectedSite = widget.prefilledSite;
      dropdownValue = widget.prefilledSite!.name;
      address = widget.prefilledSite!.address;
    }

    if (widget.prefilledDate != null && widget.prefilledEndTime != null) {
      addEmployeeTime(
        timeOn: TimeOfDay.fromDateTime(widget.prefilledDate!),
        timeOff: TimeOfDay.fromDateTime(widget.prefilledEndTime!),
      );
    } else {
      addEmployeeTime();
    }
  }

  // --- Service Type ---
  void handleServiceTypeChange(bool isRegular) {
    setState(() => isRegularMaintenance = isRegular);
  }

  // --- Site Picker ---
  void onSiteChanged(SiteInfo? site) {
    setState(() {
      selectedSite = site;
      dropdownValue = site?.name;
      address = site?.address ?? '';
    });
  }

  // --- Employee Times ---
  void addEmployeeTime({TimeOfDay? timeOn, TimeOfDay? timeOff}) {
    setState(() {
      employeeTimes.add({
        'selectedName': null as String?,
        'timeOn': timeOn ?? TimeOfDay.now(),
        'timeOff': timeOff ?? TimeOfDay.now(),
      });
    });
  }

  void updateEmployeeName(int index, String? name) {
    setState(() => employeeTimes[index]['selectedName'] = name);
  }

  void updateTimeOn(int index, TimeOfDay time) {
    setState(() => employeeTimes[index]['timeOn'] = time);
  }

  void updateTimeOff(int index, TimeOfDay time) {
    setState(() => employeeTimes[index]['timeOff'] = time);
  }

  void deleteEmployeeTime(int index) {
    setState(() => employeeTimes.removeAt(index));
  }

  // --- Materials ---
  void addMaterial() {
    setState(() {
      materials.add({
        'vendorController': TextEditingController(),
        'materialController': TextEditingController(),
        'costController': TextEditingController(),
      });
    });
  }

  void deleteMaterial(int index) {
    setState(() {
      materials.removeAt(index);
      if (materials.isEmpty) _showMaterials = false;
    });
  }

  // --- Helpers ---
  Timestamp convertDateAndTimeToTimestamp(DateTime date, TimeOfDay time) {
    final DateTime dateTime =
        DateTime(date.year, date.month, date.day, time.hour, time.minute);
    return Timestamp.fromDate(dateTime);
  }

  Duration calculateDuration(TimeOfDay startTime, TimeOfDay endTime) {
    final DateTime now = DateTime.now();
    final DateTime startDateTime = DateTime(
        now.year, now.month, now.day, startTime.hour, startTime.minute);
    final DateTime endDateTime =
        DateTime(now.year, now.month, now.day, endTime.hour, endTime.minute);
    return endDateTime.difference(startDateTime);
  }

  void _scrollToSection(GlobalKey key) {
    final context = key.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  // --- Validation ---
  bool _validateForm() {
    if (dropdownValue == null || dropdownValue!.isEmpty) {
      _showErrorDialog('Please select a site.');
      return false;
    }
    for (var employee in employeeTimes) {
      if (employee['selectedName'] == null ||
          (employee['selectedName'] as String).isEmpty) {
        _showErrorDialog('Please select an employee name.');
        return false;
      }
    }
    return true;
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Validation Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // --- Submit ---
  void _submitForm() async {
    if (!_validateForm()) return;

    Map<String, dynamic> employeeTimesMap = {};
    Duration totalCombinedDuration = Duration();

    DateTime selectedDate =
        DateFormat('MMMM d, yyyy').parse(dateController.text);

    for (var employee in employeeTimes) {
      String name = employee['selectedName'] ?? '';
      TimeOfDay? timeOn = employee['timeOn'];
      TimeOfDay? timeOff = employee['timeOff'];

      if (name.isNotEmpty && timeOn != null && timeOff != null) {
        Duration duration = calculateDuration(timeOn, timeOff);
        totalCombinedDuration += duration;

        employeeTimesMap[name] = {
          'timeOn': convertDateAndTimeToTimestamp(selectedDate, timeOn),
          'timeOff': convertDateAndTimeToTimestamp(selectedDate, timeOff),
          'duration': duration.inMinutes,
        };
      }
    }

    try {
      await reportRef.add({
        "timestamp": DateTime.now(),
        "isRegularMaintenance": isRegularMaintenance,
        "employeeTimes": employeeTimesMap,
        "totalCombinedDuration": totalCombinedDuration.inMinutes,
        "siteInfo": {
          'date': dateController.text,
          'siteName': dropdownValue,
          'address': address,
        },
        "services": {
          'garbage': _selectedGarbage,
          'debris': _selectedDebris,
          'lawn': _selectedLawn,
          'garden': _selectedGarden,
          'tree': _selectedTree,
          'blow': _selectedBlow,
        },
        "materials": materials.map((material) {
          return {
            "vendor": material['vendorController'].text,
            "description": material['materialController'].text,
            "cost": material['costController'].text,
          };
        }).toList(),
        "disposal": {
          "hasDisposal": _hasDisposal,
          "location": _disposalLocationController.text,
          "cost": _disposalCostController.text,
        },
        "noteTags": _selectedNoteTags,
        "description": _notesController.text,
        "submittedBy": currentUser.email,
        "filed": false,
      });

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      _showErrorDialog('Failed to add report, please try again.');
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    dateController.dispose();
    _disposalLocationController.dispose();
    _disposalCostController.dispose();
    _notesController.dispose();
    materials.forEach((material) {
      material['vendorController'].dispose();
      material['materialController'].dispose();
      material['costController'].dispose();
    });
    super.dispose();
  }

  // --- Section Header ---
  Widget _sectionHeader(String title, GlobalKey key) {
    return Container(
      key: key,
      width: double.infinity,
      padding: EdgeInsets.all(8),
      margin: EdgeInsets.only(top: 8),
      decoration: BoxDecoration(color: Colors.green[100]),
      child: Text(
        title,
        style: GoogleFonts.montserrat(
            fontSize: 14, fontWeight: FontWeight.w600),
      ),
    );
  }

  // --- Floating Nav ---
  Widget _buildFloatingNav() {
    return Positioned(
      bottom: 16,
      left: 16,
      right: 16,
      child: Container(
        decoration: BoxDecoration(
          color: Color.fromARGB(255, 59, 82, 73),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _navIcon(Icons.location_on, 'Site', _siteKey),
            _navIcon(Icons.people, 'Team', _employeesKey),
            _navIcon(Icons.grass, 'Svc', _servicesKey),
            _navIcon(Icons.local_shipping, 'Dump', _disposalKey),
            _navIcon(Icons.inventory, 'Mat', _materialsKey),
            _navIcon(Icons.note, 'Notes', _notesKey),
          ],
        ),
      ),
    );
  }

  Widget _navIcon(IconData icon, String label, GlobalKey key) {
    return GestureDetector(
      onTap: () => _scrollToSection(key),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 22),
            Text(
              label,
              style: GoogleFonts.montserrat(
                  color: Colors.white70, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 31, 182, 77),
        leading: MaterialButton(
          onPressed: () => Navigator.pop(context),
          child: Row(
            children: const [
              Icon(Icons.arrow_circle_left_outlined,
                  color: Colors.white, size: 18),
              Text(
                " Back",
                style: TextStyle(
                  fontSize: 15,
                  color: Color.fromARGB(255, 251, 251, 251),
                ),
              ),
            ],
          ),
        ),
        leadingWidth: 100,
        title: Image.asset("assets/gemini-icon-transparent.png",
            color: Colors.white, fit: BoxFit.contain, height: 50),
        centerTitle: true,
        actions: [
          MaterialButton(
            onPressed: _submitForm,
            child: Row(
              children: const [
                Text(
                  "Submit ",
                  style: TextStyle(
                    fontSize: 15,
                    color: Color.fromARGB(255, 251, 251, 251),
                  ),
                ),
                Icon(Icons.send, color: Colors.white, size: 18),
              ],
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            controller: _scrollController,
            padding: EdgeInsets.only(bottom: 80),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Service Type Toggle
                  ServiceTypeComponent(
                    isInitialRegularMaintenance: isRegularMaintenance,
                    onServiceTypeChanged: handleServiceTypeChange,
                  ),

                  // ===== SITE & DATE =====
                  _sectionHeader('Site & Date', _siteKey),
                  SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      DatePickerComponent(dateController: dateController),
                      AddNewSiteComponent(
                        currentUser: currentUser,
                        onSiteAdded: () {
                          // ignore: unused_result
                          ref.refresh(siteListProvider);
                        },
                      ),
                    ],
                  ),
                  SitePickerComponent(
                    dropdownValue: dropdownValue,
                    selectedSite: selectedSite,
                    onSiteChanged: onSiteChanged,
                  ),

                  // ===== EMPLOYEES & TIMES =====
                  _sectionHeader('Employees & Times', _employeesKey),
                  SizedBox(height: 5),
                  ...employeeTimes.asMap().entries.map((entry) {
                    int index = entry.key;
                    Map<String, dynamic> staffMember = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: EmployeeTimesComponent(
                        selectedName: staffMember['selectedName'],
                        initialTimeOn: staffMember['timeOn'],
                        initialTimeOff: staffMember['timeOff'],
                        onNameChanged: (name) =>
                            updateEmployeeName(index, name),
                        onTimeOnChanged: (time) =>
                            updateTimeOn(index, time),
                        onTimeOffChanged: (time) =>
                            updateTimeOff(index, time),
                        onDelete: () => deleteEmployeeTime(index),
                      ),
                    );
                  }),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color.fromARGB(255, 59, 82, 73),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      textStyle: GoogleFonts.montserrat(fontSize: 14),
                    ),
                    onPressed: addEmployeeTime,
                    child: const Text('Add Another Employee'),
                  ),

                  // ===== SERVICES =====
                  _sectionHeader('Services', _servicesKey),
                  ServiceChipGroup(
                    title: 'Pick Up Loose Garbage:',
                    icon: Icons.delete_outline,
                    services: garbage,
                    selectedServices: _selectedGarbage,
                    onSelectionChanged: (v) =>
                        setState(() => _selectedGarbage = v),
                  ),
                  ServiceChipGroup(
                    title: 'Rake Yard Debris:',
                    icon: Icons.eco,
                    services: debris,
                    selectedServices: _selectedDebris,
                    onSelectionChanged: (v) =>
                        setState(() => _selectedDebris = v),
                  ),
                  ServiceChipGroup(
                    title: 'Lawn Care:',
                    icon: Icons.grass,
                    services: lawn,
                    selectedServices: _selectedLawn,
                    onSelectionChanged: (v) =>
                        setState(() => _selectedLawn = v),
                  ),
                  ServiceChipGroup(
                    title: 'Gardens:',
                    icon: Icons.yard,
                    services: garden,
                    selectedServices: _selectedGarden,
                    onSelectionChanged: (v) =>
                        setState(() => _selectedGarden = v),
                  ),
                  ServiceChipGroup(
                    title: 'Trees (Pruning/Hedging):',
                    icon: Icons.park,
                    services: tree,
                    selectedServices: _selectedTree,
                    onSelectionChanged: (v) =>
                        setState(() => _selectedTree = v),
                  ),
                  ServiceChipGroup(
                    title: 'Blow Dust/Debris:',
                    icon: Icons.air,
                    services: blow,
                    selectedServices: _selectedBlow,
                    onSelectionChanged: (v) =>
                        setState(() => _selectedBlow = v),
                  ),

                  // ===== DISPOSAL =====
                  _sectionHeader('Disposal', _disposalKey),
                  DisposalSection(
                    hasDisposal: _hasDisposal,
                    onDisposalChanged: (v) =>
                        setState(() => _hasDisposal = v),
                    locationController: _disposalLocationController,
                    costController: _disposalCostController,
                  ),

                  // ===== MATERIALS =====
                  _sectionHeader('Materials', _materialsKey),
                  SizedBox(height: 5),
                  if (!_showMaterials && materials.isEmpty)
                    Center(
                      child: ElevatedButton.icon(
                        icon: Icon(Icons.add),
                        label: Text('Add Materials'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color.fromARGB(255, 59, 82, 73),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          textStyle: GoogleFonts.montserrat(fontSize: 14),
                        ),
                        onPressed: () {
                          setState(() {
                            _showMaterials = true;
                            addMaterial();
                          });
                        },
                      ),
                    ),
                  if (_showMaterials || materials.isNotEmpty) ...[
                    ...materials.asMap().entries.map((entry) {
                      int index = entry.key;
                      Map<String, dynamic> material = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: MaterialComponent(
                                vendorController:
                                    material['vendorController'],
                                materialController:
                                    material['materialController'],
                                costController:
                                    material['costController'],
                              ),
                            ),
                            SizedBox(
                              width: 20,
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.grey,
                                  size: 24,
                                ),
                                onPressed: () => deleteMaterial(index),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color.fromARGB(255, 59, 82, 73),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        textStyle: GoogleFonts.montserrat(fontSize: 14),
                      ),
                      onPressed: addMaterial,
                      child: const Text('Add Another Material'),
                    ),
                  ],

                  // ===== SHIFT NOTES =====
                  _sectionHeader('Shift Notes', _notesKey),
                  SizedBox(height: 5),
                  NotesSection(
                    selectedTags: _selectedNoteTags,
                    onTagsChanged: (tags) =>
                        setState(() => _selectedNoteTags = tags),
                    notesController: _notesController,
                  ),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
          _buildFloatingNav(),
        ],
      ),
    );
  }
}
