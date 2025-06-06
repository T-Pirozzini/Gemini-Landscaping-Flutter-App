import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gemini_landscaping_app/models/equipment_model.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class EquipmentPage extends StatefulWidget {
  const EquipmentPage({super.key});

  @override
  State<EquipmentPage> createState() => _EquipmentPageState();
}

// Add this enum for priority options
enum Priority { low, medium, high }

class _EquipmentPageState extends State<EquipmentPage> {
  String priority = 'low';
  String dropdownValue = 'Truck';

  @override
  Widget build(BuildContext context) {
    // Firestore collection reference
    CollectionReference equipmentCollection =
        FirebaseFirestore.instance.collection('equipment');

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.grey.shade200,
      appBar: AppBar(
        title: Text("Report Equipment Damage",
            style: GoogleFonts.montserrat(
                fontSize: 18,
                color: Colors.black,
                fontWeight: FontWeight.w500)),
        toolbarHeight: 25,
        backgroundColor: Colors.green.shade100,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          SizedBox(height: 10),
          Text('How To: Tap green "+" to add a repair report.',
              style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic)),
          Text(' Set the priority level and submit.',
              style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic)),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: equipmentCollection.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                }

                List<Equipment> equipmentList =
                    snapshot.data!.docs.map((document) {
                  Map<String, dynamic> data =
                      document.data() as Map<String, dynamic>;
                  return Equipment(
                    id: document.id,
                    name: data['name'] ?? '',
                    year: data['year'] ?? 0,
                    equipmentType: data['equipmentType'] ?? '',
                    serialNumber: data['serialNumber'] ?? '',
                    color: Color(data['color'] as int? ?? Colors.blue.value),
                  );
                }).toList();

                List<QueryDocumentSnapshot> documents = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: documents.length,
                  itemBuilder: (context, index) {
                    Equipment equipment = equipmentList[index];
                    QueryDocumentSnapshot document = documents[index];

                    String mostExtremePriority = 'resolved';

                    return FutureBuilder<QuerySnapshot>(
                      future:
                          document.reference.collection('repair_entries').get(),
                      builder: (BuildContext context,
                          AsyncSnapshot<QuerySnapshot> entrySnapshot) {
                        if (entrySnapshot.hasData) {
                          // Iterate through the repair entries to find the most extreme priority
                          for (QueryDocumentSnapshot entry
                              in entrySnapshot.data!.docs) {
                            Map<String, dynamic> entryData =
                                entry.data() as Map<String, dynamic>;
                            String entryPriority =
                                entryData['priority'] ?? 'resolved';

                            // Update the most extreme priority if the current entryPriority is higher
                            if (entryPriority == 'high') {
                              mostExtremePriority = 'high';
                              break; // No need to check further
                            } else if (entryPriority == 'medium' &&
                                mostExtremePriority != 'high') {
                              mostExtremePriority = 'medium';
                            } else if (entryPriority == 'low' &&
                                mostExtremePriority != 'high' &&
                                mostExtremePriority != 'medium') {
                              mostExtremePriority = 'low';
                            }
                          }
                        }

                        Color borderColor;

                        switch (mostExtremePriority) {
                          case 'low':
                            borderColor = Colors.yellow;
                            break;
                          case 'medium':
                            borderColor = Colors.orange;
                            break;
                          case 'high':
                            borderColor = Colors.red;
                            break;
                          default:
                            borderColor = Colors.grey;
                            break;
                        }

                        return Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: borderColor, width: 2),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          margin: EdgeInsets.all(5),
                          child: InkWell(
                            onTap: () {
                              // Open dialog with a list of dated repair entries log
                              _showRepairEntriesDialog(
                                  context, equipment.name, document.id);
                            },
                            child: ListTile(
                              tileColor: Colors.white,
                              title: Text(
                                equipment.name,
                                style: TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Year: ${equipment.year}',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  Text(
                                    'ID: ${equipment.serialNumber}',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                              leading:
                                  _getEquipmentIcon(equipment.equipmentType),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    children: [
                                      Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Report',
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.green.shade200),
                                          ),
                                          Text('Damage:',
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color:
                                                      Colors.green.shade200)),
                                        ],
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.add_box_outlined),
                                        color: Colors.green.shade200,
                                        iconSize: 28,
                                        onPressed: () {
                                          _addRepairReport(
                                              context,
                                              equipment.name,
                                              document.id,
                                              priority);
                                        },
                                      ),
                                    ],
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.edit),
                                    color: Colors.grey.shade600,
                                    iconSize: 18,
                                    onPressed: () {
                                      _editEquipment(
                                        context,
                                        equipment.name,
                                        equipment.year,
                                        equipment.serialNumber,
                                        equipment.equipmentType,
                                        document.id,
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete),
                                    color: Colors.grey,
                                    iconSize: 18,
                                    onPressed: () {
                                      if (FirebaseAuth
                                                  .instance.currentUser?.uid ==
                                              "5wwYztIxTifV0EQk3N7dfXsY0jm1" ||
                                          FirebaseAuth
                                                  .instance.currentUser?.uid ==
                                              "4Qpgb3aORKhUVXjgT2SNh6zgCWE3") {
                                        _deleteEquipment(
                                            context,
                                            equipment.name,
                                            document.id,
                                            FirebaseAuth
                                                .instance.currentUser!.uid);
                                      } else {
                                        showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return AlertDialog(
                                              title: Text('Error'),
                                              content: Text(
                                                  'You do not have permission to delete equipment'),
                                              actions: [
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.of(context).pop();
                                                  },
                                                  child: Text('OK'),
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text('Tap on the equipment to view the repair log.',
                style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic)),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.black45,
        mini: true,
        shape: ShapeBorder.lerp(RoundedRectangleBorder(), CircleBorder(), 0.5),
        onPressed: () {
          TextEditingController nameController = TextEditingController();
          TextEditingController yearController = TextEditingController();
          TextEditingController serialNumberController =
              TextEditingController();

          showModalBottomSheet(
            isScrollControlled: true,
            context: context,
            builder: (BuildContext context) {
              return StatefulBuilder(
                builder: (BuildContext context, StateSetter setState) {
                  return SingleChildScrollView(
                    child: Container(
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).viewInsets.bottom,
                      ),
                      height: 600,
                      child: Padding(
                        padding: const EdgeInsets.all(18.0),
                        child: Column(
                          children: [
                            Text(
                              'Equipment/Vehicle Information',
                              style: TextStyle(
                                  fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Container(
                                  width: 150,
                                  child: TextField(
                                    controller: nameController,
                                    decoration: InputDecoration(
                                      labelText: 'Name',
                                    ),
                                  ),
                                ),
                                SizedBox(width: 10),
                                Container(
                                  width: 80,
                                  child: TextField(
                                    controller: yearController,
                                    decoration: InputDecoration(
                                      labelText: 'Year',
                                    ),
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                SizedBox(
                                  width: 150,
                                  child: TextField(
                                    controller: serialNumberController,
                                    decoration: InputDecoration(
                                      labelText: 'ID Number',
                                    ),
                                  ),
                                ),
                                DropdownButton<String>(
                                  value: dropdownValue,
                                  hint: Text(
                                    'Select Equipment',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                  items: <String>[
                                    'Truck',
                                    'Trailer',
                                    'Mower (push)',
                                    'Mower (ride-on)',
                                    'Blower',
                                    'Trimmer',
                                    'Hedger',
                                    'Edger',
                                    'Tool (other)',
                                    'Machine (other)',
                                    'Vehicle (other)',
                                  ].map((String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value),
                                    );
                                  }).toList(),
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      dropdownValue = newValue!;
                                    });
                                  },
                                ),
                              ],
                            ),
                            SizedBox(height: 20),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  backgroundColor: Colors.black45,
                                  textStyle: TextStyle(fontSize: 18)),
                              onPressed: () async {
                                CollectionReference equipmentCollection =
                                    FirebaseFirestore.instance
                                        .collection('equipment');

                                // Validate and parse the year input
                                int? year;
                                if (yearController.text.isNotEmpty) {
                                  year = int.tryParse(yearController.text);
                                  if (year == null) {
                                    // Show an error message or handle the validation failure
                                    print('Invalid year input');
                                    return;
                                  }
                                }

                                // Create a new document and set its data
                                await equipmentCollection.add({
                                  'name': nameController.text,
                                  'year': year,
                                  'serialNumber': serialNumberController.text,
                                  'equipmentType': dropdownValue,
                                });

                                // Close the bottom sheet after adding equipment
                                Navigator.pop(context);
                              },
                              child: Text('Add New Equipment'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }

// Function to show the dialog with a list of dated repair entries log
  void _showRepairEntriesDialog(
      BuildContext context, String equipmentName, String documentId) {
    // Firestore collection reference for repair entries
    CollectionReference repairEntriesCollection = FirebaseFirestore.instance
        .collection('equipment')
        .doc(documentId)
        .collection('repair_entries');
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Repair Entries: $equipmentName'),
          content: Container(
            width: double.maxFinite,
            height: 400,
            child: SingleChildScrollView(
              child: StreamBuilder<QuerySnapshot>(
                // Fetch repair entries for the specific equipment
                stream: repairEntriesCollection
                    .orderBy('dateTime', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  }

                  List<QueryDocumentSnapshot> documents = snapshot.data!.docs;

                  return Column(
                    children: [
                      ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: documents.length,
                        itemBuilder: (context, index) {
                          Map<String, dynamic> data =
                              documents[index].data() as Map<String, dynamic>;
                          String description = data['description'] ?? '';
                          String dateTime = data['dateTime'] ?? '';
                          String priority = data['priority'] ?? 'low';

                          IconData iconData;
                          Color iconColor;

                          // Set the icon based on the priority value
                          switch (priority) {
                            case 'low':
                              iconData = Icons.error;
                              iconColor = Colors.yellow;
                              break;
                            case 'medium':
                              iconData = Icons.warning;
                              iconColor = Colors.orange;
                              break;
                            case 'high':
                              iconData = Icons.report;
                              iconColor = Colors.red;
                              break;
                            case 'resolved':
                              iconData = Icons.check_circle;
                              iconColor = Colors.green;
                              break;
                            default:
                              iconData = Icons.device_unknown;
                              iconColor = Colors.grey;
                          }

                          return ListTile(
                            title: Text(
                              '#${index + 1}: $dateTime',
                              style: TextStyle(
                                fontSize: 14,
                              ),
                            ),
                            subtitle: Text('$description'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  iconData,
                                  color: iconColor,
                                ),
                                SizedBox(width: 10),
                                if (priority != 'resolved')
                                  ElevatedButton(
                                    onPressed: () async {
                                      // Update the repair status to "resolved" in the database
                                      await repairEntriesCollection
                                          .doc(documents[index].id)
                                          .update({
                                        'priority': 'resolved',
                                      });
                                    },
                                    style: ElevatedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      backgroundColor: Colors.grey,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: Icon(Icons.check, size: 16),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                      SizedBox(height: 20),
                    ],
                  );
                },
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

// Function to add a repair report
  void _addRepairReport(BuildContext context, String equipmentName,
      String documentId, String priority) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        TextEditingController descriptionController = TextEditingController();
        DateTime currentDateTime = DateTime.now();
        String formattedDate =
            DateFormat('MMMM d, y (EEEE)').format(currentDateTime);
        String formattedTime = DateFormat('h:mm a').format(currentDateTime);

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Column(
                children: [
                  Text('Attention Required:'),
                  Text('$equipmentName'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Column(
                    children: [
                      Text('$formattedDate'),
                      Text('$formattedTime'),
                    ],
                  ),
                  SizedBox(height: 8),
                  TextField(
                    controller: descriptionController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 16),
                  // DropdownButton to select priority
                  DropdownButton<String>(
                    value: priority,
                    onChanged: (String? newValue) {
                      setState(() {
                        priority = newValue!;
                      });
                    },
                    items:
                        <String>['low', 'medium', 'high'].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Row(
                          children: [
                            Text('Priority: '),
                            Text(value),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    String description = descriptionController.text;
                    if (description.isNotEmpty) {
                      // Add the new repair entry to Firestore
                      await FirebaseFirestore.instance
                          .collection('equipment')
                          .doc(documentId)
                          .collection('repair_entries')
                          .add({
                        'dateTime': '$formattedDate @ $formattedTime',
                        'description': description,
                        'priority': priority,
                      });
                    }
                    Navigator.of(context).pop();
                  },
                  child: Text('Submit'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _editEquipment(context, String equipmentName, int equipmentYear,
      String equipmentSerialNum, String equipmentType, String documentId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        TextEditingController equipmentNameController =
            TextEditingController(text: equipmentName);
        TextEditingController equipmentYearController =
            TextEditingController(text: equipmentYear.toString());
        TextEditingController equipmentSerialNumController =
            TextEditingController(text: equipmentSerialNum);
        String dropdownValue = equipmentType;

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Text('Edit Equipment'),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(
                      controller: equipmentNameController,
                      decoration: InputDecoration(
                        labelText: 'Equipment Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: equipmentYearController,
                      decoration: InputDecoration(
                        labelText: 'Equipment Year',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: equipmentSerialNumController,
                      decoration: InputDecoration(
                        labelText: 'ID Number',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 16),
                    DropdownButton<String>(
                      value: dropdownValue,
                      hint: Text(
                        'Select Equipment Type',
                      ),
                      items: <String>[
                        'Truck',
                        'Trailer',
                        'Mower (push)',
                        'Mower (ride-on)',
                        'Blower',
                        'Trimmer',
                        'Hedger',
                        'Edger',
                        'Tool (other)',
                        'Machine (other)',
                        'Vehicle (other)',
                      ].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          dropdownValue = newValue!;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    String newEquipmentName = equipmentNameController.text;
                    if (newEquipmentName.isNotEmpty) {
                      // Update the equipment name in Firestore
                      await FirebaseFirestore.instance
                          .collection('equipment')
                          .doc(documentId)
                          .update({
                        'name': newEquipmentName,
                        'year': int.parse(equipmentYearController.text),
                        'serialNumber': equipmentSerialNumController.text,
                        'equipmentType': dropdownValue,
                      });
                    }
                    Navigator.of(context).pop();
                  },
                  child: Text('Submit'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _deleteEquipment(BuildContext context, String equipmentName,
      String documentId, String userId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Equipment', textAlign: TextAlign.center),
          content:
              Text('Are you sure you want to delete this equipment/vehicle?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            if (userId == "5wwYztIxTifV0EQk3N7dfXsY0jm1" ||
                userId == "4Qpgb3aORKhUVXjgT2SNh6zgCWE3")
              ElevatedButton(
                onPressed: () async {
                  // Delete the equipment from Firestore
                  await FirebaseFirestore.instance
                      .collection('equipment')
                      .doc(documentId)
                      .delete();
                  Navigator.of(context).pop();
                },
                child: Text('Delete'),
              ),
          ],
        );
      },
    );
  }

// Function to get the icon based on the type of equipment
  Widget _getEquipmentIcon(String equipment) {
    switch (equipment) {
      case "Mower (ride-on)":
        return Image.asset('assets/equipment/mower_small.png',
            width: 32, height: 32);
      case "Mower (push)":
        return Image.asset('assets/equipment/mower_large.png',
            width: 32, height: 32);
      case "Blower":
        return Image.asset('assets/equipment/blower.png',
            width: 32, height: 32);
      case "Trimmer":
        return Image.asset('assets/equipment/trimmer.png',
            width: 32, height: 32);
      case "Hedger":
        return Image.asset('assets/equipment/saw.png', width: 32, height: 32);
      case "Edger":
        return Image.asset('assets/equipment/saw.png', width: 32, height: 32);
      case "Tool (other)":
        return Image.asset('assets/equipment/tool_other.png',
            width: 32, height: 32);
      case "Vehicle (other)":
        return Image.asset('assets/equipment/vehicle_other.png',
            width: 32, height: 32);
      case "Machine (other)":
        return Image.asset('assets/equipment/machine_other.png',
            width: 32, height: 32);
      case "Truck":
        return Image.asset('assets/equipment/truck.png', width: 32, height: 32);
      case "Trailer":
        return Image.asset('assets/equipment/trailer.png',
            width: 32, height: 32);
      default:
        return Icon(Icons.device_unknown, size: 32);
    }
  }
}
