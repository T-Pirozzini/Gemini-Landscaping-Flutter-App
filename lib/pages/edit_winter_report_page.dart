import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

class EditWinterReport extends StatefulWidget {
  final DocumentSnapshot docid;

  EditWinterReport({required this.docid});

  @override
  _EditWinterReportState createState() => _EditWinterReportState();
}

class _EditWinterReportState extends State<EditWinterReport> {
  bool iceManagement = false;
  bool snowRemoval = false;
  double meltSliderValue = 0.0;
  double saltSliderValue = 0.0;
  double sandSliderValue = 0.0;
  TextEditingController _dateController = TextEditingController();
  TextEditingController _siteNameController = TextEditingController();
  TextEditingController _addressController = TextEditingController();
  TextEditingController _name1Controller = TextEditingController();
  TextEditingController _timeOn1Controller = TextEditingController();
  TextEditingController _timeOff1Controller = TextEditingController();

  TextEditingController _name2Controller = TextEditingController();
  TextEditingController _timeOn2Controller = TextEditingController();
  TextEditingController _timeOff2Controller = TextEditingController();

  TextEditingController _name3Controller = TextEditingController();
  TextEditingController _timeOn3Controller = TextEditingController();
  TextEditingController _timeOff3Controller = TextEditingController();

  TextEditingController _name4Controller = TextEditingController();
  TextEditingController _timeOn4Controller = TextEditingController();
  TextEditingController _timeOff4Controller = TextEditingController();

  TextEditingController _descriptionController = TextEditingController();
  late Stream<DocumentSnapshot> reportStream;

  List<bool> isServiceSelected = [false, false];
  List<String> walkwaysServices = [];
  List<String> liabilityServices = [];
  List<String> otherServices = [];

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing data
    isServiceSelected[0] = widget.docid["service"]["iceManagement"];
    isServiceSelected[1] = widget.docid["service"]["snowRemoval"];
    iceManagement = widget.docid["service"]["iceManagement"];
    snowRemoval = widget.docid["service"]["snowRemoval"];
    _siteNameController.text = widget.docid["info"]["siteName"];
    _addressController.text = widget.docid["info"]["address"];
    _dateController.text = widget.docid["info"]["date"];
    _name1Controller.text = widget.docid["names"]["name1"];
    _timeOn1Controller.text = widget.docid["times"]["timeOn1"];
    _timeOff1Controller.text = widget.docid["times"]["timeOff1"];
    _name2Controller.text = widget.docid["names"]["name2"];
    _timeOn2Controller.text = widget.docid["times"]["timeOn2"];
    _timeOff2Controller.text = widget.docid["times"]["timeOff2"];
    _name3Controller.text = widget.docid["names"]["name3"];
    _timeOn3Controller.text = widget.docid["times"]["timeOn3"];
    _timeOff3Controller.text = widget.docid["times"]["timeOff3"];
    _name4Controller.text = widget.docid["names"]["name4"];
    _timeOn4Controller.text = widget.docid["times"]["timeOn4"];
    _timeOff4Controller.text = widget.docid["times"]["timeOff4"];
    _descriptionController.text = widget.docid["description"];
    meltSliderValue = widget.docid["material"]["iceMelt"] ?? 0.0;
    saltSliderValue = widget.docid["material"]["salt"] ?? 0.0;
    sandSliderValue = widget.docid["material"]["sand"] ?? 0.0;
    if (widget.docid["service"] != null) {
      if (widget.docid["service"].containsKey("walkways")) {
        walkwaysServices =
            List<String>.from(widget.docid["service"]["walkways"]);
      }
      if (widget.docid["service"].containsKey("liability")) {
        liabilityServices =
            List<String>.from(widget.docid["service"]["liability"]);
      }
      if (widget.docid["service"].containsKey("other")) {
        otherServices = List<String>.from(widget.docid["service"]["other"]);
      }
    }

