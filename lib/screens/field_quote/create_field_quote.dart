import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gemini_landscaping_app/models/field_quote.dart';
import 'package:gemini_landscaping_app/models/site_info.dart';
import 'package:gemini_landscaping_app/screens/add_report/site_picker.dart';
import 'package:gemini_landscaping_app/screens/field_quote/signature_screen.dart';
import 'package:gemini_landscaping_app/services/firestore_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class CreateFieldQuote extends ConsumerStatefulWidget {
  const CreateFieldQuote({super.key});

  @override
  ConsumerState<CreateFieldQuote> createState() => _CreateFieldQuoteState();
}

class _CreateFieldQuoteState extends ConsumerState<CreateFieldQuote> {
  static const _darkGreen = Color.fromARGB(255, 59, 82, 73);
  static const _greenAccent = Color.fromARGB(255, 31, 182, 77);

  final _formKey = GlobalKey<FormState>();
  final _clientNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _costController = TextEditingController();
  final _dateController = TextEditingController();

  SiteInfo? _selectedSite;
  String? _selectedSiteName;
  String? _signatureBase64;
  bool _isSaving = false;

  double get _subtotal =>
      double.tryParse(_costController.text) ?? 0.0;
  double get _gstAmount => _subtotal * 0.05;
  double get _total => _subtotal + _gstAmount;

  @override
  void initState() {
    super.initState();
    _dateController.text = DateFormat('MMMM d, yyyy').format(DateTime.now());
  }

  @override
  void dispose() {
    _clientNameController.dispose();
    _descriptionController.dispose();
    _costController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _darkGreen,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dateController.text = DateFormat('MMMM d, yyyy').format(picked);
      });
    }
  }

  Future<void> _getSignature() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const SignatureScreen()),
    );
    if (result != null) {
      setState(() => _signatureBase64 = result);
    }
  }

  Future<void> _saveQuote() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSiteName == null || _selectedSiteName!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a site')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      final quote = FieldQuote(
        id: '',
        siteName: _selectedSiteName!,
        siteId: _selectedSite?.id ?? '',
        clientName: _clientNameController.text.trim(),
        date: _dateController.text,
        timestamp: DateTime.now(),
        description: _descriptionController.text.trim(),
        subtotal: _subtotal,
        gstAmount: _gstAmount,
        total: _total,
        status: _signatureBase64 != null ? 'signed' : 'created',
        signatureBase64: _signatureBase64,
        createdBy: user?.email ?? '',
        createdByName: user?.displayName ?? user?.email ?? '',
        signedAt: _signatureBase64 != null ? DateTime.now() : null,
      );

      await FirestoreService().addFieldQuote(quote);

      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: _darkGreen,
        toolbarHeight: 44,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 20, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'New Field Quote',
          style: GoogleFonts.montserrat(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date picker
              _sectionLabel('Date'),
              GestureDetector(
                onTap: _pickDate,
                child: AbsorbPointer(
                  child: TextFormField(
                    controller: _dateController,
                    decoration: _inputDecoration('Date', Icons.calendar_today),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Site picker
              _sectionLabel('Site'),
              SitePickerComponent(
                dropdownValue: _selectedSiteName,
                selectedSite: _selectedSite,
                onSiteChanged: (site) {
                  setState(() {
                    _selectedSite = site;
                    _selectedSiteName = site.name;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Client name
              _sectionLabel('Client Name'),
              TextFormField(
                controller: _clientNameController,
                decoration: _inputDecoration('Client name', Icons.person),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              // Description
              _sectionLabel('Description of Work'),
              TextFormField(
                controller: _descriptionController,
                decoration:
                    _inputDecoration('Describe the work...', Icons.description),
                maxLines: 4,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              // Cost
              _sectionLabel('Cost'),
              TextFormField(
                controller: _costController,
                decoration: _inputDecoration('Subtotal (\$)', Icons.attach_money),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                onChanged: (_) => setState(() {}),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (double.tryParse(v) == null) return 'Invalid number';
                  return null;
                },
              ),
              const SizedBox(height: 8),
              // GST breakdown
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    _costRow('Subtotal', _subtotal),
                    _costRow('GST (5%)', _gstAmount),
                    const Divider(height: 12),
                    _costRow('Total', _total, bold: true),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Signature
              _sectionLabel('Client Signature'),
              GestureDetector(
                onTap: _getSignature,
                child: Container(
                  width: double.infinity,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _signatureBase64 != null
                          ? _greenAccent
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: _signatureBase64 != null
                      ? Stack(
                          children: [
                            Center(
                              child: Image.memory(
                                base64Decode(_signatureBase64!),
                                height: 60,
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => _signatureBase64 = null),
                                child: Icon(Icons.close,
                                    size: 16, color: Colors.grey.shade500),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.draw,
                                size: 24, color: Colors.grey.shade400),
                            const SizedBox(height: 4),
                            Text(
                              'Tap to capture signature',
                              style: GoogleFonts.montserrat(
                                fontSize: 11,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 24),

              // Save button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveQuote,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _darkGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          _signatureBase64 != null
                              ? 'Save Signed Quote'
                              : 'Save Quote',
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: GoogleFonts.montserrat(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: _darkGreen,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, size: 18, color: Colors.grey.shade500),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _greenAccent, width: 2),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }

  Widget _costRow(String label, double amount, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.montserrat(
                fontSize: 12,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
                color: bold ? _darkGreen : Colors.grey.shade600,
              )),
          Text(
            '\$${amount.toStringAsFixed(2)}',
            style: GoogleFonts.montserrat(
              fontSize: 12,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              color: bold ? _darkGreen : Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}
