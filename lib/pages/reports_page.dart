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

  final Stream<QuerySnapshot> _reportStream2023 = FirebaseFirestore.instance
      .collection('SiteReports2023')
      // .orderBy('date', descending: false)
      .snapshots();

  // sign current user out
  Future<void> signOut() async {
    await Auth().signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => AuthPage()),
    );
  }

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
                            documents[index]['info']['date'],
                            style: const TextStyle(
                              fontSize: 20,
                            ),
                          ),
                          trailing: Text(
                            documents[index]['info']['siteName'],
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