    reportStream = widget.docid.reference.snapshots();
  }

  // Implement the logic to update and save data to the database
  void updateReport() {
    // Get edited values from controllers
    String updatedName = _siteNameController.text;
    String updatedAddress = _addressController.text;
    String updatedDate = _dateController.text;
    String updatedName1 = _name1Controller.text;
    String updatedTimeOn1 = _timeOn1Controller.text;
    String updatedTimeOff1 = _timeOff1Controller.text;
    String updatedName2 = _name2Controller.text;
    String updatedTimeOn2 = _timeOn2Controller.text;
    String updatedTimeOff2 = _timeOff2Controller.text;
    String updatedName3 = _name3Controller.text;
    String updatedTimeOn3 = _timeOn3Controller.text;
    String updatedTimeOff3 = _timeOff3Controller.text;
    String updatedName4 = _name4Controller.text;
    String updatedTimeOn4 = _timeOn4Controller.text;
    String updatedTimeOff4 = _timeOff4Controller.text;
    String updatedDescription = _descriptionController.text;
    double updatedIceMelt = meltSliderValue;
    double updatedSalt = saltSliderValue;
    double updatedSand = sandSliderValue;

    // Update Firestore document with new values
    widget.docid.reference.update({
      "info": {
        'siteName': updatedName,
        'date': updatedDate,
        'address': updatedAddress,
      },
      "names": {
        'name1': updatedName1,
        'name2': updatedName2,
        'name3': updatedName3,
        'name4': updatedName4,
      },
      "times": {
        'timeOn1': updatedTimeOn1,
        'timeOff1': updatedTimeOff1,
        'timeOn2': updatedTimeOn2,
        'timeOff2': updatedTimeOff2,
        'timeOn3': updatedTimeOn3,
        'timeOff3': updatedTimeOff3,
        'timeOn4': updatedTimeOn4,
        'timeOff4': updatedTimeOff4,
      },
      "description": updatedDescription,
      "material": {
        'iceMelt': updatedIceMelt,
        'salt': updatedSalt,
        'sand': updatedSand,
      },
      "service": {
        "iceManagement": isServiceSelected[0],
        "snowRemoval": isServiceSelected[1],
        "walkways": walkwaysServices,
        "liability": liabilityServices,
        "other": otherServices,
      },
    }).then((_) {
      Navigator.pop(context);
    }).catchError((error) {
      print("Error updating data: $error");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 31, 182, 77),
        title: Text('Edit Report'),
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
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: reportStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator();
          }

          if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          }

          // Get the updated data from the snapshot
          Map<String, dynamic> data =
              snapshot.data!.data() as Map<String, dynamic>;

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextFormField(
                    controller: _siteNameController
                      ..text = data["info"]["siteName"],
                    decoration: InputDecoration(labelText: 'Site Name'),
                  ),
                  TextFormField(
                    controller: _addressController
                      ..text = data["info"]["address"],
                    decoration: InputDecoration(labelText: 'Address'),
                  ),
                  TextFormField(
                    controller: _dateController..text = data["info"]["date"],
                    decoration: InputDecoration(labelText: 'Date'),
                  ),
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
                            buttonIndex < isServiceSelected.length;
                            buttonIndex++) {
                          if (buttonIndex == index) {
                            isServiceSelected[buttonIndex] = true;
                          } else {
                            isServiceSelected[buttonIndex] = false;
                          }
                        }
                      });
                    },
                    isSelected: isServiceSelected,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _name1Controller,
                          decoration: InputDecoration(labelText: 'Name#1'),
                        ),
                      ),
                      Expanded(
                        child: TextFormField(
                          controller: _timeOn1Controller,
                          decoration: InputDecoration(labelText: 'Time On'),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(
                                r'[0-9:]')), // Allow only digits and colons
                            LengthLimitingTextInputFormatter(
                                5), // Limit input length to 5 characters (e.g., 00:00)
                          ],
                        ),
                      ),
                      Expanded(
                        child: TextFormField(
                          controller: _timeOff1Controller,
                          decoration: InputDecoration(labelText: 'Time Off'),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9:]')),
                            LengthLimitingTextInputFormatter(5),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _name2Controller,
                          decoration: InputDecoration(labelText: 'Name#2'),
                        ),
                      ),
                      Expanded(
                        child: TextFormField(
                          controller: _timeOn2Controller,
                          decoration: InputDecoration(labelText: 'Time On'),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9:]')),
                            LengthLimitingTextInputFormatter(5),
                          ],
                        ),
                      ),
                      Expanded(
                        child: TextFormField(
                          controller: _timeOff2Controller,
                          decoration: InputDecoration(labelText: 'Time Off'),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9:]')),
                            LengthLimitingTextInputFormatter(5),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _name3Controller,
                          decoration: InputDecoration(labelText: 'Name#3'),
                        ),
                      ),
                      Expanded(
                        child: TextFormField(
                          controller: _timeOn3Controller,
                          decoration: InputDecoration(labelText: 'Time On'),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9:]')),
                            LengthLimitingTextInputFormatter(5),
                          ],
                        ),
                      ),
                      Expanded(
                        child: TextFormField(
                          controller: _timeOff3Controller,
                          decoration: InputDecoration(labelText: 'Time Off'),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9:]')),
                            LengthLimitingTextInputFormatter(5),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _name4Controller,
                          decoration: InputDecoration(labelText: 'Name#4'),
                        ),
                      ),
                      Expanded(
                        child: TextFormField(
                          controller: _timeOn4Controller,
                          decoration: InputDecoration(labelText: 'Time On'),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9:]')),
                            LengthLimitingTextInputFormatter(5),
                          ],
                        ),
                      ),
                      Expanded(
                        child: TextFormField(
                          controller: _timeOff4Controller,
                          decoration: InputDecoration(labelText: 'Time Off'),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9:]')),
                            LengthLimitingTextInputFormatter(5),
                          ],
                        ),
                      ),
                    ],
                  ),
                  TextFormField(
                    controller: _descriptionController
                      ..text = data["description"],
                    decoration: InputDecoration(labelText: 'Description'),
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
                  SizedBox(height: 15),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Walkways Services:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      ...walkwaysServices
                          .map((service) => Text(service))
                          .toList(),
                      SizedBox(height: 10),
                      Text(
                        'Liability Services:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      ...liabilityServices
                          .map((service) => Text(service))
                          .toList(),
                      SizedBox(height: 10),
                      Text(
                        'Other Services:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      ...otherServices.map((service) => Text(service)).toList(),
                    ],
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: updateReport,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: const Color.fromARGB(255, 31, 182, 77),
                    ),
                    child: Text('Save'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
