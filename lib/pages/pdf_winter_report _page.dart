import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

// ignore: must_be_immutable
class WinterSiteReport extends StatefulWidget {
  DocumentSnapshot docid;
  WinterSiteReport({required this.docid});
  @override
  State<WinterSiteReport> createState() => _WinterSiteReportState(docid: docid);
}

class _WinterSiteReportState extends State<WinterSiteReport> {
  DocumentSnapshot docid;
  _WinterSiteReportState({required this.docid});
  final pdf = pw.Document();

  var service;
  var date;
  var siteName;
  var address = '';

  var walkways;
  var liability;
  var other;

  var name1;
  var name2;
  var name3;
  var name4;

  var on1;
  var on2;
  var on3;
  var on4;
  var off1;
  var off2;
  var off3;
  var off4;

  var description = '';

  var iceMeltAmount = 0.0;
  var saltAmount = 0.0;
  var sandAmount = 0.0;

  var user = '';

  //get current user
  final currentUser = FirebaseAuth.instance.currentUser!;

  void initState() {
    setState(() {
      service = widget.docid['service']['iceManagement']
          ? 'Ice Management'
          : 'Snow Removal';
      date = widget.docid['info']['date'];
      siteName = widget.docid['info']['siteName'];
      address = widget.docid['info']['address'];

      name1 = widget.docid['names']['name1'];
      name2 = widget.docid['names']['name2'];
      name3 = widget.docid['names']['name3'];
      name4 = widget.docid['names']['name4'];
      on1 = widget.docid['times']['timeOn1'];
      on2 = widget.docid['times']['timeOn2'];
      on3 = widget.docid['times']['timeOn3'];
      on4 = widget.docid['times']['timeOn4'];
      off1 = widget.docid['times']['timeOff1'];
      off2 = widget.docid['times']['timeOff2'];
      off3 = widget.docid['times']['timeOff3'];
      off4 = widget.docid['times']['timeOff4'];

      walkways = widget.docid['service']['walkways'];
      liability = widget.docid['service']['liability'];
      other = widget.docid['service']['other'];

      description = widget.docid['description'];

      iceMeltAmount = widget.docid['material']['iceMelt'];
      saltAmount = widget.docid['material']['salt'];
      sandAmount = widget.docid['material']['sand'];

      final docData = widget.docid.data() as Map<String, dynamic>;
      final submittedByFieldExists = docData.containsKey('submittedBy') &&
          docData['submittedBy'] != null &&
          docData['submittedBy'].isNotEmpty;

      user = submittedByFieldExists ? docData['submittedBy'] : 'unspecified';
    });

    super.initState();
  }

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
          return pw.Container(
            child: pw.Column(
              children: [
                pw.Container(
                  child: pw.SvgImage(
                    svg: _gemini_logo,
                    height: 150,
                  ),
                ),
                pw.SizedBox(
                  height: 20,
                ),
                pw.Center(
                  child: pw.Text(
                    'WINTER REPORT 2023-2024',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(
                  height: 10,
                ),
                pw.Center(
                  child: pw.Text(
                    service,
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.Divider(),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: [
                    pw.Row(
                      children: [
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'DATE: ',
                              style: pw.TextStyle(
                                fontSize: 18,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.Text(
                              'ID #:',
                              style: pw.TextStyle(
                                fontSize: 18,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              date,
                              style: pw.TextStyle(
                                fontSize: 18,
                              ),
                            ),
                            pw.Text(
                              docid.id.substring(docid.id.length - 5),
                              style: const pw.TextStyle(
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    pw.Row(
                      children: [
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'SITE NAME: ',
                              style: pw.TextStyle(
                                  fontSize: 18, fontWeight: pw.FontWeight.bold),
                            ),
                            pw.Text(
                              'ADDRESS: ',
                              style: pw.TextStyle(
                                  fontSize: 18, fontWeight: pw.FontWeight.bold),
                            ),
                          ],
                        ),
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              siteName,
                              style: const pw.TextStyle(
                                fontSize: 20,
                              ),
                            ),
                            pw.Text(
                              address,
                              style: const pw.TextStyle(
                                fontSize: 20,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                // Team & Time ON/OFF Table
                pw.Container(
                  margin: const pw.EdgeInsets.all(20.0),
                  child: pw.Table(
                    border: pw.TableBorder.all(),
                    children: [
                      pw.TableRow(children: [
                        pw.Container(
                          alignment: pw.Alignment.center,
                          color: const PdfColor(0.5, 0.8, 0.3, 0.1),
                          height: 20,
                          child: pw.Text('NAME',
                              style:
                                  pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Container(
                          alignment: pw.Alignment.center,
                          color: const PdfColor(0.5, 0.8, 0.3, 0.1),
                          height: 20,
                          child: pw.Text('ON',
                              style:
                                  pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Container(
                          alignment: pw.Alignment.center,
                          color: const PdfColor(0.5, 0.8, 0.3, 0.1),
                          height: 20,
                          child: pw.Text('OFF',
                              style:
                                  pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Container(
                          alignment: pw.Alignment.center,
                          color: const PdfColor(0.5, 0.8, 0.3, 0.1),
                          height: 20,
                          child: pw.Text('HOURS',
                              style:
                                  pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                      ]),
                      pw.TableRow(children: [
                        pw.Container(
                          alignment: pw.Alignment.center,
                          child: pw.Text(name1),
                        ),
                        pw.Container(
                            alignment: pw.Alignment.center,
                            child: pw.Text(on1)),
                        pw.Container(
                            alignment: pw.Alignment.center,
                            child: pw.Text(off1)),
                        pw.Container(
                          alignment: pw.Alignment.center,
                          child: pw.Text(
                              "${(Duration(hours: int.parse(off1.split(":")[0]), minutes: int.parse(off1.split(":")[1])) - Duration(hours: int.parse(on1.split(":")[0]), minutes: int.parse(on1.split(":")[1]))).toString().substring(0, 4)}"),
                        )
                      ]),
                      pw.TableRow(children: [
                        pw.Container(
                          alignment: pw.Alignment.center,
                          child: pw.Text(name2),
                        ),
                        pw.Container(
                          alignment: pw.Alignment.center,
                          child: name2 == "" ? pw.Text("") : pw.Text(on2),
                        ),
                        pw.Container(
                          alignment: pw.Alignment.center,
                          child: name2 == "" ? pw.Text("") : pw.Text(off2),
                        ),
                        pw.Container(
                          alignment: pw.Alignment.center,
                          child: name2 == ""
                              ? pw.Text("")
                              : pw.Text(
                                  "${(Duration(hours: int.parse(off2.split(":")[0]), minutes: int.parse(off2.split(":")[1])) - Duration(hours: int.parse(on2.split(":")[0]), minutes: int.parse(on2.split(":")[1]))).toString().substring(0, 4)}"),
                        ),
                      ]),
                      pw.TableRow(children: [
                        pw.Container(
                          alignment: pw.Alignment.center,
                          child: pw.Text(name3),
                        ),
                        pw.Container(
                          alignment: pw.Alignment.center,
                          child: name3 == "" ? pw.Text("") : pw.Text(on3),
                        ),
                        pw.Container(
                          alignment: pw.Alignment.center,
                          child: name3 == "" ? pw.Text("") : pw.Text(off3),
                        ),
                        pw.Container(
                          alignment: pw.Alignment.center,
                          child: name3 == ""
                              ? pw.Text("")
                              : pw.Text(
                                  "${(Duration(hours: int.parse(off3.split(":")[0]), minutes: int.parse(off3.split(":")[1])) - Duration(hours: int.parse(on3.split(":")[0]), minutes: int.parse(on3.split(":")[1]))).toString().substring(0, 4)}"),
                        ),
                      ]),
                      pw.TableRow(children: [
                        pw.Container(
                          alignment: pw.Alignment.center,
                          child: pw.Text(name4),
                        ),
                        pw.Container(
                          alignment: pw.Alignment.center,
                          child: name4 == "" ? pw.Text("") : pw.Text(on4),
                        ),
                        pw.Container(
                          alignment: pw.Alignment.center,
                          child: name4 == "" ? pw.Text("") : pw.Text(off4),
                        ),
                        pw.Container(
                          alignment: pw.Alignment.center,
                          child: name4 == ""
                              ? pw.Text("")
                              : pw.Text(
                                  "${(Duration(hours: int.parse(off4.split(":")[0]), minutes: int.parse(off4.split(":")[1])) - Duration(hours: int.parse(on4.split(":")[0]), minutes: int.parse(on4.split(":")[1]))).toString().substring(0, 4)}"),
                        ),
                      ]),
                      pw.TableRow(
                        children: [
                          pw.Text(''),
                          pw.Text(''),
                          pw.Container(
                            alignment: pw.Alignment.centerRight,
                            child: pw.Text('Total:',
                                style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold,
                                    fontSize: 15)),
                          ),
                          pw.Container(
                            alignment: pw.Alignment.center,
                            child: pw.Text(
                                "${(((Duration(hours: int.parse(off1.split(":")[0]), minutes: int.parse(off1.split(":")[1])) - Duration(hours: int.parse(on1.split(":")[0]), minutes: int.parse(on1.split(":")[1])))) + (Duration(hours: int.parse(off2.split(":")[0]), minutes: int.parse(off2.split(":")[1])) - Duration(hours: int.parse(on2.split(":")[0]), minutes: int.parse(on2.split(":")[1]))) + (Duration(hours: int.parse(off3.split(":")[0]), minutes: int.parse(off3.split(":")[1])) - Duration(hours: int.parse(on3.split(":")[0]), minutes: int.parse(on3.split(":")[1]))) + (Duration(hours: int.parse(off4.split(":")[0]), minutes: int.parse(off4.split(":")[1])) - Duration(hours: int.parse(on4.split(":")[0]), minutes: int.parse(on4.split(":")[1])))).toString().substring(0, 5)}",
                                style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold,
                                    fontSize: 15)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                pw.Divider(),
                // SERVICES TABLE
                pw.Container(
                  alignment: pw.Alignment.topLeft,
                  child: pw.Text("SERVICES PROVIDED:",
                      style: pw.TextStyle(
                          fontSize: 16, fontWeight: pw.FontWeight.bold)),
                ),
                pw.SizedBox(height: 10),
                pw.Container(
                  margin: const pw.EdgeInsets.only(left: 20.0, right: 20.0),
                  child: pw.Table(
                    children: [
                      pw.TableRow(
                        decoration: const pw.BoxDecoration(
                          border: pw.TableBorder(
                            bottom: pw.BorderSide(
                                color: PdfColor(0.5, 0.8, 0.3, 0.1), width: 2),
                            top: pw.BorderSide(
                                color: PdfColor(0.5, 0.8, 0.3, 0.1), width: 2),
                          ),
                        ),
                        children: [
                          pw.Container(
                            child: pw.Text('Primary Services:',
                                style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.only(bottom: 5.0),
                            child: pw.Container(
                              child: pw.Row(
                                children: (walkways.whereType<String>().toList()
                                        as List<String>)
                                    .map(
                                      (item) => pw.Row(
                                        children: [
                                          pw.Text(item),
                                          pw.SizedBox(width: 5),
                                          pw.Text('|'),
                                          pw.SizedBox(width: 5),
                                        ],
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      pw.TableRow(
                        decoration: const pw.BoxDecoration(
                          border: pw.TableBorder(
                              bottom: pw.BorderSide(
                                  color: PdfColor(0.5, 0.8, 0.3, 0.1),
                                  width: 2)),
                        ),
                        children: [
                          pw.Container(
                            child: pw.Text('Liability:',
                                style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.only(bottom: 5.0),
                            child: pw.Container(
                              child: pw.Row(
                                children: (liability
                                        .whereType<String>()
                                        .toList() as List<String>)
                                    .map(
                                      (item) => pw.Row(
                                        children: [
                                          pw.Text(item),
                                          pw.SizedBox(width: 5),
                                          pw.Text('|'),
                                          pw.SizedBox(width: 5),
                                        ],
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      pw.TableRow(
                        decoration: const pw.BoxDecoration(
                          border: pw.TableBorder(
                              bottom: pw.BorderSide(
                                  color: PdfColor(0.5, 0.8, 0.3, 0.1),
                                  width: 2)),
                        ),
                        children: [
                          pw.Container(
                            child: pw.Text('Other:',
                                style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.only(bottom: 5.0),
                            child: pw.Container(
                              child: pw.Row(
                                children: (other.whereType<String>().toList()
                                        as List<String>)
                                    .map(
                                      (item) => pw.Row(
                                        children: [
                                          pw.Text(item),
                                          pw.SizedBox(width: 5),
                                          pw.Text('|'),
                                          pw.SizedBox(width: 5),
                                        ],
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                pw.Divider(),
                // DESCRIPTION
                pw.Container(
                  alignment: pw.Alignment.topLeft,
                  child: pw.Text("DESCRIPTION:",
                      style: pw.TextStyle(
                          fontSize: 16, fontWeight: pw.FontWeight.bold)),
                ),
                pw.Container(
                  alignment: pw.Alignment.topLeft,
                  child:
                      pw.Text(description, style: pw.TextStyle(fontSize: 14)),
                ),
                pw.Divider(),
                // MATERIALS TABLE
                pw.Container(
                  margin: const pw.EdgeInsets.all(20.0),
                  child: pw.Table(
                    border: pw.TableBorder.all(),
                    children: [
                      pw.TableRow(children: [
                        pw.Container(
                          alignment: pw.Alignment.center,
                          color: const PdfColor(0.5, 0.8, 0.3, 0.1),
                          height: 20,
                          child: pw.Text('MATERIAL',
                              style:
                                  pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Container(
                          alignment: pw.Alignment.center,
                          color: const PdfColor(0.5, 0.8, 0.3, 0.1),
                          height: 20,
                          child: pw.Text('QUANTITY (bags)',
                              style:
                                  pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                      ]),
                      pw.TableRow(children: [
                        pw.Container(
                          alignment: pw.Alignment.center,
                          child: pw.Text('Ice Melt'),
                        ),
                        pw.Container(
                            alignment: pw.Alignment.center,
                            child: pw.Text(iceMeltAmount.toString())),
                      ]),
                      pw.TableRow(children: [
                        pw.Container(
                          alignment: pw.Alignment.center,
                          child: pw.Text('Salt'),
                        ),
                        pw.Container(
                            alignment: pw.Alignment.center,
                            child: pw.Text(saltAmount.toString())),
                      ]),
                      pw.TableRow(children: [
                        pw.Container(
                          alignment: pw.Alignment.center,
                          child: pw.Text('Sand'),
                        ),
                        pw.Container(
                            alignment: pw.Alignment.center,
                            child: pw.Text(sandAmount.toString())),
                      ]),
                    ],
                  ),
                ),
                pw.Text('Submitted by: $user'),
              ],
            ),
          );
        },
      ),
    );

    return doc.save();
  }
}
