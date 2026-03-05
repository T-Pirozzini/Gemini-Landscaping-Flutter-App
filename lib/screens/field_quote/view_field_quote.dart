import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:gemini_landscaping_app/models/field_quote.dart';
import 'package:gemini_landscaping_app/screens/field_quote/field_quote_pdf.dart';
import 'package:gemini_landscaping_app/screens/field_quote/signature_screen.dart';
import 'package:gemini_landscaping_app/services/firestore_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class ViewFieldQuote extends StatelessWidget {
  final FieldQuote quote;

  const ViewFieldQuote({super.key, required this.quote});

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
        title: Text(
          'Quote Details',
          style: GoogleFonts.montserrat(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf,
                size: 20, color: Colors.white),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => FieldQuotePdf(quote: quote)),
            ),
            tooltip: 'Generate PDF',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Status badge
          Center(child: _statusBadge()),
          const SizedBox(height: 16),

          // Quote details card
          _card([
            _detailRow('Site', quote.siteName),
            _detailRow('Client', quote.clientName),
            _detailRow('Date', quote.date),
            _detailRow('Created By', quote.createdByName),
          ]),
          const SizedBox(height: 12),

          // Description
          _card([
            Text('Description',
                style: GoogleFonts.montserrat(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _darkGreen)),
            const SizedBox(height: 6),
            Text(quote.description,
                style: GoogleFonts.montserrat(fontSize: 13)),
          ]),
          const SizedBox(height: 12),

          // Cost breakdown
          _card([
            Text('Cost Breakdown',
                style: GoogleFonts.montserrat(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _darkGreen)),
            const SizedBox(height: 6),
            _costRow('Subtotal', quote.subtotal),
            _costRow('GST (5%)', quote.gstAmount),
            const Divider(height: 12),
            _costRow('Total', quote.total, bold: true),
          ]),
          const SizedBox(height: 12),

          // Signature
          if (quote.signatureBase64 != null) ...[
            _card([
              Row(
                children: [
                  Expanded(
                    child: Text('Client Signature',
                        style: GoogleFonts.montserrat(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _darkGreen)),
                  ),
                  if (quote.signedAt != null)
                    Text(
                      'Signed ${DateFormat('MMM d, yyyy').format(quote.signedAt!)}',
                      style: GoogleFonts.montserrat(
                          fontSize: 10, color: _greenAccent),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Image.memory(
                  base64Decode(quote.signatureBase64!),
                  height: 80,
                ),
              ),
            ]),
            const SizedBox(height: 12),
          ],

          // Actions
          if (quote.status != 'completed') ...[
            const SizedBox(height: 8),
            _buildActions(context),
          ],
        ],
      ),
    );
  }

  Widget _statusBadge() {
    Color statusColor;
    String label;
    switch (quote.status) {
      case 'signed':
        statusColor = _greenAccent;
        label = 'Signed';
        break;
      case 'completed':
        statusColor = Colors.blueGrey;
        label = 'Completed';
        break;
      default:
        statusColor = Colors.orange;
        label = 'Created';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: GoogleFonts.montserrat(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: statusColor,
        ),
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

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
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

  Widget _buildActions(BuildContext context) {
    return Row(
      children: [
        if (quote.signatureBase64 == null)
          Expanded(
            child: _actionButton(
              context,
              'Get Signature',
              Icons.draw,
              _greenAccent,
              () => _captureSignature(context),
            ),
          ),
        if (quote.signatureBase64 == null) const SizedBox(width: 8),
        if (quote.status == 'signed')
          Expanded(
            child: _actionButton(
              context,
              'Mark Complete',
              Icons.check_circle,
              Colors.blueGrey,
              () => _markComplete(context),
            ),
          ),
        Expanded(
          child: _actionButton(
            context,
            'PDF',
            Icons.picture_as_pdf,
            _darkGreen,
            () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => FieldQuotePdf(quote: quote)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _actionButton(BuildContext context, String label, IconData icon,
      Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 2),
            Text(label,
                style: GoogleFonts.montserrat(
                    fontSize: 10, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      ),
    );
  }

  Future<void> _captureSignature(BuildContext context) async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const SignatureScreen()),
    );
    if (result != null) {
      await FirestoreService()
          .updateFieldQuoteSignature(quote.id, result);
      if (context.mounted) {
        Navigator.pop(context); // Pop back to list to refresh
      }
    }
  }

  Future<void> _markComplete(BuildContext context) async {
    await FirestoreService()
        .updateFieldQuoteStatus(quote.id, 'completed');
    if (context.mounted) {
      Navigator.pop(context);
    }
  }
}
