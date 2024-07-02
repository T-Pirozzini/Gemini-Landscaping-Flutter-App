import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gemini_landscaping_app/models/site_info.dart';
import 'package:gemini_landscaping_app/providers/site_list_provider.dart';
import 'package:gemini_landscaping_app/screens/home/home_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

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

class AddSiteReport extends ConsumerStatefulWidget {
  const AddSiteReport({super.key});

  @override
  _AddSiteReportState createState() => _AddSiteReportState();
}

class _AddSiteReportState extends ConsumerState<AddSiteReport> {
  // site list
  List<String> siteList = [];
  // drop down site menu
  String? dropdownValue;
  SiteInfo? selectedSite;
  String address = '';
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
  }

  TextEditingController dateController = TextEditingController();
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
              Row(
                children: [
                  IconButton(
                    onPressed: () async {
                      DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2101),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: const ColorScheme.light(
                                primary: Colors.green,
                                onPrimary: Colors.white,
                                onSurface: Colors.black,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (pickedDate != null) {
                        String formattedDate =
                            DateFormat('MMMM d, yyyy').format(pickedDate);
                        setState(() {
                          dateController.text =
                              formattedDate; // Update the date in the controller
                        });
                      }
                    },
                    icon: Icon(
                      Icons.edit_calendar,
                      color: Colors.green,
                    ),
                  ),
                  Text(
                    dateController.text,
                    style: GoogleFonts.montserrat(fontSize: 14),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 300,
                    child: sitesAsyncValue.when(
                      data: (siteList) {
                        return DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.all(8),
                            border: OutlineInputBorder(),
                            labelText: 'Select a Site',
                            focusedBorder: OutlineInputBorder(
                              borderSide:
                                  BorderSide(color: Colors.green, width: 2.0),
                            ),
                          ),
                          value: dropdownValue,
                          items: siteList.map((site) {
                            return DropdownMenuItem<String>(
                              value: site.name,
                              child: Text(
                                site.name,
                                style: GoogleFonts.montserrat(fontSize: 14),
                              ),
                            );
                          }).toList(),
                          onChanged: (String? value) {
                            setState(() {
                              dropdownValue = value!;
                              selectedSite = siteList.firstWhere(
                                  (site) => site.name == dropdownValue);
                              address = selectedSite!.address;
                            });
                          },
                        );
                      },
                      loading: () => Center(child: CircularProgressIndicator()),
                      error: (error, stack) =>
                          Center(child: Text('Error: $error')),
                    ),
                  ),
                  if (selectedSite != null)
                    Text(
                      'Address: $address',
                      style: GoogleFonts.montserrat(fontSize: 14),
                    ),
                ],
              ),
              Divider(
                color: Colors.grey,
                thickness: 1,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Container(
                      width: 100,
                      height: 40,
                      child: TextField(
                        controller: name1,
                        style: GoogleFonts.montserrat(fontSize: 14),
                        maxLines: null,
                        keyboardType: TextInputType.text,
                        decoration: const InputDecoration(
                          hintText: 'Driver',
                        ),
                      ),
                    ),
                  ),
                  Column(
                    children: [
                      const Text("ON",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Container(
                        width: 100,
                        height: 30,
                        child: FloatingActionButton.extended(
                          heroTag: "btn1On",
                          icon: const Icon(Icons.access_time_outlined),
                          label: Text(
                              '${timeOn1!.hour.toString()}:${timeOn1!.minute.toString().padLeft(2, '0')}'),
                          backgroundColor:
                              const Color.fromARGB(255, 31, 182, 77),
                          onPressed: () async {
                            TimeOfDay? newTimeOn1 = await showTimePicker(
                              context: context,
                              initialTime: timeOn1!,
                            );
                            if (newTimeOn1 != null) {
                              setState(() {
                                timeOn1 = newTimeOn1;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  Column(
                    children: [
                      const Text("OFF",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Container(
                        width: 100,
                        height: 30,
                        child: FloatingActionButton.extended(
                          heroTag: "btn1Off",
                          icon: const Icon(Icons.access_time_outlined),
                          label: Text(
                              '${timeOff1!.hour.toString()}:${timeOff1!.minute.toString().padLeft(2, '0')}'),
                          backgroundColor:
                              const Color.fromARGB(255, 31, 182, 77),
                          onPressed: () async {
                            TimeOfDay? newTimeOff1 = await showTimePicker(
                              context: context,
                              initialTime: timeOff1!,
                            );
                            if (newTimeOff1 != null) {
                              setState(() {
                                timeOff1 = newTimeOff1;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Container(
                      width: 100,
                      height: 40,
                      child: TextField(
                        controller: name2,
                        style: GoogleFonts.montserrat(fontSize: 14),
                        maxLines: null,
                        keyboardType: TextInputType.text,
                        decoration: const InputDecoration(
                          hintText: 'Name',
                        ),
                      ),
                    ),
                  ),
                  Column(
                    children: [
                      const SizedBox(height: 4),
                      Container(
                        width: 100,
                        height: 30,
                        child: FloatingActionButton.extended(
                          heroTag: "btn2On",
                          icon: const Icon(Icons.access_time_outlined),
                          label: Text(
                              '${timeOn2!.hour.toString()}:${timeOn2!.minute.toString().padLeft(2, '0')}'),
                          backgroundColor:
                              const Color.fromARGB(255, 31, 182, 77),
                          onPressed: () async {
                            TimeOfDay? newTimeOn2 = await showTimePicker(
                              context: context,
                              initialTime: timeOn2!,
                            );
                            if (newTimeOn2 != null) {
                              setState(() {
                                timeOn2 = newTimeOn2;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  Column(
                    children: [
                      const SizedBox(height: 4),
                      Container(
                        width: 100,
                        height: 30,
                        child: FloatingActionButton.extended(
                          heroTag: "btn2Off",
                          icon: const Icon(Icons.access_time_outlined),
                          label: Text(
                              '${timeOff2!.hour.toString()}:${timeOff2!.minute.toString().padLeft(2, '0')}'),
                          backgroundColor:
                              const Color.fromARGB(255, 31, 182, 77),
                          onPressed: () async {
                            TimeOfDay? newTimeOff2 = await showTimePicker(
                              context: context,
                              initialTime: timeOff2!,
                            );
                            if (newTimeOff2 != null) {
                              setState(() {
                                timeOff2 = newTimeOff2;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Container(
                      width: 100,
                      height: 40,
                      child: TextField(
                        controller: name3,
                        style: GoogleFonts.montserrat(fontSize: 14),
                        maxLines: null,
                        keyboardType: TextInputType.text,
                        decoration: const InputDecoration(
                          hintText: 'Name',
                        ),
                      ),
                    ),
                  ),
                  Column(
                    children: [
                      const SizedBox(height: 4),
                      Container(
                        width: 100,
                        height: 30,
                        child: FloatingActionButton.extended(
                          heroTag: "btn3On",
                          icon: const Icon(Icons.access_time_outlined),
                          label: Text(
                              '${timeOn3!.hour.toString()}:${timeOn3!.minute.toString().padLeft(2, '0')}'),
                          backgroundColor:
                              const Color.fromARGB(255, 31, 182, 77),
                          onPressed: () async {
                            TimeOfDay? newTimeOn3 = await showTimePicker(
                              context: context,
                              initialTime: timeOn3!,
                            );
                            if (newTimeOn3 != null) {
                              setState(() {
                                timeOn3 = newTimeOn3;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  Column(
                    children: [
                      const SizedBox(height: 4),
                      Container(
                        width: 100,
                        height: 30,
                        child: FloatingActionButton.extended(
                          heroTag: "btn3Off",
                          icon: const Icon(Icons.access_time_outlined),
                          label: Text(
                              '${timeOff3!.hour.toString()}:${timeOff3!.minute.toString().padLeft(2, '0')}'),
                          backgroundColor:
                              const Color.fromARGB(255, 31, 182, 77),
                          onPressed: () async {
                            TimeOfDay? newTimeOff3 = await showTimePicker(
                              context: context,
                              initialTime: timeOff3!,
                            );
                            if (newTimeOff3 != null) {
                              setState(() {
                                timeOff3 = newTimeOff3;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Container(
                      width: 100,
                      height: 40,
                      child: TextField(
                        controller: name4,
                        style: GoogleFonts.montserrat(fontSize: 14),
                        maxLines: null,
                        keyboardType: TextInputType.text,
                        decoration: const InputDecoration(
                          hintText: 'Name',
                        ),
                      ),
                    ),
                  ),
                  Column(
                    children: [
                      const SizedBox(height: 4),
                      Container(
                        width: 100,
                        height: 30,
                        child: FloatingActionButton.extended(
                          heroTag: "btn4On",
                          icon: const Icon(Icons.access_time_outlined),
                          label: Text(
                              '${timeOn4!.hour.toString()}:${timeOn4!.minute.toString().padLeft(2, '0')}'),
                          backgroundColor:
                              const Color.fromARGB(255, 31, 182, 77),
                          onPressed: () async {
                            TimeOfDay? newTimeOn4 = await showTimePicker(
                              context: context,
                              initialTime: timeOn4!,
                            );
                            if (newTimeOn4 != null) {
                              setState(() {
                                timeOn4 = newTimeOn4;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  Column(
                    children: [
                      const SizedBox(height: 4),
                      Container(
                        width: 100,
                        height: 30,
                        child: FloatingActionButton.extended(
                          heroTag: "btn4Off",
                          icon: const Icon(Icons.access_time_outlined),
                          label: Text(
                              '${timeOff4!.hour.toString()}:${timeOff4!.minute.toString().padLeft(2, '0')}'),
                          backgroundColor:
                              const Color.fromARGB(255, 31, 182, 77),
                          onPressed: () async {
                            TimeOfDay? newTimeOff4 = await showTimePicker(
                              context: context,
                              initialTime: timeOff4!,
                            );
                            if (newTimeOff4 != null) {
                              setState(() {
                                timeOff4 = newTimeOff4;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Divider(
                    color: Colors.grey,
                    thickness: 1,
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Pick Up Loose Garbage:',
                      style: GoogleFonts.montserrat(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          height: .5),
                    ),
                  ),
                  Wrap(
                    children: [
                      ToggleButtons(
                        onPressed: (int index) {
                          // All buttons are selectable.
                          setState(() {
                            if (_selectedGarbage.contains(garbage[index])) {
                              _selectedGarbage.remove(garbage[index]);
                            } else {
                              _selectedGarbage.add(garbage[index]);
                            }
                          });
                        },
                        borderRadius:
                            const BorderRadius.all(Radius.circular(8)),
                        selectedBorderColor: Colors.green[700],
                        selectedColor: Colors.white,
                        fillColor: Colors.green[200],
                        color: Colors.green[700],
                        constraints: const BoxConstraints(
                          minHeight: 25.0,
                          minWidth: 110.0,
                        ),
                        isSelected: garbage
                            .map((value) => _selectedGarbage.contains(value))
                            .toList(),
                        children: garbage
                            .map((value) => Text(
                                  value,
                                  style: GoogleFonts.montserrat(fontSize: 12),
                                ))
                            .toList(),
                      ),
                    ],
                  ),
                  SizedBox(height: 2),
                  Divider(
                    color: Colors.grey,
                    thickness: 1,
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Rake Yard Debris:',
                      style: GoogleFonts.montserrat(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          height: .5),
                    ),
                  ),
                  ToggleButtons(
                    onPressed: (int index) {
                      // All buttons are selectable.
                      setState(() {
                        if (_selectedDebris.contains(debris[index])) {
                          _selectedDebris.remove(debris[index]);
                        } else {
                          _selectedDebris.add(debris[index]);
                        }
                      });
                    },
                    borderRadius: const BorderRadius.all(Radius.circular(8)),
                    selectedBorderColor: Colors.green[700],
                    selectedColor: Colors.white,
                    fillColor: Colors.green[200],
                    color: Colors.green[700],
                    constraints: const BoxConstraints(
                      minHeight: 25.0,
                      minWidth: 110.0,
                    ),
                    isSelected: debris
                        .map((value) => _selectedDebris.contains(value))
                        .toList(),
                    children: debris
                        .map((value) => Text(
                              value,
                              style: GoogleFonts.montserrat(fontSize: 12),
                            ))
                        .toList(),
                  ),
                  Divider(
                    color: Colors.grey,
                    thickness: 1,
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Lawn Care:',
                      style: GoogleFonts.montserrat(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          height: .5),
                    ),
                  ),
                  ToggleButtons(
                    onPressed: (int index) {
                      // All buttons are selectable.
                      setState(() {
                        if (_selectedLawn.contains(lawn[index])) {
                          _selectedLawn.remove(lawn[index]);
                        } else {
                          _selectedLawn.add(lawn[index]);
                        }
                      });
                    },
                    borderRadius: const BorderRadius.all(Radius.circular(8)),
                    selectedBorderColor: Colors.green[700],
                    selectedColor: Colors.white,
                    fillColor: Colors.green[200],
                    color: Colors.green[700],
                    constraints: const BoxConstraints(
                      minHeight: 25.0,
                      minWidth: 55.0,
                    ),
                    isSelected: lawn
                        .map((value) => _selectedLawn.contains(value))
                        .toList(),
                    children: lawn
                        .map((value) => Text(
                              value,
                              style: GoogleFonts.montserrat(fontSize: 12),
                            ))
                        .toList(),
                  ),
                  Divider(
                    color: Colors.grey,
                    thickness: 1,
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Gardens:',
                      style: GoogleFonts.montserrat(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          height: .5),
                    ),
                  ),
                  ToggleButtons(
                    onPressed: (int index) {
                      // All buttons are selectable.
                      setState(() {
                        if (_selectedGarden.contains(garden[index])) {
                          _selectedGarden.remove(garden[index]);
                        } else {
                          _selectedGarden.add(garden[index]);
                        }
                      });
                    },
                    borderRadius: const BorderRadius.all(Radius.circular(8)),
                    selectedBorderColor: Colors.green[700],
                    selectedColor: Colors.white,
                    fillColor: Colors.green[200],
                    color: Colors.green[700],
                    constraints: const BoxConstraints(
                      minHeight: 25.0,
                      minWidth: 85.0,
                    ),
                    isSelected: garden
                        .map((value) => _selectedGarden.contains(value))
                        .toList(),
                    children: garden
                        .map((value) => Text(
                              value,
                              style: GoogleFonts.montserrat(fontSize: 12),
                            ))
                        .toList(),
                  ),
                  Divider(
                    color: Colors.grey,
                    thickness: 1,
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Trees:',
                      style: GoogleFonts.montserrat(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          height: .5),
                    ),
                  ),
                  ToggleButtons(
                    onPressed: (int index) {
                      // All buttons are selectable.
                      setState(() {
                        if (_selectedTree.contains(tree[index])) {
                          _selectedTree.remove(tree[index]);
                        } else {
                          _selectedTree.add(tree[index]);
                        }
                      });
                    },
                    borderRadius: const BorderRadius.all(Radius.circular(8)),
                    selectedBorderColor: Colors.green[700],
                    selectedColor: Colors.white,
                    fillColor: Colors.green[200],
                    color: Colors.green[700],
                    constraints: const BoxConstraints(
                      minHeight: 25.0,
                      minWidth: 110.0,
                    ),
                    isSelected: tree
                        .map((value) => _selectedTree.contains(value))
                        .toList(),
                    children: tree
                        .map((value) => Text(
                              value,
                              style: GoogleFonts.montserrat(fontSize: 12),
                            ))
                        .toList(),
                  ),
                  Divider(
                    color: Colors.grey,
                    thickness: 1,
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Blow Dust/Debris:',
                      style: GoogleFonts.montserrat(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          height: .5),
                    ),
                  ),
                  ToggleButtons(
                    onPressed: (int index) {
                      // All buttons are selectable.
                      setState(() {
                        if (_selectedBlow.contains(blow[index])) {
                          _selectedBlow.remove(blow[index]);
                        } else {
                          _selectedBlow.add(blow[index]);
                        }
                      });
                    },
                    borderRadius: const BorderRadius.all(Radius.circular(8)),
                    selectedBorderColor: Colors.green[700],
                    selectedColor: Colors.white,
                    fillColor: Colors.green[200],
                    color: Colors.green[700],
                    constraints: const BoxConstraints(
                      minHeight: 25.0,
                      minWidth: 110.0,
                    ),
                    isSelected: blow
                        .map((value) => _selectedBlow.contains(value))
                        .toList(),
                    children: blow
                        .map((value) => Text(
                              value,
                              style: GoogleFonts.montserrat(fontSize: 12),
                            ))
                        .toList(),
                  ),
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
                          hintText: 'Description',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                ],
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
