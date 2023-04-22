import 'package:firebase_auth/firebase_auth.dart';
import "package:flutter/material.dart";
import 'package:gemini_landscaping_app/extraReport.dart';
import 'package:gemini_landscaping_app/pages/announcement_page.dart';
import 'package:gemini_landscaping_app/pages/folders_page.dart';
import 'package:gemini_landscaping_app/pages/profile_page.dart';
import 'package:gemini_landscaping_app/pages/recent_reports_page.dart';
import 'package:google_fonts/google_fonts.dart';
import '../addReport.dart';
import '../auth.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:floating_action_bubble/floating_action_bubble.dart';

import '../uploadPhotos.dart';
import 'chart_page.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  _HomeState createState() => _HomeState();
}

final User? user = Auth().currentUser;

class _HomeState extends State<Home> with SingleTickerProviderStateMixin {
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

  // bottom navigation bar
  int currentIndex = 0;
  final pages = [
    RecentReportsPage(),
    SiteFolders(),
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
          // Bubble(
          //   title: "Site Report",
          //   iconColor: Colors.white,
          //   bubbleColor: Color.fromARGB(255, 31, 182, 77),
          //   icon: Icons.note_add_rounded,
          //   titleStyle: TextStyle(fontSize: 16, color: Colors.white),
          //   onPress: () {
          //     Navigator.pushReplacement(context,
          //         MaterialPageRoute(builder: (_) => const AddReport()));
          //   },
          // ),
          Bubble(
            title: "Site Report",
            iconColor: Colors.white,
            bubbleColor: Color.fromARGB(255, 31, 182, 77),
            icon: Icons.note_add_outlined,
            titleStyle: TextStyle(fontSize: 16, color: Colors.white),
            onPress: () {
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const AddReport()));
            },
          ),
          Bubble(
            title: "Extras Report",
            iconColor: Colors.white,
            bubbleColor: Color.fromARGB(255, 31, 182, 77),
            icon: Icons.add_circle_outline,
            titleStyle: TextStyle(fontSize: 16, color: Colors.white),
            onPress: () {
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const ExtraReport()));
            },
          ),
          Bubble(
            title: "Pictures",
            iconColor: Colors.white,
            bubbleColor: Color.fromARGB(255, 31, 182, 77),
            icon: Icons.add_a_photo_outlined,
            titleStyle: TextStyle(fontSize: 16, color: Colors.white),
            onPress: () {
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const UploadPhotos()));
            },
          ),
        ],
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
            Icons.folder_copy_outlined,
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
