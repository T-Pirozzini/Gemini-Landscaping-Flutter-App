import 'package:flutter/material.dart';
import 'package:gemini_landscaping_app/screens/add_report/disposal_section.dart';
import 'package:gemini_landscaping_app/screens/add_report/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Page 2 of the add report flow.
/// Shows materials, disposal, and/or notes sections based on checkboxes from Page 1.
/// Pops with a result Map on submit.
class ReportDetailsPage extends StatefulWidget {
  final bool hasMaterials;
  final bool hasDisposal;
  final bool hasNotes;
  final List<String> selectedNoteTags;

  const ReportDetailsPage({
    super.key,
    required this.hasMaterials,
    required this.hasDisposal,
    required this.hasNotes,
    required this.selectedNoteTags,
  });

  @override
  State<ReportDetailsPage> createState() => _ReportDetailsPageState();
}

class _ReportDetailsPageState extends State<ReportDetailsPage> {
  List<Map<String, dynamic>> _materials = [];
  bool _hasDisposal = false;
  final _disposalLocationController = TextEditingController();
  final _disposalCostController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _hasDisposal = widget.hasDisposal;
    if (widget.hasMaterials) _addMaterial();
  }

  void _addMaterial() {
    setState(() {
      _materials.add({
        'vendorController': TextEditingController(),
        'materialController': TextEditingController(),
        'costController': TextEditingController(),
      });
    });
  }

  void _deleteMaterial(int index) {
    setState(() => _materials.removeAt(index));
  }

  void _submit() {
    final result = <String, dynamic>{
      'materials': _materials
          .map((m) => {
                'vendor':
                    (m['vendorController'] as TextEditingController).text,
                'description':
                    (m['materialController'] as TextEditingController).text,
                'cost':
                    (m['costController'] as TextEditingController).text,
              })
          .toList(),
      'hasDisposal': _hasDisposal,
      'disposalLocation': _disposalLocationController.text,
      'disposalCost': _disposalCostController.text,
      'notesText': _notesController.text,
    };
    Navigator.pop(context, result);
  }

  @override
  void dispose() {
    _disposalLocationController.dispose();
    _disposalCostController.dispose();
    _notesController.dispose();
    for (var m in _materials) {
      (m['vendorController'] as TextEditingController).dispose();
      (m['materialController'] as TextEditingController).dispose();
      (m['costController'] as TextEditingController).dispose();
    }
    super.dispose();
  }

  Widget _sectionHeader(String title) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(8),
      margin: EdgeInsets.only(top: 8),
      decoration: BoxDecoration(color: Colors.green[100]),
      child: Text(
        title,
        style: GoogleFonts.montserrat(
            fontSize: 14, fontWeight: FontWeight.w600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 31, 182, 77),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Report Details',
          style: GoogleFonts.montserrat(
              fontSize: 16, color: Colors.white, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // === MATERIALS ===
                  if (widget.hasMaterials) ...[
                    _sectionHeader('Materials'),
                    SizedBox(height: 8),
                    ..._materials.asMap().entries.map((entry) {
                      final index = entry.key;
                      final material = entry.value;
                      return Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: MaterialComponent(
                                vendorController:
                                    material['vendorController'],
                                materialController:
                                    material['materialController'],
                                costController:
                                    material['costController'],
                              ),
                            ),
                            SizedBox(
                              width: 20,
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                icon: Icon(Icons.delete,
                                    color: Colors.grey, size: 24),
                                onPressed: () => _deleteMaterial(index),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color.fromARGB(255, 59, 82, 73),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        textStyle: GoogleFonts.montserrat(fontSize: 14),
                      ),
                      onPressed: _addMaterial,
                      child: const Text('Add Another Material'),
                    ),
                  ],

                  // === DISPOSAL ===
                  if (widget.hasDisposal) ...[
                    _sectionHeader('Disposal'),
                    DisposalSection(
                      hasDisposal: _hasDisposal,
                      onDisposalChanged: (v) =>
                          setState(() => _hasDisposal = v),
                      locationController: _disposalLocationController,
                      costController: _disposalCostController,
                    ),
                  ],

                  // === NOTES ===
                  if (widget.hasNotes) ...[
                    _sectionHeader('Shift Notes'),
                    SizedBox(height: 8),
                    if (widget.selectedNoteTags.isNotEmpty) ...[
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: widget.selectedNoteTags.map((tag) {
                          return Chip(
                            label: Text(tag,
                                style:
                                    GoogleFonts.montserrat(fontSize: 11)),
                            backgroundColor: Colors.green[100],
                          );
                        }).toList(),
                      ),
                      SizedBox(height: 8),
                    ],
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      height: 120,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: TextField(
                          controller: _notesController,
                          maxLines: null,
                          keyboardType: TextInputType.multiline,
                          decoration: InputDecoration(
                            hintText: 'Any additional details...',
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                  ],
                  SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // === SUBMIT BUTTON ===
          SafeArea(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  icon: Icon(Icons.send, size: 20),
                  label: Text(
                    'Submit Report',
                    style: GoogleFonts.montserrat(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromARGB(255, 31, 182, 77),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _submit,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
