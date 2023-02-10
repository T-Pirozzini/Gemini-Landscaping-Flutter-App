// import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class SiteReport extends StatefulWidget {
  DocumentSnapshot docid;
  SiteReport({required this.docid});
  @override
  State<SiteReport> createState() => _SiteReportState(docid: docid);
}

class _SiteReportState extends State<SiteReport> {
  DocumentSnapshot docid;
  _SiteReportState({required this.docid});
  final pdf = pw.Document();
  var date;
  var siteName;

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

  void initState() {
    setState(() {
      date = widget.docid['info']['date'];
      siteName = widget.docid['info']['siteName'];

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
        // useActions: false,
        // canChangePageFormat: true,
        canChangeOrientation: false,
        // pageFormats:pageformat,
        canDebug: false,

        build: (format) => generateDocument(
          format,
        ),
      ),
    );
  }

  Future<Uint8List> generateDocument(PdfPageFormat format) async {
    final doc = pw.Document(pageMode: PdfPageMode.outlines);

    final font3 = await PdfGoogleFonts.openSansRegular();
    final font4 = await PdfGoogleFonts.openSansBold();

    final font1 = await PdfGoogleFonts.latoRegular();
    final font2 = await PdfGoogleFonts.latoBold();

    String? _gemini_logo =
        await rootBundle.loadString('assets/gemini_logo.svg');

    doc.addPage(
      pw.Page(
        pageTheme: pw.PageTheme(
          pageFormat: format.copyWith(
            marginBottom: 20,
            marginLeft: 30,
            marginRight: 30,
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
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                pw.Flexible(
                  child: pw.SvgImage(
                    svg: _gemini_logo,
                    height: 200,
                  ),
                ),
                pw.SizedBox(
                  height: 20,
                ),
                pw.Center(
                  child: pw.Text(
                    'SITE REPORT 2023',
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
                        pw.Text(
                          'DATE: ',
                          style: pw.TextStyle(
                            fontSize: 20,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          date,
                          style: const pw.TextStyle(
                            fontSize: 20,
                          ),
                        ),
                      ],
                    ),
                    pw.Row(
                      children: [
                        pw.Text(
                          'SITE NAME: ',
                          style: pw.TextStyle(
                              fontSize: 20, fontWeight: pw.FontWeight.bold),
                        ),
                        pw.Text(
                          siteName,
                          style: const pw.TextStyle(
                            fontSize: 20,
                          ),
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
                          fontSize: 20, fontWeight: pw.FontWeight.bold)),
                ),
                pw.SizedBox(height: 10),
                pw.Container(
                  margin: const pw.EdgeInsets.only(
                      left: 80.0, right: 80.0, bottom: 50.0),
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
                              child: pw.Column(
                                children: (garbage.whereType<String>().toList()
                                        as List<String>)
                                    .map((item) => pw.Text(item))
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
                              child: pw.Column(
                                children: (debris.whereType<String>().toList()
                                        as List<String>)
                                    .map((item) => pw.Text(item))
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
                              child: pw.Column(
                                children: (lawn.whereType<String>().toList()
                                        as List<String>)
                                    .map((item) => pw.Text(item))
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
                              child: pw.Column(
                                children: (garden.whereType<String>().toList()
                                        as List<String>)
                                    .map((item) => pw.Text(item))
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
                              child: pw.Column(
                                children: (tree.whereType<String>().toList()
                                        as List<String>)
                                    .map((item) => pw.Text(item))
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
                              child: pw.Column(
                                children: (blow.whereType<String>().toList()
                                        as List<String>)
                                    .map((item) => pw.Text(item))
                                    .toList(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                )
              ],
            ),
          );
        },
      ),
    );

    return doc.save();
  }
}
