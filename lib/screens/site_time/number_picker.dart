import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:numberpicker/numberpicker.dart';

class AdjustSiteTargetDialog extends StatefulWidget {
  final String siteId;
  final String currentName;
  final double currentTarget;
  final VoidCallback onConfirm;

  const AdjustSiteTargetDialog({
    Key? key,
    required this.siteId,
    required this.currentName,
    required this.currentTarget,
    required this.onConfirm,
  }) : super(key: key);

  @override
  _AdjustSiteTargetDialogState createState() => _AdjustSiteTargetDialogState();
}

class _AdjustSiteTargetDialogState extends State<AdjustSiteTargetDialog> {
  late TextEditingController _siteNameController;
  late int targetInHours;

  @override
  void initState() {
    super.initState();
    _siteNameController = TextEditingController(text: widget.currentName);
    targetInHours = (widget.currentTarget / 60)
        .round(); // Convert target from minutes to hours
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Adjust Site Target'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _siteNameController,
            decoration: InputDecoration(
              labelText: 'Edit Site Name',
            ),
          ),
          SizedBox(height: 20),
          Text('Set New Target'),
          NumberPicker(
            value: targetInHours,
            minValue: 0,
            maxValue: 100,
            onChanged: (value) {
              setState(() {
                targetInHours = value;
              });
            },
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          child: Text('Cancel'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        TextButton(
          child: Text('Confirm'),
          onPressed: () {
            final newTargetInMinutes =
                targetInHours * 60; // Convert target back to minutes
            final newName = _siteNameController.text.isEmpty
                ? widget.currentName
                : _siteNameController.text;

            FirebaseFirestore.instance
                .collection('SiteList')
                .doc(widget.siteId)
                .update({
              'target': newTargetInMinutes,
              'name': newName,
            }).then((_) {
              widget.onConfirm();
            });

            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}
