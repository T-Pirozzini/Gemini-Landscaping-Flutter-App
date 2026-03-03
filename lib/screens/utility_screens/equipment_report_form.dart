import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gemini_landscaping_app/models/equipment_model.dart';
import 'package:gemini_landscaping_app/models/repair_entry.dart';
import 'package:google_fonts/google_fonts.dart';

class EquipmentReportForm extends StatefulWidget {
  /// Optional pre-selected equipment ID (e.g. from site report linking).
  final String? preselectedEquipmentId;

  const EquipmentReportForm({super.key, this.preselectedEquipmentId});

  @override
  State<EquipmentReportForm> createState() => _EquipmentReportFormState();
}

class _EquipmentReportFormState extends State<EquipmentReportForm> {
  static const _darkGreen = Color.fromARGB(255, 59, 82, 73);

  final _descriptionController = TextEditingController();
  final _mileageController = TextEditingController();

  String? _selectedEquipmentId;
  Equipment? _selectedEquipment;
  String _selectedPriority = 'medium';
  bool _saving = false;

  // Equipment list loaded from Firestore
  List<Equipment> _equipmentList = [];
  bool _loadingEquipment = true;

  @override
  void initState() {
    super.initState();
    _loadEquipment();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _mileageController.dispose();
    super.dispose();
  }

  Future<void> _loadEquipment() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('equipment')
        .where('active', isEqualTo: true)
        .get();

    final list = snapshot.docs
        .map((doc) => Equipment.fromMap(doc.id, doc.data()))
        .toList();
    list.sort((a, b) => a.name.compareTo(b.name));

