import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gemini_landscaping_app/models/field_quote.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class FieldQuotePdf extends StatelessWidget {
  final FieldQuote quote;

  const FieldQuotePdf({super.key, required this.quote});

  @override
  Widget build(BuildContext context) {
    final fileName = '${quote.date} - ${quote.siteName} - Quote';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 31, 182, 77),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Quote PDF',
            style: GoogleFonts.montserrat(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white)),
        centerTitle: true,
      ),
      body: PdfPreview(
        maxPageWidth: 1000,
        canChangeOrientation: false,
        canDebug: false,
        pdfFileName: '$fileName.pdf',
        build: (format) => _generatePdf(format),
      ),
    );
  }

  Future<Uint8List> _generatePdf(PdfPageFormat format) async {
    final doc = pw.Document(pageMode: PdfPageMode.outlines);

    final font1 = await PdfGoogleFonts.latoRegular();
    final font2 = await PdfGoogleFonts.latoBold();

    final geminiLogo =
        await rootBundle.loadString('assets/gemini_logo.svg');

    final accentColor = PdfColor(0.12, 0.71, 0.30);

    doc.addPage(
      pw.Page(
        pageTheme: pw.PageTheme(
          pageFormat: format.copyWith(
            marginBottom: 20,
            marginLeft: 24,
            marginRight: 24,
            marginTop: 16,
          ),
          theme: pw.ThemeData.withFont(base: font1, bold: font2),
        ),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.SvgImage(
                    svg: geminiLogo,
                    width: 120,
                    height: 40,
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('FIELD QUOTE',
                          style: pw.TextStyle(
                            font: font2,
                            fontSize: 18,
                            color: accentColor,
                          )),
                      pw.Text(quote.date,
                          style: pw.TextStyle(
                              font: font1,
                              fontSize: 10,
                              color: PdfColors.grey700)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Container(
                height: 2,
                color: accentColor,
              ),
              pw.SizedBox(height: 16),

              // Site & client info
              _pdfInfoRow(font1, font2, 'Site', quote.siteName),
              _pdfInfoRow(font1, font2, 'Client', quote.clientName),
              _pdfInfoRow(font1, font2, 'Date', quote.date),
              _pdfInfoRow(font1, font2, 'Prepared By', quote.createdByName),
              pw.SizedBox(height: 16),

              // Description
              pw.Text('Description of Work',
                  style: pw.TextStyle(
                      font: font2, fontSize: 12, color: accentColor)),
              pw.SizedBox(height: 6),
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text(quote.description,
                    style: pw.TextStyle(font: font1, fontSize: 11)),
              ),
              pw.SizedBox(height: 20),

              // Cost breakdown
              pw.Text('Cost Breakdown',
                  style: pw.TextStyle(
                      font: font2, fontSize: 12, color: accentColor)),
              pw.SizedBox(height: 6),
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Column(
                  children: [
                    _pdfCostRow(font1, 'Subtotal',
                        '\$${quote.subtotal.toStringAsFixed(2)}'),
                    _pdfCostRow(font1, 'GST (5%)',
                        '\$${quote.gstAmount.toStringAsFixed(2)}'),
                    pw.Divider(color: PdfColors.grey300),
                    _pdfCostRow(font2, 'Total',
                        '\$${quote.total.toStringAsFixed(2)}'),
                  ],
                ),
              ),
              pw.SizedBox(height: 24),

              // Signature
              if (quote.signatureBase64 != null) ...[
                pw.Text('Client Approval & Signature',
                    style: pw.TextStyle(
                        font: font2, fontSize: 12, color: accentColor)),
                pw.SizedBox(height: 8),
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Image(
                        pw.MemoryImage(base64Decode(quote.signatureBase64!)),
                        height: 60,
                      ),
                      pw.SizedBox(height: 4),
                      pw.Divider(color: PdfColors.grey400),
                      pw.Text(
                        '${quote.clientName} - Signed ${quote.signedAt != null ? _formatDate(quote.signedAt!) : quote.date}',
                        style: pw.TextStyle(
                            font: font1,
                            fontSize: 9,
                            color: PdfColors.grey600),
                      ),
                    ],
                  ),
                ),
              ],
              if (quote.signatureBase64 == null) ...[
                pw.SizedBox(height: 20),
                pw.Text('Client Signature:',
                    style: pw.TextStyle(font: font2, fontSize: 11)),
                pw.SizedBox(height: 30),
                pw.Container(height: 1, color: PdfColors.grey400),
                pw.SizedBox(height: 4),
                pw.Text('Date: ____________',
                    style: pw.TextStyle(
                        font: font1,
                        fontSize: 10,
                        color: PdfColors.grey600)),
              ],

              pw.Spacer(),

              // Footer
              pw.Divider(color: PdfColors.grey300),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Gemini Landscaping Ltd.',
                      style: pw.TextStyle(
                          font: font1,
                          fontSize: 8,
                          color: PdfColors.grey500)),
                  pw.Text('Field Quote',
                      style: pw.TextStyle(
                          font: font1,
                          fontSize: 8,
                          color: PdfColors.grey500)),
                ],
              ),
            ],
          );
        },
      ),
    );

    return doc.save();
  }

  pw.Widget _pdfInfoRow(
      pw.Font font1, pw.Font font2, String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 80,
            child: pw.Text(label,
                style: pw.TextStyle(
                    font: font1, fontSize: 10, color: PdfColors.grey600)),
          ),
          pw.Text(value,
              style: pw.TextStyle(font: font2, fontSize: 11)),
        ],
      ),
    );
  }

  pw.Widget _pdfCostRow(pw.Font font, String label, String amount) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(font: font, fontSize: 11)),
          pw.Text(amount, style: pw.TextStyle(font: font, fontSize: 11)),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}
