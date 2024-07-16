import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gemini_landscaping_app/extraReport.dart';
import 'package:gemini_landscaping_app/pages/addWinterReport.dart';
import 'package:gemini_landscaping_app/providers/report_provider.dart';
import 'package:gemini_landscaping_app/screens/add_report/add_site_report.dart';
import 'package:gemini_landscaping_app/screens/view_reports/report_preview.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:floating_action_bubble/floating_action_bubble.dart';

class RecentReports extends ConsumerStatefulWidget {
  @override
  _RecentReportsState createState() => _RecentReportsState();
}

class _RecentReportsState extends ConsumerState<RecentReports>
    with SingleTickerProviderStateMixin {
  late Animation<double> _animation;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 200),
    );

    _animation = CurvedAnimation(
      curve: Curves.easeInOut,
      parent: _animationController,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reportsAsyncValue = ref.watch(allSiteReportsStreamProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text("Most Recent Reports",
            style: GoogleFonts.montserrat(
                fontSize: 18,
                color: Colors.black,
                fontWeight: FontWeight.w500)),
        toolbarHeight: 25,
        backgroundColor: Colors.green.shade100,
        elevation: 0,
        centerTitle: true,
      ),
      body: reportsAsyncValue.when(
        data: (reports) {
          reports.sort((a, b) {
            final dateA = DateFormat('MMMM d, yyyy').parse(a.date);
            final dateB = DateFormat('MMMM d, yyyy').parse(b.date);
            return dateB.compareTo(dateA); // Sort in descending order
          });

          // Limit the number of reports to 50
          final limitedReports = reports.take(50).toList();

          return ListView.builder(
            itemCount: limitedReports.length,
            itemBuilder: (context, index) {
              final report = limitedReports[index];
              // Convert duration from minutes to hours
              final durationInHours = report.totalCombinedDuration / 60;
              final formattedDuration = durationInHours.toStringAsFixed(1);
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ReportPreview(report: report),
                    ),
                  );
                },
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                  child: Container(
                    height: 65,
                    child: ListTile(
                      dense: true,
                      tileColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          width: 2.0,
                          color: report.isRegularMaintenance
                              ? Colors.green
                              : Colors.blueGrey,
                        ),
                      ),
                      leading: report.isRegularMaintenance
                          ? Icon(Icons.grass)
                          : Icon(Icons.add_circle_outline),
                      minLeadingWidth: 2,
                      title: FittedBox(
                        alignment: Alignment.centerLeft,
                        fit: BoxFit.scaleDown,
                        child: Text(
                          report.siteName,
                          style: GoogleFonts.montserrat(
                            fontSize: 20,
                            letterSpacing: .5,
                          ),
                        ),
                      ),
                      subtitle: Row(
                        children: [
                          Text(
                            'ID: ${report.id.substring(0, 5)}',
                          ),
                          report.filed
                              ? Row(
                                  children: [
                                    Text(
                                      ' - filed ',
                                      style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.green.shade200),
                                    ),
                                    Icon(
                                      Icons.task_alt_outlined,
                                      color: Colors.green.shade200,
                                    )
                                  ],
                                )
                              : Row(
                                  children: [
                                    Text(
                                      ' - in progress ',
                                      style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.blueGrey.shade200),
                                    ),
                                    Icon(
                                      Icons.pending_outlined,
                                      color: Colors.blueGrey.shade200,
                                    )
                                  ],
                                ),
                        ],
                      ),
                      trailing: Text(
                        '${report.date}\nDuration: $formattedDuration hrs\nEmployees: ${report.employees.length}',
                        style: GoogleFonts.montserrat(
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
        loading: () => Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: FloatingActionBubble(
        iconColor: Colors.white,
        backGroundColor: const Color.fromARGB(255, 59, 82, 73),
        animation: _animation,
        onPress: () => _animationController.isCompleted
            ? _animationController.reverse()
            : _animationController.forward(),
        iconData: Icons.post_add_outlined,
        items: <Bubble>[
          Bubble(
            title: "Site Report",
            iconColor: Colors.white,
            bubbleColor: const Color.fromARGB(255, 59, 82, 73),
            icon: Icons.note_add_outlined,
            titleStyle: TextStyle(fontSize: 16, color: Colors.white),
            onPress: () {
              Navigator.pushReplacement(
                  context, MaterialPageRoute(builder: (_) => AddSiteReport()));
            },
          ),
          Bubble(
            title: "Winter Report",
            iconColor: Colors.white,
            bubbleColor: const Color.fromARGB(255, 59, 82, 73),
            icon: Icons.cloudy_snowing,
            titleStyle: TextStyle(fontSize: 16, color: Colors.white),
            onPress: () {
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => AddWinterReport()));
            },
          ),
        ],
      ),
    );
  }
}
