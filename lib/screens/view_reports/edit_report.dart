import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:gemini_landscaping_app/models/site_report.dart';

class EditReport extends StatefulWidget {
  final SiteReport report;
  EditReport({required this.report});

  @override
  _EditReportState createState() => _EditReportState();
}

class _EditReportState extends State<EditReport> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _dateController;
  late TextEditingController _descriptionController;
  late bool _isRegularMaintenance;
  late List<Map<String, TextEditingController>> _employeeTimes;
  late List<Map<String, TextEditingController>> _materials;
  late String serviceType;
  late bool _hasDisposal;
  late TextEditingController _disposalLocationController;
  late TextEditingController _disposalCostController;
  late List<String> _selectedNoteTags;
  late bool _hasBothPhases;
  late List<Map<String, TextEditingController>> _regularEmployeeTimes;
  late List<Map<String, TextEditingController>> _additionalEmployeeTimes;

  List<Map<String, TextEditingController>> _employeesFromPhase(
      ReportPhase phase) {
    return phase.employees
        .map((employee) => {
              'nameController': TextEditingController(text: employee.name),
              'timeOnController': TextEditingController(
                  text: DateFormat('h:mm a').format(employee.timeOn)),
              'timeOffController': TextEditingController(
                  text: DateFormat('h:mm a').format(employee.timeOff)),
            })
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _dateController = TextEditingController(text: widget.report.date);
    _descriptionController =
        TextEditingController(text: widget.report.description);
    _isRegularMaintenance = widget.report.isRegularMaintenance;
    serviceType =
        _isRegularMaintenance ? 'Regular Maintenance' : 'Additional Service';
    _hasBothPhases = widget.report.hasBothPhases;
    if (_hasBothPhases) {
      _regularEmployeeTimes =
          _employeesFromPhase(widget.report.regularPhase!);
      _additionalEmployeeTimes =
          _employeesFromPhase(widget.report.additionalPhase!);
      _employeeTimes = [];
    } else {
      _regularEmployeeTimes = [];
      _additionalEmployeeTimes = [];
      _employeeTimes = widget.report.employees
          .map((employee) => {
                'nameController': TextEditingController(text: employee.name),
                'timeOnController': TextEditingController(
                    text: DateFormat('h:mm a').format(employee.timeOn)),
                'timeOffController': TextEditingController(
                    text: DateFormat('h:mm a').format(employee.timeOff)),
              })
          .toList();
    }
    _materials = widget.report.materials
        .map((material) => {
              'vendorController': TextEditingController(text: material.vendor),
              'materialController':
                  TextEditingController(text: material.description),
              'costController': TextEditingController(text: material.cost),
            })
        .toList();
    _hasDisposal = widget.report.disposal?.hasDisposal ?? false;
    _disposalLocationController =
        TextEditingController(text: widget.report.disposal?.location ?? '');
    _disposalCostController =
        TextEditingController(text: widget.report.disposal?.cost ?? '');
    _selectedNoteTags = List<String>.from(widget.report.noteTags);
  }

  Map<String, dynamic> _processEmployeeTimes(
      List<Map<String, TextEditingController>> employees,
      DateTime reportDate) {
    Map<String, dynamic> employeeTimesMap = {};
    int totalMinutes = 0;
    for (var employee in employees) {
      String name = employee['nameController']!.text;
      if (name.isEmpty) continue;
      TimeOfDay timeOn = _parseTimeOfDay(employee['timeOnController']!.text);
      TimeOfDay timeOff = _parseTimeOfDay(employee['timeOffController']!.text);
      Duration duration = _calculateDuration(timeOn, timeOff);
      Timestamp timeOnTs = _convertTimeOfDayToTimestamp(timeOn, reportDate);
      Timestamp timeOffTs = _convertTimeOfDayToTimestamp(timeOff, reportDate);
      totalMinutes += duration.inMinutes;
      employeeTimesMap[name] = {
        'timeOn': timeOnTs,
        'timeOff': timeOffTs,
        'duration': duration.inMinutes,
      };
    }
    return {'employeeTimesMap': employeeTimesMap, 'totalMinutes': totalMinutes};
  }

  void _updateReport() async {
    if (_formKey.currentState!.validate()) {
      DateTime reportDate =
          DateFormat('MMMM d, yyyy').parse(_dateController.text);

      final materialsData = _materials.map((material) {
        return {
          "vendor": material['vendorController']!.text,
          "description": material['materialController']!.text,
          "cost": material['costController']!.text,
        };
      }).toList();

      final sharedFields = {
        "timestamp": DateTime.now(),
        "siteInfo": {
          'date': _dateController.text,
          'siteName': widget.report.siteName,
          'address': widget.report.address,
        },
        "services": widget.report.services,
        "materials": materialsData,
        "description": _descriptionController.text,
        "disposal": {
          "hasDisposal": _hasDisposal,
          "location": _disposalLocationController.text,
          "cost": _disposalCostController.text,
        },
        "noteTags": _selectedNoteTags,
        "submittedBy": widget.report.submittedBy,
        "filed": widget.report.filed,
      };

      try {
        if (_hasBothPhases) {
          final regData =
              _processEmployeeTimes(_regularEmployeeTimes, reportDate);
          final addData =
              _processEmployeeTimes(_additionalEmployeeTimes, reportDate);
          final allEmployees = <String, dynamic>{
            ...(regData['employeeTimesMap'] as Map<String, dynamic>),
            ...(addData['employeeTimesMap'] as Map<String, dynamic>),
          };
          final totalMinutes =
              (regData['totalMinutes'] as int) +
              (addData['totalMinutes'] as int);

          await FirebaseFirestore.instance
              .collection('SiteReports')
              .doc(widget.report.id)
              .update({
            ...sharedFields,
            "version": 2,
            "isRegularMaintenance": true,
            "employeeTimes": allEmployees,
            "totalCombinedDuration": totalMinutes,
            "regularPhase": {
              "isRegularMaintenance": true,
              "employeeTimes": regData['employeeTimesMap'],
              "totalCombinedDuration": regData['totalMinutes'],
              "services": widget.report.regularPhase!.services,
            },
            "additionalPhase": {
              "isRegularMaintenance": false,
              "employeeTimes": addData['employeeTimesMap'],
              "totalCombinedDuration": addData['totalMinutes'],
              "services": widget.report.additionalPhase!.services,
            },
          });
        } else {
          final empData = _processEmployeeTimes(_employeeTimes, reportDate);
          await FirebaseFirestore.instance
              .collection('SiteReports')
              .doc(widget.report.id)
              .update({
            ...sharedFields,
            "isRegularMaintenance": _isRegularMaintenance,
            "employeeTimes": empData['employeeTimesMap'],
            "totalCombinedDuration": empData['totalMinutes'],
          });
        }

        Navigator.pop(context);
        Navigator.pop(context);
      } catch (e) {
        print('Error updating report: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update report. Please try again.'),
          ),
        );
      }
    }
  }

  Timestamp _convertTimeOfDayToTimestamp(TimeOfDay time, DateTime date) {
    int hour = time.hour;
    if (time.period == DayPeriod.pm && hour != 12) {
      hour = (hour % 12) + 12; // Correctly convert PM hours
    } else if (time.period == DayPeriod.am && hour == 12) {
      hour = 0; // Convert 12 AM to 00 hours
    }

    final DateTime dateTime = DateTime(
      date.year,
      date.month,
      date.day,
      hour,
      time.minute,
    );

    return Timestamp.fromDate(dateTime);
  }

  Duration _calculateDuration(TimeOfDay startTime, TimeOfDay endTime) {
    // Get the date from _dateController
    DateTime reportDate =
        DateFormat('MMMM d, yyyy').parse(_dateController.text);

    // Create DateTime instances for start and end times on the selected report date
    final DateTime startDateTime = DateTime(
      reportDate.year,
      reportDate.month,
      reportDate.day,
      startTime.hour,
      startTime.minute,
    );

    DateTime endDateTime = DateTime(
      reportDate.year,
      reportDate.month,
      reportDate.day,
      endTime.hour,
      endTime.minute,
    );

    // Ensure end time is after start time to prevent negative duration
    if (endDateTime.isBefore(startDateTime)) {
      endDateTime = endDateTime
          .add(Duration(days: 1)); // Add a day if end is before start
    }

    return endDateTime.difference(startDateTime);
  }

  // Helper function to parse TimeOfDay correctly with AM/PM
  TimeOfDay _parseTimeOfDay(String timeString) {
    if (timeString.isEmpty) {
      throw FormatException("Time string is empty");
    }

    try {
      List<String> parts = timeString.split(" ");
      if (parts.length != 2) {
        throw FormatException("Invalid format");
      }

      String timePart = parts[0];
      String periodPart = parts[1].toUpperCase();

      List<String> timeComponents = timePart.split(":");
      if (timeComponents.length != 2) {
        throw FormatException("Invalid format");
      }

      int hour = int.parse(timeComponents[0]);
      int minute = int.parse(timeComponents[1]);

      if (hour < 1 || hour > 12 || minute < 0 || minute > 59) {
        throw FormatException("Invalid time value");
      }

      bool isPM = periodPart == "PM";
      if (isPM && hour < 12) hour += 12; // Convert PM hour to 24-hour format
      if (!isPM && hour == 12) hour = 0; // Handle midnight case

      return TimeOfDay(hour: hour, minute: minute);
    } catch (e) {
      throw FormatException("Invalid time format: $timeString");
    }
  }

  @override
  void dispose() {
    _dateController.dispose();
    _descriptionController.dispose();
    _disposalLocationController.dispose();
    _disposalCostController.dispose();
    for (var list in [_employeeTimes, _regularEmployeeTimes, _additionalEmployeeTimes]) {
      for (var employee in list) {
        employee['nameController']!.dispose();
        employee['timeOnController']!.dispose();
        employee['timeOffController']!.dispose();
      }
    }
    _materials.forEach((material) {
      material['vendorController']!.dispose();
      material['materialController']!.dispose();
      material['costController']!.dispose();
    });
    super.dispose();
  }

  List<Widget> _buildEmployeeSection(
      String title,
      List<Map<String, TextEditingController>> employees,
      VoidCallback addEmployee) {
    return [
      Text(title, style: TextStyle(fontSize: 18)),
      SizedBox(height: 8),
      ...employees.asMap().entries.map((entry) {
        int index = entry.key;
        Map<String, TextEditingController> employee = entry.value;
        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 150,
                  padding: EdgeInsets.only(right: 10),
                  child: TextFormField(
                    controller: employee['nameController'],
                    decoration: InputDecoration(
                      labelText: 'Employee Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter an employee name';
                      }
                      return null;
                    },
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: 'Time On',
                            border: OutlineInputBorder(),
                          ),
                          controller: employee['timeOnController'],
                          onTap: () async {
                            TimeOfDay? pickedTime = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.now(),
                            );
                            if (pickedTime != null) {
                              setState(() {
                                employee['timeOnController']!.text =
                                    pickedTime.format(context);
                              });
                            }
                          },
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: 'Time Off',
                            border: OutlineInputBorder(),
                          ),
                          controller: employee['timeOffController'],
                          onTap: () async {
                            TimeOfDay? pickedTime = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.now(),
                            );
                            if (pickedTime != null) {
                              setState(() {
                                employee['timeOffController']!.text =
                                    pickedTime.format(context);
                              });
                            }
                          },
                        ),
                      ),
                      Container(
                        width: 40,
                        child: MaterialButton(
                          onPressed: () {
                            setState(() {
                              employees.removeAt(index);
                            });
                          },
                          child: Icon(Icons.delete),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 4),
          ],
        );
      }).toList(),
      MaterialButton(
        color: const Color.fromARGB(255, 59, 82, 73),
        onPressed: addEmployee,
        child: Text('Add Employee', style: TextStyle(color: Colors.white)),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 31, 182, 77),
        leading: MaterialButton(
          onPressed: () {
            Navigator.pop(context);
          },
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
          TextButton(
            onPressed: _updateReport,
            child: Text(
              'Save',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_hasBothPhases)
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    child: Text('Regular + Additional',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                  )
                else
                  SwitchListTile(
                    title: Text(serviceType),
                    value: _isRegularMaintenance,
                    activeColor: Colors.green,
                    inactiveThumbColor: const Color.fromARGB(255, 59, 82, 73),
                    onChanged: (bool value) {
                      setState(() {
                        _isRegularMaintenance = value;
                        serviceType = value
                            ? 'Regular Maintenance'
                            : 'Additional Service';
                      });
                    },
                  ),
                SizedBox(height: 4),
                Center(
                    child: Text(widget.report.siteName,
                        style: TextStyle(fontSize: 18))),
                SizedBox(height: 8),
                TextFormField(
                  controller: _dateController,
                  decoration: InputDecoration(
                    labelText: 'Date',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a date';
                    }
                    return null;
                  },
                  onTap: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2101),
                    );
                    if (pickedDate != null) {
                      String formattedDate =
                          DateFormat('MMMM d, yyyy').format(pickedDate);
                      setState(() {
                        _dateController.text = formattedDate;
                      });
                    }
                  },
                ),
                SizedBox(height: 10),
                Divider(),
                if (_hasBothPhases) ...[
                  ..._buildEmployeeSection(
                    'Regular Maintenance — Employees',
                    _regularEmployeeTimes,
                    () => setState(() => _regularEmployeeTimes.add({
                          'nameController': TextEditingController(),
                          'timeOnController': TextEditingController(),
                          'timeOffController': TextEditingController(),
                        })),
                  ),
                  SizedBox(height: 10),
                  Divider(),
                  ..._buildEmployeeSection(
                    'Additional Services — Employees',
                    _additionalEmployeeTimes,
                    () => setState(() => _additionalEmployeeTimes.add({
                          'nameController': TextEditingController(),
                          'timeOnController': TextEditingController(),
                          'timeOffController': TextEditingController(),
                        })),
                  ),
                ] else ...[
                  ..._buildEmployeeSection(
                    'Employee Times',
                    _employeeTimes,
                    () => setState(() => _employeeTimes.add({
                          'nameController': TextEditingController(),
                          'timeOnController': TextEditingController(),
                          'timeOffController': TextEditingController(),
                        })),
                  ),
                ],
                SizedBox(height: 10),
                Divider(),
                Text('Materials', style: TextStyle(fontSize: 18)),
                SizedBox(height: 8),
                ..._materials.asMap().entries.map((entry) {
                  int index = entry.key;
                  Map<String, TextEditingController> material = entry.value;
                  return Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: material['vendorController'],
                              decoration: InputDecoration(
                                labelText: 'Vendor',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          SizedBox(width: 4),
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: material['materialController'],
                              decoration: InputDecoration(
                                labelText: 'Material Description',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          SizedBox(width: 4),
                          Expanded(
                            flex: 1,
                            child: TextFormField(
                              keyboardType: TextInputType.number,
                              controller: material['costController'],
                              decoration: InputDecoration(
                                labelText: 'Cost',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          Container(
                            width: 40,
                            child: MaterialButton(
                              onPressed: () {
                                setState(() {
                                  _materials.removeAt(index);
                                });
                              },
                              child: Icon(Icons.delete),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                    ],
                  );
                }).toList(),
                MaterialButton(
                  color: const Color.fromARGB(255, 59, 82, 73),
                  onPressed: () {
                    setState(() {
                      _materials.add({
                        'vendorController': TextEditingController(),
                        'materialController': TextEditingController(),
                        'costController': TextEditingController(),
                      });
                    });
                  },
                  child: Text(
                    'Add Material',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                SizedBox(height: 10),
                Divider(),
                Text('Disposal', style: TextStyle(fontSize: 18)),
                SizedBox(height: 8),
                SwitchListTile(
                  title: Text('Disposal Run'),
                  subtitle: Text('Did you do a dump run?'),
                  value: _hasDisposal,
                  thumbColor: WidgetStateProperty.resolveWith((states) =>
                      states.contains(WidgetState.selected)
                          ? Colors.green
                          : null),
                  trackColor: WidgetStateProperty.resolveWith((states) =>
                      states.contains(WidgetState.selected)
                          ? Colors.green[200]
                          : null),
                  contentPadding: EdgeInsets.zero,
                  onChanged: (v) => setState(() => _hasDisposal = v),
                ),
                if (_hasDisposal) ...[
                  SizedBox(height: 8),
                  TextFormField(
                    controller: _disposalLocationController,
                    decoration: InputDecoration(
                      labelText: 'Dump Location',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 8),
                  TextFormField(
                    controller: _disposalCostController,
                    keyboardType:
                        TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Disposal Cost (\$)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
                SizedBox(height: 10),
                Divider(),
                Text('Shift Notes', style: TextStyle(fontSize: 18)),
                SizedBox(height: 8),
                Text('Quick Tags:', style: TextStyle(fontSize: 14)),
                SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    'Focused on specific area',
                    'Ran out of time',
                    'Resident feedback',
                    'Equipment issue',
                    'Extra work needed next visit',
                    'Weather delay',
                    'Irrigation issue',
                  ].map((tag) {
                    final isSelected = _selectedNoteTags.contains(tag);
                    return FilterChip(
                      label: Text(tag, style: TextStyle(fontSize: 11)),
                      selected: isSelected,
                      selectedColor: Colors.green[200],
                      checkmarkColor: Colors.green[800],
                      backgroundColor: Colors.grey[100],
                      onSelected: (selected) {
                        setState(() {
                          selected
                              ? _selectedNoteTags.add(tag)
                              : _selectedNoteTags.remove(tag);
                        });
                      },
                      padding:
                          EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    );
                  }).toList(),
                ),
                SizedBox(height: 8),
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Additional Notes',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: null,
                ),
                SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
