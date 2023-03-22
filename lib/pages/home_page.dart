import 'package:firebase_auth/firebase_auth.dart';
import "package:flutter/material.dart";
import 'package:gemini_landscaping_app/pages/announcement_page.dart';
import 'package:gemini_landscaping_app/pages/profile_page.dart';
import 'package:gemini_landscaping_app/pages/reports_page.dart';
import '../addReport.dart';
import '../auth.dart';
import 'auth_page.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';

class Home extends StatefulWidget {
  const Home({super.key});
  @override
  // ignore: library_private_types_in_public_api
  _HomeState createState() => _HomeState();
}

// // get current user
// final currentUser = FirebaseAuth.instance.currentUser!;

final User? user = Auth().currentUser;

bool _sortBySiteName = false;
bool _sortByDate = false;

class _HomeState extends State<Home> {
  // bottom navigation bar
  int currentIndex = 0;
  final pages = [
    ReportsPage(),
    AnnouncementPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade600,
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color.fromARGB(255, 31, 182, 77),
        onPressed: () {
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (_) => const AddReport()));
        },
        child: const Icon(
          Icons.note_add_outlined,
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
      body: pages[currentIndex],
      bottomNavigationBar: CurvedNavigationBar(
        height: 60,
        index: currentIndex,
        backgroundColor: Colors.grey.shade200,
        color: const Color.fromARGB(255, 31, 182, 77),
        animationDuration: Duration(milliseconds: 400),
        onTap: (index) => setState(() => currentIndex = index),
        items: [
          Icon(
            Icons.folder_copy_outlined,
            color: Colors.white,
            size: 40,
          ),
          Icon(
            Icons.message_outlined,
            color: Colors.white,
            size: 40,
          ),
          Icon(
            Icons.account_circle_outlined,
            color: Colors.white,
            size: 40,
          ),
        ],
      ),
    );
  }
}
