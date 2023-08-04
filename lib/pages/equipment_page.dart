import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gemini_landscaping_app/models/equipment_model.dart';
import 'package:intl/intl.dart';
// import '../models/repair_model.dart';

class EquipmentPage extends StatefulWidget {
  const EquipmentPage({super.key});

  @override
  State<EquipmentPage> createState() => _EquipmentPageState();
}

// Add this enum for priority options
enum Priority { low, medium, high }

class _EquipmentPageState extends State<EquipmentPage> {
  String priority = 'low';

  @override
  Widget build(BuildContext context) {
    // Firestore collection reference
    CollectionReference equipmentCollection =
        FirebaseFirestore.instance.collection('equipment');

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.grey.shade200,
      body: StreamBuilder<QuerySnapshot>(
        stream: equipmentCollection.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator();
          }

          List<Equipment> equipmentList = snapshot.data!.docs.map((document) {
            Map<String, dynamic> data = document.data() as Map<String, dynamic>;
            return Equipment(
              name: data['name'] ?? '',
              year: data['year'] ?? 0,
              equipment: data['equipment'] ?? '',
              serialNumber: data['serialNumber'] ?? '',
            );
          }).toList();

          List<QueryDocumentSnapshot> documents = snapshot.data!.docs;

          return ListView.builder(
            itemCount: documents.length,
            itemBuilder: (context, index) {
              Equipment equipment = equipmentList[index];
              QueryDocumentSnapshot document = documents[index];
              return Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
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
                    title: Text(equipment.name),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Year: ${equipment.year}'),
                        Text('Serial Number: ${equipment.serialNumber}'),
                      ],
                    ),
                    leading: _getEquipmentIcon(equipment.equipment),
                    // Add icon based on type
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("Submit"),
                            Text("Report"),
                          ],
                        ),
                        IconButton(
                          icon: Icon(Icons.add_box_outlined),
                          color: Colors.red.shade400, // Add repair report icon
                          onPressed: () {
                            // Perform action when the icon is clicked
                            _addRepairReport(
                                context, equipment.name, document.id, priority);
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
                String? selectedEquipmentType;

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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Container(
                                width: 200,
                                child: TextField(
                                  controller: nameController,
                                  decoration: InputDecoration(
                                    labelText: 'Name',
                                  ),
                                ),
                              ),
                              SizedBox(width: 10),
                              Container(
                                width: 100,
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
                                width: 200,
                                child: TextField(
                                  controller: serialNumberController,
                                  decoration: InputDecoration(
                                    labelText: 'Serial Number',
                                  ),
                                ),
                              ),
                              DropdownButton<String>(
                                value: selectedEquipmentType,
                                hint: Text('Select Equipment'),
                                items: <String>[
                                  'Vehicle',
                                  'trailer',
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
                                    selectedEquipmentType = newValue!;
                                  });
                                },
                              ),
                            ],
                          ),
                          SizedBox(height: 20),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                primary: Colors.black45,
                                onPrimary: Colors.white,
                                textStyle: TextStyle(fontSize: 18)),
                            onPressed: () async {
                              // Access the selected dropdown value here
                              print(
                                  'Selected Equipment: $selectedEquipmentType');
                              // Add your code for the button press here
                              print('Add equipment clicked!!');

                              // Assuming you have a reference to your 'equipment' collection
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
                                'equipmentType': selectedEquipmentType,
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
              });
        },
        child: Icon(Icons.add),
      ),
    );
  }
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
          child: StreamBuilder<QuerySnapshot>(
            // Fetch repair entries for the specific equipment
            stream: repairEntriesCollection.snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return CircularProgressIndicator();
              }

              List<QueryDocumentSnapshot> documents = snapshot.data!.docs;
              return ListView.builder(
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
                      // Add an appropriate medium priority icon and color
                      iconData = Icons.warning;
                      iconColor = Colors.orange;
                      break;
                    case 'high':
                      iconData = Icons.report;
                      iconColor = Colors.red;
                      break;
                    default:
                      iconData = Icons.device_unknown;
                      iconColor = Colors.grey;
                  }

                  return ListTile(
                    title: Text('#${index + 1}: $dateTime'),
                    subtitle: Text('$description'),
                    trailing: Icon(
                      iconData,
                      color: iconColor,
                    ),
                  );
                },
              );
            },
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
                  items: <String>['low', 'medium', 'high'].map((String value) {
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
      return Image.asset('assets/equipment/blower.png', width: 32, height: 32);
    case "Trimmer":
      return Image.asset('assets/equipment/trimmer.png', width: 32, height: 32);
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
      return Image.asset('assets/equipment/trailer.png', width: 32, height: 32);
    default:
      return Icon(Icons.device_unknown, size: 32);
  }
}
