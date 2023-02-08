import 'dart:typed_data';

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
  // var timeOn1;
  // var timeOff1;
  // var team2;
  // var timeOn2;
  // var timeOff2;
  // var team3;
  // var timeOn3;
  // var timeOff3;
  // var team4;
  // var timeOn4;
  // var timeOff4;

  // var timeTotal;
  void initState() {
    setState(() {
      date = widget.docid['info']['date'];
      siteName = widget.docid['info']['siteName'];

      name1 = widget.docid['names']['name1'];
      name2 = widget.docid['names']['name2'];
      name3 = widget.docid['names']['name3'];
      name4 = widget.docid['names']['name4'];

      garbage = widget.docid['service']['garbage'];
      debris = widget.docid['service']['debris'];
      lawn = widget.docid['service']['lawn'];
      garden = widget.docid['service']['garden'];
      tree = widget.docid['service']['tree'];
      blow = widget.docid['service']['blow'];

      //     team1 = widget.docid.get('team1');
      //     timeOn1 = widget.docid.get('timeOn1');
      //     timeOff1 = widget.docid.get('timeOff1');
      //     team2 = widget.docid.get('team2');
      //     timeOn2 = widget.docid.get('timeOn2');
      //     timeOff2 = widget.docid.get('timeOff2');
      //     team3 = widget.docid.get('team3');
      //     timeOn3 = widget.docid.get('timeOn3');
      //     timeOff3 = widget.docid.get('timeOff3');
      //     team4 = widget.docid.get('team4');
      //     timeOn4 = widget.docid.get('timeOn4');
      //     timeOff4 = widget.docid.get('timeOff4');

      // timeTotal = (int.parse(timeOff1) - int.parse(timeOn1)) +
      //     (int.parse(timeOff2) - int.parse(timeOn2)) +
      //     (int.parse(timeOff3) - int.parse(timeOn3)) +
      //     (int.parse(timeOff4) - int.parse(timeOn4));
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return PdfPreview(
      // maxPageWidth: 1000,
      // useActions: false,
      // canChangePageFormat: true,
      canChangeOrientation: false,
      // pageFormats:pageformat,
      canDebug: false,

      build: (format) => generateDocument(
        format,
      ),
    );
  }

  Future<Uint8List> generateDocument(PdfPageFormat format) async {
    final doc = pw.Document(pageMode: PdfPageMode.outlines);

    final font1 = await PdfGoogleFonts.openSansRegular();
    final font2 = await PdfGoogleFonts.openSansBold();

    String? _gemini_logo =
        await rootBundle.loadString('assets/gemini_logo.svg');

    doc.addPage(
      pw.Page(
        pageTheme: pw.PageTheme(
          pageFormat: format.copyWith(
            marginBottom: 0,
            marginLeft: 30,
            marginRight: 30,
            marginTop: 0,
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
                    'Site Report 2023',
                    style: pw.TextStyle(
                      fontSize: 30,
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
                          'Date: ',
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
                          'Site Name: ',
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
                pw.Table(
                  border: pw.TableBorder.all(),
                  children: [
                    pw.TableRow(children: [
                      pw.Text(''),
                      pw.Container(
                        alignment: pw.Alignment.center,
                        child: pw.Text('Name',
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Container(
                        alignment: pw.Alignment.center,
                        child: pw.Text('On',
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Container(
                        alignment: pw.Alignment.center,
                        child: pw.Text('Off',
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Container(
                        alignment: pw.Alignment.center,
                        child: pw.Text('Hours',
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                    ]),
                    pw.TableRow(children: [
                      pw.Text('Driver'),
                      pw.Text(name1),
                    ]),
                    pw.TableRow(children: [
                      pw.Text('Name #2:'),
                      pw.Text(name2),
                    ]),
                    pw.TableRow(children: [
                      pw.Text('Name #3'),
                      pw.Text(name3),
                    ]),
                    pw.TableRow(children: [
                      pw.Text('Name #4'),
                      pw.Text(name4),
                    ]),
                    pw.TableRow(children: [
                      pw.Text(''),
                      pw.Text(''),
                      pw.Text(''),
                      pw.Text('Total Hours:',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text(''), // Output total hours
                    ]),
                  ],
                ),
                pw.Divider(),
                // SERVICES TABLE
                pw.Container(
                  alignment: pw.Alignment.topLeft,
                  child: pw.Text("Services Provided:",
                      style: pw.TextStyle(
                          fontSize: 20, fontWeight: pw.FontWeight.bold)),
                ),
                pw.SizedBox(height: 10),
                pw.Table(
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(
                        border: pw.TableBorder(
                            bottom: pw.BorderSide(
                                color: PdfColor(0.5, 0.8, 0.3, 0.1), width: 2)),
                      ),
                      children: [
                        pw.Container(
                          child: pw.Text('Pick up loose garbage:',
                              style:
                                  pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.only(bottom: 15.0),
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
                                color: PdfColor(0.5, 0.8, 0.3, 0.1), width: 2)),
                      ),
                      children: [
                        pw.Container(
                          child: pw.Text('Rake yard debris:',
                              style:
                                  pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.only(bottom: 15.0),
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
                                color: PdfColor(0.5, 0.8, 0.3, 0.1), width: 2)),
                      ),
                      children: [
                        pw.Container(
                          child: pw.Text('Lawn care:',
                              style:
                                  pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.only(bottom: 15.0),
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
                                color: PdfColor(0.5, 0.8, 0.3, 0.1), width: 2)),
                      ),
                      children: [
                        pw.Container(
                          child: pw.Text('Gardens:',
                              style:
                                  pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.only(bottom: 15.0),
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
                                color: PdfColor(0.5, 0.8, 0.3, 0.1), width: 2)),
                      ),
                      children: [
                        pw.Container(
                          child: pw.Text('Trees:',
                              style:
                                  pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.only(bottom: 15.0),
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
                                color: PdfColor(0.5, 0.8, 0.3, 0.1), width: 2)),
                      ),
                      children: [
                        pw.Container(
                          child: pw.Text('Blow dust/debris:',
                              style:
                                  pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.only(bottom: 15.0),
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
              ],
            ),
          );
        },
      ),
    );

    return doc.save();
  }
}
