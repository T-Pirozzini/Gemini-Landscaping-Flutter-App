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
  @override
  State<AddReport> createState() => _AddReportState();
}

class _AddReportState extends State<AddReport> {
  TextEditingController dateController = TextEditingController();

  TextEditingController siteName = TextEditingController();

  TextEditingController team1 = TextEditingController();

  TextEditingController team2 = TextEditingController();

  TextEditingController team3 = TextEditingController();

  TextEditingController team4 = TextEditingController();

  TextEditingController timeOn1temp = TextEditingController();

  TextEditingController timeOff1temp = TextEditingController();

  TextEditingController timeOn2 = TextEditingController();

  TextEditingController timeOff2 = TextEditingController();

  TextEditingController timeOn3 = TextEditingController();

  TextEditingController timeOff3 = TextEditingController();

  TextEditingController timeOn4 = TextEditingController();

  TextEditingController timeOff4 = TextEditingController();

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

  var temp1 = 1;
  var temp2 = 2;

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
                'team1': team1.text,
                'team2': team1.text,
                'team3': team1.text,
                'team4': team1.text,
                'timeOn1temp': temp1,
                'timeOff1temp': temp2,
                'timeOn2': timeOn2.text,
                'timeOff2': timeOff2.text,
                'timeOn3': timeOn3.text,
                'timeOff3': timeOff3.text,
                'timeOn4': timeOn4.text,
                'timeOff4': timeOff4.text,
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
              Container(
                decoration: BoxDecoration(border: Border.all()),
                child: TextField(
                  controller: team1,
                  maxLines: null,
                  keyboardType: TextInputType.text,
                  decoration: const InputDecoration(
                    hintText: 'Enter crew leader name',
                  ),
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  FloatingActionButton.extended(
                    heroTag: "btn1On",
                    icon: const Icon(Icons.access_time_outlined),
                    label: Text(
                        'ON - ${timeOn1!.hour.toString()}:${timeOn1!.minute.toString()}'),
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
                  FloatingActionButton.extended(
                    heroTag: "btn1Off",
                    icon: const Icon(Icons.access_time_outlined),
                    label: Text(
                        'OFF - ${timeOff1!.hour.toString()}:${timeOff1!.minute.toString()}'),
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
              Container(
                decoration: BoxDecoration(border: Border.all()),
                child: TextField(
                  controller: timeOn1temp,
                  maxLines: null,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: 'Enter time On',
                  ),
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              Container(
                decoration: BoxDecoration(border: Border.all()),
                child: TextField(
                  controller: timeOff1temp,
                  maxLines: null,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: 'Enter time Off',
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(border: Border.all()),
                child: TextField(
                  controller: team2,
                  maxLines: null,
                  keyboardType: TextInputType.text,
                  decoration: const InputDecoration(
                    hintText: 'Enter name',
                  ),
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              Container(
                decoration: BoxDecoration(border: Border.all()),
                child: TextField(
                  controller: timeOn2,
                  maxLines: null,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: 'Enter time On',
                  ),
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              Container(
                decoration: BoxDecoration(border: Border.all()),
                child: TextField(
                  controller: timeOff2,
                  maxLines: null,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: 'Enter time Off',
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(border: Border.all()),
                child: TextField(
                  controller: team3,
                  maxLines: null,
                  keyboardType: TextInputType.text,
                  decoration: const InputDecoration(
                    hintText: 'Enter name',
                  ),
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              Container(
                decoration: BoxDecoration(border: Border.all()),
                child: TextField(
                  controller: timeOn3,
                  maxLines: null,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: 'Enter time On',
                  ),
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              Container(
                decoration: BoxDecoration(border: Border.all()),
                child: TextField(
                  controller: timeOff3,
                  maxLines: null,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: 'Enter time Off',
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(border: Border.all()),
                child: TextField(
                  controller: team4,
                  maxLines: null,
                  keyboardType: TextInputType.text,
                  decoration: const InputDecoration(
                    hintText: 'Enter name',
                  ),
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              Container(
                decoration: BoxDecoration(border: Border.all()),
                child: TextField(
                  controller: timeOn4,
                  maxLines: null,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: 'Enter time On',
                  ),
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              Container(
                decoration: BoxDecoration(border: Border.all()),
                child: TextField(
                  controller: timeOff4,
                  maxLines: null,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: 'Enter time Off',
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
