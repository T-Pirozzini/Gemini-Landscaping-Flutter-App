import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gemini_landscaping_app/screens/home/home_page.dart';
import 'package:gemini_landscaping_app/screens/print_save_report/print_save_report.dart';
import 'package:gemini_landscaping_app/screens/view_reports/edit_report.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:gemini_landscaping_app/models/site_report.dart';

class ReportPreview extends StatefulWidget {
  final SiteReport report;
  ReportPreview({required this.report});

  @override
  State<ReportPreview> createState() => _ReportPreviewState();
}

class _ReportPreviewState extends State<ReportPreview> {
  late SiteReport report;

  @override
  void initState() {
    super.initState();
    report = widget.report;
  }

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
              onPressed: () async {
                try {
                  await FirebaseFirestore.instance
                      .collection('SiteReports')
                      .doc(widget.report.id)
                      .delete();
                  Navigator.pop(context);
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => Home()),
                    (route) => false,
                  );
                } catch (e) {
                  print('Error deleting report: $e');
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content:
                          Text('Failed to delete report. Please try again.'),
                    ),
                  );
                }
              },
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _navigateToEditReport() async {
    final updatedReport = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditReport(report: report),
      ),
    );

    if (updatedReport != null) {
      setState(() {
        report = updatedReport;
      });
    }
  }

  Future<void> _navigateToPrintSaveReport() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PrintSaveReport(report: widget.report),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final report = this.report;

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
      body: SingleChildScrollView(
        child: Container(
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
              Text(
                report.isRegularMaintenance
                    ? 'REGULAR MAINTENANCE REPORT'
                    : 'ADDITIONAL SERVICE REPORT',
                style: report.isRegularMaintenance
                    ? GoogleFonts.montserrat(
                        textStyle: TextStyle(
                          letterSpacing: .5,
                          color: Colors.green,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : GoogleFonts.montserrat(
                        textStyle: TextStyle(
                          letterSpacing: .5,
                          color: Colors.blueGrey,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              SizedBox(
                height: 100,
                child: Image.asset(
                  'assets/gemini_logo.jpg',
                  fit: BoxFit.cover,
                ),
              ),
              SizedBox(height: 10),
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
                        Text(
                          report.address,
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
                          color: report.isRegularMaintenance
                              ? Color.fromARGB(255, 31, 182, 77)
                              : Colors.blueGrey,
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
                              DateFormat('hh:mm a')
                                  .format(employee.timeOn.toLocal()),
                              style: GoogleFonts.montserrat(fontSize: 14),
                            ),
                          ),
                          Container(
                            alignment: Alignment.center,
                            child: Text(
                              DateFormat('hh:mm a')
                                  .format(employee.timeOff.toLocal()),
                              style: GoogleFonts.montserrat(fontSize: 14),
                            ),
                          ),
                          Container(
                            alignment: Alignment.center,
                            child: Text(
                              "${(employee.duration / 60).toStringAsFixed(1)} hrs",
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
                            "${(report.totalCombinedDuration / 60).toStringAsFixed(1)} hrs",
                            style: GoogleFonts.montserrat(fontSize: 18),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 10),
              Divider(
                thickness: 2,
                color: report.isRegularMaintenance
                    ? Colors.green
                    : Colors.blueGrey,
              ),
              Container(
                padding: EdgeInsets.all(5),
                decoration: BoxDecoration(
                  border: Border.all(width: 1),
                ),
                child: Text('Services Provided',
                    style: GoogleFonts.montserrat(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: report.services.isEmpty ||
                        report.services.values.every((items) => items.isEmpty)
                    ? [Text('No services were specified')]
                    : report.services.entries
                        .where((entry) => entry.value.isNotEmpty)
                        .map((entry) {
                        final serviceKey = entry.key;
                        final serviceItems = entry.value;

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
                                children: serviceItems.map<Widget>((item) {
                                  return Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.check_circle,
                                          color: Colors.green, size: 16),
                                      SizedBox(width: 4),
                                      Text(item,
                                          style: TextStyle(fontSize: 14)),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
              ),
              SizedBox(height: 10),
              Divider(
                thickness: 2,
                color: report.isRegularMaintenance
                    ? Colors.green
                    : Colors.blueGrey,
              ),
              Container(
                padding: EdgeInsets.all(5),
                decoration: BoxDecoration(
                  border: Border.all(width: 1),
                ),
                child: Text('Materials/Disposal',
                    style: GoogleFonts.montserrat(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: report.materials.isEmpty
                    ? [Text('No materials supplied or installed.')]
                    : report.materials.map((material) {
                        return Container(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Divider(),
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
                      }).toList(),
              ),
              SizedBox(height: 10),
              Divider(
                thickness: 2,
                color: report.isRegularMaintenance
                    ? Colors.green
                    : Colors.blueGrey,
              ),
              Container(
                padding: EdgeInsets.all(5),
                decoration: BoxDecoration(
                  border: Border.all(width: 1),
                ),
                child: Text('Description of Services',
                    style: GoogleFonts.montserrat(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              report.description.isEmpty
                  ? Text('No description provided')
                  : Text(report.description),
              SizedBox(height: 10),
              Divider(
                thickness: 2,
                color: report.isRegularMaintenance
                    ? Colors.green
                    : Colors.blueGrey,
              ),
              Text("Submitted By: ${report.submittedBy}"),
              SizedBox(height: 4),
              Text(report.timestamp.toString(),
                  style: TextStyle(fontStyle: FontStyle.italic)),
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
                              _navigateToPrintSaveReport();
                              try {
                                await FirebaseFirestore.instance
                                    .collection('SiteReports')
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
                          fontSize: 14,
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
                          fontSize: 14,
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
      ),
    );
  }
}
