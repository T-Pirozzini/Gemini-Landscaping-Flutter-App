import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gemini_landscaping_app/pages/home_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'edit_report_page.dart';
import 'pdf_page.dart';

// ignore: must_be_immutable
class ViewReport extends StatefulWidget {
  DocumentSnapshot docid;
  ViewReport({required this.docid});

  @override
  State<ViewReport> createState() => _ViewReportState(docid: docid);
}

CollectionReference ref =
    FirebaseFirestore.instance.collection('SiteReports2023');

class _ViewReportState extends State<ViewReport> {
  DocumentSnapshot docid;
  _ViewReportState({required this.docid});

  void deleteReport() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Deletion'),
          content:
              Text('Are you sure you would like to delete this site report?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                widget.docid.reference.delete().whenComplete(
                  () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => Home()),
                    );
                  },
                );
              },
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 31, 182, 77),
        leading: MaterialButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Row(
            children: const [
              Icon(Icons.arrow_circle_left_outlined,
                  color: Colors.white, size: 18),
              Text(
                " Back",
                style: TextStyle(
                  fontSize: 15,
                  color: Color.fromARGB(255, 251, 251, 251),
                ),
              ),
            ],
          ),
        ),
        leadingWidth: 100,
        title: Image.asset("assets/gemini-icon-transparent.png",
            color: Colors.white, fit: BoxFit.contain, height: 50),
        centerTitle: true,
      ),
      body: Container(
        padding: EdgeInsets.all(10),
        margin: EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10.0),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade400,
              offset: Offset(2.0, 2.0),
              blurRadius: 5.0,
              spreadRadius: 1.0,
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.docid["info"]['date'],
                      style: GoogleFonts.montserrat(
                        textStyle: TextStyle(
                            letterSpacing: .5,
                            fontSize: 14,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    Text(
                      '#${widget.docid.id.substring(docid.id.length - 5)}',
                      style: GoogleFonts.montserrat(
                        textStyle: TextStyle(letterSpacing: .5, fontSize: 14),
                      ),
                    ),
                  ],
                ),
                SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.docid["info"]["siteName"].toUpperCase(),
                        style: GoogleFonts.montserrat(
                          textStyle: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (widget.docid["info"]["address"] != null)
                        Text(
                          widget.docid["info"]["address"],
                          style: GoogleFonts.montserrat(
                            textStyle: TextStyle(fontSize: 16),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 15),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
              ),
              child: Table(
                border: TableBorder.all(
                  color: Colors.black,
                ),
                children: [
                  TableRow(
                      decoration: BoxDecoration(
                        color: Color.fromARGB(255, 31, 182, 77),
                      ),
                      children: [
                        Container(
                          padding: EdgeInsets.all(2),
                          alignment: Alignment.center,
                          child: Text(
                            'Name',
                            style: GoogleFonts.montserrat(
                                fontSize: 16, color: Colors.white),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.all(2),
                          alignment: Alignment.center,
                          child: Text('On',
                              style: GoogleFonts.montserrat(
                                  fontSize: 16, color: Colors.white)),
                        ),
                        Container(
                          padding: EdgeInsets.all(2),
                          alignment: Alignment.center,
                          child: Text('Off',
                              style: GoogleFonts.montserrat(
                                  fontSize: 16, color: Colors.white)),
                        ),
                        Container(
                          padding: EdgeInsets.all(2),
                          alignment: Alignment.center,
                          child: Text('Site Time',
                              style: GoogleFonts.montserrat(
                                  fontSize: 16, color: Colors.white)),
                        ),
                      ]),
                  TableRow(children: [
                    Container(
                      alignment: Alignment.center,
                      child: Text(
                        widget.docid["names"]["name1"],
                        style: GoogleFonts.montserrat(fontSize: 14),
                      ),
                    ),
                    Container(
                      alignment: Alignment.center,
                      child: Text(
                        widget.docid["times"]["timeOn1"],
                        style: GoogleFonts.montserrat(fontSize: 14),
                      ),
                    ),
                    Container(
                      alignment: Alignment.center,
                      child: Text(
                        widget.docid["times"]["timeOff1"],
                        style: GoogleFonts.montserrat(fontSize: 14),
                      ),
                    ),
                    Container(
                      alignment: Alignment.center,
                      child: Text(
                        "${(Duration(hours: int.parse(widget.docid["times"]["timeOff1"].split(":")[0]), minutes: int.parse(widget.docid["times"]["timeOff1"].split(":")[1])) - Duration(hours: int.parse(widget.docid["times"]["timeOn1"].split(":")[0]), minutes: int.parse(widget.docid["times"]["timeOn1"].split(":")[1]))).toString().substring(0, 4)}",
                        style: GoogleFonts.montserrat(fontSize: 14),
                      ),
                    ),
                  ]),
                  TableRow(children: [
                    Container(
                      alignment: Alignment.center,
                      child: Text(
                        widget.docid["names"]["name2"],
                        style: GoogleFonts.montserrat(fontSize: 14),
                      ),
                    ),
                    Container(
                      alignment: Alignment.center,
                      child: widget.docid["names"]["name2"] == ""
                          ? Text("")
                          : Text(
                              widget.docid["times"]["timeOn2"],
                              style: GoogleFonts.montserrat(fontSize: 14),
                            ),
                    ),
                    Container(
                      alignment: Alignment.center,
                      child: widget.docid["names"]["name2"] == ""
                          ? Text("")
                          : Text(
                              widget.docid["times"]["timeOff2"],
                              style: GoogleFonts.montserrat(fontSize: 14),
                            ),
                    ),
                    Container(
                      alignment: Alignment.center,
                      child: widget.docid["names"]["name2"] == ""
                          ? Text("")
                          : Text(
                              "${(Duration(hours: int.parse(widget.docid["times"]["timeOff2"].split(":")[0]), minutes: int.parse(widget.docid["times"]["timeOff2"].split(":")[1])) - Duration(hours: int.parse(widget.docid["times"]["timeOn2"].split(":")[0]), minutes: int.parse(widget.docid["times"]["timeOn2"].split(":")[1]))).toString().substring(0, 4)}",
                              style: GoogleFonts.montserrat(fontSize: 14),
                            ),
                    ),
                  ]),
                  TableRow(children: [
                    Container(
                      alignment: Alignment.center,
                      child: Text(
                        widget.docid["names"]["name3"],
                        style: GoogleFonts.montserrat(fontSize: 14),
                      ),
                    ),
                    Container(
                      alignment: Alignment.center,
                      child: widget.docid["names"]["name3"] == ""
                          ? Text("")
                          : Text(
                              widget.docid["times"]["timeOn3"],
                              style: GoogleFonts.montserrat(fontSize: 14),
                            ),
                    ),
                    Container(
                      alignment: Alignment.center,
                      child: widget.docid["names"]["name3"] == ""
                          ? Text("")
                          : Text(
                              widget.docid["times"]["timeOff3"],
                              style: GoogleFonts.montserrat(fontSize: 14),
                            ),
                    ),
                    Container(
                      alignment: Alignment.center,
                      child: widget.docid["names"]["name3"] == ""
                          ? Text("")
                          : Text(
                              "${(Duration(hours: int.parse(widget.docid["times"]["timeOff3"].split(":")[0]), minutes: int.parse(widget.docid["times"]["timeOff3"].split(":")[1])) - Duration(hours: int.parse(widget.docid["times"]["timeOn3"].split(":")[0]), minutes: int.parse(widget.docid["times"]["timeOn3"].split(":")[1]))).toString().substring(0, 4)}",
                              style: GoogleFonts.montserrat(fontSize: 14),
                            ),
                    ),
                  ]),
                  TableRow(children: [
                    Container(
                      alignment: Alignment.center,
                      child: Text(
                        widget.docid["names"]["name4"],
                        style: GoogleFonts.montserrat(fontSize: 14),
                      ),
                    ),
                    Container(
                      alignment: Alignment.center,
                      child: widget.docid["names"]["name4"] == ""
                          ? Text("")
                          : Text(
                              widget.docid["times"]["timeOn4"],
                              style: GoogleFonts.montserrat(fontSize: 14),
                            ),
                    ),
                    Container(
                      alignment: Alignment.center,
                      child: widget.docid["names"]["name4"] == ""
                          ? Text("")
                          : Text(
                              widget.docid["times"]["timeOff4"],
                              style: GoogleFonts.montserrat(fontSize: 14),
                            ),
                    ),
                    Container(
                      alignment: Alignment.center,
                      child: widget.docid["names"]["name4"] == ""
                          ? Text("")
                          : Text(
                              "${(Duration(hours: int.parse(widget.docid["times"]["timeOff4"].split(":")[0]), minutes: int.parse(widget.docid["times"]["timeOff4"].split(":")[1])) - Duration(hours: int.parse(widget.docid["times"]["timeOn4"].split(":")[0]), minutes: int.parse(widget.docid["times"]["timeOn4"].split(":")[1]))).toString().substring(0, 4)}",
                              style: GoogleFonts.montserrat(fontSize: 14),
                            ),
                    ),
                  ]),
                  TableRow(
                    children: [
                      Container(),
                      Container(),
                      Container(
                        alignment: Alignment.center,
                        child: Text(
                          "Total",
                          style: GoogleFonts.montserrat(
                            fontSize: 18,
                          ),
                        ),
                      ),
                      Container(
                        alignment: Alignment.center,
                        child: Text(
                          "${(((Duration(hours: int.parse(widget.docid["times"]["timeOff1"].split(":")[0]), minutes: int.parse(widget.docid["times"]["timeOff1"].split(":")[1])) - Duration(hours: int.parse(widget.docid["times"]["timeOn1"].split(":")[0]), minutes: int.parse(widget.docid["times"]["timeOn1"].split(":")[1])))) + (Duration(hours: int.parse(widget.docid["times"]["timeOff2"].split(":")[0]), minutes: int.parse(widget.docid["times"]["timeOff2"].split(":")[1])) - Duration(hours: int.parse(widget.docid["times"]["timeOn2"].split(":")[0]), minutes: int.parse(widget.docid["times"]["timeOn2"].split(":")[1]))) + (Duration(hours: int.parse(widget.docid["times"]["timeOff3"].split(":")[0]), minutes: int.parse(widget.docid["times"]["timeOff3"].split(":")[1])) - Duration(hours: int.parse(widget.docid["times"]["timeOn3"].split(":")[0]), minutes: int.parse(widget.docid["times"]["timeOn3"].split(":")[1]))) + (Duration(hours: int.parse(widget.docid["times"]["timeOff4"].split(":")[0]), minutes: int.parse(widget.docid["times"]["timeOff4"].split(":")[1])) - Duration(hours: int.parse(widget.docid["times"]["timeOn4"].split(":")[0]), minutes: int.parse(widget.docid["times"]["timeOn4"].split(":")[1])))).toString().padLeft(2, '0').substring(0, 4)}",
                          style: GoogleFonts.montserrat(fontSize: 18),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: 8, // number of rows
                itemBuilder: (context, index) {
                  String label = '';
                  List<String> items = [];

                  switch (index) {
                    case 0:
                      label = 'Pick up loose garbage:';
                      if (widget.docid["service"] != null &&
                          widget.docid["service"].containsKey("garbage")) {
                        items = widget.docid["service"]["garbage"]
                            .whereType<String>()
                            .toList();
                      }
                      break;
                    case 1:
                      label = 'Rake yard debris:';
                      if (widget.docid["service"] != null &&
                          widget.docid["service"].containsKey("debris")) {
                        items = widget.docid["service"]["debris"]
                            .whereType<String>()
                            .toList();
                      }
                      break;
                    case 2:
                      label = 'Lawn care:';
                      if (widget.docid["service"] != null &&
                          widget.docid["service"].containsKey("lawn")) {
                        items = widget.docid["service"]["lawn"]
                            .whereType<String>()
                            .toList();
                      }
                      break;
                    case 3:
                      label = 'Gardens:';
                      if (widget.docid["service"] != null &&
                          widget.docid["service"].containsKey("garden")) {
                        items = widget.docid["service"]["garden"]
                            .whereType<String>()
                            .toList();
                      }
                      break;
                    case 4:
                      label = 'Trees:';
                      if (widget.docid["service"] != null &&
                          widget.docid["service"].containsKey("tree")) {
                        items = widget.docid["service"]["tree"]
                            .whereType<String>()
                            .toList();
                      }
                      break;
                    case 5:
                      label = 'Blow dust/debris:';
                      if (widget.docid["service"] != null &&
                          widget.docid["service"].containsKey("blow")) {
                        items = widget.docid["service"]["blow"]
                            .whereType<String>()
                            .toList();
                      }
                      break;
                    case 6:
                      label = 'Materials:';
                      if (widget.docid["materials"] != null) {
                        Map<String, dynamic> materials =
                            widget.docid["materials"];
                        for (int i = 1; i <= 3; i++) {
                          String amountKey = 'amount$i';
                          String materialKey = 'material$i';
                          String vendorKey = 'vendor$i';
                          if (materials.containsKey(amountKey) &&
                              materials.containsKey(materialKey) &&
                              materials.containsKey(vendorKey)) {
                            String amount = materials[amountKey];
                            String material = materials[materialKey];
                            String vendor = materials[vendorKey];
                            items.add('$material - $vendor - \$$amount /');
                          }
                        }
                      }
                      break;
                    case 7:
                      label = 'Description:';
                      if (widget.docid["description"] != null) {
                        items = [widget.docid["description"]];
                      }
                      break;
                  }

                  // Display items only if they exist
                  if (items.isNotEmpty) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: Container(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Divider(),
                            Text(
                              label.toUpperCase(),
                              style: GoogleFonts.montserrat(
                                  fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                            Wrap(
                              spacing: 8.0,
                              alignment: WrapAlignment.center,
                              children: items
                                  .map(
                                    (item) => Text(
                                      item,
                                      style: GoogleFonts.montserrat(
                                        textStyle: TextStyle(
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ],
                        ),
                      ),
                    );
                  } else {
                    return SizedBox.shrink();
                  }
                },
              ),
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Color.fromARGB(255, 20, 177, 54),
                  ),
                  child: MaterialButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SiteReport(
                            docid: docid,
                          ),
                        ),
                      );
                    },
                    child: const Text(
                      "GENERATE PDF",
                      style: TextStyle(
                        fontSize: 18,
                        color: Color.fromARGB(255, 251, 251, 251),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 15),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Color.fromARGB(255, 20, 177, 54),
                  ),
                  child: MaterialButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditReport(
                            docid: docid,
                          ),
                        ),
                      );
                    },
                    child: const Text(
                      "EDIT REPORT",
                      style: TextStyle(
                        fontSize: 18,
                        color: Color.fromARGB(255, 251, 251, 251),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 15),
                FirebaseAuth.instance.currentUser?.uid ==
                        "5wwYztIxTifV0EQk3N7dfXsY0jm1"
                    ? Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[600],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: MaterialButton(
                          onPressed: deleteReport,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: const [
                              Icon(Icons.delete, color: Colors.white),
                              SizedBox(width: 5),
                              Text("Delete",
                                  style: TextStyle(color: Colors.white)),
                            ],
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
