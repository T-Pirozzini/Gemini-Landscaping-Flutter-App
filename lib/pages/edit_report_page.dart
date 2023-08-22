import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

class EditReport extends StatefulWidget {
  final DocumentSnapshot docid;

  EditReport({required this.docid});

  @override
  _EditReportState createState() => _EditReportState();
}

class _EditReportState extends State<EditReport> {
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

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing data
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
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: updateReport,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white, backgroundColor: const Color.fromARGB(255, 31, 182, 77),
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
