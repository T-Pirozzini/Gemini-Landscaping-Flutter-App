import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gemini_landscaping_app/providers/admin_provider.dart';
import 'package:gemini_landscaping_app/screens/all_reports/report_folders.dart';
import 'package:gemini_landscaping_app/screens/recent_reports/recent_reports_new.dart';
import 'package:gemini_landscaping_app/screens/winter_reports/recent_winter_reports_page.dart';
import 'package:gemini_landscaping_app/screens/utility_screens/restricted_page.dart';

class TimeSheetController extends ConsumerStatefulWidget {
  const TimeSheetController({super.key});

  @override
  ConsumerState<TimeSheetController> createState() =>
      _TimeSheetControllerState();
}

class _TimeSheetControllerState extends ConsumerState<TimeSheetController> {
  @override
  Widget build(BuildContext context) {
    final isAdmin = ref.watch(isAdminProvider);

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
        body: TabBarView(
          children: [
            RecentReports(),
            isAdmin ? ReportFolders() : RestrictedPage(),
            RecentWinterReportsPage(),
          ],
        ),
      ),
    );
  }
}
