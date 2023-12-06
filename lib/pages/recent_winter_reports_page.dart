import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gemini_landscaping_app/pages/view_winter_report_page.dart';
import 'package:google_fonts/google_fonts.dart';

class RecentWinterReportsPage extends StatefulWidget {
  const RecentWinterReportsPage({super.key});

  @override
  State<RecentWinterReportsPage> createState() =>
      _RecentWinterReportsPageState();
}

class _RecentWinterReportsPageState extends State<RecentWinterReportsPage> {
  final currentUser = FirebaseAuth.instance.currentUser!;
  final Stream<QuerySnapshot> _winterReportStream =
      FirebaseFirestore.instance.collectionGroup('WinterReports').snapshots();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      appBar: AppBar(
        title: Text("Recent Winter Reports",
            style: GoogleFonts.montserrat(
                fontSize: 18,
                color: Colors.black,
                fontWeight: FontWeight.w500)),
        toolbarHeight: 25,
        backgroundColor: Colors.green.shade100,
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder(
        stream: _winterReportStream,
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return const Text("something is wrong");
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          List<QueryDocumentSnapshot> documents = snapshot.data!.docs;

          documents
              .sort((a, b) => b['info']['date'].compareTo(a['info']['date']));

          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListView.builder(
              itemCount: documents.length,
              itemBuilder: (_, index) {
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ViewWinterReportPage(docid: documents[index]),
                      ),
                    );
                  },
                  child: Column(
                    children: [
                      const SizedBox(
                        height: 5,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 10,
                          right: 10,
                        ),
                        child: Container(
                          height: 65,
                          child: ListTile(
                            tileColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: const BorderSide(
                                width: 2.0,
                                color: Colors.blueAccent,
                              ),
                            ),
                            title: FutureBuilder<DocumentSnapshot>(
                              future: FirebaseFirestore.instance
                                  .collection('WinterReports')
                                  .doc(documents[index].id)
                                  .get(),
                              builder: (BuildContext context,
                                  AsyncSnapshot<DocumentSnapshot> snapshot) {
                                if (snapshot.hasError) {
                                  return Text('Error: ${snapshot.error}');
                                }
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return Text('Loading...');
                                }
                                Map<String, dynamic>? data = snapshot.data!
                                    .data() as Map<String, dynamic>?;
                                if (data == null) {
                                  return Text('No data found');
                                }
                                String siteName =
                                    data['info']['siteName'] ?? '';
                                return Text(
                                  siteName,
                                  style: TextStyle(
                                    fontSize: 22,
                                  ),
                                );
                              },
                            ),
                            subtitle: FutureBuilder<DocumentSnapshot>(
                              future: FirebaseFirestore.instance
                                  .collection('WinterReports')
                                  .doc(documents[index].id)
                                  .get(),
                              builder: (BuildContext context,
                                  AsyncSnapshot<DocumentSnapshot> snapshot) {
                                if (snapshot.hasError) {
                                  return Text('Error: ${snapshot.error}');
                                }
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return Text('Loading...');
                                }
                                Map<String, dynamic>? data = snapshot.data!
                                    .data() as Map<String, dynamic>?;
                                if (data == null) {
                                  return Text('No data found');
                                }
                                final filed = data['filed'] ?? false;
                                return Row(
                                  children: [
                                    Text(
                                      'ID: ${documents[index].id.substring(documents[index].id.length - 5)}',
                                    ),
                                    filed
                                        ? Row(
                                            children: [
                                              Text(
                                                ' - filed ',
                                                style: TextStyle(
                                                    fontSize: 14,
                                                    color:
                                                        Colors.green.shade200),
                                              ),
                                              Icon(
                                                Icons.task_alt_outlined,
                                                color: Colors.green.shade200,
                                              )
                                            ],
                                          )
                                        : Row(
                                            children: [
                                              Text(
                                                ' - in progress ',
                                                style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors
                                                        .blueGrey.shade200),
                                              ),
                                              Icon(
                                                Icons.pending_outlined,
                                                color: Colors.blueGrey.shade200,
                                              )
                                            ],
                                          ),
                                  ],
                                );
                              },
                            ),
                            trailing: FutureBuilder<DocumentSnapshot>(
                              future: FirebaseFirestore.instance
                                  .collection('WinterReports')
                                  .doc(documents[index].id)
                                  .get(),
                              builder: (BuildContext context,
                                  AsyncSnapshot<DocumentSnapshot> snapshot) {
                                if (snapshot.hasError) {
                                  return Text('Error: ${snapshot.error}');
                                }
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return Text('Loading...');
                                }
                                Map<String, dynamic>? data = snapshot.data!
                                    .data() as Map<String, dynamic>?;
                                if (data == null) {
                                  return Text('No data found');
                                }
                                String siteDate = data['info']['date'] ?? '';
                                return Text(
                                  siteDate,
                                  style: TextStyle(
                                    fontSize: 14,
                                  ),
                                );
                              },
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 0,
                              horizontal: 10,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
