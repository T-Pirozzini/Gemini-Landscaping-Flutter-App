import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gemini_landscaping_app/models/site_info.dart';
import 'package:gemini_landscaping_app/models/site_report.dart';
import 'package:gemini_landscaping_app/services/firestore_service.dart';
import 'package:gemini_landscaping_app/screens/add_report/date_picker.dart';
import 'package:gemini_landscaping_app/screens/add_report/employee_times.dart';
import 'package:gemini_landscaping_app/screens/add_report/notes_section.dart';
import 'package:gemini_landscaping_app/screens/add_report/report_details_page.dart';
import 'package:gemini_landscaping_app/screens/add_report/service_list.dart';
import 'package:gemini_landscaping_app/screens/add_report/site_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class AddSiteReport extends ConsumerStatefulWidget {
  final SiteInfo? prefilledSite;
  final DateTime? prefilledDate;
  final DateTime? prefilledEndTime;
  final SiteReport? draftReport;
  final bool isRegularMaintenance;

  const AddSiteReport({
    super.key,
    this.prefilledSite,
    this.prefilledDate,
    this.prefilledEndTime,
    this.draftReport,
    this.isRegularMaintenance = true,
  });

  @override
  _AddSiteReportState createState() => _AddSiteReportState();
}

class _AddSiteReportState extends ConsumerState<AddSiteReport> {
  // Report type — set from constructor or draft
  late bool _isRegularMaintenance;

  // Date
  late TextEditingController dateController;

  // Site
  String? dropdownValue;
  SiteInfo? selectedSite;
  String address = '';

  // Single employee list
  List<Map<String, dynamic>> _employees = [];

  // Services map — 3 categories, each with main + extras
  final Map<String, List<String>> _services = {
    'Lawn Care': [],
    'Lawn Extras': [],
    'Garden Maintenance': [],
    'Garden Extras': [],
    'Common Areas': [],
    'Common Extras': [],
  };

  // Quick note tags
  List<String> _selectedNoteTags = [];

  // Page 2 checkboxes
  bool _hasMaterials = false;
  bool _hasDisposal = false;
  bool _hasNotes = false;

  // Draft tracking
  String? _draftId;
  Timer? _draftTimer;

  final currentUser = FirebaseAuth.instance.currentUser!;
  final _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();

