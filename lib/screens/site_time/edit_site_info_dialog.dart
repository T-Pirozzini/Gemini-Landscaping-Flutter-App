// New Dialog Widget for Editing Site Info
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class EditSiteInfoDialog extends StatefulWidget {
  final String siteId;
  final String currentName;
  final String currentAddress;
  final bool currentProgram;

  const EditSiteInfoDialog({
    required this.siteId,
    required this.currentName,
    required this.currentAddress,
    required this.currentProgram,
    super.key,
  });

  @override
  _EditSiteInfoDialogState createState() => _EditSiteInfoDialogState();
}

class _EditSiteInfoDialogState extends State<EditSiteInfoDialog> {
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late bool _isProgram;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentName);
    _addressController = TextEditingController(text: widget.currentAddress);
    _isProgram = widget.currentProgram;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Site Information'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Site Name'),
            ),
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(labelText: 'Address'),
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
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            FirebaseFirestore.instance
                .collection('SiteList')
                .doc(widget.siteId)
                .update({
              'name': _nameController.text,
              'address': _addressController.text,
              'program': _isProgram,
            });
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
