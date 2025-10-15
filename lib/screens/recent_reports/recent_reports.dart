import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gemini_landscaping_app/models/site_report.dart';
import 'package:gemini_landscaping_app/screens/winter_reports/addWinterReport.dart';
import 'package:gemini_landscaping_app/providers/report_provider.dart';
import 'package:gemini_landscaping_app/screens/add_report/add_site_report.dart';
import 'package:gemini_landscaping_app/screens/view_reports/report_preview.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:floating_action_bubble/floating_action_bubble.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

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
    tz.initializeTimeZones();
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

    final vancouver = tz.getLocation('America/Vancouver');

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text("Recent Site Reports",
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
          // Ensure we parse the dates consistently and sort by date first (descending)
          reports.sort((a, b) {
            final dateA = DateFormat('MMMM d, yyyy').parse(a.date);
            final dateB = DateFormat('MMMM d, yyyy').parse(b.date);
            return dateB.compareTo(dateA); // Sort most recent first
          });

          // Get the most recent 80 reports
          final limitedReports = reports.take(80).toList();

          // Group the limited reports by date, then by submittedBy
          final groupedByDate = <DateTime, Map<String, List<SiteReport>>>{};

          for (var report in limitedReports) {
            final reportDate = DateFormat('MMMM d, yyyy').parse(report.date);

            // Initialize date group if not present
            if (!groupedByDate.containsKey(reportDate)) {
              groupedByDate[reportDate] = {};
            }

            final submittedBy = report.submittedBy;

            // Initialize submittedBy group within the date if not present
            if (!groupedByDate[reportDate]!.containsKey(submittedBy)) {
              groupedByDate[reportDate]![submittedBy] = [];
            }

            // Add the report to the appropriate group
            groupedByDate[reportDate]![submittedBy]!.add(report);
          }

          // Sort each employee's reports by latest timeOff within the same date group
          groupedByDate.forEach((date, reportsByEmployee) {
            reportsByEmployee.forEach((employee, employeeReports) {
              employeeReports.sort((a, b) {
                final latestTimeOffA = a.employees
                    .map((e) => e.timeOff)
                    .reduce((a, b) => a.isAfter(b) ? a : b);
                final latestTimeOffB = b.employees
                    .map((e) => e.timeOff)
                    .reduce((a, b) => a.isAfter(b) ? a : b);

                return latestTimeOffB.compareTo(latestTimeOffA);
              });
            });
          });

          // Flatten the grouped structure while maintaining the order
          final List<Map<String, dynamic>> reportsList = [];
          groupedByDate.forEach((date, reportsByEmployee) {
            final formattedDate =
                DateFormat('MMMM d, yyyy').format(date); // Format DateTime

            reportsList.add({"date": formattedDate, "type": "date"});
            reportsByEmployee.forEach((submittedBy, employeeReports) {
              final firstName = submittedBy.split('@')[0];
              final capitalizedFirstName = firstName[0].toUpperCase() +
                  firstName.substring(1).toLowerCase();
              reportsList
                  .add({"name": capitalizedFirstName, "type": "employee"});
              for (var report in employeeReports) {
                reportsList.add({"report": report, "type": "report"});
              }
              reportsList.add({"divider": true, "type": "divider"});
            });
          });

          return ListView.builder(
            itemCount: reportsList.length,
            itemBuilder: (context, index) {
              final item = reportsList[index];

              if (item['type'] == 'date') {
                // Display the date header in bold
                return Container(
                  color: Colors.grey.shade800,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      item['date'],
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                );
              }

              if (item['type'] == 'employee') {
                // Display the first part of the email (before @)
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'Submitted by: ${item['name']}',
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }

              if (item['type'] == 'divider') {
                // Display a divider after each group
                return Divider(thickness: 2);
              }

              if (item['type'] == 'report') {
                // Display the report details
                final report = item['report'];
                // final durationInHours = report.totalCombinedDuration / 60;
                // final formattedDuration = durationInHours.toStringAsFixed(1);

                // Get the first employee's timeOn and timeOff
                final firstEmployee =
                    report.employees.isNotEmpty ? report.employees.first : null;
                // Convert DateTime to Vancouver time zone (Pacific Time) before formatting
                final timeOn = firstEmployee != null
                    ? DateFormat('hh:mm a').format(
                        tz.TZDateTime.from(firstEmployee.timeOn, vancouver))
                    : 'N/A';
                final timeOff = firstEmployee != null
                    ? DateFormat('hh:mm a').format(
                        tz.TZDateTime.from(firstEmployee.timeOff, vancouver))
                    : 'N/A';

                // Convert the total duration from minutes to hours and minutes
                final int totalMinutes = report.totalCombinedDuration;
                final int hours =
                    totalMinutes ~/ 60; // Get the whole number of hours
                final int minutes =
                    totalMinutes % 60; // Get the remaining minutes

// Format the duration as "Xhrs Ymins"
                final formattedDuration = '${hours}hrs ${minutes}mins';

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
                            fontSize: 16,
                            letterSpacing: .5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      subtitle: Row(
                        children: [
                          Text('ID: ${report.id.substring(0, 5)}'),
                          report.filed
                              ? Row(
                                  children: [
                                    Text(
                                      ' - filed ',
                                      style: TextStyle(
                                          fontSize: 12,
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
                                          fontSize: 12,
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
                      trailing: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (firstEmployee != null) ...[
                            Text('Employees: ${report.employees.length}',
                                style: GoogleFonts.montserrat(fontSize: 12)),
                            Text('$timeOn - $timeOff',
                                style: GoogleFonts.montserrat(fontSize: 12)),
                          ],
                          Text('Site Time: $formattedDuration',
                              style: GoogleFonts.montserrat(fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                );
              }

              return SizedBox.shrink();
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
              Navigator.push(
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
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => AddWinterReport()));
            },
          ),
        ],
      ),
    );
  }
}
