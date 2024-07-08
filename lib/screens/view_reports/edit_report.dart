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
  late List<Map<String, TextEditingController>> _employeeTimes;
  late List<Map<String, TextEditingController>> _materials;
  late String serviceType;

  @override
  void initState() {
    super.initState();
    _dateController = TextEditingController(text: widget.report.date);
    _descriptionController =
        TextEditingController(text: widget.report.description);
    _isRegularMaintenance = widget.report.isRegularMaintenance;
    serviceType =
        _isRegularMaintenance ? 'Regular Maintenance' : 'Additional Service';
    _employeeTimes = widget.report.employees
        .map((employee) => {
              'nameController': TextEditingController(text: employee.name),
              'timeOnController': TextEditingController(
                  text: DateFormat('hh:mm a').format(employee.timeOn)),
              'timeOffController': TextEditingController(
                  text: DateFormat('hh:mm a').format(employee.timeOff)),
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
        String name = employee['nameController']!.text;
        TimeOfDay? timeOn = TimeOfDay(
            hour: int.parse(employee['timeOnController']!.text.split(":")[0]),
            minute: int.parse(employee['timeOnController']!
                .text
                .split(":")[1]
                .split(" ")[0]));
        TimeOfDay? timeOff = TimeOfDay(
            hour: int.parse(employee['timeOffController']!.text.split(":")[0]),
            minute: int.parse(employee['timeOffController']!
                .text
                .split(":")[1]
                .split(" ")[0]));

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
              "vendor": material['vendorController']!.text,
              "description": material['materialController']!.text,
              "cost": material['costController']!.text,
            };
          }).toList(),
          "description": _descriptionController.text,
          "submittedBy": widget.report.submittedBy,
          "filed": widget.report.filed,
        });

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
      employee['nameController']!.dispose();
      employee['timeOnController']!.dispose();
      employee['timeOffController']!.dispose();
    });
    _materials.forEach((material) {
      material['vendorController']!.dispose();
      material['materialController']!.dispose();
      material['costController']!.dispose();
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
                SwitchListTile(
                  title: Text(serviceType),
                  value: _isRegularMaintenance,
                  activeColor: Colors.green,
                  inactiveThumbColor: const Color.fromARGB(255, 59, 82, 73),
                  onChanged: (bool value) {
                    setState(() {
                      _isRegularMaintenance = value;
                      serviceType =
                          value ? 'Regular Maintenance' : 'Additional Service';
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
                Text('Employee Times', style: TextStyle(fontSize: 18)),
                SizedBox(height: 8),
                ..._employeeTimes.asMap().entries.map((entry) {
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
                                      TimeOfDay? pickedTime =
                                          await showTimePicker(
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
                                      TimeOfDay? pickedTime =
                                          await showTimePicker(
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
                                        _employeeTimes.removeAt(index);
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
                  onPressed: () {
                    setState(() {
                      _employeeTimes.add({
                        'nameController': TextEditingController(),
                        'timeOnController': TextEditingController(),
                        'timeOffController': TextEditingController(),
                      });
                    });
                  },
                  child: Text(
                    'Add Employee',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
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
                Text('Description', style: TextStyle(fontSize: 18)),
                SizedBox(height: 8),
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description',
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