    setState(() {
      _equipmentList = list;
      _loadingEquipment = false;

      // Pre-select if provided
      if (widget.preselectedEquipmentId != null) {
        final match = list
            .where((eq) => eq.id == widget.preselectedEquipmentId)
            .toList();
        if (match.isNotEmpty) {
          _selectedEquipmentId = match.first.id;
          _selectedEquipment = match.first;
        }
      }
    });
  }

  bool get _isVehicleType =>
      _selectedEquipment != null &&
      (_selectedEquipment!.equipmentType == 'Truck' ||
          _selectedEquipment!.equipmentType == 'Trailer' ||
          _selectedEquipment!.equipmentType == 'Vehicle (other)');

  Future<void> _submit() async {
    if (_selectedEquipmentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select equipment')),
      );
      return;
    }
    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please describe the issue')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      final mileage = int.tryParse(_mileageController.text);

      final entry = RepairEntry(
        id: '',
        dateTime: DateTime.now(),
        description: _descriptionController.text.trim(),
        priority: _selectedPriority,
        reportedBy: user?.email ?? 'unknown',
        mileageAtReport: mileage,
      );

      // Add repair entry to equipment subcollection
      await FirebaseFirestore.instance
          .collection('equipment')
          .doc(_selectedEquipmentId)
          .collection('repair_entries')
          .add(entry.toMap());

      // Update equipment status if priority is high
      if (_selectedPriority == 'high') {
        await FirebaseFirestore.instance
            .collection('equipment')
            .doc(_selectedEquipmentId)
            .update({'currentStatus': 'needs-attention'});
      }

      // Update mileage on the equipment doc if provided
      if (mileage != null) {
        await FirebaseFirestore.instance
            .collection('equipment')
            .doc(_selectedEquipmentId)
            .update({'mileage': mileage});
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Issue reported successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.amber[700],
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Equipment Report',
          style: GoogleFonts.montserrat(
              fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: _loadingEquipment
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // === EQUIPMENT PICKER ===
                  _label('Select Equipment'),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.white,
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _selectedEquipmentId,
                        hint: Text('Choose equipment...',
                            style: GoogleFonts.montserrat(
                                fontSize: 13, color: Colors.grey[400])),
                        style: GoogleFonts.montserrat(
                            fontSize: 13, color: Colors.black87),
                        items: _equipmentList.map((eq) {
                          return DropdownMenuItem(
                            value: eq.id,
                            child: Row(
                              children: [
                                Icon(_iconForType(eq.equipmentType),
                                    size: 18, color: Colors.grey[600]),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${eq.name} (${eq.equipmentType})',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (v) {
                          setState(() {
                            _selectedEquipmentId = v;
                            _selectedEquipment = _equipmentList
                                .firstWhere((eq) => eq.id == v);
                          });
                        },
                      ),
                    ),
                  ),

                  // Show selected equipment info
                  if (_selectedEquipment != null) ...[
                    SizedBox(height: 8),
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.blueGrey[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _statusColor(
                                  _selectedEquipment!.currentStatus),
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            _statusLabel(
                                _selectedEquipment!.currentStatus),
                            style: GoogleFonts.montserrat(
                                fontSize: 11, color: Colors.blueGrey[700]),
                          ),
                          if (_selectedEquipment!.mileage != null) ...[
                            Spacer(),
                            Icon(Icons.speed,
                                size: 12, color: Colors.blueGrey[400]),
                            SizedBox(width: 4),
                            Text(
                              '${_selectedEquipment!.mileage} km',
                              style: GoogleFonts.montserrat(
                                  fontSize: 11, color: Colors.blueGrey[700]),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                  SizedBox(height: 16),

                  // === DESCRIPTION ===
                  _label('Issue Description'),
                  TextField(
                    controller: _descriptionController,
                    style: GoogleFonts.montserrat(fontSize: 13),
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Describe the issue...',
                      hintStyle: GoogleFonts.montserrat(
                          fontSize: 13, color: Colors.grey[400]),
                      filled: true,
                      fillColor: Colors.white,
                      isDense: true,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: _darkGreen, width: 2),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),

                  // === PRIORITY ===
                  _label('Priority'),
                  Row(
                    children: ['low', 'medium', 'high'].map((p) {
                      final isSelected = _selectedPriority == p;
                      final color = _priorityColor(p);
                      return Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _selectedPriority = p),
                          child: Container(
                            margin: EdgeInsets.symmetric(horizontal: 4),
                            padding: EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? color.withAlpha(25)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color:
                                    isSelected ? color : Colors.grey[300]!,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              p[0].toUpperCase() + p.substring(1),
                              style: GoogleFonts.montserrat(
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color:
                                    isSelected ? color : Colors.grey[600],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 16),

                  // === MILEAGE (vehicles only) ===
                  if (_isVehicleType) ...[
                    _label('Current Mileage (km)'),
                    TextField(
                      controller: _mileageController,
                      style: GoogleFonts.montserrat(fontSize: 13),
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: _selectedEquipment?.mileage != null
                            ? 'Last recorded: ${_selectedEquipment!.mileage} km'
                            : 'Enter current mileage',
                        hintStyle: GoogleFonts.montserrat(
                            fontSize: 13, color: Colors.grey[400]),
                        filled: true,
                        fillColor: Colors.white,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              BorderSide(color: _darkGreen, width: 2),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                  ],

                  SizedBox(height: 8),

                  // === SUBMIT ===
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber[700],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _saving ? null : _submit,
                      icon: _saving
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : Icon(Icons.send),
                      label: Text(
                        _saving ? 'Submitting...' : 'Submit Report',
                        style: GoogleFonts.montserrat(
                            fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6),
      child: Text(text,
          style: GoogleFonts.montserrat(
              fontSize: 12, fontWeight: FontWeight.w600, color: _darkGreen)),
    );
  }

  static IconData _iconForType(String type) {
    switch (type) {
      case 'Truck':
      case 'Vehicle (other)':
        return Icons.local_shipping;
      case 'Trailer':
        return Icons.rv_hookup;
      case 'Mower (push)':
      case 'Mower (ride-on)':
        return Icons.grass;
      case 'Blower':
        return Icons.air;
      case 'Trimmer':
      case 'Hedger':
      case 'Edger':
        return Icons.content_cut;
      case 'Tool (other)':
        return Icons.build;
      case 'Machine (other)':
        return Icons.precision_manufacturing;
      default:
        return Icons.handyman;
    }
  }

  static Color _priorityColor(String priority) {
    switch (priority) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.amber[700]!;
      default:
        return Colors.grey;
    }
  }

  static String _statusLabel(String status) {
    switch (status) {
      case 'operational':
        return 'Operational';
      case 'needs-attention':
        return 'Needs Attention';
      case 'out-of-service':
        return 'Out of Service';
      default:
        return status;
    }
  }

  static Color _statusColor(String status) {
    switch (status) {
      case 'operational':
        return Colors.green;
      case 'needs-attention':
        return Colors.amber[700]!;
      case 'out-of-service':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
