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
  var team1;
  var timeOn1;
  var timeOff1;
  var team2;
  var timeOn2;
  var timeOff2;
  var team3;
  var timeOn3;
  var timeOff3;
  var team4;
  var timeOn4;
  var timeOff4;

  var timeTotal;
  void initState() {
    setState(() {
      date = widget.docid.get('date');
      siteName = widget.docid.get('siteName');
      team1 = widget.docid.get('team1');
      timeOn1 = widget.docid.get('timeOn1');
      timeOff1 = widget.docid.get('timeOff1');
      team2 = widget.docid.get('team2');
      timeOn2 = widget.docid.get('timeOn2');
      timeOff2 = widget.docid.get('timeOff2');
      team3 = widget.docid.get('team3');
      timeOn3 = widget.docid.get('timeOn3');
      timeOff3 = widget.docid.get('timeOff3');
      team4 = widget.docid.get('team4');
      timeOn4 = widget.docid.get('timeOn4');
      timeOff4 = widget.docid.get('timeOff4');

      timeTotal = (int.parse(timeOff1) - int.parse(timeOn1)) +
          (int.parse(timeOff2) - int.parse(timeOn2)) +
          (int.parse(timeOff3) - int.parse(timeOn3)) +
          (int.parse(timeOff4) - int.parse(timeOn4));
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
                    style: const pw.TextStyle(
                      fontSize: 30,
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
                          style: const pw.TextStyle(
                            fontSize: 20,
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
                          style: const pw.TextStyle(
                            fontSize: 20,
                          ),
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
                        child: pw.Text('Name'),
                      ),
                      pw.Container(
                        alignment: pw.Alignment.center,
                        child: pw.Text('On'),
                      ),
                      pw.Container(
                        alignment: pw.Alignment.center,
                        child: pw.Text('Off'),
                      ),
                      pw.Container(
                        alignment: pw.Alignment.center,
                        child: pw.Text('Hours'),
                      ),
                    ]),
                    pw.TableRow(children: [
                      pw.Text('Driver'),
                    ]),
                    pw.TableRow(children: [
                      pw.Text('Team #1'),
                      pw.Text(''),
                    ]),
                    pw.TableRow(children: [
                      pw.Text('Team #2'),
                      pw.Text(''),
                    ]),
                    pw.TableRow(children: [
                      pw.Text('Team #3'),
                      pw.Text(''),
                    ]),
                    pw.TableRow(children: [
                      pw.Text('Team #4'),
                      pw.Text(''),
                    ]),
                    pw.TableRow(children: [
                      pw.Text(''),
                      pw.Text(''),
                      pw.Text(''),
                      pw.Text('Total Hours:'),
                      pw.Text(''), // Output total hours
                    ]),
                  ],
                ),
                // SERVICES TABLE
                pw.Container(
                  alignment: pw.Alignment.topLeft,
                  child: pw.Text("Services Provided:"),
                ),
                pw.Table(
                  border: pw.TableBorder.all(),
                  children: [
                    pw.TableRow(
                      children: [
                        pw.Text('Pick up loose garbage:'),
                        pw.Text('grassed areas - '),
                        pw.Text('garden beds - '),
                        pw.Text('walkways'),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Text('Rake yard debris:'),
                        pw.Text('grassed areas -'),
                        pw.Text('garden beds -'),
                        pw.Text('tree wells'),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Text('Lawn care:'),
                        pw.Text('mow -'),
                        pw.Text('trim -'),
                        pw.Text('edge -'),
                        pw.Text('lime -'),
                        pw.Text('aerate -'),
                        pw.Text('fertilize -'),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Text('Gardens:'),
                        pw.Text('blow out debris -'),
                        pw.Text('weed -'),
                        pw.Text('prune -'),
                        pw.Text('fertilize'),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Text('Trees:'),
                        pw.Text('< 6ft -'),
                        pw.Text('> 6ft -'),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Text('Blow dust/debris:'),
                        pw.Text('parking lot curbs -'),
                        pw.Text('drain basins -'),
                        pw.Text('walkways'),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Text('Pick up loose garbage:'),
                        pw.Text('Rake yard debris:'),
                        pw.Text('Lawn care:'),
                        pw.Text('Gardens:'),
                        pw.Text('Trees:'),
                        pw.Text('Blow dust/debris:'),
                      ],
                    ),
                  ],
                ),

                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Text(
                      'Name#1: ',
                      style: const pw.TextStyle(
                        fontSize: 20,
                      ),
                    ),
                    pw.Text(
                      team1,
                      style: const pw.TextStyle(
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Text(
                      'Name#2: ',
                      style: const pw.TextStyle(
                        fontSize: 20,
                      ),
                    ),
                    pw.Text(
                      team2,
                      style: const pw.TextStyle(
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Text(
                      'Name#3: ',
                      style: const pw.TextStyle(
                        fontSize: 20,
                      ),
                    ),
                    pw.Text(
                      team3,
                      style: const pw.TextStyle(
                        fontSize: 20,
                      ),
                    ),
                    pw.Text(
                      'On:',
                      style: const pw.TextStyle(
                        fontSize: 20,
                      ),
                    ),
                    pw.Text(
                      timeOn1,
                      style: const pw.TextStyle(
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
                pw.Divider(),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Text(
                      'Total Time: ',
                      style: const pw.TextStyle(
                        fontSize: 50,
                      ),
                    ),
                    pw.Text(
                      timeTotal.toString(),
                      style: const pw.TextStyle(
                        fontSize: 50,
                      ),
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
