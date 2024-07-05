import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
  late List<Map<String, dynamic>> _employeeTimes;
  late List<Map<String, dynamic>> _materials;

  @override
  void initState() {
    super.initState();
    _dateController = TextEditingController(text: widget.report.date);
    _descriptionController =
        TextEditingController(text: widget.report.description);
    _isRegularMaintenance = widget.report.isRegularMaintenance;
    _employeeTimes = widget.report.employees
        .map((employee) => {
              'nameController': TextEditingController(text: employee.name),
              'timeOn': TimeOfDay.fromDateTime(employee.timeOn),
              'timeOff': TimeOfDay.fromDateTime(employee.timeOff),
            })
        .toList();
    _materials = widget.report.materials
        .map((material) => {
              'vendorController': TextEditingController(text: material.vendor),
              'materialController':
                  TextEditingController(text: material.description),
              'costController': TextEditingController(text: material.cost),
            })
        .toList();
  }

  void _updateReport() async {
    if (_formKey.currentState!.validate()) {
      Map<String, dynamic> employeeTimesMap = {};
      Duration totalCombinedDuration = Duration();

      for (var employee in _employeeTimes) {
        String name = employee['nameController'].text;
        TimeOfDay? timeOn = employee['timeOn'];
        TimeOfDay? timeOff = employee['timeOff'];

        if (name.isNotEmpty && timeOn != null && timeOff != null) {
          Duration duration = _calculateDuration(timeOn, timeOff);
          totalCombinedDuration += duration;

          employeeTimesMap[name] = {
            'timeOn': _convertTimeOfDayToTimestamp(timeOn),
            'timeOff': _convertTimeOfDayToTimestamp(timeOff),
            'duration': duration.inMinutes,
          };
        }
      }

      try {
        await FirebaseFirestore.instance
            .collection('SiteReports')
            .doc(widget.report.id)
            .update({
          "timestamp": DateTime.now(),
          "isRegularMaintenance": _isRegularMaintenance,
          "employeeTimes": employeeTimesMap,
          "totalCombinedDuration": totalCombinedDuration.inMinutes,
          "siteInfo": {
            'date': _dateController.text,
            'siteName': widget.report.siteName,
            'address': widget.report.address,
          },
          "services": widget.report.services,
          "materials": _materials.map((material) {
            return {
              "vendor": material['vendorController'].text,
              "description": material['materialController'].text,
              "cost": material['costController'].text,
            };
          }).toList(),
          "description": _descriptionController.text,
          "submittedBy": widget.report.submittedBy,
          "filed": widget.report.filed,
        });

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

  Timestamp _convertTimeOfDayToTimestamp(TimeOfDay time) {
    final DateTime now = DateTime.now();
    final DateTime dateTime =
        DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return Timestamp.fromDate(dateTime);
  }

  Duration _calculateDuration(TimeOfDay startTime, TimeOfDay endTime) {
    final DateTime now = DateTime.now();
    final DateTime startDateTime = DateTime(
        now.year, now.month, now.day, startTime.hour, startTime.minute);
    final DateTime endDateTime =
        DateTime(now.year, now.month, now.day, endTime.hour, endTime.minute);

    return endDateTime.difference(startDateTime);
  }

  @override
  void dispose() {
    _dateController.dispose();
    _descriptionController.dispose();
    _employeeTimes.forEach((employee) {
      employee['nameController'].dispose();
    });
    _materials.forEach((material) {
      material['vendorController'].dispose();
      material['materialController'].dispose();
      material['costController'].dispose();
    });
    super.dispose();
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
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: null,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a description';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 10),
                SwitchListTile(
                  title: Text('Regular Maintenance'),
                  value: _isRegularMaintenance,
                  onChanged: (bool value) {
                    setState(() {
                      _isRegularMaintenance = value;
                    });
                  },
                ),
                SizedBox(height: 10),
                Text('Employee Times', style: TextStyle(fontSize: 18)),
                ..._employeeTimes.asMap().entries.map((entry) {
                  int index = entry.key;
                  Map<String, dynamic> employee = entry.value;
                  return Column(
                    children: [
                      TextFormField(
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
                      SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              readOnly: true,
                              decoration: InputDecoration(
                                labelText: 'Time On',
                                border: OutlineInputBorder(),
                              ),
                              controller: TextEditingController(
                                text: employee['timeOn'].format(context),
                              ),
                              onTap: () async {
                                TimeOfDay? pickedTime = await showTimePicker(
                                  context: context,
                                  initialTime: employee['timeOn'],
                                );
                                if (pickedTime != null) {
                                  setState(() {
                                    employee['timeOn'] = pickedTime;
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
                              controller: TextEditingController(
                                text: employee['timeOff'].format(context),
                              ),
                              onTap: () async {
                                TimeOfDay? pickedTime = await showTimePicker(
                                  context: context,
                                  initialTime: employee['timeOff'],
                                );
                                if (pickedTime != null) {
                                  setState(() {
                                    employee['timeOff'] = pickedTime;
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _employeeTimes.removeAt(index);
                          });
                        },
                        child: Text('Remove Employee'),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                      ),
                      SizedBox(height: 10),
                    ],
                  );
                }).toList(),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _employeeTimes.add({
                        'nameController': TextEditingController(),
                        'timeOn': TimeOfDay.now(),
                        'timeOff': TimeOfDay.now(),
                      });
                    });
                  },
                  child: Text('Add Employee'),
                ),
                SizedBox(height: 10),
                Text('Materials', style: TextStyle(fontSize: 18)),
                ..._materials.asMap().entries.map((entry) {
                  int index = entry.key;
                  Map<String, dynamic> material = entry.value;
                  return Column(
                    children: [
                      TextFormField(
                        controller: material['vendorController'],
                        decoration: InputDecoration(
                          labelText: 'Vendor',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      SizedBox(height: 10),
                      TextFormField(
                        controller: material['materialController'],
                        decoration: InputDecoration(
                          labelText: 'Material Description',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      SizedBox(height: 10),
                      TextFormField(
                        controller: material['costController'],
                        decoration: InputDecoration(
                          labelText: 'Cost',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _materials.removeAt(index);
                          });
                        },
                        child: Text('Remove Material'),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                      ),
                      SizedBox(height: 10),
                    ],
                  );
                }).toList(),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _materials.add({
                        'vendorController': TextEditingController(),
                        'materialController': TextEditingController(),
                        'costController': TextEditingController(),
                      });
                    });
                  },
                  child: Text('Add Material'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
