import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gemini_landscaping_app/providers/admin_notification_provider.dart';
import 'package:gemini_landscaping_app/providers/admin_provider.dart';
import 'package:gemini_landscaping_app/screens/admin/admin_notifications_screen.dart';
import 'package:gemini_landscaping_app/screens/proposals/proposal_list.dart';
import 'package:gemini_landscaping_app/screens/utility_screens/restricted_page.dart';
import 'package:gemini_landscaping_app/screens/site_time/site_time.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminController extends ConsumerStatefulWidget {
  const AdminController({super.key});

  @override
  ConsumerState<AdminController> createState() => AdminControllerState();
}

class AdminControllerState extends ConsumerState<AdminController> {
  @override
  Widget build(BuildContext context) {
    final isAdmin = ref.watch(isAdminProvider);
    final pendingCount = ref.watch(pendingNotificationCountProvider);

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
              Tab(text: 'Site Time'),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Notifications',
                        style: GoogleFonts.montserrat(fontSize: 13)),
                    pendingCount.when(
                      data: (count) => count > 0
                          ? Container(
                              margin: const EdgeInsets.only(left: 6),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '$count',
                                style: GoogleFonts.montserrat(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
              Tab(text: 'Proposals'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            isAdmin ? SiteTime() : RestrictedPage(),
            isAdmin ? AdminNotificationsScreen() : RestrictedPage(),
            isAdmin ? ProposalList() : RestrictedPage(),
          ],
        ),
      ),
    );
  }
}
