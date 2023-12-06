import 'package:firebase_auth/firebase_auth.dart';
import "package:flutter/material.dart";
import 'package:gemini_landscaping_app/pages/announcement_page.dart';
import 'package:gemini_landscaping_app/pages/folders_page.dart';
import 'package:gemini_landscaping_app/pages/profile_page.dart';
import 'package:gemini_landscaping_app/pages/recent_reports_page.dart';
import 'package:gemini_landscaping_app/pages/reports_controller.dart';
import 'package:gemini_landscaping_app/uploadPhotos.dart';
import 'package:google_fonts/google_fonts.dart';
import '../auth.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'equipment_page.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  _HomeState createState() => _HomeState();
}

final User? user = Auth().currentUser;

class _HomeState extends State<Home> {
  // bottom navigation bar
  int currentIndex = 0;
  final pages = [
    TimeSheetController(),
    // RecentReportsPage(),
    // SiteFolders(),
    UploadPhotos(),
    EquipmentPage(),
    // Chart(), Add when completed
    AnnouncementPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade600,
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 31, 182, 77),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset("assets/gemini-icon-transparent.png",
                color: Colors.white, fit: BoxFit.contain, height: 50),
            SizedBox(width: 10),
            Text('Gemini Landscaping',
                style: GoogleFonts.pathwayGothicOne(
                    fontSize: 38,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
      body: pages[currentIndex],
      // Bottom Navigator
      bottomNavigationBar: CurvedNavigationBar(
        height: 60,
        index: currentIndex,
        backgroundColor: Colors.grey.shade200,
        color: const Color.fromARGB(255, 31, 182, 77),
        animationDuration: Duration(milliseconds: 400),
        onTap: (index) => setState(() => currentIndex = index),
        items: [
          Icon(
            Icons.grade_outlined,
            color: Colors.white,
            size: 30,
          ),
          Icon(
            Icons.add_a_photo_outlined,
            color: Colors.white,
            size: 30,
          ),
          Icon(
            Icons.handyman_outlined,
            color: Colors.white,
            size: 30,
          ),
          // Icon(
          //   Icons.auto_graph,
          //   color: Colors.white,
          //   size: 30,
          // ),
          Icon(
            Icons.message_outlined,
            color: Colors.white,
            size: 30,
          ),
          Icon(
            Icons.account_circle_outlined,
            color: Colors.white,
            size: 30,
          ),
        ],
      ),
    );
  }
}
