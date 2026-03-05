import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gemini_landscaping_app/screens/add_report/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Page 2: Additional Services — per-employee time entry with +/- 30m steppers.
/// Default start = site start time from regular maintenance.
/// Quick duration chips let employees fast-set end times.
class AdditionalServicesPage extends StatefulWidget {
  final String date;
  final String siteName;
  final Map<String, List<String>> selectedExtras;
  final List<String> employeeNames;
  final TimeOfDay siteStartTime;
  final bool extrasOnly;

  const AdditionalServicesPage({
    super.key,
    required this.date,
    required this.siteName,
    required this.selectedExtras,
    required this.employeeNames,
    required this.siteStartTime,
    this.extrasOnly = false,
  });

  @override
  State<AdditionalServicesPage> createState() =>
      _AdditionalServicesPageState();
}

class _AdditionalServicesPageState extends State<AdditionalServicesPage> {
  // Per-service → list of employee entries {name, timeOn, timeOff}
  final Map<String, List<Map<String, dynamic>>> _serviceEmployees = {};

  // Per-service details
  final Map<String, TextEditingController> _serviceNotesControllers = {};
  final Map<String, bool> _serviceHasNotes = {};
  final Map<String, List<Map<String, dynamic>>> _serviceMaterialsList = {};
  final Map<String, bool> _serviceHasMaterials = {};
  final Map<String, bool> _serviceHasDisposal = {};
  final Map<String, TextEditingController>
      _serviceDisposalLocationControllers = {};
  final Map<String, TextEditingController> _serviceDisposalCostControllers =
      {};
  final Map<String, bool> _serviceDetailsExpanded = {};

  late final List<String> _allExtras;

  @override
  void initState() {
    super.initState();

    final defaultStart = widget.siteStartTime;
    final defaultEnd = _addMinutes(defaultStart, 60);

    _allExtras = [];
    for (var entry in widget.selectedExtras.entries) {
      for (var service in entry.value) {
        _allExtras.add(service);

        // Each employee gets their own time row, defaulting to site start + 1h
        _serviceEmployees[service] = widget.employeeNames
            .map((name) => {
                  'name': name,
                  'timeOn': defaultStart,
                  'timeOff': defaultEnd,
                })
            .toList();

        _serviceNotesControllers[service] = TextEditingController();
        _serviceHasNotes[service] = false;
        _serviceMaterialsList[service] = [];
        _serviceHasMaterials[service] = false;
        _serviceHasDisposal[service] = false;
        _serviceDisposalLocationControllers[service] = TextEditingController();
        _serviceDisposalCostControllers[service] = TextEditingController();
        _serviceDetailsExpanded[service] = false;
      }
    }
  }

  @override
  void dispose() {
    for (var service in _allExtras) {
      _serviceNotesControllers[service]?.dispose();
      _serviceDisposalLocationControllers[service]?.dispose();
      _serviceDisposalCostControllers[service]?.dispose();
      for (var m in _serviceMaterialsList[service] ?? []) {
        (m['vendorController'] as TextEditingController).dispose();
        (m['materialController'] as TextEditingController).dispose();
        (m['costController'] as TextEditingController).dispose();
      }
    }
    super.dispose();
  }

  TimeOfDay _addMinutes(TimeOfDay t, int minutes) {
    final total = t.hour * 60 + t.minute + minutes;
    return TimeOfDay(hour: (total ~/ 60) % 24, minute: total % 60);
  }

  String _formatTime(TimeOfDay t) =>
      '${t.hour}:${t.minute.toString().padLeft(2, '0')}';

  void _removeEmployee(String service, int index) {
    setState(() => _serviceEmployees[service]!.removeAt(index));
  }

