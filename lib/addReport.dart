import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'main.dart';

List<String> siteList = [
  'Merewood Apartments',
  'Uplands Terrace',
  'North Point Apartments',
  'Country Grocer'
];

class AddReport extends StatefulWidget {
  const AddReport({super.key});
  
  @override
  State<AddReport> createState() => _AddReportState();
}

class _AddReportState extends State<AddReport> {
  TextEditingController dateController = TextEditingController();

  TextEditingController siteName = TextEditingController();

  TextEditingController name1 = TextEditingController();

  TextEditingController name2 = TextEditingController();

  TextEditingController name3 = TextEditingController();

  TextEditingController name4 = TextEditingController();

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
              ref.add({
                'date': dateController.text,
                'siteName': dropdownValue,
                'name1': name1.text,
                'name2': name2.text,
                'name3': name3.text,
                'name4': name4.text,
                'timeOn1':
                    timeOn1!.hour.toString() + ':' + timeOn1!.minute.toString(),
                'timeOff1': timeOff1!.hour.toString() +
                    ':' +
                    timeOff1!.minute.toString(),
                'timeOn2':
                    timeOn2!.hour.toString() + ':' + timeOn2!.minute.toString(),
                'timeOff2': timeOff2!.hour.toString() +
                    ':' +
                    timeOff2!.minute.toString(),
                'timeOn3':
                    timeOn3!.hour.toString() + ':' + timeOn3!.minute.toString(),
                'timeOff3': timeOff3!.hour.toString() +
                    ':' +
                    timeOff3!.minute.toString(),
                'timeOn4':
                    timeOn4!.hour.toString() + ':' + timeOn4!.minute.toString(),
                'timeOff4': timeOff4!.hour.toString() +
                    ':' +
                    timeOff4!.minute.toString(),
              }).whenComplete(() {
                Navigator.pushReplacement(
                    context, MaterialPageRoute(builder: (_) => Home()));
              });
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
              Container(
                decoration: BoxDecoration(border: Border.all()),
                child: TextField(
                  controller: dateController,
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
                        label: Text(
                            '${timeOn1!.hour.toString()}:${timeOn1!.minute.toString()}'),
                        backgroundColor: const Color.fromARGB(255, 31, 182, 77),
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
                        label: Text(
                            '${timeOff1!.hour.toString()}:${timeOff1!.minute.toString()}'),
                        backgroundColor: const Color.fromARGB(255, 31, 182, 77),
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
                        label: Text(
                            '${timeOn2!.hour.toString()}:${timeOn2!.minute.toString()}'),
                        backgroundColor: const Color.fromARGB(255, 31, 182, 77),
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
                        label: Text(
                            '${timeOff2!.hour.toString()}:${timeOff2!.minute.toString()}'),
                        backgroundColor: const Color.fromARGB(255, 31, 182, 77),
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
                        label: Text(
                            '${timeOn3!.hour.toString()}:${timeOn3!.minute.toString()}'),
                        backgroundColor: const Color.fromARGB(255, 31, 182, 77),
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
                        label: Text(
                            '${timeOff3!.hour.toString()}:${timeOff3!.minute.toString()}'),
                        backgroundColor: const Color.fromARGB(255, 31, 182, 77),
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
                        label: Text(
                            '${timeOn4!.hour.toString()}:${timeOn4!.minute.toString()}'),
                        backgroundColor: const Color.fromARGB(255, 31, 182, 77),
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
                        label: Text(
                            '${timeOff4!.hour.toString()}:${timeOff4!.minute.toString()}'),
                        backgroundColor: const Color.fromARGB(255, 31, 182, 77),
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
