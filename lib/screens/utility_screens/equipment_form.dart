import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:gemini_landscaping_app/models/equipment_model.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

class EquipmentFormPage extends StatefulWidget {
  final Equipment? equipment; // null = adding new, non-null = editing

  const EquipmentFormPage({super.key, this.equipment});

  @override
  State<EquipmentFormPage> createState() => _EquipmentFormPageState();
}

class _EquipmentFormPageState extends State<EquipmentFormPage> {
  static const _darkGreen = Color.fromARGB(255, 59, 82, 73);

  static const _equipmentTypes = [
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
  ];

  static const _statusOptions = [
    'operational',
    'needs-attention',
    'out-of-service',
  ];

  late final TextEditingController _nameController;
  late final TextEditingController _yearController;
  late final TextEditingController _serialController;
  late final TextEditingController _mileageController;
  late String _selectedType;
  late String _selectedStatus;
  String? _imageUrl;
  File? _pickedImage;
  bool _saving = false;

  bool get _isEditing => widget.equipment != null;

  @override
  void initState() {
    super.initState();
    final eq = widget.equipment;
    _nameController = TextEditingController(text: eq?.name ?? '');
    _yearController =
        TextEditingController(text: eq != null && eq.year > 0 ? '${eq.year}' : '');
    _serialController = TextEditingController(text: eq?.serialNumber ?? '');
    _mileageController =
        TextEditingController(text: eq?.mileage != null ? '${eq!.mileage}' : '');
    _selectedType = eq?.equipmentType ?? 'Truck';
    _selectedStatus = eq?.currentStatus ?? 'operational';
    _imageUrl = eq?.imageUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _yearController.dispose();
    _serialController.dispose();
    _mileageController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.camera_alt),
              title: Text('Camera', style: GoogleFonts.montserrat(fontSize: 14)),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: Icon(Icons.photo_library),
              title: Text('Gallery', style: GoogleFonts.montserrat(fontSize: 14)),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    final picked = await picker.pickImage(source: source, maxWidth: 800);
    if (picked != null) {
      setState(() => _pickedImage = File(picked.path));
    }
  }

  Future<String?> _uploadImage(String equipmentId) async {
    if (_pickedImage == null) return _imageUrl;

    final ref = FirebaseStorage.instance
        .ref()
        .child('equipment_images')
        .child('$equipmentId.jpg');
    await ref.putFile(_pickedImage!);
    return await ref.getDownloadURL();
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a name')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final collection =
          FirebaseFirestore.instance.collection('equipment');
      final year = int.tryParse(_yearController.text) ?? 0;
      final mileage = int.tryParse(_mileageController.text);

      if (_isEditing) {
        // Upload image if changed
        final uploadedUrl = await _uploadImage(widget.equipment!.id);

        final updates = <String, dynamic>{
          'name': _nameController.text.trim(),
          'year': year,
          'serialNumber': _serialController.text.trim(),
          'equipmentType': _selectedType,
          'currentStatus': _selectedStatus,
        };
        if (uploadedUrl != null) updates['imageUrl'] = uploadedUrl;
        if (mileage != null) updates['mileage'] = mileage;

        await collection.doc(widget.equipment!.id).update(updates);
      } else {
        // Create new equipment
        final docRef = await collection.add({
          'name': _nameController.text.trim(),
          'year': year,
          'serialNumber': _serialController.text.trim(),
          'equipmentType': _selectedType,
          'currentStatus': _selectedStatus,
          'active': true,
          if (mileage != null) 'mileage': mileage,
        });

        // Upload image after we have the doc ID
        final uploadedUrl = await _uploadImage(docRef.id);
        if (uploadedUrl != null) {
          await docRef.update({'imageUrl': uploadedUrl});
        }
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
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
        backgroundColor: _darkGreen,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isEditing ? 'Edit Equipment' : 'Add Equipment',
          style: GoogleFonts.montserrat(
              fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // === IMAGE ===
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _pickedImage != null
                      ? Image.file(_pickedImage!,
                          width: 140, height: 140, fit: BoxFit.cover)
                      : (_imageUrl != null && _imageUrl!.isNotEmpty
                          ? Image.network(_imageUrl!,
                              width: 140, height: 140, fit: BoxFit.cover)
                          : Container(
                              width: 140,
                              height: 140,
                              color: Colors.grey[200],
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.camera_alt,
                                      size: 36, color: Colors.grey[400]),
                                  SizedBox(height: 4),
                                  Text('Add Photo',
                                      style: GoogleFonts.montserrat(
                                          fontSize: 11,
                                          color: Colors.grey[500])),
                                ],
                              ),
                            )),
                ),
              ),
            ),
            SizedBox(height: 20),

            // === NAME ===
            _label('Name'),
            _textField(_nameController, 'Equipment name'),
            SizedBox(height: 12),

            // === TYPE ===
            _label('Type'),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _selectedType,
                  style: GoogleFonts.montserrat(
                      fontSize: 13, color: Colors.black87),
                  items: _equipmentTypes
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedType = v!),
                ),
              ),
            ),
            SizedBox(height: 12),

            // === YEAR & SERIAL ===
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Year'),
                      _textField(_yearController, 'Year',
                          keyboardType: TextInputType.number),
                    ],
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('ID / Serial'),
                      _textField(_serialController, 'Serial number'),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),

            // === MILEAGE ===
            if (_selectedType == 'Truck' ||
                _selectedType == 'Trailer' ||
                _selectedType == 'Vehicle (other)') ...[
              _label('Mileage (km)'),
              _textField(_mileageController, 'Current mileage',
                  keyboardType: TextInputType.number),
              SizedBox(height: 12),
            ],

            // === STATUS ===
            _label('Status'),
            Wrap(
              spacing: 8,
              children: _statusOptions.map((s) {
                final isSelected = _selectedStatus == s;
                final color = _statusColor(s);
                return GestureDetector(
                  onTap: () => setState(() => _selectedStatus = s),
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? color.withAlpha(25) : Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? color : Colors.grey[300]!,
                      ),
                    ),
                    child: Text(
                      _statusLabel(s),
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected ? color : Colors.grey[600],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 24),

            // === SAVE BUTTON ===
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _darkGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _saving ? null : _save,
                child: _saving
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text(
                        _isEditing ? 'Save Changes' : 'Add Equipment',
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

  Widget _textField(TextEditingController controller, String hint,
      {TextInputType? keyboardType}) {
    return TextField(
      controller: controller,
      style: GoogleFonts.montserrat(fontSize: 13),
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            GoogleFonts.montserrat(fontSize: 13, color: Colors.grey[400]),
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _darkGreen, width: 2),
        ),
      ),
    );
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