    _isRegularMaintenance = widget.isRegularMaintenance;

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
      _addEmployee(
        timeOn: TimeOfDay.fromDateTime(widget.prefilledDate!),
        timeOff: TimeOfDay.fromDateTime(widget.prefilledEndTime!),
      );
    } else {
      _addEmployee();
    }

    if (widget.draftReport != null) {
      _loadFromDraft(widget.draftReport!);
    }
  }

  // Map old service keys to new ones for backward compat
  static const _oldToNewKeyMap = {
    'lawn': 'Lawn Care',
    'garden': 'Garden Maintenance',
    'garbage': 'Common Areas',
    'debris': 'Garden Maintenance',
    'tree': 'Garden Maintenance',
    'blow': 'Common Areas',
    'extras': 'Common Extras',
  };

  void _loadServicesFromMap(Map<String, List<String>> source) {
    for (var entry in source.entries) {
      if (entry.value.isEmpty) continue;
      if (_services.containsKey(entry.key)) {
        // New-format key — load directly
        _services[entry.key] = List<String>.from(entry.value);
      } else {
        // Old-format key — map to closest new category
        final newKey = _oldToNewKeyMap[entry.key];
        if (newKey != null && _services.containsKey(newKey)) {
          _services[newKey]!.addAll(entry.value);
        }
      }
    }
  }

  void _loadFromDraft(SiteReport draft) {
    _draftId = draft.id;
    dateController.text = draft.date;
    dropdownValue = draft.siteName;
    address = draft.address;
    _selectedNoteTags = List<String>.from(draft.noteTags);
    _isRegularMaintenance = draft.isRegularMaintenance;

    // Load the appropriate phase for v2 reports
    final phase =
        _isRegularMaintenance ? draft.regularPhase : draft.additionalPhase;

    if (phase != null) {
      _employees.clear();
      for (var emp in phase.employees) {
        _employees.add({
          'selectedName': emp.name,
          'timeOn': TimeOfDay.fromDateTime(emp.timeOn),
          'timeOff': TimeOfDay.fromDateTime(emp.timeOff),
        });
      }
      _loadServicesFromMap(phase.services);
    }

    // For v1 reports (no phases)
    if (draft.version == 1 ||
        (draft.regularPhase == null && draft.additionalPhase == null)) {
      _employees.clear();
      for (var emp in draft.employees) {
        _employees.add({
          'selectedName': emp.name,
          'timeOn': TimeOfDay.fromDateTime(emp.timeOn),
          'timeOff': TimeOfDay.fromDateTime(emp.timeOff),
        });
      }
      _loadServicesFromMap(draft.services);
    }

    // Ensure at least one employee row
    if (_employees.isEmpty) {
      _employees.add({
        'selectedName': null as String?,
        'timeOn': TimeOfDay.now(),
        'timeOff': TimeOfDay.now(),
      });
    }

    if (draft.description.isNotEmpty) _hasNotes = true;
    if (draft.materials.isNotEmpty) _hasMaterials = true;
    if (draft.disposal?.hasDisposal == true) _hasDisposal = true;
  }

  // --- Employee management ---
  void _addEmployee({TimeOfDay? timeOn, TimeOfDay? timeOff}) {
    setState(() {
      _employees.add({
        'selectedName': null as String?,
        'timeOn': timeOn ?? TimeOfDay.now(),
        'timeOff': timeOff ?? TimeOfDay.now(),
      });
    });
  }

  void _updateEmployeeName(int index, String? name) {
    setState(() => _employees[index]['selectedName'] = name);
    _scheduleDraftSave();
  }

  void _updateTimeOn(int index, TimeOfDay time) {
    setState(() => _employees[index]['timeOn'] = time);
    _scheduleDraftSave();
  }

  void _updateTimeOff(int index, TimeOfDay time) {
    setState(() => _employees[index]['timeOff'] = time);
    _scheduleDraftSave();
  }

  void _deleteEmployee(int index) {
    setState(() => _employees.removeAt(index));
    _scheduleDraftSave();
  }

  // --- Draft auto-save ---
  bool get _hasContent =>
      dropdownValue != null || _employees.any((e) => e['selectedName'] != null);

  void _scheduleDraftSave() {
    if (!_hasContent) return;
    _draftTimer?.cancel();
    _draftTimer = Timer(Duration(seconds: 3), () => _saveDraftNow());
  }

  Future<void> _saveDraftNow() async {
    if (!_hasContent) return;

    final phase = _buildPhaseForDraft();

    final report = SiteReport.fromPhases(
      id: _draftId ?? '',
      siteName: dropdownValue ?? '',
      date: dateController.text,
      address: address,
      submittedBy: currentUser.email ?? '',
      timestamp: DateTime.now(),
      materials: [],
      noteTags: _selectedNoteTags,
      description: '',
      status: 'draft',
      draftOwnerId: currentUser.email,
      regularPhase: _isRegularMaintenance ? phase : null,
      additionalPhase: !_isRegularMaintenance ? phase : null,
    );

    final data = report.toMap();
    if (_draftId != null && _draftId!.isNotEmpty) {
      data['id'] = _draftId;
    }
    _draftId = await _firestoreService.saveDraft(data);
  }

  ReportPhase? _buildPhaseForDraft() {
    DateTime selectedDate;
    try {
      selectedDate = DateFormat('MMMM d, yyyy').parse(dateController.text);
    } catch (_) {
      selectedDate = DateTime.now();
    }

    int totalDuration = 0;
    final employeeTimes = _employees
        .where((e) =>
            e['selectedName'] != null &&
            (e['selectedName'] as String).isNotEmpty)
        .map((e) {
      final timeOn = e['timeOn'] as TimeOfDay;
      final timeOff = e['timeOff'] as TimeOfDay;
      final duration = _calculateDuration(timeOn, timeOff);
      totalDuration += duration.inMinutes;
      return EmployeeTime(
        name: e['selectedName'],
        timeOn: DateTime(selectedDate.year, selectedDate.month,
            selectedDate.day, timeOn.hour, timeOn.minute),
        timeOff: DateTime(selectedDate.year, selectedDate.month,
            selectedDate.day, timeOff.hour, timeOff.minute),
        duration: duration.inMinutes,
      );
    }).toList();

    final filteredServices = Map<String, List<String>>.fromEntries(
        _services.entries.where((e) => e.value.isNotEmpty));

    if (employeeTimes.isEmpty && filteredServices.isEmpty) return null;

    return ReportPhase(
      isRegularMaintenance: _isRegularMaintenance,
      employees: employeeTimes,
      totalDuration: totalDuration,
      services: filteredServices,
    );
  }

  Future<void> _handleBackButton() async {
    if (!_hasContent) {
      Navigator.pop(context);
      return;
    }

    final action = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Save as draft?'),
        content: Text('You can resume this report later from Recent Reports.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'discard'),
            child: Text('Discard', style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'save'),
            child: Text('Save Draft'),
          ),
        ],
      ),
    );

    if (action == 'save') {
      await _saveDraftNow();
      if (mounted) Navigator.pop(context);
    } else if (action == 'discard') {
      if (_draftId != null &&
          _draftId!.isNotEmpty &&
          widget.draftReport == null) {
        await _firestoreService.deleteDraft(_draftId!);
      }
      if (mounted) Navigator.pop(context);
    }
  }

  // --- Helpers ---
  Duration _calculateDuration(TimeOfDay start, TimeOfDay end) {
    final now = DateTime.now();
    final startDT =
        DateTime(now.year, now.month, now.day, start.hour, start.minute);
    final endDT = DateTime(now.year, now.month, now.day, end.hour, end.minute);
    return endDT.difference(startDT);
  }

  ReportPhase? _buildPhase() {
    final selectedDate = DateFormat('MMMM d, yyyy').parse(dateController.text);
    int totalDuration = 0;

    final employeeTimes = _employees
        .where((e) =>
            e['selectedName'] != null &&
            (e['selectedName'] as String).isNotEmpty)
        .map((e) {
      final timeOn = e['timeOn'] as TimeOfDay;
      final timeOff = e['timeOff'] as TimeOfDay;
      final duration = _calculateDuration(timeOn, timeOff);
      totalDuration += duration.inMinutes;

      return EmployeeTime(
        name: e['selectedName'],
        timeOn: DateTime(selectedDate.year, selectedDate.month,
            selectedDate.day, timeOn.hour, timeOn.minute),
        timeOff: DateTime(selectedDate.year, selectedDate.month,
            selectedDate.day, timeOff.hour, timeOff.minute),
        duration: duration.inMinutes,
      );
    }).toList();

    if (employeeTimes.isEmpty) return null;

    final filteredServices = Map<String, List<String>>.fromEntries(
        _services.entries.where((e) => e.value.isNotEmpty));

    return ReportPhase(
      isRegularMaintenance: _isRegularMaintenance,
      employees: employeeTimes,
      totalDuration: totalDuration,
      services: filteredServices,
    );
  }

  // --- Validation ---
  bool _validateForm() {
    if (dropdownValue == null || dropdownValue!.isEmpty) {
      _showError('Please select a site.');
      return false;
    }

    for (var emp in _employees) {
      if (emp['selectedName'] == null ||
          (emp['selectedName'] as String).isEmpty) {
        _showError('Please select an employee name.');
        return false;
      }
    }
    return true;
  }

  void _showError(String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Validation Error'),
        content: Text(msg),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: Text('OK')),
        ],
      ),
    );
  }

  // --- Submit ---
  Future<void> _submitReport({
    List<Map<String, String>> materials = const [],
    bool hasDisposal = false,
    String disposalLocation = '',
    String disposalCost = '',
    String notesText = '',
  }) async {
    final phase = _buildPhase();

    final materialsList = materials
        .map((m) => MaterialList(
              vendor: m['vendor'] ?? '',
              description: m['description'] ?? '',
              cost: m['cost'] ?? '',
            ))
        .toList();

    final disposal = Disposal(
      hasDisposal: hasDisposal,
      location: disposalLocation,
      cost: disposalCost,
    );

    final report = SiteReport.fromPhases(
      siteName: dropdownValue ?? '',
      date: dateController.text,
      address: address,
      submittedBy: currentUser.email ?? '',
      timestamp: DateTime.now(),
      materials: materialsList,
      disposal: disposal,
      noteTags: _selectedNoteTags,
      description: notesText,
      status: 'submitted',
      regularPhase: _isRegularMaintenance ? phase : null,
      additionalPhase: !_isRegularMaintenance ? phase : null,
    );

    try {
      final collection = FirebaseFirestore.instance.collection('SiteReports');
      if (_draftId != null && _draftId!.isNotEmpty) {
        await collection.doc(_draftId).set(report.toMap());
      } else {
        await collection.add(report.toMap());
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showError('Failed to submit report, please try again.');
    }
  }

  // --- Action button logic ---
  void _handleAction() {
    if (!_validateForm()) return;

    final needsPage2 = _hasMaterials || _hasDisposal || _hasNotes;
    if (needsPage2) {
      _navigateToDetails();
    } else {
      _submitReport();
    }
  }

  void _navigateToDetails() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => ReportDetailsPage(
          hasMaterials: _hasMaterials,
          hasDisposal: _hasDisposal,
          hasNotes: _hasNotes,
          selectedNoteTags: _selectedNoteTags,
        ),
      ),
    );

    if (result != null) {
      await _submitReport(
        materials: List<Map<String, String>>.from(
          (result['materials'] as List<dynamic>?)
                  ?.map((m) => Map<String, String>.from(m)) ??
              [],
        ),
        hasDisposal: result['hasDisposal'] ?? false,
        disposalLocation: result['disposalLocation'] ?? '',
        disposalCost: result['disposalCost'] ?? '',
        notesText: result['notesText'] ?? '',
      );
    }
  }

  @override
  void dispose() {
    _draftTimer?.cancel();
    // Flush any pending draft save
    if (_hasContent && _draftTimer != null) {
      _saveDraftNow();
    }
    dateController.dispose();
    super.dispose();
  }

  // --- Service selection helper ---
  void _onServiceChanged(String key, List<String> v) {
    setState(() => _services[key] = v);
    _scheduleDraftSave();
  }

  // --- Section header ---
  Widget _sectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.only(top: 10, bottom: 4),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.montserrat(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Colors.grey[500],
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  // --- Build services section ---
  Widget _buildServicesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ServiceCategory(
          title: 'Lawn Care',
          icon: Icons.grass,
          accentColor: Colors.green[700]!,
          mainServices: const [
            'mow',
            'trim',
            'edge lawns',
            'edge tree wells',
            'rake leaves',
            'litter pick up',
          ],
          extraServices: const ['aerate', 'fertilize', 'lime'],
          selectedMain: _services['Lawn Care']!,
          selectedExtras: _services['Lawn Extras']!,
          onMainChanged: (v) => _onServiceChanged('Lawn Care', v),
          onExtrasChanged: (v) => _onServiceChanged('Lawn Extras', v),
        ),
        ServiceCategory(
          title: 'Garden Maintenance',
          icon: Icons.yard,
          accentColor: const Color(0xFF2E7D32),
          mainServices: const [
            'weed',
            'prune < 8ft',
            'prune > 8ft',
            'hedge',
            'rake debris',
            'litter pick up',
          ],
          extraServices: const [
            'fertilize',
            'bark mulch gardens',
            'bark mulch tree wells',
            'top soil gardens',
            'top soil tree wells',
          ],
          selectedMain: _services['Garden Maintenance']!,
          selectedExtras: _services['Garden Extras']!,
          onMainChanged: (v) => _onServiceChanged('Garden Maintenance', v),
          onExtrasChanged: (v) => _onServiceChanged('Garden Extras', v),
        ),
        ServiceCategory(
          title: 'Common Areas',
          icon: Icons.location_city,
          accentColor: Colors.blueGrey[700]!,
          mainServices: const [
            'dog park',
            'parking stalls',
            'blow walkways',
            'parking curbs',
            'drain basins',
            'garbage enclosures',
            'litter pick up',
          ],
          extraServices: const [
            'pressure washing',
            'irrigation startup',
            'irrigation blowout',
            'irrigation repairs',
          ],
          selectedMain: _services['Common Areas']!,
          selectedExtras: _services['Common Extras']!,
          onMainChanged: (v) => _onServiceChanged('Common Areas', v),
          onExtrasChanged: (v) => _onServiceChanged('Common Extras', v),
        ),
      ],
    );
  }

  // --- Build employees section ---
  Widget _buildEmployeesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ..._employees.asMap().entries.map((entry) {
          final index = entry.key;
          final staff = entry.value;
          return Padding(
            padding: EdgeInsets.only(bottom: 4),
            child: EmployeeTimesComponent(
              key: ValueKey('emp_$index'),
              selectedName: staff['selectedName'],
              initialTimeOn: staff['timeOn'],
              initialTimeOff: staff['timeOff'],
              onNameChanged: (name) => _updateEmployeeName(index, name),
              onTimeOnChanged: (time) => _updateTimeOn(index, time),
              onTimeOffChanged: (time) => _updateTimeOff(index, time),
              onDelete: () => _deleteEmployee(index),
            ),
          );
        }),
        GestureDetector(
          onTap: () => _addEmployee(),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_circle_outline,
                    size: 14, color: Colors.green[700]),
                SizedBox(width: 4),
                Text(
                  'Add employee',
                  style: GoogleFonts.montserrat(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- Checkbox row ---
  Widget _checkboxRow(
      String label, IconData icon, bool value, ValueChanged<bool?> onChanged) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: Checkbox(
                value: value,
                onChanged: onChanged,
                activeColor: Color.fromARGB(255, 31, 182, 77),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
            SizedBox(width: 8),
            Icon(icon, size: 15, color: Colors.grey[600]),
            SizedBox(width: 6),
            Text(label, style: GoogleFonts.montserrat(fontSize: 11)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final needsPage2 = _hasMaterials || _hasDisposal || _hasNotes;
    final accentColor = _isRegularMaintenance
        ? Color.fromARGB(255, 31, 182, 77)
        : Color.fromARGB(255, 97, 125, 140);
    final typeLabel =
        _isRegularMaintenance ? 'Maintenance Program' : 'Additional Service';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: accentColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: _handleBackButton,
        ),
        title: Text(
          typeLabel,
          style: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // === SITE & DATE ===
                  _sectionHeader('Site & Date'),
                  DatePickerComponent(dateController: dateController),
                  SizedBox(height: 6),
                  SitePickerComponent(
                    dropdownValue: dropdownValue,
                    selectedSite: selectedSite,
                    onSiteChanged: (site) {
                      setState(() {
                        selectedSite = site;
                        dropdownValue = site.name;
                        address = site.address;
                      });
                      _scheduleDraftSave();
                    },
                  ),

                  // === EMPLOYEES & TIMES ===
                  _sectionHeader('Employees & Times'),
                  _buildEmployeesSection(),

                  // === SERVICES ===
                  _buildServicesSection(),

                  // === QUICK NOTE TAGS ===
                  _sectionHeader('Quick Notes'),
                  Wrap(
                    spacing: 4,
                    runSpacing: 0,
                    children: NotesSection.defaultTags.map((tag) {
                      final isSelected = _selectedNoteTags.contains(tag);
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            isSelected
                                ? _selectedNoteTags.remove(tag)
                                : _selectedNoteTags.add(tag);
                            if (_selectedNoteTags.isNotEmpty) {
                              _hasNotes = true;
                            }
                          });
                          _scheduleDraftSave();
                        },
                        child: Container(
                          margin: EdgeInsets.only(bottom: 4),
                          padding:
                              EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.green[100]
                                : Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.green[400]!
                                  : Colors.grey[300]!,
                              width: 0.5,
                            ),
                          ),
                          child: Text(
                            tag,
                            style: GoogleFonts.montserrat(
                              fontSize: 10,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: isSelected
                                  ? Colors.green[900]
                                  : Colors.grey[700],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 6),

                  // === PAGE 2 CHECKBOXES ===
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      border: Border.all(color: Colors.grey[200]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        _checkboxRow(
                          'Materials purchased',
                          Icons.inventory_2_outlined,
                          _hasMaterials,
                          (v) => setState(() => _hasMaterials = v ?? false),
                        ),
                        _checkboxRow(
                          'Disposal run',
                          Icons.local_shipping_outlined,
                          _hasDisposal,
                          (v) => setState(() => _hasDisposal = v ?? false),
                        ),
                        _checkboxRow(
                          'Add detailed notes',
                          Icons.edit_note,
                          _hasNotes,
                          (v) => setState(() => _hasNotes = v ?? false),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // === ACTION BUTTON ===
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton.icon(
                  icon: Icon(needsPage2 ? Icons.arrow_forward : Icons.send,
                      size: 16),
                  label: Text(
                    needsPage2 ? 'Next' : 'Submit Report',
                    style: GoogleFonts.montserrat(
                        fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _handleAction,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
