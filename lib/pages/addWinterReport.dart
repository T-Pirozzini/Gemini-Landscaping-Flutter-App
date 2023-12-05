import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gemini_landscaping_app/pages/home_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

List<String> walkways = ['Common Walkways', 'Building Entrances', 'Crosswalks'];
List<String> _selectedWalkways = [];
List<String> liability = [
  'Access. Parking Stalls',
  'Stairs',
  'Curb Down-slopes'
];
List<String> _selectedLiability = [];
List<String> other = ['Cart Returns', 'Other - specify'];
List<String> _selectedOther = [];

class AddWinterReport extends StatefulWidget {
  const AddWinterReport({super.key});

  @override
  State<AddWinterReport> createState() => _AddWinterReportState();
}

class _AddWinterReportState extends State<AddWinterReport> {
  // site list
  List<String> winterSiteList = [];
  // drop down site menu
  String? dropdownValue;
  String enteredSiteName = '';
  final currentUser = FirebaseAuth.instance.currentUser!;
  double saltSliderValue = 0.0;
  double meltSliderValue = 0.0;
  double sandSliderValue = 0.0;
  List<bool> isIceManagement = [true, false]; // Initial state for ToggleButtons

  @override
  void initState() {
    super.initState();
    // add site names to siteList
    FirebaseFirestore.instance
        .collection('WinterSiteList')
        .get()
        .then((QuerySnapshot querySnapshot) {
      querySnapshot.docs.forEach((doc) {
        if (!winterSiteList.contains(doc["name"])) {
          setState(() {
            winterSiteList.add(doc["name"]);
          });
        }
      });

      // Check if siteList is not empty and then set dropdownValue
      if (winterSiteList.isNotEmpty) {
        setState(() {
          dropdownValue = winterSiteList.first;
        });
      } else {
        setState(() {
          dropdownValue = null; // or some default value that exists in the list
        });
      }
    });
  }

  void _updateSiteAddress(String siteName) {
    FirebaseFirestore.instance
        .collection('WinterSiteList')
        .get()
        .then((QuerySnapshot querySnapshot) {
      querySnapshot.docs.forEach((doc) {
        if (siteName == doc["name"]) {
          setState(() {
            _addressController.text = doc["address"];
          });
        }
      });
    });
  }

  void addSiteToList(String newSiteName) {
    setState(() {
      winterSiteList.add(newSiteName);
    });
  }

  TextEditingController dateController = TextEditingController();
  TextEditingController siteNameController = TextEditingController();
  TextEditingController _addressController = TextEditingController();
  TextEditingController name1 = TextEditingController();
  TextEditingController name2 = TextEditingController();
  TextEditingController name3 = TextEditingController();
  TextEditingController name4 = TextEditingController();
  TextEditingController _descriptionController = TextEditingController();

  CollectionReference reportRef =
      FirebaseFirestore.instance.collection('WinterReports');

