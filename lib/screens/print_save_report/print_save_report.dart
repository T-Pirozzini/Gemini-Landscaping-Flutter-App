import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:gemini_landscaping_app/models/site_report.dart';

class PrintSaveReport extends StatefulWidget {
  final SiteReport report;
  PrintSaveReport({required this.report});

  @override
  State<PrintSaveReport> createState() => _PrintSaveReportState(report: report);
}

class _PrintSaveReportState extends State<PrintSaveReport> {
  final SiteReport report;
  _PrintSaveReportState({required this.report});
  final pdf = pw.Document();

  // get current year
  final String year = DateTime.now().year.toString();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 31, 182, 77),
        leading: IconButton(
          icon: const Icon(Icons.arrow_circle_left_outlined),
          onPressed: () => Navigator.pop(context),
        ),
        leadingWidth: 100,
        title: Image.asset("assets/gemini-icon-transparent.png",
            color: Colors.white, fit: BoxFit.contain, height: 50),
        centerTitle: true,
      ),
      body: PdfPreview(
        maxPageWidth: 1000,
        canChangeOrientation: false,
        canDebug: false,
        build: (format) => generateDocument(
          format,
        ),
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

    // convert string amounts to a double
    double totalAmount = 0.0;

    for (var material in report.materials) {
      if (material.cost.isNotEmpty) {
        double amountValue = double.tryParse(material.cost) ?? 0.0;
        totalAmount += amountValue;
      }
    }

    doc.addPage(
      pw.Page(
        pageTheme: pw.PageTheme(
          pageFormat: format.copyWith(
            marginBottom: 10,
            marginLeft: 20,
            marginRight: 20,
            marginTop: 10,
          ),
          orientation: pw.PageOrientation.portrait,
          theme: pw.ThemeData.withFont(
            base: font1,
            bold: font2,
          ),
        ),
        build: (context) {
          return pw.Column(
            children: [
              pw.Align(
                alignment: pw.Alignment.topLeft,
                child: report.isRegularMaintenance
                    ? pw.Text(
                        "Regular Maintenance Report",
                        style: pw.TextStyle(
                          fontSize: 12,
                          color: PdfColor(0.5, 0.8, 0.3, 1),
                        ),
                      )
                    : pw.Text(
                        "Additional Service Report",
                        style: pw.TextStyle(
                          fontSize: 12,
                          color: PdfColor(0.4, 0.5, 0.7, 1),
                        ),
                      ),
              ),

              pw.Expanded(
                child: pw.Container(
                  child: pw.SvgImage(
                    svg: _gemini_logo,
                    height: 80,
                  ),
                ),
              ),
              pw.SizedBox(height: 25),
              pw.Center(
                child: pw.Text(
                  'SITE REPORT $year',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(
                height: 10,
              ),
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'DATE: ',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'ID #:',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        report.date,
                        style: pw.TextStyle(
                          fontSize: 12,
                        ),
                      ),
                      pw.Text(
                        report.id.substring(report.id.length - 5),
                        style: const pw.TextStyle(
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'SITE NAME: ',
                        style: pw.TextStyle(
                            fontSize: 12, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text(
                        'ADDRESS: ',
                        style: pw.TextStyle(
                            fontSize: 12, fontWeight: pw.FontWeight.bold),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        report.siteName,
                        style: const pw.TextStyle(
                          fontSize: 12,
                        ),
                      ),
                      pw.Text(
                        report.address,
                        style: const pw.TextStyle(
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // pw.Spacer(),
              // Team & Time ON/OFF Table
              pw.Container(
                margin: const pw.EdgeInsets.all(10.0),
                child: pw.Table(
                  border: pw.TableBorder.all(),
                  children: [
                    pw.TableRow(children: [
                      pw.Container(
                        alignment: pw.Alignment.center,
                        color: report.isRegularMaintenance
                            ? PdfColor(0.5, 0.8, 0.3, 0.1)
                            : PdfColor(0.4, 0.5, 0.7, 0.2),
                        height: 15,
                        child: pw.Text('NAME',
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Container(
                        alignment: pw.Alignment.center,
                        color: report.isRegularMaintenance
                            ? PdfColor(0.5, 0.8, 0.3, 0.1)
                            : PdfColor(0.4, 0.5, 0.7, 0.2),
                        height: 15,
                        child: pw.Text('ON',
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Container(
                        alignment: pw.Alignment.center,
                        color: report.isRegularMaintenance
                            ? PdfColor(0.5, 0.8, 0.3, 0.1)
                            : PdfColor(0.4, 0.5, 0.7, 0.2),
                        height: 15,
                        child: pw.Text('OFF',
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Container(
                        alignment: pw.Alignment.center,
                        color: report.isRegularMaintenance
                            ? PdfColor(0.5, 0.8, 0.3, 0.1)
                            : PdfColor(0.4, 0.5, 0.7, 0.2),
                        height: 15,
                        child: pw.Text('HOURS',
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                    ]),
                    ...report.employees.map((employee) {
                      return pw.TableRow(children: [
                        pw.Container(
                          alignment: pw.Alignment.center,
                          child: pw.Text(employee.name,
                              style: const pw.TextStyle(fontSize: 10)),
                        ),
                        pw.Container(
                          alignment: pw.Alignment.center,
                          child: pw.Text(
                            DateFormat('hh:mm a')
                                .format(employee.timeOn.toLocal()),
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                        ),
                        pw.Container(
                          alignment: pw.Alignment.center,
                          child: pw.Text(
                            DateFormat('hh:mm a')
                                .format(employee.timeOff.toLocal()),
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                        ),
                        pw.Container(
                          alignment: pw.Alignment.center,
                          child: pw.Text(
                              "${(employee.duration / 60).toStringAsFixed(1)} hrs",
                              style: const pw.TextStyle(fontSize: 10)),
                        )
                      ]);
                    }).toList(),
                    pw.TableRow(
                      children: [
                        pw.Text(''),
                        pw.Text(''),
                        pw.Container(
                          alignment: pw.Alignment.centerRight,
                          child: pw.Text('Total:',
                              style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 10)),
                        ),
                        pw.Container(
                          alignment: pw.Alignment.center,
                          child: pw.Text(
                              "${(report.totalCombinedDuration / 60).toStringAsFixed(1)} hrs",
                              style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 10)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // pw.Spacer(),
              pw.Divider(),
              // SERVICES TABLE
              pw.Container(
                alignment: pw.Alignment.topLeft,
                child: pw.Text("SERVICES PROVIDED:",
                    style: pw.TextStyle(
                        fontSize: 12, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(height: 5),
              pw.Container(
                margin: const pw.EdgeInsets.only(left: 10.0, right: 10.0),
                child: pw.Table(
                  children: report.services.entries.map((entry) {
                    final serviceKey = entry.key;
                    final serviceItems = entry.value;

                    return pw.TableRow(
                      decoration: pw.BoxDecoration(
                        border: pw.TableBorder(
                          bottom: pw.BorderSide(
                              color: report.isRegularMaintenance
                                  ? PdfColor(0.5, 0.8, 0.3, 0.1)
                                  : PdfColor(0.4, 0.5, 0.7, 0.2),
                              width: 2),
                          top: pw.BorderSide(
                              color: report.isRegularMaintenance
                                  ? PdfColor(0.5, 0.8, 0.3, 0.1)
                                  : PdfColor(0.4, 0.5, 0.7, 0.2),
                              width: 2),
                        ),
                      ),
                      children: [
                        pw.Container(
                          child: pw.Text(
                            '$serviceKey:',
                            style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold, fontSize: 10),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.only(bottom: 5.0),
                          child: pw.Container(
                            child: pw.Wrap(
                              spacing: 5,
                              runSpacing: 5,
                              children: serviceItems.map((item) {
                                return pw.Text(item,
                                    style: const pw.TextStyle(fontSize: 10));
                              }).toList(),
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
              // pw.Spacer(),
              pw.Divider(),
              // DESCRIPTION
              pw.Container(
                alignment: pw.Alignment.topLeft,
                child: pw.Text("DESCRIPTION:",
                    style: pw.TextStyle(
                        fontSize: 12, fontWeight: pw.FontWeight.bold)),
              ),
              pw.Container(
                alignment: pw.Alignment.topLeft,
                child: pw.Text(report.description,
                    style: const pw.TextStyle(fontSize: 10)),
              ),
              // pw.Spacer(),
              pw.Divider(),
              // MATERIALS TABLE
              pw.Container(
                margin: const pw.EdgeInsets.all(10.0),
                child: pw.Table(
                  border: pw.TableBorder.all(),
                  children: [
                    pw.TableRow(children: [
                      pw.Container(
                        alignment: pw.Alignment.center,
                        color: report.isRegularMaintenance
                            ? PdfColor(0.5, 0.8, 0.3, 0.1)
                            : PdfColor(0.4, 0.5, 0.7, 0.2),
                        height: 15,
                        child: pw.Text('MATERIAL',
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Container(
                        alignment: pw.Alignment.center,
                        color: report.isRegularMaintenance
                            ? PdfColor(0.5, 0.8, 0.3, 0.1)
                            : PdfColor(0.4, 0.5, 0.7, 0.2),
                        height: 15,
                        child: pw.Text('VENDOR',
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Container(
                        alignment: pw.Alignment.center,
                        color: report.isRegularMaintenance
                            ? PdfColor(0.5, 0.8, 0.3, 0.1)
                            : PdfColor(0.4, 0.5, 0.7, 0.2),
                        height: 15,
                        child: pw.Text('AMOUNT \$',
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                    ]),
                    ...report.materials.map((material) {
                      return pw.TableRow(children: [
                        pw.Container(
                          alignment: pw.Alignment.center,
                          child: pw.Text(material.description,
                              style: const pw.TextStyle(fontSize: 10)),
                        ),
                        pw.Container(
                          alignment: pw.Alignment.center,
                          child: pw.Text(material.vendor,
                              style: const pw.TextStyle(fontSize: 10)),
                        ),
                        pw.Container(
                          alignment: pw.Alignment.center,
                          child: pw.Text(material.cost,
                              style: const pw.TextStyle(fontSize: 10)),
                        ),
                      ]);
                    }).toList(),
                    pw.TableRow(
                      children: [
                        pw.Text(''),
                        pw.Container(
                          alignment: pw.Alignment.centerRight,
                          child: pw.Text('Total:',
                              style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 10)),
                        ),
                        pw.Container(
                          alignment: pw.Alignment.center,
                          child: pw.Text(
                            '${totalAmount.toStringAsFixed(2)}',
                            style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold, fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              pw.Spacer(),
              pw.Text('Submitted by: ${report.submittedBy}',
                  style: const pw.TextStyle(fontSize: 10)),
            ],
          );
        },
      ),
    );

    return doc.save();
  }
}
