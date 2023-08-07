import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  late Stream<DocumentSnapshot> reportStream;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing data
    _siteNameController.text = widget.docid["info"]["siteName"];
    _addressController.text = widget.docid["info"]["address"];
    _dateController.text = widget.docid["info"]["date"];
    reportStream = widget.docid.reference.snapshots();
    // ... initialize other controllers
  }

  // Implement the logic to update and save data to the database
  void updateReport() {
  // Get edited values from controllers
  String updatedName = _siteNameController.text;
  String updatedAddress = _addressController.text;
  String updatedDate = _dateController.text;
  // ... get updated values for other fields

  // Update Firestore document with new values
  widget.docid.reference.update({
    "info": {
      'siteName': updatedName,
      'date': updatedDate,
      'address': updatedAddress,
    },
    // ... update other fields
  }).then((_) {
    // Data updated successfully, navigate back
    Navigator.pop(context);
  }).catchError((error) {
    // Handle error if necessary
    print("Error updating data: $error");
  });
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Report'),
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
          String siteName = data["info"]["siteName"];
          String address = data["info"]["address"];
          String date = data["info"]["date"];

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextFormField(
                    controller: _siteNameController..text = siteName,
                    decoration: InputDecoration(labelText: 'Name'),
                  ),
                  TextFormField(
                    controller: _addressController..text = address,
                    decoration: InputDecoration(labelText: 'Address'),
                  ),
                  TextFormField(
                    controller: _dateController..text = date,
                    decoration: InputDecoration(labelText: 'Date'),
                  ),
                  // ... add form fields for other data
                  ElevatedButton(
                    onPressed: updateReport,
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
