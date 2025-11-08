import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gemini_landscaping_app/screens/all_reports/report_folders.dart';
import 'package:gemini_landscaping_app/screens/recent_reports/recent_reports_new.dart';
import 'package:gemini_landscaping_app/screens/winter_reports/recent_winter_reports_page.dart';
import 'package:gemini_landscaping_app/screens/utility_screens/restricted_page.dart';

class TimeSheetController extends StatefulWidget {
  const TimeSheetController({super.key});

  @override
  State<TimeSheetController> createState() => _TimeSheetControllerState();
}

class _TimeSheetControllerState extends State<TimeSheetController> {
  String userRole = '';
  final currentUser = FirebaseAuth.instance.currentUser!;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFDFD3C3),
        appBar: AppBar(
          backgroundColor: const Color.fromARGB(255, 59, 82, 73),
          toolbarHeight: 0,
          bottom: TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey.shade400,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'Recent'),
              Tab(text: 'All Reports'),
              Tab(text: 'Winter Reports'),
            ],
          ),
        ),
        body: FirebaseAuth.instance.currentUser?.uid ==
                    "5wwYztIxTifV0EQk3N7dfXsY0jm1" ||
                FirebaseAuth.instance.currentUser?.uid ==
                    "4Qpgb3aORKhUVXjgT2SNh6zgCWE3"
            ? TabBarView(
                children: [
                  RecentReports(),
                  ReportFolders(),
                  RecentWinterReportsPage(),
                ],
              )
            : TabBarView(
                children: [
                  RecentReports(),
                  RestrictedPage(),
                  RecentWinterReportsPage(),
                ],
              ),
      ),
    );
  }
}