  void _submitForm() {
    reportRef.add({
      "info": {
        'date': dateController.text,
        'siteName': dropdownValue,
        'address': _addressController.text,
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
        'iceManagement': isIceManagement[0],
        'snowRemoval': isIceManagement[1],
        'walkways': _selectedWalkways,
        'liability': _selectedLiability,
        'other': _selectedOther,
      },
      "material": {
        'iceMelt': meltSliderValue,
        'salt': saltSliderValue,
        'sand': sandSliderValue,
      },
      "description": _descriptionController.text,
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
      _selectedWalkways = [];
      _selectedLiability = [];
      _selectedOther = [];
      meltSliderValue = 0.0;
      saltSliderValue = 0.0;
      sandSliderValue = 0.0;
      _descriptionController.clear();
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
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // date picker
                  Expanded(
                    flex: 1,
                    child: TextField(
                      controller: dateController,
                      style: GoogleFonts.montserrat(fontSize: 12),
                      decoration: InputDecoration(
                        prefixIcon:
                            Icon(Icons.calendar_month_rounded, size: 32),
                        prefixIconColor: Colors.green,
                        labelText: "Date:",
                        border: OutlineInputBorder(),
                        labelStyle: GoogleFonts.montserrat(fontSize: 14),
                        focusedBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Colors.green, width: 2.0),
                        ),
                      ),
                      readOnly: true,
                      onTap: () async {
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
                              DateFormat("yyyy-MM-dd").format(pickedDate);
                          setState(() {
                            dateController.text = formattedDate.toString();
                          });
                        } else {
                          print('No Date Selected');
                        }
                      },
                    ),
                  ),
                  SizedBox(width: 10),
                  // site list drop down
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Select a Site',
                        focusedBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Colors.green, width: 2.0),
                        ),
                      ),
                      value: dropdownValue,
                      items: winterSiteList.map((site) {
                        return DropdownMenuItem<String>(
                          value: site,
                          child: Text(
                            site,
                            style: GoogleFonts.montserrat(fontSize: 14),
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) async {
                        setState(
                          () {
                            dropdownValue = newValue!;
                            _updateSiteAddress(newValue);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: 10,
              ),
              // site list drop down

              TextFormField(
                controller: _addressController,
                style: GoogleFonts.montserrat(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Enter address',
                ),
              ),
              const SizedBox(
                height: 10,
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
                  Divider(),
                  SizedBox(height: 5),
                  ToggleButtons(
                    borderRadius: const BorderRadius.all(Radius.circular(8)),
                    selectedBorderColor: const Color.fromARGB(255, 59, 82, 73),
                    selectedColor: Colors.white,
                    fillColor: const Color.fromARGB(255, 59, 82, 73),
                    color: Colors.black,
                    children: <Widget>[
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text('Ice Management'),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text('Snow Removal'),
                      ),
                    ],
                    onPressed: (int index) {
                      setState(() {
                        for (int buttonIndex = 0;
                            buttonIndex < isIceManagement.length;
                            buttonIndex++) {
                          if (buttonIndex == index) {
                            isIceManagement[buttonIndex] = true;
                          } else {
                            isIceManagement[buttonIndex] = false;
                          }
                        }
                      });
                    },
                    isSelected: isIceManagement,
                  ),
                  Divider(
                    color: Colors.grey,
                    thickness: 1,
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Primary Winter Services:',
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
                        if (_selectedWalkways.contains(walkways[index])) {
                          _selectedWalkways.remove(walkways[index]);
                        } else {
                          _selectedWalkways.add(walkways[index]);
                        }
                      });
                    },
                    borderRadius: const BorderRadius.all(Radius.circular(8)),
                    selectedBorderColor: Colors.green[700],
                    selectedColor: Colors.white,
                    fillColor: Colors.green[200],
                    color: Colors.green[700],
                    constraints: BoxConstraints(
                      minWidth: (MediaQuery.of(context).size.width * .9) /
                          walkways.length,
                      minHeight: 30.0,
                    ),
                    isSelected: walkways
                        .map((value) => _selectedWalkways.contains(value))
                        .toList(),
                    children: walkways
                        .map((value) => Text(
                              value,
                              style: GoogleFonts.montserrat(fontSize: 12),
                            ))
                        .toList(),
                  ),
                  SizedBox(height: 2),
                  Divider(
                    color: Colors.grey,
                    thickness: 1,
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'High Liability Winter Services:',
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
                        if (_selectedLiability.contains(liability[index])) {
                          _selectedLiability.remove(liability[index]);
                        } else {
                          _selectedLiability.add(liability[index]);
                        }
                      });
                    },
                    borderRadius: const BorderRadius.all(Radius.circular(8)),
                    selectedBorderColor: Colors.green[700],
                    selectedColor: Colors.white,
                    fillColor: Colors.green[200],
                    color: Colors.green[700],
                    constraints: BoxConstraints(
                      minWidth: (MediaQuery.of(context).size.width * .9) /
                          walkways.length,
                      minHeight: 30.0,
                    ),
                    isSelected: liability
                        .map((value) => _selectedLiability.contains(value))
                        .toList(),
                    children: liability
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
                      'Other Services:',
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
                        if (_selectedOther.contains(other[index])) {
                          _selectedOther.remove(other[index]);
                        } else {
                          _selectedOther.add(other[index]);
                        }
                      });
                    },
                    borderRadius: const BorderRadius.all(Radius.circular(8)),
                    selectedBorderColor: Colors.green[700],
                    selectedColor: Colors.white,
                    fillColor: Colors.green[200],
                    color: Colors.green[700],
                    constraints: BoxConstraints(
                      minWidth: (MediaQuery.of(context).size.width * .9) /
                          walkways.length,
                      minHeight: 30.0,
                    ),
                    isSelected: other
                        .map((value) => _selectedOther.contains(value))
                        .toList(),
                    children: other
                        .map((value) => Text(
                              value,
                              style: GoogleFonts.montserrat(fontSize: 12),
                            ))
                        .toList(),
                  ),
                  Slider(
                    value: meltSliderValue,
                    min: 0.0,
                    max: 10.0,
                    divisions: 40,
                    activeColor: Colors.blueAccent,
                    label: meltSliderValue.toStringAsFixed(2),
                    onChanged: (double value) {
                      setState(() {
                        meltSliderValue = value;
                      });
                    },
                  ),
                  Text(
                      'Ice Melt Used: ${meltSliderValue.toStringAsFixed(2)} bags'),
                  Slider(
                    value: saltSliderValue,
                    min: 0.0,
                    max: 10.0,
                    divisions: 40,
                    label: saltSliderValue.toStringAsFixed(2),
                    activeColor: Colors.blueAccent,
                    onChanged: (double value) {
                      setState(() {
                        saltSliderValue = value;
                      });
                    },
                  ),
                  Text('Salt Used: ${saltSliderValue.toStringAsFixed(2)} bags'),
                  Slider(
                    value: sandSliderValue,
                    min: 0.0,
                    max: 10.0,
                    divisions: 40,
                    label: sandSliderValue.toStringAsFixed(2),
                    activeColor: Colors.blueAccent,
                    onChanged: (double value) {
                      setState(() {
                        sandSliderValue = value;
                      });
                    },
                  ),
                  Text('Sand Used: ${sandSliderValue.toStringAsFixed(2)} bags'),
                  Divider(
                    color: Colors.grey,
                    thickness: 1,
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
          Text('Add a new site'),
          Icon(Icons.arrow_right_outlined, size: 18),
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
                                  'Add a new Winter Site:',
                                  style: TextStyle(
                                      fontSize: 22,
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
                                            .collection('WinterSiteList');

                                    // Create a new document and set its data
                                    await equipmentCollection.add({
                                      'name': nameController.text,
                                      'address': addressController.text,
                                      'addedBy': currentUser.email,
                                    });

                                    // add site to drop down list
                                    addSiteToList(nameController.text);

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
