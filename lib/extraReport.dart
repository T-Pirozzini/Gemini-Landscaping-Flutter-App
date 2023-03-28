import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gemini_landscaping_app/pages/home_page.dart';
import 'package:intl/intl.dart';

class ExtraReport extends StatefulWidget {
  const ExtraReport({super.key});

  @override
  State<ExtraReport> createState() => _ExtraReportState();
}

class _ExtraReportState extends State<ExtraReport> {
  TextEditingController dateController = TextEditingController();
  TextEditingController _siteNameController = TextEditingController();
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

  CollectionReference extraReportRef =
      FirebaseFirestore.instance.collection('SiteReports2023');

  void _submitForm() {
    extraReportRef.add({
      "info": {
        'date': dateController.text,
        'siteName': _siteNameController.text,
        'address': _addressController.text,
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
    }).whenComplete(() {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => Home()));
    });
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

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    width: 250,
                    height: 50,
                    child: TextField(
                      controller: _siteNameController,
                      maxLines: null,
                      keyboardType: TextInputType.text,
                      decoration: const InputDecoration(
                        hintText: 'Site Name',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    width: 350,
                    height: 50,
                    child: TextField(
                      controller: _addressController,
                      maxLines: null,
                      keyboardType: TextInputType.text,
                      decoration: InputDecoration(
                        hintText: 'Address',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
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
              const SizedBox(height: 15),
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
              SizedBox(height: 20),
              Table(
                border: TableBorder.all(
                  color: Color.fromARGB(255, 31, 182, 77),
                ),
                children: [
                  TableRow(
                    children: [
                      Center(
                        child: Text(
                          'MATERIALS',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                      Center(
                        child: Text('VENDOR',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                      Center(
                        child: Text('AMOUNT',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                    ],
                  ),
                  TableRow(
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: TextField(
                          controller: _materialController1,
                          maxLines: null,
                          keyboardType: TextInputType.text,
                          decoration: InputDecoration(
                            hintText: 'Item #1',
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: TextField(
                          controller: _vendorController1,
                          maxLines: null,
                          keyboardType: TextInputType.text,
                          decoration: InputDecoration(
                            hintText: 'Vendor',
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: TextField(
                          controller: _amountController1,
                          maxLines: null,
                          keyboardType: TextInputType.text,
                          decoration: InputDecoration(
                            hintText: 'Amount',
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                  TableRow(
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: TextField(
                          controller: _materialController2,
                          maxLines: null,
                          keyboardType: TextInputType.text,
                          decoration: InputDecoration(
                            hintText: 'Item #2',
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: TextField(
                          controller: _vendorController2,
                          maxLines: null,
                          keyboardType: TextInputType.text,
                          decoration: InputDecoration(
                            hintText: 'Vendor',
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: TextField(
                          controller: _amountController2,
                          maxLines: null,
                          keyboardType: TextInputType.text,
                          decoration: InputDecoration(
                            hintText: 'Amount',
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                  TableRow(
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: TextField(
                          controller: _materialController3,
                          maxLines: null,
                          keyboardType: TextInputType.text,
                          decoration: InputDecoration(
                            hintText: 'Item #3',
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: TextField(
                          controller: _vendorController3,
                          maxLines: null,
                          keyboardType: TextInputType.text,
                          decoration: InputDecoration(
                            hintText: 'Vendor',
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: TextField(
                          controller: _amountController3,
                          maxLines: null,
                          keyboardType: TextInputType.text,
                          decoration: InputDecoration(
                            hintText: 'Amount',
                            border: InputBorder.none,
                          ),
                        ),
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
