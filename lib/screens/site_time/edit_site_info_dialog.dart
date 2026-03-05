import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:gemini_landscaping_app/providers/management_company_provider.dart';

class EditSiteInfoDialog extends ConsumerStatefulWidget {
  final String siteId;
  final String currentName;
  final String currentAddress;
  final bool currentProgram;
  final String currentManagement;
  final String currentImageUrl;

  const EditSiteInfoDialog({
    required this.siteId,
    required this.currentName,
    required this.currentAddress,
    required this.currentProgram,
    this.currentManagement = '',
    this.currentImageUrl = '',
    super.key,
  });

  @override
  ConsumerState<EditSiteInfoDialog> createState() => _EditSiteInfoDialogState();
}

class _EditSiteInfoDialogState extends ConsumerState<EditSiteInfoDialog> {
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late bool _isProgram;
  late String _selectedManagement;
  late String _currentImageUrl;
  File? _pickedImage;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentName);
    _addressController = TextEditingController(text: widget.currentAddress);
    _isProgram = widget.currentProgram;
    _selectedManagement = widget.currentManagement;
    _currentImageUrl = widget.currentImageUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );
    if (picked != null) {
      setState(() => _pickedImage = File(picked.path));
    }
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);

    try {
      String imageUrl = _currentImageUrl;

      if (_pickedImage != null) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final storageRef =
            FirebaseStorage.instance.ref().child('site_images/$timestamp.jpg');
        await storageRef.putFile(_pickedImage!);
        imageUrl = await storageRef.getDownloadURL();
      }

      await FirebaseFirestore.instance
          .collection('SiteList')
          .doc(widget.siteId)
          .update({
        'name': _nameController.text,
        'address': _addressController.text,
        'program': _isProgram,
        'management': _selectedManagement,
        'imageUrl': imageUrl,
      });

      Navigator.pop(context);
    } catch (e) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final companiesAsync = ref.watch(managementCompaniesStreamProvider);
    final companyNames = <String>[''];
    companiesAsync.whenData((companies) {
      companyNames.addAll(companies.map((c) => c.name));
    });

    if (_selectedManagement.isNotEmpty &&
        !companyNames.contains(_selectedManagement)) {
      companyNames.add(_selectedManagement);
    }

    return AlertDialog(
      title: const Text('Edit Site Information'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Site image
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: _pickedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(_pickedImage!, fit: BoxFit.cover),
                      )
                    : _currentImageUrl.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: CachedNetworkImage(
                              imageUrl: _currentImageUrl,
                              fit: BoxFit.cover,
                              placeholder: (_, __) =>
                                  const Icon(Icons.image, color: Colors.grey),
                              errorWidget: (_, __, ___) => const Icon(
                                  Icons.broken_image,
                                  color: Colors.grey),
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate,
                                  size: 28, color: Colors.grey.shade400),
                              const SizedBox(height: 2),
                              Text(
                                'Add Image',
                                style: GoogleFonts.montserrat(
                                    fontSize: 9, color: Colors.grey.shade500),
                              ),
                            ],
                          ),
              ),
            ),
            if (_currentImageUrl.isNotEmpty || _pickedImage != null)
              TextButton(
                onPressed: () {
                  setState(() {
                    _pickedImage = null;
                    _currentImageUrl = '';
                  });
                },
                child: Text(
                  'Remove Image',
                  style: GoogleFonts.montserrat(
                      fontSize: 11, color: Colors.red.shade400),
                ),
              ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Site Name'),
            ),
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(labelText: 'Address'),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _selectedManagement,
              decoration: const InputDecoration(
                labelText: 'Management Company',
                border: OutlineInputBorder(),
              ),
              items: companyNames.map((name) {
                return DropdownMenuItem(
                  value: name,
                  child: Text(
                    name.isEmpty ? 'None' : name,
                    style: GoogleFonts.montserrat(fontSize: 14),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedManagement = value ?? '');
              },
            ),
            Row(
              children: [
                const Text('Monthly Program'),
                Checkbox(
                  value: _isProgram,
                  onChanged: (bool? value) {
                    setState(() {
                      _isProgram = value ?? false;
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}
