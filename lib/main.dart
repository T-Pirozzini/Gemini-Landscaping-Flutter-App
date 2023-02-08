import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'addReport.dart';
import 'viewReport.dart';
import 'auth.dart';
import 'pages/login_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  MyApp({Key? key}) : super(key: key);
  final User? user = Auth().currentUser;

  Future<void> signOut() async {
    await Auth().signOut();
  }

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Gemini Landscaping",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color.fromARGB(255, 31, 182, 77),
      ),
      home: LoginPage(),
    );
  }
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final Stream<QuerySnapshot> _reportStream2023 =
      FirebaseFirestore.instance.collection('SiteReports2023').snapshots();
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

          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListView.builder(
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (_, index) {
                return GestureDetector(
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ViewReport(docid: snapshot.data!.docs[index]),
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
                            snapshot.data!.docChanges[index].doc['info']
                                ['date'],
                            style: const TextStyle(
                              fontSize: 20,
                            ),
                          ),
                          trailing: Text(
                            snapshot.data!.docChanges[index].doc['info']
                                ['siteName'],
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
