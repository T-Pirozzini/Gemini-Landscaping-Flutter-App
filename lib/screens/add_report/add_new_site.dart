import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AddNewSiteComponent extends StatefulWidget {
  final User currentUser;
  final VoidCallback onSiteAdded;
  const AddNewSiteComponent(
      {super.key, required this.currentUser, required this.onSiteAdded});

  @override
  State<AddNewSiteComponent> createState() => _AddNewSiteComponentState();
}

class _AddNewSiteComponentState extends State<AddNewSiteComponent> {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'Add a New Site',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                                    width:
                                        MediaQuery.of(context).size.width * .6,
                                    child: TextField(
                                      controller: nameController,
                                      decoration: InputDecoration(
                                        border: OutlineInputBorder(),
                                        labelText: 'Site Name',
                                        focusedBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                              color: Colors.green, width: 2.0),
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 5),
                                  Container(
                                    width:
                                        MediaQuery.of(context).size.width * .8,
                                    child: TextField(
                                      controller: addressController,
                                      decoration: InputDecoration(
                                        border: OutlineInputBorder(),
                                        labelText: 'Address',
                                        focusedBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                              color: Colors.green, width: 2.0),
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
                                  CollectionReference siteCollection =
                                      FirebaseFirestore.instance
                                          .collection('SiteList');

                                  // Create a new document and set its data
                                  await siteCollection.add({
                                    'name': nameController.text,
                                    'address': addressController.text,
                                    'management': "",
                                    'imageUrl': "",
                                    'status': true,
                                    'addedBy': widget.currentUser.email,
                                  });

                                  // Clear the text fields
                                  nameController.clear();
                                  addressController.clear();

                                  // Notify the parent widget to refresh the site list
                                  widget.onSiteAdded();

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
    );
  }
}
