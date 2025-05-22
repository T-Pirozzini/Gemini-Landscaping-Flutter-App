import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gemini_landscaping_app/models/site_info.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddSiteDialog extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController addressController;
  final VoidCallback onSuccess; // Callback for successful addition

  const AddSiteDialog({
    required this.nameController,
    required this.addressController,
    required this.onSuccess,
    Key? key,
  }) : super(key: key);

  Future<void> _saveSite(BuildContext context) async {
    try {
      final siteRef = FirebaseFirestore.instance.collection('SiteList');
      final newDocRef = siteRef.doc();

      final newSite = SiteInfo(
        address: addressController.text.trim().isEmpty
            ? ""
            : addressController.text.trim(),
        imageUrl: "",
        management: "",
        name: nameController.text.trim(),
        status: true,
        target: 0.0,
        id: newDocRef.id,
        program: true,
      );

      await newDocRef.set(newSite.toMap());
      
      // Clear controllers
      nameController.clear();
      addressController.clear();
      
      // Notify parent of success
      onSuccess();
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Site added successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add site: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final _formKey = GlobalKey<FormState>();

    return AlertDialog(
      title: Text(
        'Add New Site',
        style: GoogleFonts.montserrat(),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Site Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a site name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: addressController,
                decoration: const InputDecoration(
                  labelText: 'Address (Optional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: GoogleFonts.roboto()),
        ),
        TextButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              _saveSite(context).then((_) => Navigator.pop(context));
            }
          },
          child: Text('Save', style: GoogleFonts.roboto()),
        ),
      ],
    );
  }
}