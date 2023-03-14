import 'package:firebase_auth/firebase_auth.dart';
import "package:flutter/material.dart";
import 'package:cloud_firestore/cloud_firestore.dart';
import '../addReport.dart';
import '../viewReport.dart';
import '../auth.dart';
import 'auth_page.dart';

class Home extends StatefulWidget {
  const Home({super.key});
  @override
  // ignore: library_private_types_in_public_api
  _HomeState createState() => _HomeState();
}

// get current user
final currentUser = FirebaseAuth.instance.currentUser!;

final User? user = Auth().currentUser;

bool _sortBySiteName = false;
bool _sortByDate = false;

class _HomeState extends State<Home> {
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
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color.fromARGB(255, 31, 182, 77),
        onPressed: () {
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (_) => const AddReport()));
        },
        child: const Icon(
          Icons.add,
        ),
      ),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 31, 182, 77),
        title: const Text('SITE REPORTS 2023'),
        centerTitle: true,
        leading: IconButton(
          onPressed: () {
            setState(() {
              _sortByDate = !_sortByDate;
            });
          },
          icon: Icon(Icons.access_time),
        ),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _sortBySiteName = !_sortBySiteName;
              });
            },
            icon: Icon(Icons.sort),
          ),
        ],
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
                        height: 4,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 3,
                          right: 3,
                        ),
                        child: ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: const BorderSide(
                              color: Colors.black,
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
      bottomNavigationBar: Container(
        height: 50.0,
        color: const Color.fromARGB(255, 31, 182, 77),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Row(
                children: [
                  const Icon(Icons.account_circle, color: Colors.white),
                  const SizedBox(width: 5),
                  Text(
                    currentUser.email!,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w400),
                  ),
                ],
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: signOut,
                    child:
                        Text('Sign Out', style: TextStyle(color: Colors.white)),
                  ),
                  IconButton(
                    onPressed: signOut,
                    icon: Icon(Icons.logout_outlined, color: Colors.white),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
