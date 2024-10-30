import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gemini_landscaping_app/models/site_info.dart';
import 'package:gemini_landscaping_app/providers/site_list_provider.dart';
import 'package:gemini_landscaping_app/screens/add_report/add_new_site.dart';
import 'package:gemini_landscaping_app/screens/add_report/date_picker.dart';
import 'package:gemini_landscaping_app/screens/add_report/employee_times.dart';
import 'package:gemini_landscaping_app/screens/add_report/material.dart';
import 'package:gemini_landscaping_app/screens/add_report/service_list.dart';
import 'package:gemini_landscaping_app/screens/add_report/service_type.dart';
import 'package:gemini_landscaping_app/screens/add_report/site_picker.dart';
import 'package:gemini_landscaping_app/screens/home/home_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class AddSiteReport extends ConsumerStatefulWidget {
  const AddSiteReport({super.key});

  @override
  _AddSiteReportState createState() => _AddSiteReportState();
}

class _AddSiteReportState extends ConsumerState<AddSiteReport> {
  // service type component
  bool isRegularMaintenance = true;

  // date picker component
  TextEditingController dateController = TextEditingController();

  // site picker component
  String? dropdownValue;
  SiteInfo? selectedSite;
  String address = '';

  // employee times component
  List<Map<String, dynamic>> employeeTimes = [];

  // description component
  TextEditingController _descriptionController = TextEditingController();

  // service list component
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

  // material component
  List<Map<String, dynamic>> materials = [];

  final currentUser = FirebaseAuth.instance.currentUser!;

  @override
  void initState() {
    super.initState();
    DateTime now = DateTime.now();
    String formattedDate = DateFormat('MMMM d, yyyy').format(now);
    dateController = TextEditingController(text: formattedDate);

    addEmployeeTime();
  }

  // Service Type Component
  void handleServiceTypeChange(bool isRegular) {
    setState(() {
      isRegularMaintenance = isRegular;
    });
  }

  // Site Picker Component
  void onSiteChanged(SiteInfo? site) {
    setState(() {
      selectedSite = site;
      dropdownValue = site?.name;
      address = site?.address ?? '';
    });
  }

  // Employee Times Component
  void addEmployeeTime() {
    setState(() {
      TimeOfDay timeOn = TimeOfDay.now();
      TimeOfDay timeOff = TimeOfDay.now();

      if (employeeTimes.isNotEmpty) {
        timeOn = employeeTimes.last['timeOn'];
        timeOff = employeeTimes.last['timeOff'];
      }

      employeeTimes.add({
        'nameController': TextEditingController(),
        'timeOn': timeOn,
        'timeOff': timeOff,
      });
    });
  }

  void updateTimeOn(int index, TimeOfDay time) {
    setState(() {
      employeeTimes[index]['timeOn'] = time;
    });
  }

  void updateTimeOff(int index, TimeOfDay time) {
    setState(() {
      employeeTimes[index]['timeOff'] = time;
    });
  }

  void deleteEmployeeTime(int index) {
    setState(() {
      employeeTimes.removeAt(index);
    });
  }

  // Service List Component
  void onGarbageSelectionChanged(List<String> selectedGarbage) {
    setState(() {
      _selectedGarbage = selectedGarbage;
    });
  }

  void onDebrisSelectionChanged(List<String> selectedDebris) {
    setState(() {
      _selectedDebris = selectedDebris;
    });
  }

  void onLawnSelectionChanged(List<String> selectedLawn) {
    setState(() {
      _selectedLawn = selectedLawn;
    });
  }

  void onGardenSelectionChanged(List<String> selectedGarden) {
    setState(() {
      _selectedGarden = selectedGarden;
    });
  }

  void onTreeSelectionChanged(List<String> selectedTree) {
    setState(() {
      _selectedTree = selectedTree;
    });
  }

  void onBlowSelectionChanged(List<String> selectedBlow) {
    setState(() {
      _selectedBlow = selectedBlow;
    });
  }

