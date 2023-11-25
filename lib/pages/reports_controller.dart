import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gemini_landscaping_app/pages/chart_page.dart';
import 'package:gemini_landscaping_app/pages/folders_page.dart';
import 'package:gemini_landscaping_app/pages/recent_reports_page.dart';

class TimeSheetController extends StatefulWidget {
  const TimeSheetController({super.key});

  @override
  State<TimeSheetController> createState() => _TimeSheetControllerState();
}

class _TimeSheetControllerState extends State<TimeSheetController> {
  String userRole = '';
  final currentUser = FirebaseAuth.instance.currentUser!;

  @override
  void initState() {
    super.initState();
    // fetchUserRole();
  }

  // Future<void> fetchUserRole() async {
  //   final user = FirebaseAuth.instance.currentUser;
  //   if (user != null) {
  //     final userDoc = await FirebaseFirestore.instance
  //         .collection('Users')
  //         .doc(currentUser.email)
  //         .get();
  //     final role = userDoc['role'];
  //     setState(() {
  //       userRole = role;
  //     });
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFDFD3C3),
        appBar: AppBar(
          toolbarHeight: 0,
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.black,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'Recent'),
              Tab(text: 'All Reports'),
              Tab(text: 'Analysis'),
            ],
          ),
        ),
        body: userRole == 'admin'
            ? const TabBarView(
                children: [
                  RecentReportsPage(),
                  SiteFolders(),
                  ChartPage(),
                ],
              )
            : const TabBarView(
                children: [
                  RecentReportsPage(),
                  SiteFolders(),
                  ChartPage(),
                ],
              ),
      ),
    );
  }
}
