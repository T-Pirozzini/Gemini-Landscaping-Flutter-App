import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

// ignore: must_be_immutable
class PrintReport extends StatefulWidget {
  DocumentSnapshot docid;
  PrintReport({required this.docid});
  @override
  State<PrintReport> createState() => _PrintReportState(docid: docid);
}

class _PrintReportState extends State<PrintReport> {
  DocumentSnapshot docid;
  _PrintReportState({required this.docid});
  final pdf = pw.Document();

  var date;
  var siteName;
  var address = '';

  var garbage;
  var lawn;
  var garden;
  var tree;
  var debris;
  var blow;

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
  var material1 = '';
  var material2 = '';
  var material3 = '';
  var vendor1 = '';
  var vendor2 = '';
  var vendor3 = '';
  var amount1;
  var amount2;
  var amount3;

  var user = '';

  //get current user
  final currentUser = FirebaseAuth.instance.currentUser!;

  // get current year
  final String year = DateTime.now().year.toString();

  void initState() {
    setState(() {
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

      garbage = widget.docid['service']['garbage'];
      debris = widget.docid['service']['debris'];
      lawn = widget.docid['service']['lawn'];
      garden = widget.docid['service']['garden'];
      tree = widget.docid['service']['tree'];
      blow = widget.docid['service']['blow'];

      description = widget.docid['description'];
      material1 = widget.docid['materials']['material1'];
      material2 = widget.docid['materials']['material2'];
      material3 = widget.docid['materials']['material3'];
      vendor1 = widget.docid['materials']['vendor1'];
      vendor2 = widget.docid['materials']['vendor2'];
      vendor3 = widget.docid['materials']['vendor3'];
      amount1 = widget.docid['materials']['amount1'];
      amount2 = widget.docid['materials']['amount2'];
      amount3 = widget.docid['materials']['amount3'];

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

    // convert string amounts to a double
    double totalAmount = 0.0;

    if (amount1 != "") {
      double amount1Value = double.tryParse(amount1) ?? 0.0;
      totalAmount += amount1Value;
    }

    if (amount2 != "") {
      double amount2Value = double.tryParse(amount2) ?? 0.0;
      totalAmount += amount2Value;
    }

    if (amount3 != "") {
      double amount3Value = double.tryParse(amount3) ?? 0.0;
      totalAmount += amount3Value;
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
                    'SITE REPORT $year',
                    style: pw.TextStyle(
                      fontSize: 25,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(
                  height: 20,
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
                            child: pw.Text('Pick up loose garbage:',
                                style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.only(bottom: 5.0),
                            child: pw.Container(
                              child: pw.Row(
                                children: (garbage.whereType<String>().toList()
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
                            child: pw.Text('Rake yard debris:',
                                style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.only(bottom: 5.0),
                            child: pw.Container(
                              child: pw.Row(
                                children: (debris.whereType<String>().toList()
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
                            child: pw.Text('Lawn care:',
                                style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.only(bottom: 5.0),
                            child: pw.Container(
                              child: pw.Row(
                                children: (lawn.whereType<String>().toList()
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
                            child: pw.Text('Gardens:',
                                style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.only(bottom: 5.0),
                            child: pw.Container(
                              child: pw.Row(
                                children: (garden.whereType<String>().toList()
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
                            child: pw.Text('Trees:',
                                style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.only(bottom: 5.0),
                            child: pw.Container(
                              child: pw.Row(
                                children: (tree.whereType<String>().toList()
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
                            child: pw.Text('Blow dust/debris:',
                                style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.only(bottom: 5.0),
                            child: pw.Container(
                              child: pw.Row(
                                children: (blow.whereType<String>().toList()
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
                          child: pw.Text('VENDOR',
                              style:
                                  pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Container(
                          alignment: pw.Alignment.center,
                          color: const PdfColor(0.5, 0.8, 0.3, 0.1),
                          height: 20,
                          child: pw.Text('AMOUNT \$',
                              style:
                                  pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                      ]),
                      pw.TableRow(children: [
                        pw.Container(
                          alignment: pw.Alignment.center,
                          child: pw.Text(material1),
                        ),
                        pw.Container(
                            alignment: pw.Alignment.center,
                            child: pw.Text(vendor1)),
                        pw.Container(
                            alignment: pw.Alignment.center,
                            child: pw.Text(amount1)),
                      ]),
                      pw.TableRow(children: [
                        pw.Container(
                          alignment: pw.Alignment.center,
                          child: pw.Text(material2),
                        ),
                        pw.Container(
                            alignment: pw.Alignment.center,
                            child: pw.Text(vendor2)),
                        pw.Container(
                            alignment: pw.Alignment.center,
                            child: pw.Text(amount2)),
                      ]),
                      pw.TableRow(children: [
                        pw.Container(
                          alignment: pw.Alignment.center,
                          child: pw.Text(material3),
                        ),
                        pw.Container(
                            alignment: pw.Alignment.center,
                            child: pw.Text(vendor3)),
                        pw.Container(
                            alignment: pw.Alignment.center,
                            child: pw.Text(amount3)),
                      ]),
                      pw.TableRow(
                        children: [
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
                              '${totalAmount.toStringAsFixed(2)}',
                              style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold, fontSize: 15),
                            ),
                          ),
                        ],
                      ),
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
