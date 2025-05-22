import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:gemini_landscaping_app/models/equipment_model.dart';
import 'package:gemini_landscaping_app/services/schedule_service.dart';
import 'package:google_fonts/google_fonts.dart';

class TruckManagerDialog extends StatefulWidget {
  final List<Equipment> trucks;
  final ScheduleService service;
  final VoidCallback onDataUpdated;
  final String? userRole;

  const TruckManagerDialog({
    required this.trucks,
    required this.service,
    required this.onDataUpdated,
    this.userRole,
    Key? key,
  }) : super(key: key);

  @override
  _TruckManagerDialogState createState() => _TruckManagerDialogState();
}

class _TruckManagerDialogState extends State<TruckManagerDialog> {
  late List<Equipment> _localTrucks;

  @override
  void initState() {
    super.initState();
    _localTrucks = List.from(widget.trucks);
  }

  Future<void> _updateTruckColor(Equipment truck, Color newColor) async {
    try {
      await widget.service.updateTruck(truck.id, truck.active, newColor);
      widget.onDataUpdated();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update color: $e')),
      );
    }
  }

  Future<void> _updateTruckName(Equipment truck, String newName) async {
    if (newName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Truck name cannot be empty')),
      );
      return;
    }

    try {
      await widget.service.updateTruckName(truck.id, newName);
      widget.onDataUpdated();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update name: $e')),
      );
    }
  }

  Future<void> _updateTruckStatus(Equipment truck, bool isActive) async {
    try {
      await widget.service.updateTruck(truck.id, isActive, truck.color);
      widget.onDataUpdated();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update status: $e')),
      );
    }
  }

  Future<void> _deleteTruck(String truckId) async {
    try {
      await widget.service.deleteTruck(truckId);
      widget.onDataUpdated();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete truck: $e')),
      );
    }
  }

  Future<void> _showColorPicker(BuildContext context, Equipment truck) async {
    final currentColor = truck.color;
    final pickedColor = await showDialog<Color>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Pick a Color', style: GoogleFonts.roboto()),
        content: SingleChildScrollView(
          child: BlockPicker(
            pickerColor: currentColor,
            onColorChanged: (color) {
              setState(() {
                _localTrucks[_localTrucks.indexOf(truck)] =
                    truck.copyWith(color: color);
              });
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, currentColor),
            child: Text('Cancel', style: GoogleFonts.roboto()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(
                context, _localTrucks[_localTrucks.indexOf(truck)].color),
            child: Text('Select', style: GoogleFonts.roboto()),
          ),
        ],
      ),
    );

    if (pickedColor != null && pickedColor != currentColor) {
      await _updateTruckColor(truck, pickedColor);
    }
  }

  Future<void> _showNameEditor(BuildContext context, Equipment truck) async {
    final nameController = TextEditingController(text: truck.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Truck Name', style: GoogleFonts.roboto()),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            hintText: 'Enter new truck name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.roboto()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, nameController.text),
            child: Text('Save', style: GoogleFonts.roboto()),
          ),
        ],
      ),
    );

    if (newName != null && newName != truck.name) {
      await _updateTruckName(truck, newName);
    }
  }

  Future<void> _confirmDelete(BuildContext context, Equipment truck) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Truck', style: GoogleFonts.roboto()),
        content: Text(
          'Are you sure you want to delete ${truck.name}?',
          style: GoogleFonts.roboto(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.roboto()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: GoogleFonts.roboto()),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _deleteTruck(truck.id);
    }
  }

  @override
  Widget build(BuildContext context) {
   
    if (widget.userRole != 'admin') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Only admins can manage trucks.')),
        );
        Navigator.pop(context); 
      });
      return const SizedBox.shrink(); 
    }
    return AlertDialog(
      title: Text('Manage Trucks', style: GoogleFonts.roboto()),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: _localTrucks.map((truck) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Color Picker
                      GestureDetector(
                        onTap: () => _showColorPicker(context, truck),
                        child: Container(
                          width: 32,
                          height: 32,
                          margin: const EdgeInsets.only(right: 16.0),
                          decoration: BoxDecoration(
                            color: truck.color,
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                        ),
                      ),
                      // Truck Name
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _showNameEditor(context, truck),
                          child: Text(
                            truck.name,
                            style: GoogleFonts.roboto(fontSize: 16),
                          ),
                        ),
                      ),
                      // Active Switch
                      Switch(
                        value: truck.active,
                        onChanged: (value) => _updateTruckStatus(truck, value),
                      ),
                      // Delete Button
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _confirmDelete(context, truck),
                      ),
                    ],
                  ),
                  const Divider(),
                ],
              ),
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Close', style: GoogleFonts.roboto()),
        ),
      ],
    );
  }
}