  // Material Component
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
    });
  }

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

  final reportRef = FirebaseFirestore.instance.collection('SiteReports');

  // form validation
  bool _validateForm() {
    if (dropdownValue == null || dropdownValue!.isEmpty) {
      _showErrorDialog('Please select a site.');
      return false;
    }

    for (var employee in employeeTimes) {
      if (employee['nameController'].text.isEmpty) {
        _showErrorDialog('Please enter an employee name.');
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
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _submitForm() async {
    if (!_validateForm()) {
      return; // Exit if the form is not valid
    }

    Map<String, dynamic> employeeTimesMap = {};
    Duration totalCombinedDuration = Duration();

    DateTime selectedDate =
        DateFormat('MMMM d, yyyy').parse(dateController.text);

    for (var employee in employeeTimes) {
      String name = employee['nameController'].text;
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
        "description": _descriptionController.text,
        "submittedBy": currentUser.email,
        "filed": false,
      });

      print('Report added successfully');

      if (mounted) {
        print('Widget is still mounted, proceeding with reset and navigation');

        // Reset all the form fields
        dateController.clear();
        dropdownValue = null;
        selectedSite = null;
        address = '';
        employeeTimes.clear();
        _selectedGarbage = [];
        _selectedDebris = [];
        _selectedLawn = [];
        _selectedGarden = [];
        _selectedTree = [];
        _selectedBlow = [];
        materials.clear();
        _descriptionController.clear();

        // Navigate back to Home
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => Home()));
      } else {
        print('Widget is no longer mounted, skipping reset and navigation');
      }
    } catch (e) {
      print('Error adding report: $e');
      _showErrorDialog('Failed to add report, please try again.');
    }
  }

  @override
  void dispose() {
    dateController.dispose();
    employeeTimes.forEach((employee) {
      employee['nameController'].dispose();
    });
    materials.forEach((material) {
      material['vendorController'].dispose();
      material['materialController'].dispose();
      material['costController'].dispose();
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // final sitesAsyncValue = ref.watch(siteListProvider);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 31, 182, 77),
        leading: MaterialButton(
          onPressed: () {
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (_) => Home()));
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
                Icon(
                  Icons.send,
                  color: Colors.white,
                  size: 18,
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ServiceTypeComponent(
                isInitialRegularMaintenance: isRegularMaintenance,
                onServiceTypeChanged: handleServiceTypeChange,
              ),
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
              Divider(
                color: Colors.grey,
                thickness: 1,
              ),
              Container(
                padding: EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                ),
                child: Text('Add Employees & Times:',
                    style: GoogleFonts.montserrat(fontSize: 14)),
              ),
              SizedBox(height: 5),
              ...employeeTimes.asMap().entries.map((entry) {
                int index = entry.key;
                Map<String, dynamic> staffMember = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: EmployeeTimesComponent(
                    nameController: staffMember['nameController'],
                    initialTimeOn: staffMember['timeOn'],
                    initialTimeOff: staffMember['timeOff'],
                    onTimeOnChanged: (time) => updateTimeOn(index, time),
                    onTimeOffChanged: (time) => updateTimeOff(index, time),
                    onDelete: () => deleteEmployeeTime(index),
                  ),
                );
              }).toList(),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 59, 82, 73),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  textStyle: GoogleFonts.montserrat(fontSize: 14),
                ),
                onPressed: addEmployeeTime,
                child: const Text('Add Another Employee Time'),
              ),
              Divider(
                color: Colors.grey,
                thickness: 1,
              ),
              Container(
                padding: EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                ),
                child: Text('Select Services Provided:',
                    style: GoogleFonts.montserrat(fontSize: 14)),
              ),
              ServiceToggleComponent(
                title: 'Pick Up Loose Garbage:',
                services: garbage,
                selectedServices: _selectedGarbage,
                onSelectionChanged: onGarbageSelectionChanged,
              ),
              ServiceToggleComponent(
                title: 'Rake Yard Debris:',
                services: debris,
                selectedServices: _selectedDebris,
                onSelectionChanged: onDebrisSelectionChanged,
              ),
              ServiceToggleComponent(
                title: 'Lawn Care:',
                services: lawn,
                selectedServices: _selectedLawn,
                onSelectionChanged: onLawnSelectionChanged,
              ),
              ServiceToggleComponent(
                title: 'Gardens:',
                services: garden,
                selectedServices: _selectedGarden,
                onSelectionChanged: onGardenSelectionChanged,
              ),
              ServiceToggleComponent(
                title: 'Trees (Pruning/Hedging):',
                services: tree,
                selectedServices: _selectedTree,
                onSelectionChanged: onTreeSelectionChanged,
              ),
              ServiceToggleComponent(
                title: 'Blow Dust/Debris:',
                services: blow,
                selectedServices: _selectedBlow,
                onSelectionChanged: onBlowSelectionChanged,
              ),
              Divider(
                color: Colors.grey,
                thickness: 1,
              ),
              Container(
                padding: EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                ),
                child: Text('Add Materials or Disposal:',
                    style: GoogleFonts.montserrat(fontSize: 14)),
              ),
              SizedBox(height: 5),
              ...materials.asMap().entries.map((entry) {
                int index = entry.key;
                Map<String, dynamic> material = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: MaterialComponent(
                          vendorController: material['vendorController'],
                          materialController: material['materialController'],
                          costController: material['costController'],
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
              }).toList(),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 59, 82, 73),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  textStyle: GoogleFonts.montserrat(fontSize: 14),
                ),
                onPressed: addMaterial,
                child: const Text('Add Material or Disposal'),
              ),
              Divider(
                color: Colors.grey,
                thickness: 1,
              ),
              Container(
                padding: EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                ),
                child: Text('Service Details:',
                    style: GoogleFonts.montserrat(fontSize: 14)),
              ),
              const SizedBox(height: 5),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(10),
                ),
                height: 150,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: TextField(
                    controller: _descriptionController,
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    decoration: InputDecoration(
                      hintText: 'Add a description of services provided . . .',
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