  // --- Tap grid time picker with optional exact (Cupertino) mode ---
  void _pickTime(String service, int empIndex, bool isStart) {
    final current = isStart
        ? _serviceEmployees[service]![empIndex]['timeOn'] as TimeOfDay
        : _serviceEmployees[service]![empIndex]['timeOff'] as TimeOfDay;

    // Generate 30-min slots from 6:00 to 19:30
    final slots = <TimeOfDay>[];
    for (var h = 6; h <= 19; h++) {
      slots.add(TimeOfDay(hour: h, minute: 0));
      slots.add(TimeOfDay(hour: h, minute: 30));
    }

    var pickerTime = DateTime(2000, 1, 1, current.hour, current.minute);

    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (sheetContext) {
        var showExact = false;
        return StatefulBuilder(
          builder: (_, setSheetState) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    children: [
                      Text(
                        isStart ? 'Start Time' : 'End Time',
                        style: GoogleFonts.montserrat(
                            fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      Spacer(),
                      if (showExact)
                        GestureDetector(
                          onTap: () {
                            final picked = TimeOfDay(
                                hour: pickerTime.hour,
                                minute: pickerTime.minute);
                            setState(() {
                              final key = isStart ? 'timeOn' : 'timeOff';
                              _serviceEmployees[service]![empIndex][key] =
                                  picked;
                            });
                            Navigator.pop(sheetContext);
                          },
                          child: Text('Done',
                              style: GoogleFonts.montserrat(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.amber[700])),
                        )
                      else
                        GestureDetector(
                          onTap: () =>
                              setSheetState(() => showExact = true),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.tune,
                                  size: 14, color: Colors.grey[500]),
                              SizedBox(width: 4),
                              Text('Exact',
                                  style: GoogleFonts.montserrat(
                                      fontSize: 12,
                                      color: Colors.grey[500])),
                            ],
                          ),
                        ),
                      SizedBox(width: 12),
                      GestureDetector(
                        onTap: () => Navigator.pop(sheetContext),
                        child: Icon(Icons.close,
                            size: 20, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1),
                if (showExact)
                  SizedBox(
                    height: 200,
                    child: CupertinoDatePicker(
                      mode: CupertinoDatePickerMode.time,
                      use24hFormat: true,
                      initialDateTime: pickerTime,
                      onDateTimeChanged: (dt) => pickerTime = dt,
                    ),
                  )
                else
                  Padding(
                    padding: EdgeInsets.all(12),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      gridDelegate:
                          SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        childAspectRatio: 2.5,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: slots.length,
                      itemBuilder: (_, i) {
                        final slot = slots[i];
                        final isSelected = slot.hour == current.hour &&
                            slot.minute == current.minute;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              final key = isStart ? 'timeOn' : 'timeOff';
                              _serviceEmployees[service]![empIndex][key] =
                                  slot;
                            });
                            Navigator.pop(sheetContext);
                          },
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.amber[600]
                                  : Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.amber[600]!
                                    : Colors.grey[300]!,
                              ),
                            ),
                            child: Text(
                              _formatTime(slot),
                              style: GoogleFonts.montserrat(
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isSelected
                                    ? Colors.white
                                    : Colors.black87,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _addMaterial(String service) {
    setState(() {
      _serviceMaterialsList[service]!.add({
        'vendorController': TextEditingController(),
        'materialController': TextEditingController(),
        'costController': TextEditingController(),
      });
    });
  }

  void _deleteMaterial(String service, int index) {
    setState(() {
      final m = _serviceMaterialsList[service]!.removeAt(index);
      (m['vendorController'] as TextEditingController).dispose();
      (m['materialController'] as TextEditingController).dispose();
      (m['costController'] as TextEditingController).dispose();
    });
  }

  void _submit() {
    final serviceEmps = <String, List<Map<String, dynamic>>>{};
    for (var service in _allExtras) {
      serviceEmps[service] = _serviceEmployees[service]!
          .map((emp) => {
                'name': emp['name'],
                'timeOn': emp['timeOn'],
                'timeOff': emp['timeOff'],
              })
          .toList();
    }

    final serviceNotes = <String, String>{};
    for (var service in _allExtras) {
      final text = _serviceNotesControllers[service]?.text ?? '';
      if (text.isNotEmpty) serviceNotes[service] = text;
    }

    final serviceMaterials = <String, List<Map<String, dynamic>>>{};
    for (var service in _allExtras) {
      if (_serviceHasMaterials[service] == true) {
        final mats = _serviceMaterialsList[service] ?? [];
        final matData = mats
            .map((m) => {
                  'vendor':
                      (m['vendorController'] as TextEditingController).text,
                  'description':
                      (m['materialController'] as TextEditingController).text,
                  'cost':
                      (m['costController'] as TextEditingController).text,
                })
            .where((m) =>
                m['description']!.isNotEmpty || m['vendor']!.isNotEmpty)
            .toList();
        if (matData.isNotEmpty) serviceMaterials[service] = matData;
      }
    }

    final serviceDisposal = <String, Map<String, dynamic>>{};
    for (var service in _allExtras) {
      if (_serviceHasDisposal[service] == true) {
        serviceDisposal[service] = {
          'hasDisposal': true,
          'location':
              _serviceDisposalLocationControllers[service]?.text ?? '',
          'cost': _serviceDisposalCostControllers[service]?.text ?? '',
        };
      }
    }

    Navigator.pop(context, <String, dynamic>{
      'serviceEmployees': serviceEmps,
      'serviceNotes': serviceNotes,
      'serviceMaterials': serviceMaterials,
      'serviceDisposal': serviceDisposal,
    });
  }

  @override
  Widget build(BuildContext context) {
    const accentColor = Color.fromARGB(255, 97, 125, 140);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: accentColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Additional Services',
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
                  Row(
                    children: [
                      _infoPill(Icons.calendar_today, widget.date),
                      SizedBox(width: 8),
                      Expanded(
                          child:
                              _infoPill(Icons.location_on, widget.siteName)),
                    ],
                  ),
                  SizedBox(height: 4),

                  // === PER-SERVICE CARDS ===
                  ..._allExtras
                      .map((s) => _buildServiceCard(s, accentColor)),

                  SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // === SUBMIT ===
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton.icon(
                  icon: Icon(Icons.send, size: 16),
                  label: Text(
                    widget.extrasOnly
                        ? 'Submit Report'
                        : 'Submit Both Reports',
                    style: GoogleFonts.montserrat(
                        fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _submit,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoPill(IconData icon, String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey[600]),
          SizedBox(width: 4),
          Flexible(
            child: Text(text,
                style: GoogleFonts.montserrat(
                    fontSize: 11, color: Colors.grey[700]),
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(String service, Color accentColor) {
    final emps = _serviceEmployees[service] ?? [];
    final isExpanded = _serviceDetailsExpanded[service] ?? false;
    final hasNotes = _serviceHasNotes[service] ?? false;
    final hasMats = _serviceHasMaterials[service] ?? false;
    final hasDisp = _serviceHasDisposal[service] ?? false;
    final hasAnyDetail = hasNotes || hasMats || hasDisp;

    return Container(
      margin: EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Amber left accent bar
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: Colors.amber[600],
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(10),
                  bottomLeft: Radius.circular(10),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- Header: service name ---
                    Text(
                      service.toUpperCase(),
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.amber[900],
                      ),
                    ),
                    SizedBox(height: 6),

                    // --- Per-employee time rows ---
                    ...emps.asMap().entries.map((entry) {
                      final i = entry.key;
                      final emp = entry.value;
                      final name = emp['name'] as String;
                      final tOn = emp['timeOn'] as TimeOfDay;
                      final tOff = emp['timeOff'] as TimeOfDay;

                      return Container(
                        margin: EdgeInsets.only(bottom: 4),
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Row(
                          children: [
                            // Employee name
                            Expanded(
                              child: Text(
                                name,
                                style: GoogleFonts.montserrat(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // Time on — tap to open grid
                            GestureDetector(
                              onTap: () => _pickTime(service, i, true),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.blueGrey[50],
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                      color: Colors.blueGrey[200]!),
                                ),
                                child: Text(
                                  _formatTime(tOn),
                                  style: GoogleFonts.montserrat(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.blueGrey[800]),
                                ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 3),
                              child: Icon(Icons.arrow_forward,
                                  size: 10, color: Colors.grey[400]),
                            ),
                            // Time off — tap to open grid
                            GestureDetector(
                              onTap: () => _pickTime(service, i, false),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.blueGrey[50],
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                      color: Colors.blueGrey[200]!),
                                ),
                                child: Text(
                                  _formatTime(tOff),
                                  style: GoogleFonts.montserrat(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.blueGrey[800]),
                                ),
                              ),
                            ),
                            // Remove employee
                            SizedBox(width: 4),
                            GestureDetector(
                              onTap: () => _removeEmployee(service, i),
                              child: Padding(
                                padding: EdgeInsets.all(2),
                                child: Icon(Icons.close,
                                    size: 16, color: Colors.grey[400]),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),

                    // Empty state
                    if (emps.isEmpty)
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'No employees assigned',
                          style: GoogleFonts.montserrat(
                              fontSize: 11,
                              color: Colors.grey[400],
                              fontStyle: FontStyle.italic),
                        ),
                      ),

                    // --- Details toggle ---
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => setState(() =>
                          _serviceDetailsExpanded[service] = !isExpanded),
                      child: Padding(
                        padding: EdgeInsets.only(top: 6, bottom: 4),
                        child: Row(
                          children: [
                            Icon(
                              isExpanded
                                  ? Icons.expand_less
                                  : Icons.expand_more,
                              size: 16,
                              color: accentColor,
                            ),
                            SizedBox(width: 4),
                            Text(
                              hasAnyDetail && !isExpanded
                                  ? 'DETAILS (${_detailCount(service)})'
                                  : 'DETAILS',
                              style: GoogleFonts.montserrat(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: accentColor,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // --- Expanded detail content ---
                    if (isExpanded) ...[
                      _detailToggle(
                        'Notes',
                        Icons.edit_note,
                        hasNotes,
                        (v) => setState(
                            () => _serviceHasNotes[service] = v ?? false),
                      ),
                      if (hasNotes)
                        Container(
                          margin: EdgeInsets.only(top: 4, bottom: 4),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          height: 60,
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10),
                            child: TextField(
                              controller:
                                  _serviceNotesControllers[service],
                              maxLines: null,
                              style: GoogleFonts.montserrat(fontSize: 12),
                              keyboardType: TextInputType.multiline,
                              decoration: InputDecoration(
                                hintText: 'Notes for $service...',
                                hintStyle: GoogleFonts.montserrat(
                                    fontSize: 12,
                                    color: Colors.grey[400]),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                        ),

                      _detailToggle(
                        'Materials',
                        Icons.inventory_2_outlined,
                        hasMats,
                        (v) {
                          setState(() {
                            _serviceHasMaterials[service] = v ?? false;
                            if (v == true &&
                                _serviceMaterialsList[service]!.isEmpty) {
                              _addMaterial(service);
                            }
                          });
                        },
                      ),
                      if (hasMats) ...[
                        ...(_serviceMaterialsList[service] ?? [])
                            .asMap()
                            .entries
                            .map((entry) {
                          final index = entry.key;
                          final material = entry.value;
                          return Padding(
                            padding: EdgeInsets.only(bottom: 4),
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
                                GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () =>
                                      _deleteMaterial(service, index),
                                  child: Padding(
                                    padding: EdgeInsets.all(4),
                                    child: Icon(Icons.close,
                                        color: Colors.grey[400],
                                        size: 16),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                        GestureDetector(
                          onTap: () => _addMaterial(service),
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add_circle_outline,
                                    size: 14, color: accentColor),
                                SizedBox(width: 4),
                                Text('Add material',
                                    style: GoogleFonts.montserrat(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: accentColor)),
                              ],
                            ),
                          ),
                        ),
                      ],

                      _detailToggle(
                        'Disposal',
                        Icons.local_shipping_outlined,
                        hasDisp,
                        (v) => setState(() =>
                            _serviceHasDisposal[service] = v ?? false),
                      ),
                      if (hasDisp)
                        Padding(
                          padding: EdgeInsets.only(top: 4, bottom: 4),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: TextField(
                                  controller:
                                      _serviceDisposalLocationControllers[
                                          service],
                                  style:
                                      GoogleFonts.montserrat(fontSize: 12),
                                  decoration: InputDecoration(
                                    hintText: 'Location',
                                    hintStyle: GoogleFonts.montserrat(
                                        fontSize: 12,
                                        color: Colors.grey[400]),
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 8),
                                    border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(8)),
                                  ),
                                ),
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller:
                                      _serviceDisposalCostControllers[
                                          service],
                                  style:
                                      GoogleFonts.montserrat(fontSize: 12),
                                  keyboardType:
                                      TextInputType.numberWithOptions(
                                          decimal: true),
                                  decoration: InputDecoration(
                                    hintText: '\$ Cost',
                                    hintStyle: GoogleFonts.montserrat(
                                        fontSize: 12,
                                        color: Colors.grey[400]),
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 8),
                                    border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(8)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _detailCount(String service) {
    int count = 0;
    if (_serviceHasNotes[service] == true) count++;
    if (_serviceHasMaterials[service] == true) count++;
    if (_serviceHasDisposal[service] == true) count++;
    return count;
  }

  Widget _detailToggle(String label, IconData icon, bool value,
      ValueChanged<bool?> onChanged) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
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
                activeColor: Color.fromARGB(255, 97, 125, 140),
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
}
