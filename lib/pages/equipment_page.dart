import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gemini_landscaping_app/models/equipment_model.dart';

class EquipmentPage extends StatefulWidget {
  const EquipmentPage({super.key});

  @override
  State<EquipmentPage> createState() => _EquipmentPageState();
}

class _EquipmentPageState extends State<EquipmentPage> {
  @override
  Widget build(BuildContext context) {
    // Firestore collection reference
    CollectionReference equipmentCollection =
        FirebaseFirestore.instance.collection('equipment');

    return Scaffold(
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
              serialNumber: data['serialNumber'] ?? 0,
            );
          }).toList();

          return ListView.builder(
            itemCount: equipmentList.length,
            itemBuilder: (context, index) {
              Equipment equipment = equipmentList[index];
              return Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(2),
                ),
                margin: EdgeInsets.all(5),
                child: InkWell(
                  onTap: () {
                    // Open dialog with a list of dated repair entries log
                    _showRepairEntriesDialog(context, equipment.name);
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
                            _addRepairReport(context, equipment.name);
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
    );
  }
}

// Function to show the dialog with a list of dated repair entries log
void _showRepairEntriesDialog(BuildContext context, String equipmentName) {
  // Implement your dialog here
  // You can use showDialog() or a custom dialog widget.
  // Retrieve and display the repair entries for the selected equipment.
}

// Function to add a repair report
void _addRepairReport(BuildContext context, String equipmentName) {
  // Implement the functionality to add a repair report here.
}

// Function to get the icon based on the type of equipment
Widget _getEquipmentIcon(String equipment) {
  switch (equipment) {
    case "excavator":
      return Icon(Icons.front_loader,
          size: 32); // Replace with appropriate icon
    case "vehicle":
      return Icon(Icons.local_shipping,
          size: 32); // Replace with appropriate icon
    // Add more cases for other equipment types
    default:
      return Icon(Icons.device_unknown,
          size: 32); // Default icon for unknown types
  }
}
