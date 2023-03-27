import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gemini_landscaping_app/pages/home_page.dart';
import 'package:intl/intl.dart';

List<String> siteList = [
  // 'Enter Site Name', implement this functionality in future versions
  'Merewood Apartments',
  'Uplands Terrace',
  'North Point Apartments',
  'Country Grocer',
  'Alderwood',
  'Prideaux Manor',
  'Sandscapes',
  'Bowen Estates',
  'Riverbend Terrace',
  'Valley View Terrace',
  'Woodgrove Pines',
  'Pinewood Estates',
  'Lancelot Gardens',
  'Harwell Place',
  'Peartree Meadows',
  'Nanaimo Liquor Plus',
  'Azalea Apartments',
  'Westhill Centre',
  'The Chemainus',
];

String dropdownValue = siteList.first;
String enteredSiteName = '';

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

class AddReport extends StatefulWidget {
  const AddReport({super.key});

  @override
  State<AddReport> createState() => _AddReportState();
}

class _AddReportState extends State<AddReport> {
  TextEditingController dateController = TextEditingController();
  TextEditingController siteNameController = TextEditingController();
  TextEditingController name1 = TextEditingController();
  TextEditingController name2 = TextEditingController();
  TextEditingController name3 = TextEditingController();
  TextEditingController name4 = TextEditingController();

  CollectionReference reportRef =
      FirebaseFirestore.instance.collection('SiteReports2023');
      
