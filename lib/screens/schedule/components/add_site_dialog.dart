import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gemini_landscaping_app/models/site_info.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gemini_landscaping_app/providers/management_company_provider.dart';

class AddSiteDialog extends ConsumerStatefulWidget {
  final TextEditingController nameController;
  final TextEditingController addressController;
  final VoidCallback onSuccess;

  const AddSiteDialog({
    required this.nameController,
    required this.addressController,
    required this.onSuccess,
    Key? key,
  }) : super(key: key);

  @override
  ConsumerState<AddSiteDialog> createState() => _AddSiteDialogState();
}

class _AddSiteDialogState extends ConsumerState<AddSiteDialog> {
  final _formKey = GlobalKey<FormState>();
  final _cityController = TextEditingController();
  String _selectedManagement = '';

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _saveSite(BuildContext context) async {
    try {
      final siteRef = FirebaseFirestore.instance.collection('SiteList');
      final newDocRef = siteRef.doc();

      final newSite = SiteInfo(
        address: widget.addressController.text.trim().isEmpty
            ? ""
            : widget.addressController.text.trim(),
        city: _cityController.text.trim(),
        imageUrl: "",
        management: _selectedManagement,
        name: widget.nameController.text.trim(),
        status: true,
        target: 0.0,
        id: newDocRef.id,
        program: true,
      );

      await newDocRef.set(newSite.toMap());

      widget.nameController.clear();
      widget.addressController.clear();
      widget.onSuccess();

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
    final companiesAsync = ref.watch(managementCompaniesStreamProvider);
    final companyNames = <String>[''];
    companiesAsync.whenData((companies) {
      companyNames.addAll(companies.map((c) => c.name));
    });

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
                controller: widget.nameController,
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
                controller: widget.addressController,
                decoration: const InputDecoration(
                  labelText: 'Street Address (Optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(
                  labelText: 'City (Optional)',
                  border: OutlineInputBorder(),
                ),
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
