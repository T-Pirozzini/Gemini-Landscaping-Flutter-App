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
  static const _darkGreen = Color.fromARGB(255, 59, 82, 73);
  static const _greenAccent = Color.fromARGB(255, 31, 182, 77);

  late List<Equipment> _localTrucks;

  @override
  void initState() {
    super.initState();
    _localTrucks = List.from(widget.trucks);
  }

  Future<void> _updateTruckColor(Equipment truck, Color newColor) async {
    try {
      await widget.service.updateTruck(truck.id, truck.active, newColor);
      setState(() {
        final idx = _localTrucks.indexWhere((t) => t.id == truck.id);
        if (idx != -1) {
          _localTrucks[idx] = _localTrucks[idx].copyWith(color: newColor);
        }
      });
      widget.onDataUpdated();
    } catch (e) {
      if (!mounted) return;
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
      setState(() {
        final idx = _localTrucks.indexWhere((t) => t.id == truck.id);
        if (idx != -1) {
          _localTrucks[idx] = _localTrucks[idx].copyWith(name: newName);
        }
      });
      widget.onDataUpdated();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update name: $e')),
      );
    }
  }

  Future<void> _updateTruckStatus(Equipment truck, bool isActive) async {
    try {
      await widget.service.updateTruck(truck.id, isActive, truck.color);
      setState(() {
        final idx = _localTrucks.indexWhere((t) => t.id == truck.id);
        if (idx != -1) {
          _localTrucks[idx] = _localTrucks[idx].copyWith(active: isActive);
        }
      });
      widget.onDataUpdated();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update status: $e')),
      );
    }
  }

  Future<void> _deleteTruck(String truckId) async {
    try {
      await widget.service.deleteTruck(truckId);
      setState(() {
        _localTrucks.removeWhere((t) => t.id == truckId);
      });
      widget.onDataUpdated();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete truck: $e')),
      );
    }
  }

  Future<void> _showColorPicker(BuildContext context, Equipment truck) async {
    Color tempColor = truck.color;
    final pickedColor = await showDialog<Color>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Pick a Color',
            style: GoogleFonts.montserrat(fontWeight: FontWeight.w600)),
        content: SingleChildScrollView(
          child: BlockPicker(
            pickerColor: truck.color,
            onColorChanged: (color) => tempColor = color,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: GoogleFonts.montserrat(color: Colors.grey[600])),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, tempColor),
            style: FilledButton.styleFrom(backgroundColor: _darkGreen),
            child: Text('Select', style: GoogleFonts.montserrat()),
          ),
        ],
      ),
    );

    if (pickedColor != null && pickedColor != truck.color) {
      await _updateTruckColor(truck, pickedColor);
    }
  }

  Future<void> _showNameEditor(BuildContext context, Equipment truck) async {
    final nameController = TextEditingController(text: truck.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Edit Truck Name',
            style: GoogleFonts.montserrat(fontWeight: FontWeight.w600)),
        content: TextField(
          controller: nameController,
          autofocus: true,
          style: GoogleFonts.montserrat(),
          decoration: InputDecoration(
            hintText: 'Enter truck name',
            hintStyle: GoogleFonts.montserrat(color: Colors.grey[400]),
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _greenAccent, width: 2),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: GoogleFonts.montserrat(color: Colors.grey[600])),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, nameController.text),
            style: FilledButton.styleFrom(backgroundColor: _darkGreen),
            child: Text('Save', style: GoogleFonts.montserrat()),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red[400], size: 28),
            const SizedBox(width: 8),
            Text('Delete Truck',
                style: GoogleFonts.montserrat(fontWeight: FontWeight.w600)),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${truck.name}"? This cannot be undone.',
          style: GoogleFonts.montserrat(fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel',
                style: GoogleFonts.montserrat(color: Colors.grey[600])),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red[600]),
            child: Text('Delete', style: GoogleFonts.montserrat()),
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

    final activeTrucks = _localTrucks.where((t) => t.active).toList();
    final inactiveTrucks = _localTrucks.where((t) => !t.active).toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
              decoration: const BoxDecoration(
                color: _darkGreen,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.local_shipping_outlined,
                      color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Manage Trucks',
                      style: GoogleFonts.montserrat(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Truck list
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (activeTrucks.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 8),
                        child: Text(
                          'ACTIVE',
                          style: GoogleFonts.montserrat(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _greenAccent,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      ...activeTrucks.map((truck) => _buildTruckCard(truck)),
                    ],
                    if (inactiveTrucks.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.only(left: 4, top: 12, bottom: 8),
                        child: Text(
                          'INACTIVE',
                          style: GoogleFonts.montserrat(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[500],
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      ...inactiveTrucks.map((truck) => _buildTruckCard(truck)),
                    ],
                    if (_localTrucks.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Center(
                          child: Text(
                            'No trucks added yet',
                            style: GoogleFonts.montserrat(
                              color: Colors.grey[400],
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Bottom padding
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildTruckCard(Equipment truck) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: truck.active ? Colors.white : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: truck.active
              ? truck.color.withValues(alpha: 0.3)
              : Colors.grey[300]!,
        ),
        boxShadow: truck.active
            ? [
                BoxShadow(
                  color: truck.color.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            // Color swatch — tap to change
            GestureDetector(
              onTap: () => _showColorPicker(context, truck),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: truck.color,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.black.withValues(alpha: 0.1),
                  ),
                ),
                child: const Icon(Icons.palette, color: Colors.white, size: 18),
              ),
            ),
            const SizedBox(width: 12),
            // Truck name — tap to edit
            Expanded(
              child: GestureDetector(
                onTap: () => _showNameEditor(context, truck),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      truck.name,
                      style: GoogleFonts.montserrat(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: truck.active ? _darkGreen : Colors.grey[500],
                      ),
                    ),
                    Text(
                      'Tap to rename',
                      style: GoogleFonts.montserrat(
                        fontSize: 11,
                        color: Colors.grey[400],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Active toggle
            Switch.adaptive(
              value: truck.active,
              activeTrackColor: _greenAccent,
              onChanged: (value) => _updateTruckStatus(truck, value),
            ),
            // Delete button
            IconButton(
              icon: Icon(Icons.delete_outline, color: Colors.red[300], size: 20),
              onPressed: () => _confirmDelete(context, truck),
              splashRadius: 20,
              tooltip: 'Delete truck',
            ),
          ],
        ),
      ),
    );
  }
}
