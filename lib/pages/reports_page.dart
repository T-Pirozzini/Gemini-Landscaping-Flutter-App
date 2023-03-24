import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../viewReport.dart';
import '../auth.dart';
import 'auth_page.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  // get current user
  final currentUser = FirebaseAuth.instance.currentUser!;

  final User? user = Auth().currentUser;

  bool _sortBySiteName = false;
  bool _sortByDate = false;

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

  // void getSiteReports() async {
  //   QuerySnapshot siteReportsSnapshot =
  //       await FirebaseFirestore.instance.collection('SiteReports2023').get();

  //   for (DocumentSnapshot siteReportDoc in siteReportsSnapshot.docs) {
  //     Query subCollectionsQuery = FirebaseFirestore.instance.collectionGroup(
  //         siteReportDoc
  //             .id); // use collectionGroup() to get all subcollections with the specified ID
  //     QuerySnapshot subCollectionsSnapshot = await subCollectionsQuery.get();

  //     subCollectionsSnapshot.docs.forEach((subDoc) {
  //       print(subDoc.id + " => " + subDoc.data().toString());
  //     });
  //   }
  // }

  // Future<List<String>> getSubDocumentIds() async {
  //   List<String> subDocIds = [];

  //   QuerySnapshot siteReportsSnapshot =
  //       await FirebaseFirestore.instance.collection('SiteReports2023').get();

  //   for (DocumentSnapshot siteReportDoc in siteReportsSnapshot.docs) {
  //     Query subCollectionsQuery = FirebaseFirestore.instance.collectionGroup(
  //         siteReportDoc
  //             .id); // use collectionGroup() to get all subcollections with the specified ID
  //     QuerySnapshot subCollectionsSnapshot = await subCollectionsQuery.get();

  //     subCollectionsSnapshot.docs.forEach((subDoc) {
  //       subDocIds.add(subDoc.id);
  //     });
  //   }

  //   return subDocIds;
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade200,
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

          // Call the function to get the subcollections and print their IDs
          // getSiteReports();

          List<QueryDocumentSnapshot> documents = snapshot.data!.docs;

          if (_sortByDate) {
            _sortBySiteName = false;
            documents.sort((a, b) => DateTime.parse(a['info']['date'])
                .compareTo(DateTime.parse(b['info']['date'])));
          }
          if (_sortBySiteName) {
            _sortByDate = false;
            documents.sort((a, b) =>
                a['info']['siteName'].compareTo(b['info']['siteName']));
          }

          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListView.builder(
              itemCount: documents.length,
              itemBuilder: (_, index) {
                return GestureDetector(
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ViewReport(docid: documents[index]),
                      ),
                    );
                  },
                  child: Column(
                    children: [
                      const SizedBox(
                        height: 10,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 10,
                          right: 10,
                        ),
                        child: ListTile(
                          tileColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: const BorderSide(
                              width: 2.0,
                              color: Colors.green,
                            ),
                          ),
                          title: Text(
                            documents[index].id,
                            style: const TextStyle(
                              fontSize: 20,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 16,
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
