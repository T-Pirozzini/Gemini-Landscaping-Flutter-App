import 'package:flutter/material.dart';
import 'package:gemini_landscaping_app/screens/field_quote/field_quote_list.dart';
import 'package:gemini_landscaping_app/screens/utility_screens/announcement_page.dart';
import 'package:gemini_landscaping_app/screens/utility_screens/equipment_page.dart';
import 'package:gemini_landscaping_app/screens/utility_screens/uploadPhotos.dart';

class UtilityController extends StatefulWidget {
  const UtilityController({super.key});

  @override
  State<UtilityController> createState() => UtilityControllerState();
}

class UtilityControllerState extends State<UtilityController> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: const Color(0xFFDFD3C3),
        appBar: AppBar(
          backgroundColor: const Color.fromARGB(255, 59, 82, 73),
          toolbarHeight: 0,
          bottom: TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey.shade400,
            indicatorColor: Colors.white,
            isScrollable: true,
            tabs: [
              Tab(text: 'Announcements'),
              Tab(text: 'Quotes'),
              Tab(text: 'Upload Photos'),
              Tab(text: 'Equipment'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            AnnouncementPage(),
            FieldQuoteList(),
            UploadPhotos(),
            EquipmentPage(),
          ],
        ),
      ),
    );
  }
}
