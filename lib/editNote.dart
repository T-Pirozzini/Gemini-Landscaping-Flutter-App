import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:intl/intl.dart';
import 'main.dart';
import 'sitereport.dart';

List<String> siteList = [
  'Merewood Apartments',
  'Uplands Terrace',
  'North Point Apartments',
  'Country Grocer'
];

class editnote extends StatefulWidget {
  DocumentSnapshot docid;
  editnote({required this.docid});

  @override
  _editnoteState createState() => _editnoteState(docid: docid);
}

class _editnoteState extends State<editnote> {
  DocumentSnapshot docid;
  _editnoteState({required this.docid});
  TextEditingController date = TextEditingController();
  TextEditingController siteName = TextEditingController();
  TextEditingController name1 = TextEditingController();
  TextEditingController name2 = TextEditingController();
  TextEditingController name3 = TextEditingController();
  TextEditingController name4 = TextEditingController();
  String timeOn1 = "12";
  String timeOff1 = "12";
  String timeOn2 = "12";
  String timeOff2 = "12;";
  String timeOn3 = "12";
  String timeOff3 = "12";
  String timeOn4 = "12";
  String timeOff4 = "12";

  CollectionReference ref =
      FirebaseFirestore.instance.collection('SiteReports2023');

  Future<void> getData() async {
    // Get docs from collection reference
    QuerySnapshot querySnapshot = await ref.get();

    // Get data from docs and convert map to List
    final allData = querySnapshot.docs.map((doc) => doc.data()).toList();
    print(allData);
  }

  String dropdownValue = siteList.first;

