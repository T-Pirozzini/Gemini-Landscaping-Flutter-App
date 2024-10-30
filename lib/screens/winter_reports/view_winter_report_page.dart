import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gemini_landscaping_app/screens/winter_reports/edit_winter_report_page.dart';
import 'package:gemini_landscaping_app/screens/home/home_page.dart';
import 'package:gemini_landscaping_app/screens/winter_reports/pdf_winter_report%20_page.dart';
import 'package:google_fonts/google_fonts.dart';

// ignore: must_be_immutable
class ViewWinterReportPage extends StatefulWidget {
  DocumentSnapshot docid;
  ViewWinterReportPage({super.key, required this.docid});

  @override
  State<ViewWinterReportPage> createState() =>
      _ViewWinterReportPageState(docid: docid);
}

CollectionReference ref =
    FirebaseFirestore.instance.collection('WinterReports');

class _ViewWinterReportPageState extends State<ViewWinterReportPage> {
  DocumentSnapshot docid;
  _ViewWinterReportPageState({required this.docid});

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
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => Home()),
                      (route) => false,
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
            Text(
                widget.docid['service']['iceManagement'] == true
                    ? "Ice Management"
                    : "Snow Removal",
                style: GoogleFonts.montserrat(fontSize: 18)),
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
                          "${(((Duration(hours: int.parse(widget.docid["times"]["timeOff1"].split(":")[0]), minutes: int.parse(widget.docid["times"]["timeOff1"].split(":")[1])) - Duration(hours: int.parse(widget.docid["times"]["timeOn1"].split(":")[0]), minutes: int.parse(widget.docid["times"]["timeOn1"].split(":")[1])))) + (Duration(hours: int.parse(widget.docid["times"]["timeOff2"].split(":")[0]), minutes: int.parse(widget.docid["times"]["timeOff2"].split(":")[1])) - Duration(hours: int.parse(widget.docid["times"]["timeOn2"].split(":")[0]), minutes: int.parse(widget.docid["times"]["timeOn2"].split(":")[1]))) + (Duration(hours: int.parse(widget.docid["times"]["timeOff3"].split(":")[0]), minutes: int.parse(widget.docid["times"]["timeOff3"].split(":")[1])) - Duration(hours: int.parse(widget.docid["times"]["timeOn3"].split(":")[0]), minutes: int.parse(widget.docid["times"]["timeOn3"].split(":")[1]))) + (Duration(hours: int.parse(widget.docid["times"]["timeOff4"].split(":")[0]), minutes: int.parse(widget.docid["times"]["timeOff4"].split(":")[1])) - Duration(hours: int.parse(widget.docid["times"]["timeOn4"].split(":")[0]), minutes: int.parse(widget.docid["times"]["timeOn4"].split(":")[1])))).toString().padLeft(2, '0').substring(0, 5)}",
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
                      label = 'Primary Services:';
                      if (widget.docid["service"] != null &&
                          widget.docid["service"].containsKey("walkways")) {
                        items = widget.docid["service"]["walkways"]
                            .whereType<String>()
                            .toList();
                      }
                      break;
                    case 1:
                      label = 'Liability:';
                      if (widget.docid["service"] != null &&
                          widget.docid["service"].containsKey("liability")) {
                        items = widget.docid["service"]["liability"]
                            .whereType<String>()
                            .toList();
                      }
                      break;
                    case 2:
                      label = 'Other:';
                      if (widget.docid["service"] != null &&
                          widget.docid["service"].containsKey("other")) {
                        items = widget.docid["service"]["other"]
                            .whereType<String>()
                            .toList();
                      }
                      break;
                    case 3:
                      label = 'Description:';
                      if (widget.docid["description"] != null) {
                        items = [widget.docid["description"]];
                      }
                      break;
                    case 4:
                      label = 'Material:';
                      if (widget.docid["material"] != null) {
                        double iceMeltValue =
                            widget.docid["material"]["iceMelt"].toDouble();
                        double saltValue =
                            widget.docid["material"]["salt"].toDouble();
                        double sandValue =
                            widget.docid["material"]["sand"].toDouble();
                        items = [
                          "Ice Melt: ${iceMeltValue.toStringAsFixed(2)} bags",
                          "Salt: ${saltValue.toStringAsFixed(2)} bags",
                          "Sand: ${sandValue.toStringAsFixed(2)} bags"
                        ];
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
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
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
                    color: FirebaseAuth.instance.currentUser?.uid ==
                                "5wwYztIxTifV0EQk3N7dfXsY0jm1" ||
                            FirebaseAuth.instance.currentUser?.uid ==
                                "4Qpgb3aORKhUVXjgT2SNh6zgCWE3"
                        ? Color.fromARGB(255, 20, 177, 54)
                        : Colors.grey[400],
                  ),
                  child: MaterialButton(
                    onPressed: (FirebaseAuth.instance.currentUser?.uid ==
                                "5wwYztIxTifV0EQk3N7dfXsY0jm1" ||
                            FirebaseAuth.instance.currentUser?.uid ==
                                "4Qpgb3aORKhUVXjgT2SNh6zgCWE3")
                        ? () async {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => WinterSiteReport(
                                  docid: docid,
                                ),
                              ),
                            );
                            // Update the field in Firestore
                            try {
                              await FirebaseFirestore.instance
                                  .collection('WinterReports')
                                  .doc(widget.docid.id)
                                  .set(
                                {'filed': true},
                                SetOptions(merge: true),
                              );
                            } catch (error) {
                              print('Error updating document: $error');
                            }
                          }
                        : null,
                    child: Text(
                      "GENERATE PDF",
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                    elevation: 0,
                    color: ((widget.docid.data()
                                as Map<String, dynamic>?)?['filed'] ==
                            true)
                        ? Colors.green.shade200
                        : Color.fromARGB(255, 20, 177, 54),
                  ),
                ),
                SizedBox(width: 15),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: FirebaseAuth.instance.currentUser?.uid ==
                                "5wwYztIxTifV0EQk3N7dfXsY0jm1" ||
                            FirebaseAuth.instance.currentUser?.uid ==
                                "4Qpgb3aORKhUVXjgT2SNh6zgCWE3"
                        ? Color.fromARGB(255, 20, 177, 54)
                        : Colors.grey[400],
                  ),
                  child: MaterialButton(
                    onPressed: FirebaseAuth.instance.currentUser?.uid ==
                                "5wwYztIxTifV0EQk3N7dfXsY0jm1" ||
                            FirebaseAuth.instance.currentUser?.uid ==
                                "4Qpgb3aORKhUVXjgT2SNh6zgCWE3"
                        ? _navigateToEditReport
                        : null,
                    child: const Text(
                      "EDIT REPORT",
                      style: TextStyle(
                        fontSize: 18,
                        color: Color.fromARGB(255, 251, 251, 251),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FirebaseAuth.instance.currentUser?.uid ==
                            "5wwYztIxTifV0EQk3N7dfXsY0jm1" ||
                        FirebaseAuth.instance.currentUser?.uid ==
                            "4Qpgb3aORKhUVXjgT2SNh6zgCWE3"
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

  Future<void> _navigateToEditReport() async {
    Navigator.pop(context);
    final updatedData = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditWinterReport(
          docid: docid,
        ),
      ),
    );

    if (updatedData != null) {
      setState(() {
        // Update UI with the received updated data
        docid["info"]["siteName"] = updatedData["siteName"];
        docid["info"]["address"] = updatedData["address"];
        docid["info"]["date"] = updatedData["date"];        
      });
    }
  }
}
