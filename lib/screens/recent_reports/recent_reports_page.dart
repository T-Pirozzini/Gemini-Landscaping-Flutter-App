import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gemini_landscaping_app/pages/addWinterReport.dart';
import 'package:gemini_landscaping_app/screens/recent_reports/add_site_report.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../pages/view_report_page.dart';
import '../../auth.dart';
import '../auth/auth_page.dart';
import 'package:floating_action_bubble/floating_action_bubble.dart';
import 'addReport.dart';
import 'package:gemini_landscaping_app/extraReport.dart';

class RecentReportsPage extends StatefulWidget {
  const RecentReportsPage({super.key});

  @override
  State<RecentReportsPage> createState() => _RecentReportsPageState();
}

class _RecentReportsPageState extends State<RecentReportsPage>
    with SingleTickerProviderStateMixin {
  // get current user
  final currentUser = FirebaseAuth.instance.currentUser!;

  final User? user = Auth().currentUser;

  final Stream<QuerySnapshot> _reportStream2023 =
      FirebaseFirestore.instance.collectionGroup('SiteReports2023').snapshots();

  // sign current user out
  Future<void> signOut() async {
    await Auth().signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => AuthPage()),
    );
  }

  // floating action bubble
  late Animation<double> _animation;
  late AnimationController _animationController;

  @override
  void initState() {
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 260),
    );

    final curvedAnimation =
        CurvedAnimation(curve: Curves.easeInOut, parent: _animationController);
    _animation = Tween<double>(begin: 0, end: 1).animate(curvedAnimation);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      appBar: AppBar(
        title: Text("Most Recent Reports",
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
        stream: _reportStream2023,
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
              itemCount: 50,
              itemBuilder: (_, index) {
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ViewReport(docid: documents[index]),
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
                                color: Colors.green,
                              ),
                            ),
                            title: FutureBuilder<DocumentSnapshot>(
                              future: FirebaseFirestore.instance
                                  .collection('SiteReports2023')
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
                                  .collection('SiteReports2023')
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
                                  .collection('SiteReports2023')
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
      // Floating Action Button
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: FloatingActionBubble(
        iconColor: Colors.white,
        backGroundColor: const Color.fromARGB(255, 31, 182, 77),
        animation: _animation,
        onPress: () => _animationController.isCompleted
            ? _animationController.reverse()
            : _animationController.forward(),
        iconData: Icons.add,
        items: <Bubble>[
          Bubble(
            title: "Site Report",
            iconColor: Colors.white,
            bubbleColor: const Color.fromARGB(255, 59, 82, 73),
            icon: Icons.note_add_outlined,
            titleStyle: TextStyle(fontSize: 16, color: Colors.white),
            onPress: () {
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const AddSiteReport()));
            },
          ),
          Bubble(
            title: "Extras Report",
            iconColor: Colors.white,
            bubbleColor: const Color.fromARGB(255, 59, 82, 73),
            icon: Icons.add_circle_outline,
            titleStyle: TextStyle(fontSize: 16, color: Colors.white),
            onPress: () {
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const ExtraReport()));
            },
          ),
          Bubble(
            title: "Winter Report",
            iconColor: Colors.white,
            bubbleColor: const Color.fromARGB(255, 59, 82, 73),
            icon: Icons.cloudy_snowing,
            titleStyle: TextStyle(fontSize: 16, color: Colors.white),
            onPress: () {
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => AddWinterReport()));
            },
          ),
        ],
      ),
    );
  }
}
