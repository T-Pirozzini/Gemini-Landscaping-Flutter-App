import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gemini_landscaping_app/providers/admin_provider.dart';
import 'package:gemini_landscaping_app/screens/utility_screens/restricted_page.dart';
import 'package:gemini_landscaping_app/screens/site_time/site_time.dart';

class AdminController extends ConsumerStatefulWidget {
  const AdminController({super.key});

  @override
  ConsumerState<AdminController> createState() => AdminControllerState();
}

class AdminControllerState extends ConsumerState<AdminController> {
  @override
  Widget build(BuildContext context) {
    final isAdmin = ref.watch(isAdminProvider);

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
            ],
          ),
        ),
        body: TabBarView(
          children: [
            isAdmin ? SiteTime() : RestrictedPage(),
          ],
        ),
      ),
    );
  }
}
