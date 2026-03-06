import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gemini_landscaping_app/models/site_info.dart';
import 'package:gemini_landscaping_app/models/site_report.dart';
import 'package:gemini_landscaping_app/services/firestore_service.dart';
import 'package:gemini_landscaping_app/screens/add_report/date_picker.dart';
import 'package:gemini_landscaping_app/screens/add_report/employee_times.dart';
import 'package:gemini_landscaping_app/screens/add_report/material.dart';
import 'package:gemini_landscaping_app/screens/add_report/notes_section.dart';
import 'package:gemini_landscaping_app/screens/add_report/report_details_page.dart';
import 'package:gemini_landscaping_app/screens/add_report/service_list.dart';
import 'package:gemini_landscaping_app/screens/add_report/site_picker.dart';
import 'package:gemini_landscaping_app/models/equipment_model.dart';
import 'package:gemini_landscaping_app/models/repair_entry.dart';
import 'package:gemini_landscaping_app/services/photo_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
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
  bool _notesExpanded = false;
  bool _hasDetailedNotes = false;
  final _notesController = TextEditingController();

  // Inline materials
  bool _hasMaterials = false;
  List<Map<String, dynamic>> _materials = [];

  // Inline disposal
  bool _hasDisposal = false;
  final _disposalLocationController = TextEditingController();
  final _disposalCostController = TextEditingController();

  // Equipment issue linking
  List<Equipment> _equipmentList = [];
  bool _equipmentLoaded = false;
  String? _linkedEquipmentId;
  final _equipmentIssueController = TextEditingController();
  String _equipmentIssuePriority = 'medium';

  // Photos
  final List<File> _pickedPhotos = [];
  final _imagePicker = ImagePicker();

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

    if (draft.description.isNotEmpty) _hasDetailedNotes = true;
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

  static const _extrasKeys = {'Lawn Extras', 'Garden Extras', 'Common Extras'};

  ReportPhase? _buildPhase({bool excludeExtras = false}) {
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
        _services.entries.where((e) =>
            e.value.isNotEmpty &&
            (!excludeExtras || !_extrasKeys.contains(e.key))));

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

  // ─── Photo picking ──────────────────────────────────
  Future<void> _pickPhoto(ImageSource source) async {
    final picked = await _imagePicker.pickImage(
      source: source,
      maxWidth: 1200,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() => _pickedPhotos.add(File(picked.path)));
    }
  }

  void _showPhotoSourceSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(ctx);
                _pickPhoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(ctx);
                _pickPhoto(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Upload picked photos after report is saved. Fire-and-forget.
  void _uploadReportPhotos(String reportId) {
    if (_pickedPhotos.isEmpty) return;
    final siteId = selectedSite?.id;
    final siteName = dropdownValue ?? '';
    final uploadedBy = currentUser.displayName ?? currentUser.email ?? '';
    final uploadedByUid = currentUser.uid;
    final files = List<File>.from(_pickedPhotos);

    // Fire-and-forget — don't block navigation
    PhotoService().uploadMultiple(
      files: files,
      category: 'site',
      uploadedBy: uploadedBy,
      uploadedByUid: uploadedByUid,
      siteId: siteId,
      siteName: siteName,
      reportId: reportId,
      tags: ['report'],
    );
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

  // --- Collect inline page 1 data ---
  List<MaterialList> _collectMaterials() {
    if (!_hasMaterials) return [];
    return _materials
        .map((m) => MaterialList(
              vendor: (m['vendorController'] as TextEditingController).text,
              description:
                  (m['materialController'] as TextEditingController).text,
              cost: (m['costController'] as TextEditingController).text,
            ))
        .toList();
  }

  Disposal _collectDisposal() {
    return Disposal(
      hasDisposal: _hasDisposal,
      location: _disposalLocationController.text,
      cost: _disposalCostController.text,
    );
  }

  String _collectNotesText() {
    return _hasDetailedNotes ? _notesController.text : '';
  }

  // --- Submit single maintenance report ---
  Future<void> _submitSingleReport() async {
    // Build phase with only main services (strip extras)
    final phase = _buildPhase();

    final report = SiteReport.fromPhases(
      siteName: dropdownValue ?? '',
      date: dateController.text,
      address: address,
      submittedBy: currentUser.email ?? '',
      timestamp: DateTime.now(),
      materials: _collectMaterials(),
      disposal: _collectDisposal(),
      noteTags: _selectedNoteTags,
      description: _collectNotesText(),
      status: 'submitted',
      regularPhase: _isRegularMaintenance ? phase : null,
      additionalPhase: !_isRegularMaintenance ? phase : null,
    );

    try {
      final collection = FirebaseFirestore.instance.collection('SiteReports');
      String reportId;
      if (_draftId != null && _draftId!.isNotEmpty) {
        await collection.doc(_draftId).set(report.toMap());
        reportId = _draftId!;
      } else {
        final docRef = await collection.add(report.toMap());
        reportId = docRef.id;
      }
      await _createEquipmentRepairEntry(reportId);
      _uploadReportPhotos(reportId);
      // Auto-detect service program matches (fire-and-forget)
      FirestoreService().detectServiceProgramMatches(
        reportId: reportId,
        siteName: report.siteName,
        reportDate: report.date,
        services: report.services,
      );
      // Prevent dispose() from re-saving as draft
      _draftTimer?.cancel();
      _draftTimer = null;
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showError('Failed to submit report, please try again.');
    }
  }

  // --- Submit both reports (maintenance + additional services) ---
  Future<void> _submitBothReports(Map<String, dynamic> page2Data) async {
    final selectedDate = DateFormat('MMMM d, yyyy').parse(dateController.text);

    // 1. Build Maintenance report (main services only, no extras)
    final mainPhase = _buildPhase(excludeExtras: true);
    final mainReport = SiteReport.fromPhases(
      siteName: dropdownValue ?? '',
      date: dateController.text,
      address: address,
      submittedBy: currentUser.email ?? '',
      timestamp: DateTime.now(),
      materials: _collectMaterials(),
      disposal: _collectDisposal(),
      noteTags: _selectedNoteTags,
      description: _collectNotesText(),
      status: 'submitted',
      regularPhase: mainPhase,
    );

    // 2. Build Additional Services report from page 2 data
    final serviceEmpsRaw = page2Data['serviceEmployees']
        as Map<String, List<Map<String, dynamic>>>;

    // Build per-service EmployeeTime map
    final serviceEmployees = <String, List<EmployeeTime>>{};
    final allAdditionalEmps = <EmployeeTime>[];
    int additionalDuration = 0;

    for (var entry in serviceEmpsRaw.entries) {
      final emps = entry.value.map((e) {
        final timeOn = e['timeOn'] as TimeOfDay;
        final timeOff = e['timeOff'] as TimeOfDay;
        final duration = _calculateDuration(timeOn, timeOff);
        additionalDuration += duration.inMinutes;
        return EmployeeTime(
          name: e['name'] as String,
          timeOn: DateTime(selectedDate.year, selectedDate.month,
              selectedDate.day, timeOn.hour, timeOn.minute),
          timeOff: DateTime(selectedDate.year, selectedDate.month,
              selectedDate.day, timeOff.hour, timeOff.minute),
          duration: duration.inMinutes,
        );
      }).toList();
      serviceEmployees[entry.key] = emps;
      allAdditionalEmps.addAll(emps);
    }

    // Build extras services map
    final extrasServices = Map<String, List<String>>.from(_selectedExtrasMap);

    // Per-service notes from page 2
    final serviceNotesRaw =
        page2Data['serviceNotes'] as Map<String, String>? ?? {};

    // Per-service materials from page 2
    Map<String, List<MaterialList>>? serviceMaterials;
    final smRaw = page2Data['serviceMaterials']
        as Map<String, List<Map<String, dynamic>>>?;
    if (smRaw != null && smRaw.isNotEmpty) {
      serviceMaterials = smRaw.map((key, matList) => MapEntry(
            key,
            matList
                .map((m) => MaterialList(
                      vendor: m['vendor'] ?? '',
                      description: m['description'] ?? '',
                      cost: m['cost'] ?? '',
                    ))
                .toList(),
          ));
    }

    // Per-service disposal from page 2
    Map<String, Disposal>? serviceDisposal;
    final sdRaw =
        page2Data['serviceDisposal'] as Map<String, Map<String, dynamic>>?;
    if (sdRaw != null && sdRaw.isNotEmpty) {
      serviceDisposal = sdRaw.map((key, d) => MapEntry(
            key,
            Disposal(
              hasDisposal: d['hasDisposal'] ?? true,
              location: d['location'] ?? '',
              cost: d['cost'] ?? '',
            ),
          ));
    }

    final additionalPhase = ReportPhase(
      isRegularMaintenance: false,
      employees: allAdditionalEmps,
      totalDuration: additionalDuration,
      services: extrasServices,
      serviceEmployees: serviceEmployees,
      serviceNotes: serviceNotesRaw.isNotEmpty ? serviceNotesRaw : null,
      serviceMaterials: serviceMaterials,
      serviceDisposal: serviceDisposal,
    );

    final additionalReport = SiteReport.fromPhases(
      siteName: dropdownValue ?? '',
      date: dateController.text,
      address: address,
      submittedBy: currentUser.email ?? '',
      timestamp: DateTime.now(),
      materials: [],
      status: 'submitted',
      additionalPhase: additionalPhase,
    );

    try {
      final collection = FirebaseFirestore.instance.collection('SiteReports');
      // Submit maintenance report
      String mainReportId;
      if (_draftId != null && _draftId!.isNotEmpty) {
        await collection.doc(_draftId).set(mainReport.toMap());
        mainReportId = _draftId!;
      } else {
        final docRef = await collection.add(mainReport.toMap());
        mainReportId = docRef.id;
      }
      // Submit additional services report (always new doc)
      final addDocRef = await collection.add(additionalReport.toMap());
      // Link equipment issue to the main report
      await _createEquipmentRepairEntry(mainReportId);
      _uploadReportPhotos(mainReportId);
      // Auto-detect service program matches (fire-and-forget)
      FirestoreService().detectServiceProgramMatches(
        reportId: mainReportId,
        siteName: mainReport.siteName,
        reportDate: mainReport.date,
        services: mainReport.services,
      );
      FirestoreService().detectServiceProgramMatches(
        reportId: addDocRef.id,
        siteName: additionalReport.siteName,
        reportDate: additionalReport.date,
        services: additionalReport.services,
      );
      // Prevent dispose() from re-saving as draft
      _draftTimer?.cancel();
      _draftTimer = null;
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showError('Failed to submit reports, please try again.');
    }
  }

  // --- Submit extras-only report (no maintenance report) ---
  Future<void> _submitExtrasOnly(Map<String, dynamic> page2Data) async {
    final selectedDate = DateFormat('MMMM d, yyyy').parse(dateController.text);

    // Build additional phase from page 2 data (same parsing as _submitBothReports)
    final serviceEmpsRaw = page2Data['serviceEmployees']
        as Map<String, List<Map<String, dynamic>>>;

    final serviceEmployees = <String, List<EmployeeTime>>{};
    final allAdditionalEmps = <EmployeeTime>[];
    int additionalDuration = 0;

    for (var entry in serviceEmpsRaw.entries) {
      final emps = entry.value.map((e) {
        final timeOn = e['timeOn'] as TimeOfDay;
        final timeOff = e['timeOff'] as TimeOfDay;
        final duration = _calculateDuration(timeOn, timeOff);
        additionalDuration += duration.inMinutes;
        return EmployeeTime(
          name: e['name'] as String,
          timeOn: DateTime(selectedDate.year, selectedDate.month,
              selectedDate.day, timeOn.hour, timeOn.minute),
          timeOff: DateTime(selectedDate.year, selectedDate.month,
              selectedDate.day, timeOff.hour, timeOff.minute),
          duration: duration.inMinutes,
        );
      }).toList();
      serviceEmployees[entry.key] = emps;
      allAdditionalEmps.addAll(emps);
    }

    final extrasServices = Map<String, List<String>>.from(_selectedExtrasMap);

    final serviceNotesRaw =
        page2Data['serviceNotes'] as Map<String, String>? ?? {};

    Map<String, List<MaterialList>>? serviceMaterials;
    final smRaw = page2Data['serviceMaterials']
        as Map<String, List<Map<String, dynamic>>>?;
    if (smRaw != null && smRaw.isNotEmpty) {
      serviceMaterials = smRaw.map((key, matList) => MapEntry(
            key,
            matList
                .map((m) => MaterialList(
                      vendor: m['vendor'] ?? '',
                      description: m['description'] ?? '',
                      cost: m['cost'] ?? '',
                    ))
                .toList(),
          ));
    }

    Map<String, Disposal>? serviceDisposal;
    final sdRaw =
        page2Data['serviceDisposal'] as Map<String, Map<String, dynamic>>?;
    if (sdRaw != null && sdRaw.isNotEmpty) {
      serviceDisposal = sdRaw.map((key, d) => MapEntry(
            key,
            Disposal(
              hasDisposal: d['hasDisposal'] ?? true,
              location: d['location'] ?? '',
              cost: d['cost'] ?? '',
            ),
          ));
    }

    final additionalPhase = ReportPhase(
      isRegularMaintenance: false,
      employees: allAdditionalEmps,
      totalDuration: additionalDuration,
      services: extrasServices,
      serviceEmployees: serviceEmployees,
      serviceNotes: serviceNotesRaw.isNotEmpty ? serviceNotesRaw : null,
      serviceMaterials: serviceMaterials,
      serviceDisposal: serviceDisposal,
    );

    final report = SiteReport.fromPhases(
      siteName: dropdownValue ?? '',
      date: dateController.text,
      address: address,
      submittedBy: currentUser.email ?? '',
      timestamp: DateTime.now(),
      materials: _collectMaterials(),
      disposal: _collectDisposal(),
      noteTags: _selectedNoteTags,
      description: _collectNotesText(),
      status: 'submitted',
      additionalPhase: additionalPhase,
    );

    try {
      final collection = FirebaseFirestore.instance.collection('SiteReports');
      String reportId;
      if (_draftId != null && _draftId!.isNotEmpty) {
        await collection.doc(_draftId).set(report.toMap());
        reportId = _draftId!;
      } else {
        final docRef = await collection.add(report.toMap());
        reportId = docRef.id;
      }
      await _createEquipmentRepairEntry(reportId);
      _uploadReportPhotos(reportId);
      // Auto-detect service program matches (fire-and-forget)
      FirestoreService().detectServiceProgramMatches(
        reportId: reportId,
        siteName: report.siteName,
        reportDate: report.date,
        services: report.services,
      );
      _draftTimer?.cancel();
      _draftTimer = null;
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showError('Failed to submit report, please try again.');
    }
  }

  // --- Equipment issue linking ---
  bool get _hasEquipmentIssueTag =>
      _selectedNoteTags.contains('Equipment issue');

  Future<void> _loadEquipmentList() async {
    if (_equipmentLoaded) return;
    final snapshot = await FirebaseFirestore.instance
        .collection('equipment')
        .where('active', isEqualTo: true)
        .get();
    final list = snapshot.docs
        .map((doc) => Equipment.fromMap(doc.id, doc.data()))
        .toList();
    list.sort((a, b) => a.name.compareTo(b.name));
    if (mounted) {
      setState(() {
        _equipmentList = list;
        _equipmentLoaded = true;
      });
    }
  }

  /// Creates a repair_entry in the linked equipment's subcollection.
  /// Call after report is saved so we have the report doc ID.
  Future<void> _createEquipmentRepairEntry(String reportId) async {
    if (!_hasEquipmentIssueTag || _linkedEquipmentId == null) return;

    final entry = RepairEntry(
      id: '',
      dateTime: DateTime.now(),
      description: _equipmentIssueController.text.trim().isNotEmpty
          ? _equipmentIssueController.text.trim()
          : 'Issue reported from site report',
      priority: _equipmentIssuePriority,
      reportedBy: currentUser.email ?? 'unknown',
      linkedReportId: reportId,
      linkedSiteName: dropdownValue,
    );

    await FirebaseFirestore.instance
        .collection('equipment')
        .doc(_linkedEquipmentId)
        .collection('repair_entries')
        .add(entry.toMap());

    // Update equipment status if priority warrants it
    if (_equipmentIssuePriority == 'high') {
      await FirebaseFirestore.instance
          .collection('equipment')
          .doc(_linkedEquipmentId)
          .update({'currentStatus': 'needs-attention'});
    }
  }

  // --- Action button logic ---
  void _handleAction() {
    if (!_validateForm()) return;

    if (!_isRegularMaintenance) {
      // Additional services mode — all services go to page 2
      if (_hasAnyServicesSelected) {
        _navigateToAdditionalServices();
      } else {
        _showError('Please select at least one service.');
      }
    } else if (_hasExtrasSelected) {
      // Regular maintenance + extras → page 2 for extras
      _navigateToAdditionalServices();
    } else {
      // Regular maintenance only → submit single report
      _submitSingleReport();
    }
  }

  void _navigateToAdditionalServices() async {
    // Gather employee names from page 1
    final employeeNames = _employees
        .where((e) =>
            e['selectedName'] != null &&
            (e['selectedName'] as String).isNotEmpty)
        .map((e) => e['selectedName'] as String)
        .toList();

    // Find the earliest start time from page 1 employees
    TimeOfDay siteStartTime = TimeOfDay(hour: 23, minute: 59);
    for (var emp in _employees) {
      if (emp['selectedName'] != null) {
        final t = emp['timeOn'] as TimeOfDay;
        if (t.hour * 60 + t.minute <
            siteStartTime.hour * 60 + siteStartTime.minute) {
          siteStartTime = t;
        }
      }
    }

    final extrasOnly = !_isRegularMaintenance;

    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => AdditionalServicesPage(
          date: dateController.text,
          siteName: dropdownValue ?? '',
          selectedExtras: _selectedExtrasMap,
          employeeNames: employeeNames,
          siteStartTime: siteStartTime,
          extrasOnly: extrasOnly,
        ),
      ),
    );

    if (result != null) {
      if (extrasOnly) {
        await _submitExtrasOnly(result);
      } else {
        await _submitBothReports(result);
      }
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
    _notesController.dispose();
    _disposalLocationController.dispose();
    _disposalCostController.dispose();
    _equipmentIssueController.dispose();
    for (var m in _materials) {
      (m['vendorController'] as TextEditingController).dispose();
      (m['materialController'] as TextEditingController).dispose();
      (m['costController'] as TextEditingController).dispose();
    }
    super.dispose();
  }

  // --- Service selection helper ---
  void _onServiceChanged(String key, List<String> v) {
    setState(() => _services[key] = v);
    _scheduleDraftSave();
  }

  // --- Extras selected check ---
  bool get _hasExtrasSelected =>
      _services['Lawn Extras']!.isNotEmpty ||
      _services['Garden Extras']!.isNotEmpty ||
      _services['Common Extras']!.isNotEmpty;

  bool get _hasAnyServicesSelected => _services.values.any((v) => v.isNotEmpty);

  // Show "Next" button when extras-only mode with services, or maintenance with extras
  bool get _showNextButton =>
      (!_isRegularMaintenance && _hasAnyServicesSelected) ||
      (_isRegularMaintenance && _hasExtrasSelected);

  Map<String, List<String>> get _selectedExtrasMap {
    final map = <String, List<String>>{};
    if (_isRegularMaintenance) {
      // Only extras categories
      for (var key in ['Lawn Extras', 'Garden Extras', 'Common Extras']) {
        if (_services[key]!.isNotEmpty) {
          map[key] = _services[key]!;
        }
      }
    } else {
      // All categories — everything is an "extra" in additional services mode
      for (var entry in _services.entries) {
        if (entry.value.isNotEmpty) {
          map[entry.key] = entry.value;
        }
      }
    }
    return map;
  }

  // --- Inline materials ---
  void _addMaterial() {
    setState(() {
      _materials.add({
        'vendorController': TextEditingController(),
        'materialController': TextEditingController(),
        'costController': TextEditingController(),
      });
    });
  }

  void _deleteMaterial(int index) {
    final m = _materials[index];
    (m['vendorController'] as TextEditingController).dispose();
    (m['materialController'] as TextEditingController).dispose();
    (m['costController'] as TextEditingController).dispose();
    setState(() => _materials.removeAt(index));
  }

  // --- Section header ---
  Widget _sectionHeader(String title, {IconData? icon}) {
    return Padding(
      padding: EdgeInsets.only(top: 14, bottom: 6),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 15, color: Color.fromARGB(255, 59, 82, 73)),
            SizedBox(width: 6),
          ],
          Text(
            title.toUpperCase(),
            style: GoogleFonts.montserrat(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color.fromARGB(255, 59, 82, 73),
              letterSpacing: 0.8,
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Divider(
              color: Colors.grey[300],
              thickness: 0.5,
            ),
          ),
        ],
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
          extraServices: const ['aerate', 'lawn fertilizer', 'lime'],
          selectedMain: _services['Lawn Care']!,
          selectedExtras: _services['Lawn Extras']!,
          onMainChanged: (v) => _onServiceChanged('Lawn Care', v),
          onExtrasChanged: (v) => _onServiceChanged('Lawn Extras', v),
          collapsibleExtras: true,
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
            'garden fertilizer',
            'bark mulch gardens',
            'bark mulch tree wells',
            'top soil gardens',
            'top soil tree wells',
          ],
          selectedMain: _services['Garden Maintenance']!,
          selectedExtras: _services['Garden Extras']!,
          onMainChanged: (v) => _onServiceChanged('Garden Maintenance', v),
          onExtrasChanged: (v) => _onServiceChanged('Garden Extras', v),
          collapsibleExtras: true,
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
          collapsibleExtras: true,
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
            padding: EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_circle_outline,
                    size: 16, color: Colors.green[700]),
                SizedBox(width: 6),
                Text(
                  'Add employee',
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
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

  // --- Inline equipment issue picker ---
  Widget _buildEquipmentIssuePicker() {
    return Container(
      margin: EdgeInsets.only(top: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.amber[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber, size: 16, color: Colors.amber[800]),
              SizedBox(width: 6),
              Text(
                'Link Equipment Issue',
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.amber[900],
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          // Equipment dropdown
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: _equipmentLoaded
                ? DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _linkedEquipmentId,
                      hint: Text('Select equipment...',
                          style: GoogleFonts.montserrat(
                              fontSize: 12, color: Colors.grey[400])),
                      style: GoogleFonts.montserrat(
                          fontSize: 12, color: Colors.black87),
                      items: _equipmentList.map((eq) {
                        return DropdownMenuItem(
                          value: eq.id,
                          child: Text('${eq.name} (${eq.equipmentType})',
                              overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (v) {
                        setState(() => _linkedEquipmentId = v);
                      },
                    ),
                  )
                : Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text('Loading equipment...',
                            style: GoogleFonts.montserrat(
                                fontSize: 12, color: Colors.grey[500])),
                      ],
                    ),
                  ),
          ),
          SizedBox(height: 8),
          // Brief description
          TextField(
            controller: _equipmentIssueController,
            style: GoogleFonts.montserrat(fontSize: 12),
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'Brief description of issue...',
              hintStyle:
                  GoogleFonts.montserrat(fontSize: 12, color: Colors.grey[400]),
              filled: true,
              fillColor: Colors.white,
              isDense: true,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.amber[700]!, width: 1.5),
              ),
            ),
          ),
          SizedBox(height: 8),
          // Priority chips
          Row(
            children: [
              Text('Priority: ',
                  style: GoogleFonts.montserrat(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700])),
              SizedBox(width: 4),
              ...['low', 'medium', 'high'].map((p) {
                final isSelected = _equipmentIssuePriority == p;
                final color = p == 'high'
                    ? Colors.red
                    : p == 'medium'
                        ? Colors.orange
                        : Colors.amber[700]!;
                return GestureDetector(
                  onTap: () => setState(() => _equipmentIssuePriority = p),
                  child: Container(
                    margin: EdgeInsets.only(right: 6),
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isSelected ? color.withAlpha(25) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? color : Colors.grey[300]!,
                      ),
                    ),
                    child: Text(
                      p[0].toUpperCase() + p.substring(1),
                      style: GoogleFonts.montserrat(
                        fontSize: 11,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected ? color : Colors.grey[600],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  // --- Toggle row ---
  Widget _toggleRow(
      String label, IconData icon, bool value, ValueChanged<bool?> onChanged) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        margin: EdgeInsets.only(top: 6),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: value ? Colors.green[50] : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: value ? Colors.green[300]! : Colors.grey[200]!,
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 18, color: value ? Colors.green[700] : Colors.grey[500]),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.montserrat(
                  fontSize: 13,
                  fontWeight: value ? FontWeight.w600 : FontWeight.w400,
                  color: value ? Colors.green[800] : Colors.grey[700],
                ),
              ),
            ),
            Icon(
              value ? Icons.check_circle : Icons.circle_outlined,
              size: 20,
              color: value ? Colors.green[600] : Colors.grey[300],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = _isRegularMaintenance
        ? Color.fromARGB(255, 31, 182, 77)
        : Color.fromARGB(255, 97, 125, 140);
    final typeLabel =
        _isRegularMaintenance ? 'Maintenance Program' : 'Additional Service';

    return Scaffold(
      backgroundColor: Colors.grey[50],
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
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // === SITE & DATE ===
                  _sectionHeader('Site & Date', icon: Icons.business),
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

                  // === REPORT TYPE TOGGLE ===
                  SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    padding: EdgeInsets.all(3),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              if (!_isRegularMaintenance) {
                                setState(() => _isRegularMaintenance = true);
                              }
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: _isRegularMaintenance
                                    ? Color.fromARGB(255, 31, 182, 77)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'Maintenance',
                                style: GoogleFonts.montserrat(
                                  fontSize: 13,
                                  fontWeight: _isRegularMaintenance
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: _isRegularMaintenance
                                      ? Colors.white
                                      : Colors.grey[600],
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              if (_isRegularMaintenance) {
                                setState(() => _isRegularMaintenance = false);
                              }
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: !_isRegularMaintenance
                                    ? Color.fromARGB(255, 97, 125, 140)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'Additional Services',
                                style: GoogleFonts.montserrat(
                                  fontSize: 13,
                                  fontWeight: !_isRegularMaintenance
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: !_isRegularMaintenance
                                      ? Colors.white
                                      : Colors.grey[600],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // === EMPLOYEES & TIMES ===
                  _sectionHeader('Employees & Times',
                      icon: Icons.people_outline),
                  _buildEmployeesSection(),

                  // === SERVICES ===
                  _sectionHeader('Services', icon: Icons.checklist),
                  _buildServicesSection(),

                  // === QUICK NOTES (collapsible) ===
                  GestureDetector(
                    onTap: () =>
                        setState(() => _notesExpanded = !_notesExpanded),
                    child: Padding(
                      padding: EdgeInsets.only(top: 14, bottom: 6),
                      child: Row(
                        children: [
                          Icon(Icons.sticky_note_2_outlined,
                              size: 15, color: Color.fromARGB(255, 59, 82, 73)),
                          SizedBox(width: 6),
                          Text(
                            'QUICK NOTES',
                            style: GoogleFonts.montserrat(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color.fromARGB(255, 59, 82, 73),
                              letterSpacing: 0.8,
                            ),
                          ),
                          if (_selectedNoteTags.isNotEmpty && !_notesExpanded)
                            Container(
                              margin: EdgeInsets.only(left: 6),
                              padding: EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.green[100],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${_selectedNoteTags.length}',
                                style: GoogleFonts.montserrat(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.green[800],
                                ),
                              ),
                            ),
                          SizedBox(width: 4),
                          Icon(
                            _notesExpanded
                                ? Icons.expand_less
                                : Icons.expand_more,
                            size: 16,
                            color: Color.fromARGB(255, 59, 82, 73),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Divider(
                                color: Colors.grey[300], thickness: 0.5),
                          ),
                          SizedBox(width: 8),
                          // "Add detailed notes" toggle
                          GestureDetector(
                            onTap: () => setState(
                                () => _hasDetailedNotes = !_hasDetailedNotes),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _hasDetailedNotes
                                    ? Colors.green[50]
                                    : Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _hasDetailedNotes
                                      ? Colors.green[300]!
                                      : Colors.grey[300]!,
                                  width: 0.5,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _hasDetailedNotes
                                        ? Icons.edit_note
                                        : Icons.edit_note,
                                    size: 14,
                                    color: _hasDetailedNotes
                                        ? Colors.green[700]
                                        : Colors.grey[500],
                                  ),
                                  SizedBox(width: 3),
                                  Text(
                                    'Add notes',
                                    style: GoogleFonts.montserrat(
                                      fontSize: 10,
                                      fontWeight: _hasDetailedNotes
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                      color: _hasDetailedNotes
                                          ? Colors.green[700]
                                          : Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_notesExpanded)
                    Wrap(
                      spacing: 6,
                      runSpacing: 2,
                      children: NotesSection.defaultTags.map((tag) {
                        final isSelected = _selectedNoteTags.contains(tag);
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              isSelected
                                  ? _selectedNoteTags.remove(tag)
                                  : _selectedNoteTags.add(tag);
                            });
                            // Load equipment list when Equipment issue tag is selected
                            if (tag == 'Equipment issue' &&
                                _selectedNoteTags.contains(tag)) {
                              _loadEquipmentList();
                            }
                            _scheduleDraftSave();
                          },
                          child: Container(
                            margin: EdgeInsets.only(bottom: 6),
                            padding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.green[100]
                                  : Colors.grey[50],
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.green[400]!
                                    : Colors.grey[300]!,
                                width: isSelected ? 1.0 : 0.5,
                              ),
                            ),
                            child: Text(
                              tag,
                              style: GoogleFonts.montserrat(
                                fontSize: 12,
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
                  if (_hasDetailedNotes)
                    Container(
                      margin: EdgeInsets.only(top: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      height: 80,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: TextField(
                          controller: _notesController,
                          maxLines: null,
                          style: GoogleFonts.montserrat(fontSize: 12),
                          keyboardType: TextInputType.multiline,
                          decoration: InputDecoration(
                            hintText: 'Any additional details...',
                            hintStyle: GoogleFonts.montserrat(
                                fontSize: 12, color: Colors.grey[400]),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),

                  SizedBox(height: 4),

                  // === INLINE EQUIPMENT ISSUE PICKER ===
                  if (_hasEquipmentIssueTag) _buildEquipmentIssuePicker(),

                  // === MAINTENANCE-ONLY REMINDER ===
                  if (_isRegularMaintenance && _hasExtrasSelected)
                    Padding(
                      padding: EdgeInsets.only(top: 8, bottom: 2),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline,
                              size: 14, color: Colors.blueGrey[400]),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Maintenance only — extras have their own on the next page',
                              style: GoogleFonts.montserrat(
                                fontSize: 11,
                                color: Colors.blueGrey[400],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // === INLINE MATERIALS ===
                  _toggleRow(
                    'Materials purchased',
                    Icons.inventory_2_outlined,
                    _hasMaterials,
                    (v) {
                      setState(() {
                        _hasMaterials = v ?? false;
                        if (_hasMaterials && _materials.isEmpty) {
                          _addMaterial();
                        }
                      });
                    },
                  ),
                  if (_hasMaterials) ...[
                    ..._materials.asMap().entries.map((entry) {
                      final index = entry.key;
                      final material = entry.value;
                      return Padding(
                        padding: EdgeInsets.only(top: 6),
                        child: Row(
                          children: [
                            Expanded(
                              child: MaterialComponent(
                                vendorController: material['vendorController'],
                                materialController:
                                    material['materialController'],
                                costController: material['costController'],
                              ),
                            ),
                            SizedBox(width: 4),
                            GestureDetector(
                              onTap: () => _deleteMaterial(index),
                              child: Container(
                                padding: EdgeInsets.all(6),
                                child: Icon(Icons.remove_circle_outline,
                                    color: Colors.red[300], size: 18),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    GestureDetector(
                      onTap: _addMaterial,
                      child: Padding(
                        padding: EdgeInsets.only(top: 6),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add_circle_outline,
                                size: 16, color: Colors.green[700]),
                            SizedBox(width: 6),
                            Text('Add material',
                                style: GoogleFonts.montserrat(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.green[700])),
                          ],
                        ),
                      ),
                    ),
                  ],

                  // === INLINE DISPOSAL ===
                  _toggleRow(
                    'Disposal run',
                    Icons.local_shipping_outlined,
                    _hasDisposal,
                    (v) => setState(() => _hasDisposal = v ?? false),
                  ),
                  if (_hasDisposal)
                    Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: _disposalLocationController,
                              style: GoogleFonts.montserrat(fontSize: 12),
                              decoration: InputDecoration(
                                hintText: 'Location',
                                hintStyle: GoogleFonts.montserrat(
                                    fontSize: 12, color: Colors.grey[400]),
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 8),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _disposalCostController,
                              style: GoogleFonts.montserrat(fontSize: 12),
                              keyboardType: TextInputType.numberWithOptions(
                                  decimal: true),
                              decoration: InputDecoration(
                                hintText: '\$ Cost',
                                hintStyle: GoogleFonts.montserrat(
                                    fontSize: 12, color: Colors.grey[400]),
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 8),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  SizedBox(height: 16),

                  // === PHOTOS (optional) ===
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.camera_alt,
                                size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 6),
                            Text(
                              'Site Photos',
                              style: GoogleFonts.montserrat(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '(optional)',
                              style: GoogleFonts.montserrat(
                                fontSize: 11,
                                color: Colors.grey[400],
                              ),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: _showPhotoSourceSheet,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: const Color.fromARGB(255, 59, 82, 73),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.add,
                                        size: 14, color: Colors.white),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Add',
                                      style: GoogleFonts.montserrat(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_pickedPhotos.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          SizedBox(
                            height: 80,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: _pickedPhotos.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 8),
                              itemBuilder: (context, index) {
                                return Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.file(
                                        _pickedPhotos[index],
                                        width: 80,
                                        height: 80,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    Positioned(
                                      top: 2,
                                      right: 2,
                                      child: GestureDetector(
                                        onTap: () => setState(() =>
                                            _pickedPhotos.removeAt(index)),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.black54,
                                            shape: BoxShape.circle,
                                          ),
                                          padding: const EdgeInsets.all(3),
                                          child: const Icon(Icons.close,
                                              size: 12, color: Colors.white),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                          Text(
                            '${_pickedPhotos.length} photo${_pickedPhotos.length == 1 ? '' : 's'} will upload with report',
                            style: GoogleFonts.montserrat(
                              fontSize: 10,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
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
                  icon: Icon(_showNextButton ? Icons.arrow_forward : Icons.send,
                      size: 16),
                  label: Text(
                    _showNextButton ? 'Next' : 'Submit Report',
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
