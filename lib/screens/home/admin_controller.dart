import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gemini_landscaping_app/screens/utility_screens/restricted_page.dart';
import 'package:gemini_landscaping_app/screens/site_time/site_time.dart';

class AdminController extends StatefulWidget {
  const AdminController({super.key});

  @override
  State<AdminController> createState() => AdminControllerState();
}

class AdminControllerState extends State<AdminController> {
  String userRole = '';
  final currentUser = FirebaseAuth.instance.currentUser!;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 1,
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
              Tab(text: 'Site Time'),
              // Tab(text: 'Recent (old)'),
              // Tab(text: 'All (old)'),
            ],
          ),
        ),
        body: FirebaseAuth.instance.currentUser?.uid ==
                    "5wwYztIxTifV0EQk3N7dfXsY0jm1" ||
                FirebaseAuth.instance.currentUser?.uid ==
                    "4Qpgb3aORKhUVXjgT2SNh6zgCWE3"
            ? TabBarView(
                children: [
                  SiteTime(),
                  // RecentReportsPage(),
                  // SiteFolders(),
                ],
              )
            : TabBarView(
                children: [
                  RestrictedPage(),
                  // RestrictedPage(),
                  // RestrictedPage(),
                ],
              ),
      ),
    );
  }
}
