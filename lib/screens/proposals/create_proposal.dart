import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gemini_landscaping_app/models/proposal.dart';
import 'package:gemini_landscaping_app/providers/management_company_provider.dart';
import 'package:gemini_landscaping_app/services/firestore_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class CreateProposal extends ConsumerStatefulWidget {
  final Proposal? existing; // for editing/duplicating

  const CreateProposal({super.key, this.existing});

  @override
  ConsumerState<CreateProposal> createState() => _CreateProposalState();
}

class _CreateProposalState extends ConsumerState<CreateProposal> {
  static const _darkGreen = Color.fromARGB(255, 59, 82, 73);
  static const _greenAccent = Color.fromARGB(255, 31, 182, 77);

  final _formKey = GlobalKey<FormState>();
  final _siteNameController = TextEditingController();
  final _siteAddressController = TextEditingController();
  final _contactNameController = TextEditingController();
  final _paymentTermController = TextEditingController();
  final _serviceTermController = TextEditingController();
  final _monthlyRateController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedManagement = '';
  bool _hasGrass = false;
  final Set<String> _selectedExtras = {};
  final Set<String> _selectedServiceMonths = {};
  DateTime? _dueDate;
  bool _isSaving = false;

  // Payment schedule — 12 controllers
  final List<TextEditingController> _paymentControllers =
      List.generate(12, (_) => TextEditingController());

