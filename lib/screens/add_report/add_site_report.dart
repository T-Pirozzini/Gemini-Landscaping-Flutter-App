import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gemini_landscaping_app/models/site_info.dart';
import 'package:gemini_landscaping_app/providers/site_list_provider.dart';
import 'package:gemini_landscaping_app/screens/add_report/date_picker.dart';
import 'package:gemini_landscaping_app/screens/add_report/employee_times.dart';
import 'package:gemini_landscaping_app/screens/add_report/material.dart';
import 'package:gemini_landscaping_app/screens/add_report/service_list.dart';
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
  // date picker component
  TextEditingController dateController = TextEditingController();

  // site picker component
  String? dropdownValue;
  SiteInfo? selectedSite;
  String address = '';

  // employee times component
  List<Map<String, dynamic>> employeeTimes = [];

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

  // possibly unused?
  String currentDate = DateFormat('MMMM d, yyyy').format(DateTime.now());
  String enteredSiteName = '';
  String imageURL = '';
  final currentUser = FirebaseAuth.instance.currentUser!;

  @override
  void initState() {
    super.initState();
    DateTime now = DateTime.now();
    String formattedDate = DateFormat('MMMM d, yyyy').format(now);
    dateController = TextEditingController(text: formattedDate);

    addEmployeeTime();
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
      employeeTimes.add({
        'nameController': TextEditingController(),
        'timeOn': TimeOfDay.now(),
        'timeOff': TimeOfDay.now(),
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

  TextEditingController siteNameController = TextEditingController();
  TextEditingController _addressController = TextEditingController();
  TextEditingController name1 = TextEditingController();
  TextEditingController name2 = TextEditingController();
  TextEditingController name3 = TextEditingController();
  TextEditingController name4 = TextEditingController();
  TextEditingController _descriptionController = TextEditingController();
  TextEditingController _materialController1 = TextEditingController();
  TextEditingController _vendorController1 = TextEditingController();
  TextEditingController _amountController1 = TextEditingController();
  TextEditingController _materialController2 = TextEditingController();
  TextEditingController _vendorController2 = TextEditingController();
  TextEditingController _amountController2 = TextEditingController();
  TextEditingController _materialController3 = TextEditingController();
  TextEditingController _vendorController3 = TextEditingController();
  TextEditingController _amountController3 = TextEditingController();

  CollectionReference reportRef =
      FirebaseFirestore.instance.collection('SiteReports2023');

  Timestamp convertTimeOfDayToTimestamp(TimeOfDay time) {
    final DateTime now = DateTime.now();
    final DateTime dateTime =
        DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return Timestamp.fromDate(dateTime);
  }

  void _submitForm() {
    Map<String, dynamic> employeeTimes = {};

    void addEmployeeTime(String name, TimeOfDay? timeOn, TimeOfDay? timeOff) {
      if (name.isNotEmpty && timeOn != null && timeOff != null) {
        employeeTimes[name] = {
          'timeOn': convertTimeOfDayToTimestamp(timeOn),
          'timeOff': convertTimeOfDayToTimestamp(timeOff),
        };
      }
    }

    // Add data for each employee if all required data is present
    addEmployeeTime(name1.text, timeOn1, timeOff1);
    addEmployeeTime(name2.text, timeOn2, timeOff2);
    addEmployeeTime(name3.text, timeOn3, timeOff3);
    addEmployeeTime(name4.text, timeOn4, timeOff4);

    reportRef.add({
      "timestamp": DateTime.now(),
      "employeeTimes": employeeTimes,
      "info": {
        'date': dateController.text,
        'siteName': dropdownValue,
        'address': _addressController.text,
        'imageURL': imageURL,
      },
      "names": {
        'name1': name1.text,
        'name2': name2.text,
        'name3': name3.text,
        'name4': name4.text,
      },
      "times": {
        'timeOn1': timeOn1!.hour.toString() +
            ':' +
            timeOn1!.minute.toString().padLeft(2, '0'),
        'timeOff1': timeOff1!.hour.toString() +
            ':' +
            timeOff1!.minute.toString().padLeft(2, '0'),
        'timeOn2': timeOn2!.hour.toString() +
            ':' +
            timeOn2!.minute.toString().padLeft(2, '0'),
        'timeOff2': timeOff2!.hour.toString() +
            ':' +
            timeOff2!.minute.toString().padLeft(2, '0'),
        'timeOn3': timeOn3!.hour.toString() +
            ':' +
            timeOn3!.minute.toString().padLeft(2, '0'),
        'timeOff3': timeOff3!.hour.toString() +
            ':' +
            timeOff3!.minute.toString().padLeft(2, '0'),
        'timeOn4': timeOn4!.hour.toString() +
            ':' +
            timeOn4!.minute.toString().padLeft(2, '0'),
        'timeOff4': timeOff4!.hour.toString() +
            ':' +
            timeOff4!.minute.toString().padLeft(2, '0'),
      },
      "service": {
        'garbage': _selectedGarbage,
        'debris': _selectedDebris,
        'lawn': _selectedLawn,
        'garden': _selectedGarden,
        'tree': _selectedTree,
        'blow': _selectedBlow,
      },
      "description": _descriptionController.text,
      "materials": {
        "material1": _materialController1.text,
        "vendor1": _vendorController1.text,
        "amount1": _amountController1.text,
        "material2": _materialController2.text,
        "vendor2": _vendorController2.text,
        "amount2": _amountController2.text,
        "material3": _materialController3.text,
        "vendor3": _vendorController3.text,
        "amount3": _amountController3.text,
      },
      "submittedBy": currentUser.email,
    }).whenComplete(() {
      // reset all the form fields
      dateController.clear();
      dropdownValue = 'Select a site';
      _addressController.clear();
      name1.clear();
      name2.clear();
      name3.clear();
      name4.clear();
      timeOn1 = null;
      timeOff1 = null;
      timeOn2 = null;
      timeOff2 = null;
      timeOn3 = null;
      timeOff3 = null;
      timeOn4 = null;
      timeOff4 = null;
      _selectedGarbage = [];
      _selectedDebris = [];
      _selectedLawn = [];
      _selectedGarden = [];
      _selectedTree = [];
      _selectedBlow = [];
      _descriptionController.clear();
      _materialController1.clear();
      _vendorController1.clear();
      _amountController1.clear();
      _materialController2.clear();
      _vendorController2.clear();
      _amountController2.clear();
      _materialController3.clear();
      _vendorController3.clear();
      _amountController3.clear();
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => Home()));
    });
  }

  @override
  void dispose() {
    dateController.dispose();
    siteNameController.dispose();
    _addressController.dispose();
    name1.dispose();
    name2.dispose();
    name3.dispose();
    name4.dispose();
    _descriptionController.dispose();
    _materialController1.dispose();
    _vendorController1.dispose();
    _amountController1.dispose();
    _materialController2.dispose();
    _vendorController2.dispose();
    _amountController2.dispose();
    _materialController3.dispose();
    _vendorController3.dispose();
    _amountController3.dispose();
    super.dispose();
  }

  TimeOfDay? timeOn1 = TimeOfDay.now();
  TimeOfDay? timeOff1 = TimeOfDay.now();
  TimeOfDay? timeOn2 = TimeOfDay.now();
  TimeOfDay? timeOff2 = TimeOfDay.now();
  TimeOfDay? timeOn3 = TimeOfDay.now();
  TimeOfDay? timeOff3 = TimeOfDay.now();
  TimeOfDay? timeOn4 = TimeOfDay.now();
  TimeOfDay? timeOff4 = TimeOfDay.now();

  @override
  Widget build(BuildContext context) {
    final sitesAsyncValue = ref.watch(siteListProvider);
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
              DatePickerComponent(dateController: dateController),
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
                  ),
                );
              }).toList(),
              ElevatedButton(
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
                child: Text('Add Materials Used:',
                    style: GoogleFonts.montserrat(fontSize: 14)),
              ),
              SizedBox(height: 5),
              ...materials.asMap().entries.map((entry) {
                int index = entry.key;
                Map<String, dynamic> material = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: MaterialComponent(
                    vendorController: material['vendorController'],
                    materialController: material['materialController'],
                    costController: material['costController'],
                  ),
                );
              }).toList(),
              ElevatedButton(
                onPressed: addMaterial,
                child: const Text('Add Material'),
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
                      hintText: 'Add a description of services provided',
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            'Add a New Site',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Icon(Icons.arrow_right_outlined, size: 24),
          FloatingActionButton(
            backgroundColor: Colors.black45,
            mini: true,
            shape:
                ShapeBorder.lerp(RoundedRectangleBorder(), CircleBorder(), 0.5),
            onPressed: () {
              TextEditingController nameController = TextEditingController();
              TextEditingController addressController = TextEditingController();

              showModalBottomSheet(
                isScrollControlled: true,
                context: context,
                builder: (BuildContext context) {
                  return StatefulBuilder(
                    builder: (BuildContext context, StateSetter setState) {
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: MediaQuery.of(context).viewInsets.bottom,
                        ),
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          children: [
                            Column(
                              children: [
                                Text(
                                  'Add a New Site:',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontFamily: 'Montserrat',
                                      fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: MediaQuery.of(context).size.width *
                                          .6,
                                      child: TextField(
                                        controller: nameController,
                                        decoration: InputDecoration(
                                          border: OutlineInputBorder(),
                                          labelText: 'Site Name',
                                          focusedBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                                color: Colors.green,
                                                width: 2.0),
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 5),
                                    Container(
                                      width: MediaQuery.of(context).size.width *
                                          .8,
                                      child: TextField(
                                        controller: addressController,
                                        decoration: InputDecoration(
                                          border: OutlineInputBorder(),
                                          labelText: 'Address',
                                          focusedBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                                color: Colors.green,
                                                width: 2.0),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 5),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      backgroundColor: Colors.black45,
                                      textStyle: TextStyle(fontSize: 18)),
                                  onPressed: () async {
                                    CollectionReference equipmentCollection =
                                        FirebaseFirestore.instance
                                            .collection('SiteList');

                                    // Create a new document and set its data
                                    await equipmentCollection.add({
                                      'name': nameController.text,
                                      'address': addressController.text,
                                      'management': "",
                                      'imageUrl': "",
                                      'status:': true,
                                      'addedBy': currentUser.email,
                                    });

                                    // Clear the text fields
                                    nameController.clear();
                                    addressController.clear();

                                    // Close the bottom sheet after adding equipment
                                    Navigator.pop(context);
                                  },
                                  child: Text('Add Site'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              );
            },
            child: Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}
