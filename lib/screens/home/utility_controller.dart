import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gemini_landscaping_app/pages/equipment_page.dart';
import 'package:gemini_landscaping_app/screens/all_reports/folders_page.dart';
import 'package:gemini_landscaping_app/screens/recent_reports/recent_reports_page.dart';
import 'package:gemini_landscaping_app/pages/restricted_page.dart';
import 'package:gemini_landscaping_app/screens/site_time/site_time.dart';
import 'package:gemini_landscaping_app/uploadPhotos.dart';

class UtilityController extends StatefulWidget {
  const UtilityController({super.key});

  @override
  State<UtilityController> createState() => UtilityControllerState();
}

class UtilityControllerState extends State<UtilityController> {
  String userRole = '';
  final currentUser = FirebaseAuth.instance.currentUser!;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
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
              Tab(text: 'Upload Photos'),
              Tab(text: 'Report Repairs'),
            ],
          ),
        ),
        body: FirebaseAuth.instance.currentUser?.uid ==
                    "5wwYztIxTifV0EQk3N7dfXsY0jm1" ||
                FirebaseAuth.instance.currentUser?.uid ==
                    "4Qpgb3aORKhUVXjgT2SNh6zgCWE3"
            ? TabBarView(
                children: [
                  UploadPhotos(),
                  EquipmentPage(),
                ],
              )
            : TabBarView(
                children: [
                  UploadPhotos(),
                  EquipmentPage(),
                ],
              ),
      ),
    );
  }
}
