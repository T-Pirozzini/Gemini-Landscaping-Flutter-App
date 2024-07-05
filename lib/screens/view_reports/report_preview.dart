import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gemini_landscaping_app/screens/home/home_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../pages/edit_report_page.dart';
import '../../pages/pdf_page.dart';
import 'package:gemini_landscaping_app/models/site_report.dart';

class ReportPreview extends StatefulWidget {
  final SiteReport report;
  ReportPreview({required this.report});

  @override
  State<ReportPreview> createState() => _ReportPreviewState();
}

class _ReportPreviewState extends State<ReportPreview> {
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
                // widget.docid.reference.delete().whenComplete(
                //   () {
                //     Navigator.pushAndRemoveUntil(
                //       context,
                //       MaterialPageRoute(builder: (_) => Home()),
                //       (route) => false,
                //     );
                //   },
                // );
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
    final report = widget.report;

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
                      report.date,
                      style: GoogleFonts.montserrat(
                        textStyle: TextStyle(
                            letterSpacing: .5,
                            fontSize: 14,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    Text(
                      '#${report.id.substring(report.id.length - 5)}',
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
                        report.siteName.toUpperCase(),
                        style: GoogleFonts.montserrat(
                          textStyle: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (report.address != null)
                        Text(
                          report.address!,
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
                  ...report.employees.map((employee) {
                    return TableRow(
                      children: [
                        Container(
                          alignment: Alignment.center,
                          child: Text(
                            employee.name,
                            style: GoogleFonts.montserrat(fontSize: 14),
                          ),
                        ),
                        Container(
                          alignment: Alignment.center,
                          child: Text(
                            DateFormat('yyyy-MM-dd – kk:mm')
                                .format(employee.timeOn),
                            style: GoogleFonts.montserrat(fontSize: 14),
                          ),
                        ),
                        Container(
                          alignment: Alignment.center,
                          child: Text(
                            DateFormat('yyyy-MM-dd – kk:mm')
                                .format(employee.timeOff),
                            style: GoogleFonts.montserrat(fontSize: 14),
                          ),
                        ),
                        Container(
                          alignment: Alignment.center,
                          child: Text(
                            "${employee.duration} minutes",
                            style: GoogleFonts.montserrat(fontSize: 14),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
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
                          "${report.totalCombinedDuration}",
                          style: GoogleFonts.montserrat(fontSize: 18),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: report.services.length,
                itemBuilder: (context, index) {
                  final serviceKey = report.services.keys.elementAt(index);
                  final serviceItems = report.services[serviceKey];

                  return Container(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Divider(),
                        Text(
                          serviceKey.toUpperCase(),
                          style: GoogleFonts.montserrat(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        Wrap(
                          spacing: 8.0,
                          runSpacing: 4.0,
                          children: serviceItems!.map<Widget>((item) {
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle,
                                    color: Colors.green, size: 16),
                                SizedBox(width: 4),
                                Text(item, style: TextStyle(fontSize: 14)),
                              ],
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: report.materials.length,
                itemBuilder: (context, index) {
                  final material = report.materials[index];

                  return Container(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Divider(),
                        Text(
                          'Material ${index + 1}'.toUpperCase(),
                          style: GoogleFonts.montserrat(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          'Description: ${material.description}',
                          style: GoogleFonts.montserrat(fontSize: 14),
                        ),
                        Text(
                          'Vendor: ${material.vendor}',
                          style: GoogleFonts.montserrat(fontSize: 14),
                        ),
                        Text(
                          'Cost: \$${material.cost}',
                          style: GoogleFonts.montserrat(fontSize: 14),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Text(report.description),
            Text(report.submittedBy),
            Text(report.timestamp.toString()),
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
                            // Navigator.push(
                            // context,
                            // MaterialPageRoute(
                            //   builder: (_) => PrintReport(
                            //     report: report,
                            //   ),
                            // ),
                            // );
                            // Update the field in Firestore
                            try {
                              await FirebaseFirestore.instance
                                  .collection('SiteReports2023')
                                  .doc(report.id)
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
                    color: report.filed
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
    // final updatedData = await Navigator.push(
    //   // context,
    //   // MaterialPageRoute(
    //   //   // builder: (_) => EditReport(
    //   //   //   report: widget.report,
    //   //   // ),
    //   // ),
    // // );

    // if (updatedData != null) {
    //   setState(() {
    //     // widget.report = updatedData;
    //   });
    // }
  }
}