  void _submitForm() {
    reportRef.add({
      "info": {
        'date': dateController.text,
        'siteName': dropdownValue,
      },
      "names": {
        'name1': name1.text,
        'name2': name2.text,
        'name3': name3.text,
        'name4': name4.text,
      },
      "times": {
        'timeOn1': timeOn1!.hour.toString() + ':' + timeOn1!.minute.toString(),
        'timeOff1':
            timeOff1!.hour.toString() + ':' + timeOff1!.minute.toString(),
        'timeOn2': timeOn2!.hour.toString() + ':' + timeOn2!.minute.toString(),
        'timeOff2':
            timeOff2!.hour.toString() + ':' + timeOff2!.minute.toString(),
        'timeOn3': timeOn3!.hour.toString() + ':' + timeOn3!.minute.toString(),
        'timeOff3':
            timeOff3!.hour.toString() + ':' + timeOff3!.minute.toString(),
        'timeOn4': timeOn4!.hour.toString() + ':' + timeOn4!.minute.toString(),
        'timeOff4':
            timeOff4!.hour.toString() + ':' + timeOff4!.minute.toString(),
      },
      "service": {
        'garbage': _selectedGarbage,
        'debris': _selectedDebris,
        'lawn': _selectedLawn,
        'garden': _selectedGarden,
        'tree': _selectedTree,
        'blow': _selectedBlow,
      },
    }).whenComplete(() {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => Home()));
    });
  }

  Future<void> getData() async {
    // Get docs from collection reference
    QuerySnapshot querySnapshot = await reportRef.get();

    // Get data from docs and convert map to List
    final allData = querySnapshot.docs.map((doc) => doc.data()).toList();
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
            onPressed: () {
              _submitForm();
            },
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
              // date picker
              SizedBox(
                height: 55,
                child: TextField(
                  controller: dateController,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.calendar_month_rounded),
                    prefixIconColor: Colors.green,
                    labelText: "Date:",
                    labelStyle: TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    hintText: 'Select date',
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
              const SizedBox(
                height: 10,
              ),
              // site list drop down
              SizedBox(
                height: 45,
                child: Stack(
                  children: [
                    DropdownButtonFormField<String>(
                      value: dropdownValue,
                      items: siteList.map((site) {
                        return DropdownMenuItem<String>(
                          value: site,
                          child: Text(site),
                        );
                      }).toList(),
                      onChanged: (String? value) {
                        setState(() {
                          dropdownValue = value!;
                          if (value == 'Enter site name') {
                            enteredSiteName = '';
                          }
                        });
                      },
                    ),
                    if (dropdownValue == 'Enter site name')
                      Container(
                        height: 45,
                        margin: const EdgeInsets.only(left: 10, right: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(
                            color: Colors.red,
                          ),
                        ),
                        child: TextField(
                          onChanged: (String value) {
                            setState(() {
                              enteredSiteName = value;
                            });
                            getData();
                          },
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(
                height: 10,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    // decoration: BoxDecoration(border: Border.all()),
                    child: Container(
                      width: 100,
                      height: 40,
                      child: TextField(
                        controller: name1,
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
                              '${timeOn1!.hour.toString()}:${timeOn1!.minute.toString()}'),
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
                              '${timeOff1!.hour.toString()}:${timeOff1!.minute.toString()}'),
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
                              '${timeOn2!.hour.toString()}:${timeOn2!.minute.toString()}'),
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
                              '${timeOff2!.hour.toString()}:${timeOff2!.minute.toString()}'),
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
                    // decoration: BoxDecoration(border: Border.all()),
                    child: Container(
                      width: 100,
                      height: 40,
                      child: TextField(
                        controller: name3,
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
                              '${timeOn3!.hour.toString()}:${timeOn3!.minute.toString()}'),
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
                              '${timeOff3!.hour.toString()}:${timeOff3!.minute.toString()}'),
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
                    // decoration: BoxDecoration(border: Border.all()),
                    child: Container(
                      width: 100,
                      height: 40,
                      child: TextField(
                        controller: name4,
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
                              '${timeOn4!.hour.toString()}:${timeOn4!.minute.toString()}'),
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
                              '${timeOff4!.hour.toString()}:${timeOff4!.minute.toString()}'),
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
              const Text('Pick up loose garbage:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
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
                borderRadius: const BorderRadius.all(Radius.circular(8)),
                selectedBorderColor: Colors.green[700],
                selectedColor: Colors.white,
                fillColor: Colors.green[200],
                color: Colors.green[700],
                constraints: const BoxConstraints(
                  minHeight: 30.0,
                  minWidth: 110.0,
                ),
                isSelected: garbage
                    .map((value) => _selectedGarbage.contains(value))
                    .toList(),
                children: garbage.map((value) => Text(value)).toList(),
              ),
              const SizedBox(height: 5),
              const Text('Rake yard debris:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
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
                  minHeight: 30.0,
                  minWidth: 110.0,
                ),
                isSelected: debris
                    .map((value) => _selectedDebris.contains(value))
                    .toList(),
                children: debris.map((value) => Text(value)).toList(),
              ),
              const SizedBox(height: 5),
              const Text('Lawn care:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
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
                  minHeight: 30.0,
                  minWidth: 55.0,
                ),
                isSelected:
                    lawn.map((value) => _selectedLawn.contains(value)).toList(),
                children: lawn.map((value) => Text(value)).toList(),
              ),
              const SizedBox(height: 5),
              const Text('Gardens:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
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
                  minHeight: 30.0,
                  minWidth: 85.0,
                ),
                isSelected: garden
                    .map((value) => _selectedGarden.contains(value))
                    .toList(),
                children: garden.map((value) => Text(value)).toList(),
              ),
              const SizedBox(height: 5),
              const Text('Trees:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
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
                  minHeight: 30.0,
                  minWidth: 110.0,
                ),
                isSelected:
                    tree.map((value) => _selectedTree.contains(value)).toList(),
                children: tree.map((value) => Text(value)).toList(),
              ),
              const SizedBox(height: 5),
              const Text('Blow dust/debris:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
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
                  minHeight: 30.0,
                  minWidth: 110.0,
                ),
                isSelected:
                    blow.map((value) => _selectedBlow.contains(value)).toList(),
                children: blow.map((value) => Text(value)).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
