import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:gemini_landscaping_app/models/site_report.dart';
import 'package:timezone/timezone.dart' as tz;

class PrintSaveReport extends StatefulWidget {
  final SiteReport report;
  PrintSaveReport({required this.report});

  @override
  State<PrintSaveReport> createState() =>
      _PrintSaveReportState(report: report);
}

class _PrintSaveReportState extends State<PrintSaveReport> {
  final SiteReport report;
  _PrintSaveReportState({required this.report});

  @override
  Widget build(BuildContext context) {
    final parsedDate = DateFormat('MMMM d, yyyy').parse(report.date);
    final formattedDate = DateFormat('MMM d, yyyy').format(parsedDate);
    final fileName = '$formattedDate - ${report.siteName}';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 31, 182, 77),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Image.asset("assets/gemini-icon-transparent.png",
            color: Colors.white, fit: BoxFit.contain, height: 50),
        centerTitle: true,
      ),
      body: PdfPreview(
        maxPageWidth: 1000,
        canChangeOrientation: false,
        canDebug: false,
        pdfFileName: '$fileName.pdf',
        build: (format) => generateDocument(format),
      ),
    );
  }

  Future<Uint8List> generateDocument(PdfPageFormat format) async {
    final doc = pw.Document(pageMode: PdfPageMode.outlines);

    final font1 = await PdfGoogleFonts.latoRegular();
    final font2 = await PdfGoogleFonts.latoBold();

    // ignore: non_constant_identifier_names
    String? _gemini_logo =
        await rootBundle.loadString('assets/gemini_logo.svg');

    // Calculate material totals
    double totalAmount = 0.0;
    for (var material in report.materials) {
      if (material.cost.isNotEmpty) {
        totalAmount += double.tryParse(material.cost) ?? 0.0;
      }
    }

    final vancouver = tz.getLocation('America/Vancouver');

    // Use the report's actual year, not current year
    final reportYear =
        DateFormat('MMMM d, yyyy').parse(report.date).year.toString();

    // Colors
    final accentColor = report.isRegularMaintenance
        ? PdfColor(0.12, 0.71, 0.30)  // green
        : PdfColor(0.38, 0.49, 0.55); // blueGrey
    final lightAccent = report.isRegularMaintenance
        ? PdfColor(0.12, 0.71, 0.30, 0.08)
        : PdfColor(0.38, 0.49, 0.55, 0.08);

    // Display-friendly submittedBy
    final submitterName = report.submittedBy.contains('@')
        ? report.submittedBy.split('@')[0]
        : report.submittedBy;
    final capitalizedSubmitter = submitterName.isNotEmpty
        ? submitterName[0].toUpperCase() +
            submitterName.substring(1).toLowerCase()
        : 'Unknown';

    doc.addPage(
      pw.Page(
        pageTheme: pw.PageTheme(
          pageFormat: format.copyWith(
            marginBottom: 20,
            marginLeft: 24,
            marginRight: 24,
            marginTop: 16,
          ),
          orientation: pw.PageOrientation.portrait,
          theme: pw.ThemeData.withFont(
            base: font1,
            bold: font2,
          ),
        ),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // --- HEADER ---
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.SvgImage(svg: _gemini_logo, height: 50),
                  pw.SizedBox(width: 12),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'SITE REPORT $reportYear',
                          style: pw.TextStyle(
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          report.isRegularMaintenance
                              ? 'Regular Maintenance'
                              : 'Additional Service',
                          style: pw.TextStyle(
                            fontSize: 10,
                            color: accentColor,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('ID: ${report.id.substring(report.id.length - 5)}',
                          style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                      pw.Text(report.date,
                          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 6),
              pw.Container(height: 2, color: accentColor),
              pw.SizedBox(height: 8),

              // --- SITE INFO ---
              pw.Row(
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(report.siteName,
                            style: pw.TextStyle(
                                fontSize: 14, fontWeight: pw.FontWeight.bold)),
                        pw.Text(report.address,
                            style: const pw.TextStyle(fontSize: 10)),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 10),

              // --- EMPLOYEES TABLE ---
              pw.Text('TEAM & TIME',
                  style: pw.TextStyle(
                      fontSize: 11, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 4),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: accentColor),
                    children: [
                      _pdfTableHeader('NAME'),
                      _pdfTableHeader('ON'),
                      _pdfTableHeader('OFF'),
                      _pdfTableHeader('HOURS'),
                    ],
                  ),
                  ...report.employees.asMap().entries.map((entry) {
                    final i = entry.key;
                    final employee = entry.value;
                    final rowColor =
                        i % 2 == 1 ? lightAccent : PdfColors.white;
                    return pw.TableRow(
                      decoration: pw.BoxDecoration(color: rowColor),
                      children: [
                        _pdfTableCell(employee.name),
                        _pdfTableCell(DateFormat('h:mm a').format(
                            tz.TZDateTime.from(employee.timeOn, vancouver))),
                        _pdfTableCell(DateFormat('h:mm a').format(
                            tz.TZDateTime.from(employee.timeOff, vancouver))),
                        _pdfTableCell(
                            '${(employee.duration / 60).toStringAsFixed(1)} hrs'),
                      ],
                    );
                  }).toList(),
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColors.grey100),
                    children: [
                      pw.Container(),
                      pw.Container(),
                      pw.Container(
                        alignment: pw.Alignment.centerRight,
                        padding: const pw.EdgeInsets.symmetric(
                            horizontal: 4, vertical: 3),
                        child: pw.Text('Total:',
                            style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 10)),
                      ),
                      pw.Container(
                        alignment: pw.Alignment.center,
                        padding: const pw.EdgeInsets.symmetric(vertical: 3),
                        child: pw.Text(
                            '${(report.totalCombinedDuration / 60).toStringAsFixed(1)} hrs',
                            style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 10)),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 10),

              // --- SERVICES ---
              pw.Text('SERVICES PROVIDED',
                  style: pw.TextStyle(
                      fontSize: 11, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 4),
              ...report.services.entries
                  .where((e) => e.value.isNotEmpty)
                  .map((entry) {
                return pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 3),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.SizedBox(
                        width: 80,
                        child: pw.Text('${entry.key}:',
                            style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 9)),
                      ),
                      pw.Expanded(
                        child: pw.Wrap(
                          spacing: 4,
                          runSpacing: 2,
                          children: entry.value.map((item) {
                            return pw.Container(
                              padding: const pw.EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 1),
                              decoration: pw.BoxDecoration(
                                border: pw.Border.all(color: PdfColors.grey400),
                                borderRadius:
                                    pw.BorderRadius.circular(3),
                              ),
                              child: pw.Text(item,
                                  style: const pw.TextStyle(fontSize: 8)),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              pw.SizedBox(height: 6),
              pw.Container(height: 1, color: PdfColors.grey300),
              pw.SizedBox(height: 6),

              // --- DISPOSAL ---
              if (report.disposal != null &&
                  report.disposal!.hasDisposal) ...[
                pw.Text('DISPOSAL',
                    style: pw.TextStyle(
                        fontSize: 11, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 3),
                pw.Row(
                  children: [
                    pw.Text('Location: ',
                        style: pw.TextStyle(
                            fontSize: 9, fontWeight: pw.FontWeight.bold)),
                    pw.Text(report.disposal!.location,
                        style: const pw.TextStyle(fontSize: 9)),
                    pw.SizedBox(width: 20),
                    pw.Text('Cost: ',
                        style: pw.TextStyle(
                            fontSize: 9, fontWeight: pw.FontWeight.bold)),
                    pw.Text('\$${report.disposal!.cost}',
                        style: const pw.TextStyle(fontSize: 9)),
                  ],
                ),
                pw.SizedBox(height: 6),
                pw.Container(height: 1, color: PdfColors.grey300),
                pw.SizedBox(height: 6),
              ],

              // --- SHIFT NOTES ---
              if (report.noteTags.isNotEmpty ||
                  report.description.isNotEmpty) ...[
                pw.Text('SHIFT NOTES',
                    style: pw.TextStyle(
                        fontSize: 11, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 3),
                if (report.noteTags.isNotEmpty)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 3),
                    child: pw.Wrap(
                      spacing: 4,
                      runSpacing: 2,
                      children: report.noteTags.map((tag) {
                        return pw.Container(
                          padding: const pw.EdgeInsets.symmetric(
                              horizontal: 4, vertical: 1),
                          decoration: pw.BoxDecoration(
                            color: lightAccent,
                            borderRadius: pw.BorderRadius.circular(3),
                          ),
                          child: pw.Text(tag,
                              style: const pw.TextStyle(fontSize: 8)),
                        );
                      }).toList(),
                    ),
                  ),
                if (report.description.isNotEmpty)
                  pw.Text(report.description,
                      style: const pw.TextStyle(fontSize: 9)),
                pw.SizedBox(height: 6),
                pw.Container(height: 1, color: PdfColors.grey300),
                pw.SizedBox(height: 6),
              ],

              // --- MATERIALS TABLE ---
              if (report.materials.isNotEmpty) ...[
                pw.Text('MATERIALS',
                    style: pw.TextStyle(
                        fontSize: 11, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 4),
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300),
                  children: [
                    pw.TableRow(
                      decoration: pw.BoxDecoration(color: accentColor),
                      children: [
                        _pdfTableHeader('MATERIAL'),
                        _pdfTableHeader('VENDOR'),
                        _pdfTableHeader('AMOUNT \$'),
                      ],
                    ),
                    ...report.materials.asMap().entries.map((entry) {
                      final i = entry.key;
                      final material = entry.value;
                      final rowColor =
                          i % 2 == 1 ? lightAccent : PdfColors.white;
                      return pw.TableRow(
                        decoration: pw.BoxDecoration(color: rowColor),
                        children: [
                          _pdfTableCell(material.description),
                          _pdfTableCell(material.vendor),
                          _pdfTableCell(material.cost),
                        ],
                      );
                    }).toList(),
                    pw.TableRow(
                      decoration: pw.BoxDecoration(color: PdfColors.grey100),
                      children: [
                        pw.Container(),
                        pw.Container(
                          alignment: pw.Alignment.centerRight,
                          padding: const pw.EdgeInsets.symmetric(
                              horizontal: 4, vertical: 3),
                          child: pw.Text('Total:',
                              style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 10)),
                        ),
                        pw.Container(
                          alignment: pw.Alignment.center,
                          padding: const pw.EdgeInsets.symmetric(vertical: 3),
                          child: pw.Text(
                            '\$${totalAmount.toStringAsFixed(2)}',
                            style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold, fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],

              pw.Spacer(),

              // --- FOOTER ---
              pw.Container(height: 1, color: PdfColors.grey300),
              pw.SizedBox(height: 6),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Submitted by: $capitalizedSubmitter',
                      style: const pw.TextStyle(fontSize: 9)),
                  pw.Text(
                      DateFormat('MMM d, yyyy h:mm a')
                          .format(report.timestamp),
                      style: pw.TextStyle(
                          fontSize: 8, color: PdfColors.grey600)),
                ],
              ),
            ],
          );
        },
      ),
    );

    return doc.save();
  }

  pw.Widget _pdfTableHeader(String text) {
    return pw.Container(
      alignment: pw.Alignment.center,
      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      child: pw.Text(text,
          style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 9,
              color: PdfColors.white)),
    );
  }

  pw.Widget _pdfTableCell(String text) {
    return pw.Container(
      alignment: pw.Alignment.center,
      padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 4),
      child: pw.Text(text, style: const pw.TextStyle(fontSize: 9)),
    );
  }
}
