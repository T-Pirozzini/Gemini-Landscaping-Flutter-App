import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gemini_landscaping_app/models/proposal.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ProposalPdf extends StatelessWidget {
  final Proposal proposal;

  const ProposalPdf({super.key, required this.proposal});

  @override
  Widget build(BuildContext context) {
    final fileName = '${proposal.siteName} - Proposal';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 31, 182, 77),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Proposal PDF',
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

    final accent = PdfColor(0.12, 0.71, 0.30);
    final grey = PdfColors.grey600;
    final lightBg = PdfColor(0.95, 0.97, 0.95);

    doc.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: format.copyWith(
            marginBottom: 20,
            marginLeft: 24,
            marginRight: 24,
            marginTop: 16,
          ),
          theme: pw.ThemeData.withFont(base: font1, bold: font2),
        ),
        header: (context) => pw.Column(
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.SvgImage(svg: geminiLogo, width: 120, height: 40),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('LANDSCAPE PROPOSAL',
                        style: pw.TextStyle(
                            font: font2, fontSize: 16, color: accent)),
                    if (proposal.dueDate != null)
                      pw.Text(
                          'Due: ${DateFormat('MMMM d, yyyy').format(proposal.dueDate!)}',
                          style: pw.TextStyle(
                              font: font1, fontSize: 9, color: grey)),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 4),
            pw.Container(height: 2, color: accent),
            pw.SizedBox(height: 12),
          ],
        ),
        footer: (context) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Gemini Landscaping Ltd.',
                style: pw.TextStyle(font: font1, fontSize: 8, color: grey)),
            pw.Text('Page ${context.pageNumber} of ${context.pagesCount}',
                style: pw.TextStyle(font: font1, fontSize: 8, color: grey)),
          ],
        ),
        build: (context) => [
          // Site info section
          _pdfSection(font2, accent, 'Site Information'),
          _pdfRow(font1, font2, 'Site Name', proposal.siteName),
          if (proposal.siteAddress.isNotEmpty)
            _pdfRow(font1, font2, 'Address', proposal.siteAddress),
          if (proposal.contactName.isNotEmpty)
            _pdfRow(font1, font2, 'Contact', proposal.contactName),
          if (proposal.managementCompany.isNotEmpty)
            _pdfRow(font1, font2, 'Management', proposal.managementCompany),
          pw.SizedBox(height: 16),

          // Terms
          _pdfSection(font2, accent, 'Terms'),
          if (proposal.paymentTerm.isNotEmpty)
            _pdfRow(font1, font2, 'Payment Term', proposal.paymentTerm),
          if (proposal.serviceTerm.isNotEmpty)
            _pdfRow(font1, font2, 'Service Term', proposal.serviceTerm),
          if (proposal.serviceMonths.isNotEmpty)
            _pdfRow(
                font1, font2, 'Service Months', proposal.serviceMonths.join(', ')),
          pw.SizedBox(height: 16),

          // Financial
          _pdfSection(font2, accent, 'Financial Summary'),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: lightBg,
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                pw.Column(children: [
                  pw.Text('Monthly Rate',
                      style:
                          pw.TextStyle(font: font1, fontSize: 9, color: grey)),
                  pw.Text('\$${proposal.monthlyRate.toStringAsFixed(2)}',
                      style: pw.TextStyle(font: font2, fontSize: 14)),
                ]),
                pw.Column(children: [
                  pw.Text('Annual Rate',
                      style:
                          pw.TextStyle(font: font1, fontSize: 9, color: grey)),
                  pw.Text('\$${proposal.annualRate.toStringAsFixed(2)}',
                      style: pw.TextStyle(
                          font: font2, fontSize: 14, color: accent)),
                ]),
              ],
            ),
          ),
          pw.SizedBox(height: 16),

          // Payment schedule table
          if (proposal.paymentSchedule.isNotEmpty) ...[
            _pdfSection(font2, accent, 'Payment Schedule'),
            pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(font: font2, fontSize: 10),
              cellStyle: pw.TextStyle(font: font1, fontSize: 10),
              headerDecoration:
                  pw.BoxDecoration(color: PdfColor(0.23, 0.32, 0.28)),
              headerCellDecoration: const pw.BoxDecoration(),
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.center,
                2: pw.Alignment.centerRight,
              },
              headers: ['Month', 'Service', 'Amount'],
              data: proposal.paymentSchedule.map((p) {
                return [
                  p.month,
                  p.isServiceMonth ? 'Yes' : '-',
                  '\$${p.amount.toStringAsFixed(2)}',
                ];
              }).toList(),
              border: pw.TableBorder.all(color: PdfColors.grey300),
              cellHeight: 22,
              oddRowDecoration: pw.BoxDecoration(color: lightBg),
            ),
            pw.SizedBox(height: 16),
          ],

          // Site details
          _pdfSection(font2, accent, 'Site Details'),
          _pdfRow(font1, font2, 'Has Grass', proposal.hasGrass ? 'Yes' : 'No'),
          if (proposal.extraServices.isNotEmpty)
            _pdfRow(
                font1, font2, 'Extra Services', proposal.extraServices.join(', ')),
          pw.SizedBox(height: 16),

          // Notes
          if (proposal.notes.isNotEmpty) ...[
            _pdfSection(font2, accent, 'Notes & Conditions'),
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Text(proposal.notes,
                  style: pw.TextStyle(font: font1, fontSize: 10)),
            ),
            pw.SizedBox(height: 16),
          ],

          // Signature lines
          pw.SizedBox(height: 24),
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Client Signature:',
                        style: pw.TextStyle(font: font2, fontSize: 10)),
                    pw.SizedBox(height: 30),
                    pw.Container(height: 1, color: PdfColors.grey400),
                    pw.SizedBox(height: 4),
                    pw.Text('Date: ____________',
                        style: pw.TextStyle(
                            font: font1, fontSize: 9, color: grey)),
                  ],
                ),
              ),
              pw.SizedBox(width: 40),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Gemini Landscaping:',
                        style: pw.TextStyle(font: font2, fontSize: 10)),
                    pw.SizedBox(height: 30),
                    pw.Container(height: 1, color: PdfColors.grey400),
                    pw.SizedBox(height: 4),
                    pw.Text('Date: ____________',
                        style: pw.TextStyle(
                            font: font1, fontSize: 9, color: grey)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );

    return doc.save();
  }

  pw.Widget _pdfSection(pw.Font font, PdfColor color, String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Text(title,
          style: pw.TextStyle(font: font, fontSize: 12, color: color)),
    );
  }

  pw.Widget _pdfRow(
      pw.Font font1, pw.Font font2, String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 100,
            child: pw.Text(label,
                style: pw.TextStyle(
                    font: font1, fontSize: 10, color: PdfColors.grey600)),
          ),
          pw.Expanded(
            child:
                pw.Text(value, style: pw.TextStyle(font: font2, fontSize: 10)),
          ),
        ],
      ),
    );
  }
}
