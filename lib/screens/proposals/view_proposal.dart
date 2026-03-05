import 'package:flutter/material.dart';
import 'package:gemini_landscaping_app/models/proposal.dart';
import 'package:gemini_landscaping_app/screens/proposals/create_proposal.dart';
import 'package:gemini_landscaping_app/screens/proposals/proposal_pdf.dart';
import 'package:gemini_landscaping_app/services/firestore_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class ViewProposal extends StatelessWidget {
  final Proposal proposal;

  const ViewProposal({super.key, required this.proposal});

  static const _darkGreen = Color.fromARGB(255, 59, 82, 73);
  static const _greenAccent = Color.fromARGB(255, 31, 182, 77);

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
        title: Text('Proposal',
            style: GoogleFonts.montserrat(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf,
                size: 20, color: Colors.white),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => ProposalPdf(proposal: proposal)),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Status
          Center(child: _statusBadge()),
          const SizedBox(height: 16),

          // Site info
          _card([
            _detailRow('Site', proposal.siteName),
            if (proposal.siteAddress.isNotEmpty)
              _detailRow('Address', proposal.siteAddress),
            if (proposal.contactName.isNotEmpty)
              _detailRow('Contact', proposal.contactName),
            if (proposal.managementCompany.isNotEmpty)
              _detailRow('Management', proposal.managementCompany),
          ]),
          const SizedBox(height: 12),

          // Terms
          _card([
            _sectionTitle('Terms'),
            if (proposal.paymentTerm.isNotEmpty)
              _detailRow('Payment', proposal.paymentTerm),
            if (proposal.serviceTerm.isNotEmpty)
              _detailRow('Service', proposal.serviceTerm),
            if (proposal.serviceMonths.isNotEmpty)
              _detailRow('Months', proposal.serviceMonths.join(', ')),
            if (proposal.dueDate != null)
              _detailRow(
                  'Due Date', DateFormat('MMMM d, yyyy').format(proposal.dueDate!)),
          ]),
          const SizedBox(height: 12),

          // Financial
          _card([
            _sectionTitle('Financial'),
            _costRow('Monthly Rate', proposal.monthlyRate),
            _costRow('Annual Rate', proposal.annualRate, bold: true),
          ]),
          const SizedBox(height: 12),

          // Payment schedule
          if (proposal.paymentSchedule.isNotEmpty)
            _card([
              _sectionTitle('Payment Schedule'),
              ...proposal.paymentSchedule.map((p) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 70,
                          child: Text(p.month.substring(0, 3),
                              style: GoogleFonts.montserrat(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: p.isServiceMonth
                                    ? _darkGreen
                                    : Colors.grey,
                              )),
                        ),
                        if (p.isServiceMonth)
                          Icon(Icons.grass,
                              size: 12, color: _greenAccent)
                        else
                          const SizedBox(width: 12),
                        const SizedBox(width: 8),
                        Text('\$${p.amount.toStringAsFixed(2)}',
                            style: GoogleFonts.montserrat(fontSize: 11)),
                      ],
                    ),
                  )),
            ]),
          const SizedBox(height: 12),

          // Site details
          _card([
            _sectionTitle('Site Details'),
            _detailRow('Has Grass', proposal.hasGrass ? 'Yes' : 'No'),
            if (proposal.extraServices.isNotEmpty)
              _detailRow('Extras', proposal.extraServices.join(', ')),
          ]),

          if (proposal.notes.isNotEmpty) ...[
            const SizedBox(height: 12),
            _card([
              _sectionTitle('Notes'),
              Text(proposal.notes,
                  style: GoogleFonts.montserrat(fontSize: 12)),
            ]),
          ],

          const SizedBox(height: 16),
          _buildActions(context),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _statusBadge() {
    Color c;
    switch (proposal.status) {
      case 'sent':
        c = Colors.blue;
        break;
      case 'accepted':
        c = _greenAccent;
        break;
      case 'declined':
        c = Colors.red.shade400;
        break;
      default:
        c = Colors.orange;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        proposal.status[0].toUpperCase() + proposal.status.substring(1),
        style: GoogleFonts.montserrat(
            fontSize: 13, fontWeight: FontWeight.w600, color: c),
      ),
    );
  }

  Widget _card(List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text,
          style: GoogleFonts.montserrat(
              fontSize: 12, fontWeight: FontWeight.w600, color: _darkGreen)),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(label,
                style: GoogleFonts.montserrat(
                    fontSize: 11, color: Colors.grey.shade600)),
          ),
          Expanded(
            child: Text(value,
                style: GoogleFonts.montserrat(
                    fontSize: 12, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
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
          Text('\$${amount.toStringAsFixed(2)}',
              style: GoogleFonts.montserrat(
                fontSize: 12,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                color: bold ? _darkGreen : Colors.grey.shade700,
              )),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (proposal.status == 'draft') ...[
          _actionButton(context, 'Edit', Icons.edit, Colors.orange,
              () => _edit(context)),
          _actionButton(context, 'Send', Icons.send, Colors.blue,
              () => _updateStatus(context, 'sent')),
        ],
        if (proposal.status == 'sent') ...[
          _actionButton(context, 'Accept', Icons.check_circle,
              _greenAccent, () => _updateStatus(context, 'accepted')),
          _actionButton(context, 'Decline', Icons.cancel,
              Colors.red.shade400, () => _updateStatus(context, 'declined')),
        ],
        _actionButton(context, 'Duplicate', Icons.copy, _darkGreen,
            () => _duplicate(context)),
        _actionButton(context, 'PDF', Icons.picture_as_pdf, _darkGreen,
            () => _generatePdf(context)),
      ],
    );
  }

  Widget _actionButton(BuildContext context, String label, IconData icon,
      Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(label,
                style: GoogleFonts.montserrat(
                    fontSize: 11, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      ),
    );
  }

  void _edit(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
          builder: (_) => CreateProposal(existing: proposal)),
    );
  }

  Future<void> _updateStatus(BuildContext context, String status) async {
    await FirestoreService().updateProposalStatus(proposal.id, status);
    if (context.mounted) Navigator.pop(context);
  }

  void _duplicate(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => CreateProposal(existing: proposal)),
    );
  }

  void _generatePdf(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => ProposalPdf(proposal: proposal)),
    );
  }
}