  @override
  void initState() {
    date = TextEditingController(text: widget.docid.get('date'));
    siteName = TextEditingController(text: widget.docid.get('siteName'));
    name1 = TextEditingController(text: widget.docid.get('name1'));
    // timeOn1 = widget.docid.get('timeOn1');
    // timeOff1 = widget.docid.get("timeOff1");
    name2 = TextEditingController(text: widget.docid.get('name2'));
    // timeOn2 = widget.docid.get('timeOn2');
    // timeOff2 = widget.docid.get('timeOff2');
    name3 = TextEditingController(text: widget.docid.get('name3'));
    // timeOn3 = widget.docid.get('timeOn3');
    // timeOff3 = widget.docid.get('timeOff3');
    name4 = TextEditingController(text: widget.docid.get('name4'));
    // timeOn4 = widget.docid.get('timeOn4');
    // timeOff4 = widget.docid.get('timeOff4');

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 31, 182, 77),
        actions: [
          MaterialButton(
            onPressed: () {
              Navigator.pushReplacement(
                  context, MaterialPageRoute(builder: (_) => Home()));
            },
            child: const Text(
              "Back",
              style: TextStyle(
                fontSize: 20,
                color: Color.fromARGB(255, 251, 251, 251),
              ),
            ),
          ),
          MaterialButton(
            onPressed: () {
              widget.docid.reference.update({
                'date': date.text,
                'siteName': siteName.text,
                'team1': name1.text,
                'team2': name1.text,
                'team3': name1.text,
                'team4': name1.text,
                // 'timeOn1': timeOn1,
                // 'timeOff1': timeOff1,
                // 'timeOn2': timeOn2,
                // 'timeOff2': timeOff2,
                // 'timeOn3': timeOn3,
                // 'timeOff3': timeOff3,
                // 'timeOn4': timeOn4,
                // 'timeOff4': timeOff4,
              }).whenComplete(() {
                Navigator.pushReplacement(
                    context, MaterialPageRoute(builder: (_) => Home()));
              });
            },
            child: const Text(
              "Save",
              style: TextStyle(
                fontSize: 20,
                color: Color.fromARGB(255, 251, 251, 251),
              ),
            ),
          ),
          MaterialButton(
            onPressed: () {
              widget.docid.reference.delete().whenComplete(() {
                Navigator.pushReplacement(
                    context, MaterialPageRoute(builder: (_) => Home()));
              });
            },
            child: const Text(
              "Delete",
              style: TextStyle(
                fontSize: 20,
                color: Color.fromARGB(255, 251, 251, 251),
              ),
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
              Container(
                decoration: BoxDecoration(border: Border.all()),
                child: TextField(
                  controller: date,
                  decoration: const InputDecoration(
                    icon: Icon(Icons.calendar_month_rounded),
                    labelText: "Date:",
                    hintText: 'Select date',
                  ),
                  readOnly: true,
                  onTap: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2101),
                    );
                    if (pickedDate != null) {
                      String formattedDate =
                          DateFormat("yyyy-MM-dd").format(pickedDate);
                      setState(() {
                        date.text = formattedDate.toString();
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
                  });
                  getData();
                },
              ),
              const SizedBox(
                height: 10,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    // decoration: BoxDecoration(border: Border.all()),
                    child: TextField(
                      controller: name1,
                      maxLines: null,
                      keyboardType: TextInputType.text,
                      decoration: const InputDecoration(
                        hintText: 'Driver',
                      ),
                    ),
                  ),
                  Column(
                    children: [
                      const Text("On"),
                      FloatingActionButton.extended(
                        heroTag: "btn1On",
                        icon: const Icon(Icons.access_time_outlined),
                        label: Text(timeOn1.toString()),
                        backgroundColor: const Color.fromARGB(255, 31, 182, 77),
                        onPressed: () async {
                          TimeOfDay? newTimeOn1 = await showTimePicker(
                            context: context,
                            initialTime: widget.docid.get('timeOn1'),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  Column(
                    children: [
                      const Text("Off"),
                      FloatingActionButton.extended(
                        heroTag: "btn1Off",
                        icon: const Icon(Icons.access_time_outlined),
                        label: Text(timeOff1.toString()),
                        backgroundColor: const Color.fromARGB(255, 31, 182, 77),
                        onPressed: () async {
                          TimeOfDay? newTimeOff1 = await showTimePicker(
                            context: context,
                            initialTime: widget.docid.get('timeOff1'),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: TextField(
                      controller: name2,
                      maxLines: null,
                      keyboardType: TextInputType.text,
                      decoration: const InputDecoration(
                        hintText: 'Name',
                      ),
                    ),
                  ),
                  Column(
                    children: [
                      const SizedBox(height: 4),
                      FloatingActionButton.extended(
                        heroTag: "btn2On",
                        icon: const Icon(Icons.access_time_outlined),
                        label: Text(timeOn2.toString()),
                        backgroundColor: const Color.fromARGB(255, 31, 182, 77),
                        onPressed: () async {
                          TimeOfDay? newTimeOn2 = await showTimePicker(
                            context: context,
                            initialTime: widget.docid.get('timeOn2'),
                          );
                          // if (newTimeOn2 != null) {
                          //   setState(() {
                          //     timeOn2 = newTimeOn2;
                          //   });
                          // }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  Column(
                    children: [
                      const SizedBox(height: 4),
                      FloatingActionButton.extended(
                        heroTag: "btn2Off",
                        icon: const Icon(Icons.access_time_outlined),
                        label: Text(timeOff2.toString()),
                        backgroundColor: const Color.fromARGB(255, 31, 182, 77),
                        onPressed: () async {
                          TimeOfDay? newTimeOff2 = await showTimePicker(
                            context: context,
                            initialTime: widget.docid.get('timeOff2'),
                          );
                          // if (newTimeOff2 != null) {
                          //   setState(() {
                          //     timeOff2 = newTimeOff2;
                          //   });
                          // }
                        },
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
                    child: TextField(
                      controller: name3,
                      maxLines: null,
                      keyboardType: TextInputType.text,
                      decoration: const InputDecoration(
                        hintText: 'Name',
                      ),
                    ),
                  ),
                  Column(
                    children: [
                      const SizedBox(height: 4),
                      FloatingActionButton.extended(
                        heroTag: "btn3On",
                        icon: const Icon(Icons.access_time_outlined),
                        label: Text(timeOn3.toString()),
                        backgroundColor: const Color.fromARGB(255, 31, 182, 77),
                        onPressed: () async {
                          TimeOfDay? newTimeOn3 = await showTimePicker(
                            context: context,
                            initialTime: widget.docid.get('timeOn3'),
                          );
                          // if (newTimeOn3 != null) {
                          //   setState(() {
                          //     timeOn3 = newTimeOn3;
                          //   });
                          // }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  Column(
                    children: [
                      const SizedBox(height: 4),
                      FloatingActionButton.extended(
                        heroTag: "btn3Off",
                        icon: const Icon(Icons.access_time_outlined),
                        label: Text(timeOff3.toString()),
                        backgroundColor: const Color.fromARGB(255, 31, 182, 77),
                        onPressed: () async {
                          TimeOfDay? newTimeOff3 = await showTimePicker(
                            context: context,
                            initialTime: widget.docid.get('timeOff3'),
                          );
                          // if (newTimeOff3 != null) {
                          //   setState(() {
                          //     timeOff3 = newTimeOff3;
                          //   });
                          // }
                        },
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
                    child: TextField(
                      controller: name4,
                      maxLines: null,
                      keyboardType: TextInputType.text,
                      decoration: const InputDecoration(
                        hintText: 'Name',
                      ),
                    ),
                  ),
                  Column(
                    children: [
                      const SizedBox(height: 4),
                      FloatingActionButton.extended(
                        heroTag: "btn4On",
                        icon: const Icon(Icons.access_time_outlined),
                        label: Text(timeOn4.toString()),
                        backgroundColor: const Color.fromARGB(255, 31, 182, 77),
                        onPressed: () async {
                          TimeOfDay? newTimeOn4 = await showTimePicker(
                            context: context,
                            initialTime: widget.docid.get('timeOn4'),
                          );
                          // if (newTimeOn4 != null) {
                          //   setState(() {
                          //     timeOn4 = newTimeOn4;
                          //   });
                          // }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  Column(
                    children: [
                      const SizedBox(height: 4),
                      FloatingActionButton.extended(
                        heroTag: "btn4Off",
                        icon: const Icon(Icons.access_time_outlined),
                        label: Text(timeOff4.toString()),
                        backgroundColor: const Color.fromARGB(255, 31, 182, 77),
                        onPressed: () async {
                          TimeOfDay? newTimeOff4 = await showTimePicker(
                            context: context,
                            initialTime: widget.docid.get('timeOff4'),
                          );
                          // if (newTimeOff4 != null) {
                          //   setState(() {
                          //     timeOff4 = newTimeOff4;
                          //   });
                          // }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