  double get _monthlyRate =>
      double.tryParse(_monthlyRateController.text) ?? 0.0;
  double get _annualRate => _monthlyRate * 12;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _prefill(widget.existing!);
    }
  }

  void _prefill(Proposal p) {
    _siteNameController.text = p.siteName;
    _siteAddressController.text = p.siteAddress;
    _contactNameController.text = p.contactName;
    _paymentTermController.text = p.paymentTerm;
    _serviceTermController.text = p.serviceTerm;
    _monthlyRateController.text =
        p.monthlyRate > 0 ? p.monthlyRate.toStringAsFixed(2) : '';
    _notesController.text = p.notes;
    _selectedManagement = p.managementCompany;
    _hasGrass = p.hasGrass;
    _selectedExtras.addAll(p.extraServices);
    _selectedServiceMonths.addAll(p.serviceMonths);
    _dueDate = p.dueDate;
    for (int i = 0; i < p.paymentSchedule.length && i < 12; i++) {
      _paymentControllers[i].text =
          p.paymentSchedule[i].amount > 0
              ? p.paymentSchedule[i].amount.toStringAsFixed(2)
              : '';
    }
  }

  @override
  void dispose() {
    _siteNameController.dispose();
    _siteAddressController.dispose();
    _contactNameController.dispose();
    _paymentTermController.dispose();
    _serviceTermController.dispose();
    _monthlyRateController.dispose();
    _notesController.dispose();
    for (var c in _paymentControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _autoFillSchedule() {
    for (int i = 0; i < 12; i++) {
      final month = Proposal.allMonths[i];
      final isService = _selectedServiceMonths.contains(month);
      _paymentControllers[i].text =
          _monthlyRate > 0 ? _monthlyRate.toStringAsFixed(2) : '';
      // Keep non-service months at the same monthly rate for equal billing
      // (standard landscaping contract pattern)
      if (!isService && _monthlyRate > 0) {
        _paymentControllers[i].text = _monthlyRate.toStringAsFixed(2);
      }
    }
    setState(() {});
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now().add(const Duration(days: 14)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
              primary: _darkGreen, onPrimary: Colors.white),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _save({String status = 'draft'}) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      final schedule = List.generate(12, (i) {
        final month = Proposal.allMonths[i];
        return MonthlyPayment(
          month: month,
          amount: double.tryParse(_paymentControllers[i].text) ?? 0.0,
          isServiceMonth: _selectedServiceMonths.contains(month),
        );
      });

      final proposal = Proposal(
        id: '',
        status: status,
        siteName: _siteNameController.text.trim(),
        siteAddress: _siteAddressController.text.trim(),
        contactName: _contactNameController.text.trim(),
        managementCompany: _selectedManagement,
        paymentTerm: _paymentTermController.text.trim(),
        serviceTerm: _serviceTermController.text.trim(),
        serviceMonths: _selectedServiceMonths.toList(),
        monthlyRate: _monthlyRate,
        annualRate: _annualRate,
        paymentSchedule: schedule,
        hasGrass: _hasGrass,
        extraServices: _selectedExtras.toList(),
        dueDate: _dueDate,
        notes: _notesController.text.trim(),
        createdBy: user?.email ?? '',
        createdAt: DateTime.now(),
      );

      await FirestoreService().addProposal(proposal);
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
    final companiesAsync = ref.watch(managementCompaniesStreamProvider);
    final companyNames = <String>[''];
    companiesAsync.whenData((companies) {
      companyNames.addAll(companies.map((c) => c.name));
    });
    if (_selectedManagement.isNotEmpty &&
        !companyNames.contains(_selectedManagement)) {
      companyNames.add(_selectedManagement);
    }

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
          widget.existing != null ? 'Edit Proposal' : 'New Proposal',
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
              // ── Section 1: Site Info ──
              _sectionHeader('Site Information'),
              _textField(_siteNameController, 'Site Name', Icons.location_on,
                  required: true),
              const SizedBox(height: 10),
              _textField(
                  _siteAddressController, 'Address', Icons.home),
              const SizedBox(height: 10),
              _textField(
                  _contactNameController, 'Contact Name', Icons.person),
              const SizedBox(height: 10),
              // Management company dropdown
              DropdownButtonFormField<String>(
                value: _selectedManagement,
                decoration: _inputDecoration(
                    'Management Company', Icons.business),
                items: companyNames.map((name) {
                  return DropdownMenuItem(
                    value: name,
                    child: Text(name.isEmpty ? 'None' : name,
                        style: GoogleFonts.montserrat(fontSize: 13)),
                  );
                }).toList(),
                onChanged: (v) =>
                    setState(() => _selectedManagement = v ?? ''),
              ),

              const SizedBox(height: 20),

              // ── Section 2: Terms ──
              _sectionHeader('Terms'),
              _textField(
                  _paymentTermController, 'Payment Term', Icons.payment),
              const SizedBox(height: 10),
              _textField(_serviceTermController, 'Service Term',
                  Icons.date_range),
              const SizedBox(height: 10),
              // Service months
              Text('Service Months',
                  style: GoogleFonts.montserrat(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _darkGreen)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: Proposal.allMonths.map((month) {
                  final selected = _selectedServiceMonths.contains(month);
                  return ChoiceChip(
                    label: Text(month.substring(0, 3),
                        style: GoogleFonts.montserrat(
                          fontSize: 10,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: selected ? Colors.white : _darkGreen,
                        )),
                    selected: selected,
                    selectedColor: _darkGreen,
                    backgroundColor: Colors.white,
                    side: BorderSide(
                        color: selected
                            ? _darkGreen
                            : Colors.grey.shade300),
                    showCheckmark: false,
                    onSelected: (_) {
                      setState(() {
                        if (selected) {
                          _selectedServiceMonths.remove(month);
                        } else {
                          _selectedServiceMonths.add(month);
                        }
                      });
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),

              // ── Section 3: Financial ──
              _sectionHeader('Financial'),
              _textField(
                _monthlyRateController,
                'Monthly Rate (\$)',
                Icons.attach_money,
                isNumber: true,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 8),
              // Annual rate display
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: _greenAccent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Annual Rate',
                        style: GoogleFonts.montserrat(
                            fontSize: 12, fontWeight: FontWeight.w600)),
                    Text('\$${_annualRate.toStringAsFixed(2)}',
                        style: GoogleFonts.montserrat(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _darkGreen)),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              // Auto-fill button
              Center(
                child: TextButton.icon(
                  onPressed: _autoFillSchedule,
                  icon: Icon(Icons.auto_fix_high,
                      size: 16, color: _darkGreen),
                  label: Text('Auto-fill Payment Schedule',
                      style: GoogleFonts.montserrat(
                          fontSize: 11, color: _darkGreen)),
                ),
              ),
              // Payment schedule
              _sectionHeader('12-Month Payment Schedule'),
              ...List.generate(12, (i) {
                final month = Proposal.allMonths[i];
                final isService = _selectedServiceMonths.contains(month);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 70,
                        child: Text(
                          month.substring(0, 3),
                          style: GoogleFonts.montserrat(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isService ? _darkGreen : Colors.grey,
                          ),
                        ),
                      ),
                      if (isService)
                        Icon(Icons.grass, size: 14, color: _greenAccent)
                      else
                        const SizedBox(width: 14),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SizedBox(
                          height: 36,
                          child: TextField(
                            controller: _paymentControllers[i],
                            keyboardType:
                                const TextInputType.numberWithOptions(
                                    decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d+\.?\d{0,2}')),
                            ],
                            style: GoogleFonts.montserrat(fontSize: 12),
                            decoration: InputDecoration(
                              prefixText: '\$ ',
                              prefixStyle: GoogleFonts.montserrat(
                                  fontSize: 12,
                                  color: Colors.grey.shade500),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                    color: Colors.grey.shade300),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                    color: Colors.grey.shade300),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),

              const SizedBox(height: 20),

              // ── Section 4: Site Details ──
              _sectionHeader('Site Details'),
              // Has grass toggle
              Row(
                children: [
                  Text('Has Grass',
                      style: GoogleFonts.montserrat(fontSize: 12)),
                  const SizedBox(width: 8),
                  Switch(
                    value: _hasGrass,
                    activeTrackColor: _greenAccent,
                    onChanged: (v) => setState(() => _hasGrass = v),
                  ),
                ],
              ),
              // Extra services
              Text('Extra Services Required',
                  style: GoogleFonts.montserrat(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _darkGreen)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: Proposal.defaultExtraServices.map((service) {
                  final selected = _selectedExtras.contains(service);
                  return ChoiceChip(
                    label: Text(service,
                        style: GoogleFonts.montserrat(
                          fontSize: 10,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: selected ? Colors.white : _darkGreen,
                        )),
                    selected: selected,
                    selectedColor: _darkGreen,
                    backgroundColor: Colors.white,
                    side: BorderSide(
                        color: selected
                            ? _darkGreen
                            : Colors.grey.shade300),
                    showCheckmark: false,
                    onSelected: (_) {
                      setState(() {
                        if (selected) {
                          _selectedExtras.remove(service);
                        } else {
                          _selectedExtras.add(service);
                        }
                      });
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),

              // ── Section 5: Details ──
              _sectionHeader('Additional Details'),
              // Due date
              GestureDetector(
                onTap: _pickDueDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.event, size: 18, color: Colors.grey.shade500),
                      const SizedBox(width: 10),
                      Text(
                        _dueDate != null
                            ? 'Due: ${DateFormat('MMMM d, yyyy').format(_dueDate!)}'
                            : 'Set Due Date',
                        style: GoogleFonts.montserrat(
                          fontSize: 13,
                          color: _dueDate != null
                              ? _darkGreen
                              : Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _textField(_notesController, 'Notes / Conditions',
                  Icons.note, maxLines: 3),

              const SizedBox(height: 24),

              // Save buttons
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        onPressed:
                            _isSaving ? null : () => _save(status: 'draft'),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: _darkGreen),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2))
                            : Text('Save Draft',
                                style: GoogleFonts.montserrat(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: _darkGreen)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed:
                            _isSaving ? null : () => _save(status: 'sent'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _darkGreen,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text('Send Proposal',
                            style: GoogleFonts.montserrat(
                                fontSize: 13, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Text(
        text,
        style: GoogleFonts.montserrat(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: _darkGreen,
        ),
      ),
    );
  }

  Widget _textField(
    TextEditingController controller,
    String hint,
    IconData icon, {
    bool required = false,
    bool isNumber = false,
    int maxLines = 1,
    ValueChanged<String>? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      onChanged: onChanged,
      keyboardType: isNumber
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      inputFormatters: isNumber
          ? [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))]
          : null,
      decoration: _inputDecoration(hint, icon),
      validator: required
          ? (v) => v == null || v.trim().isEmpty ? 'Required' : null
          : null,
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      labelText: hint,
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
}
