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
      siteName = widget.docid.get('site name');
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
            marginLeft: 0,
            marginRight: 0,
            marginTop: 0,
          ),
          orientation: pw.PageOrientation.portrait,
          theme: pw.ThemeData.withFont(
            base: font1,
            bold: font2,
          ),
        ),
        build: (context) {
          return pw.Center(
              child: pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
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
                        ),
                      ),
                      pw.Text(
                        date,
                        style: pw.TextStyle(
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
                          fontSize: 20,
                        ),
                      ),
                      pw.Text(
                        siteName,
                        style: pw.TextStyle(
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text(
                    'Name#1: ',
                    style: pw.TextStyle(
                      fontSize: 20,
                    ),
                  ),
                  pw.Text(
                    team1,
                    style: pw.TextStyle(
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
                    style: pw.TextStyle(
                      fontSize: 20,
                    ),
                  ),
                  pw.Text(
                    team2,
                    style: pw.TextStyle(
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
                    style: pw.TextStyle(
                      fontSize: 20,
                    ),
                  ),
                  pw.Text(
                    team3,
                    style: pw.TextStyle(
                      fontSize: 20,
                    ),
                  ),
                  pw.Text(
                    'On:',
                    style: pw.TextStyle(
                      fontSize: 20,
                    ),
                  ),
                  pw.Text(
                    timeOn1,
                    style: pw.TextStyle(
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
                    style: pw.TextStyle(
                      fontSize: 50,
                    ),
                  ),
                  pw.Text(
                    timeTotal.toString(),
                    style: pw.TextStyle(
                      fontSize: 50,
                    ),
                  ),
                ],
              ),
            ],
          ));
        },
      ),
    );

    return doc.save();
  }
}
