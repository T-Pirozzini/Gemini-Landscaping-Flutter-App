import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gemini_landscaping_app/providers/management_company_provider.dart';

class AddNewSiteComponent extends ConsumerStatefulWidget {
  final User currentUser;
  final VoidCallback onSiteAdded;
  const AddNewSiteComponent(
      {super.key, required this.currentUser, required this.onSiteAdded});

  @override
  ConsumerState<AddNewSiteComponent> createState() =>
      _AddNewSiteComponentState();
}

class _AddNewSiteComponentState extends ConsumerState<AddNewSiteComponent> {
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
            String selectedManagement = '';

            final companiesAsync =
                ref.read(managementCompaniesStreamProvider);
            final companyNames = <String>[''];
            companiesAsync.whenData((companies) {
              companyNames.addAll(companies.map((c) => c.name));
            });

            showModalBottomSheet(
              isScrollControlled: true,
              context: context,
              builder: (BuildContext sheetContext) {
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
                                  SizedBox(height: 5),
                                  Container(
                                    width:
                                        MediaQuery.of(context).size.width * .8,
                                    child: DropdownButtonFormField<String>(
                                      value: selectedManagement,
                                      decoration: InputDecoration(
                                        labelText: 'Management Company',
                                        border: OutlineInputBorder(),
                                        focusedBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                              color: Colors.green, width: 2.0),
                                        ),
                                      ),
                                      items: companyNames.map((name) {
                                        return DropdownMenuItem(
                                          value: name,
                                          child: Text(
                                            name.isEmpty ? 'None' : name,
                                            style: GoogleFonts.montserrat(
                                                fontSize: 14),
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (value) {
                                        setState(() =>
                                            selectedManagement = value ?? '');
                                      },
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

                                  DocumentReference docRef =
                                      await siteCollection.add({
                                    'name': nameController.text,
                                    'address': addressController.text,
                                    'management': selectedManagement,
                                    'imageUrl': "",
                                    'status': true,
                                    'addedBy': widget.currentUser.email,
                                    'target': 1000,
                                  });

                                  await docRef.update({'id': docRef.id});

                                  nameController.clear();
                                  addressController.clear();

                                  widget.onSiteAdded();
                                  Navigator.pop(sheetContext);
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
