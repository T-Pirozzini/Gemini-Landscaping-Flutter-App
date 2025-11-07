import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gemini_landscaping_app/screens/view_reports/report_preview.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:gemini_landscaping_app/models/site_report.dart';
import 'package:gemini_landscaping_app/providers/report_provider.dart';
import 'package:gemini_landscaping_app/screens/add_report/add_site_report.dart';
import 'package:gemini_landscaping_app/screens/winter_reports/addWinterReport.dart';
import 'package:floating_action_bubble/floating_action_bubble.dart';
import 'package:timezone/data/latest.dart' as tz;

// Utility for date formatting
class DateUtils {
  static final vancouver = tz.getLocation('America/Vancouver');
  static String formatDate(DateTime date) =>
      DateFormat('MMMM d, yyyy').format(date);
  static String formatTime(DateTime time) =>
      DateFormat('hh:mm a').format(tz.TZDateTime.from(time, vancouver));
  static DateTime parseDate(String dateStr) =>
      DateFormat('MMMM d, yyyy').parse(dateStr);
}

// Widget for date header
class DateHeader extends StatelessWidget {
  final String date;
  const DateHeader({super.key, required this.date});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade800,
      padding: const EdgeInsets.all(8.0),
      child: Text(
        date,
        style: GoogleFonts.montserrat(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}

// Widget for employee header
class EmployeeHeader extends StatelessWidget {
  final String name;
  const EmployeeHeader({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        'Submitted by: $name',
        style:
            GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}

// Widget for report card
class ReportCard extends StatelessWidget {
  final SiteReport report;
  const ReportCard({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    final firstEmployee =
        report.employees.isNotEmpty ? report.employees.first : null;
    final timeOn = firstEmployee != null
        ? DateUtils.formatTime(firstEmployee.timeOn)
        : 'N/A';
    final timeOff = firstEmployee != null
        ? DateUtils.formatTime(firstEmployee.timeOff)
        : 'N/A';
    final hours = report.totalCombinedDuration ~/ 60;
    final minutes = report.totalCombinedDuration % 60;
    final formattedDuration = '${hours}hrs ${minutes}mins';

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ReportPreview(report: report)),
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            width: 2.0,
            color: report.isRegularMaintenance ? Colors.green : Colors.blueGrey,
          ),
        ),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          leading: Icon(
            report.isRegularMaintenance
                ? Icons.grass
                : Icons.add_circle_outline,
            color: Colors.grey.shade700,
          ),
          title: Text(
            report.siteName,
            style: GoogleFonts.montserrat(
                fontSize: 16, fontWeight: FontWeight.w500),
          ),
          subtitle: Row(
            children: [
              Text('ID: ${report.id.substring(0, 5)}'),
              const SizedBox(width: 8),
              Text(
                report.filed ? 'filed' : 'in progress',
                style: TextStyle(
                  fontSize: 12,
                  color: report.filed
                      ? Colors.green.shade200
                      : Colors.blueGrey.shade200,
                ),
              ),
              Icon(
                report.filed ? Icons.task_alt_outlined : Icons.pending_outlined,
                color: report.filed
                    ? Colors.green.shade200
                    : Colors.blueGrey.shade200,
                size: 16,
              ),
            ],
          ),
          trailing: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
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
}

class RecentReports extends ConsumerStatefulWidget {
  const RecentReports({super.key});

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
      duration: const Duration(milliseconds: 200),
    );
    _animation =
        CurvedAnimation(curve: Curves.easeInOut, parent: _animationController);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _groupReports(List<SiteReport> reports) {
    reports.sort((a, b) =>
        DateUtils.parseDate(b.date).compareTo(DateUtils.parseDate(a.date)));
    final limitedReports = reports.take(80).toList();
    final groupedByDate = <DateTime, Map<String, List<SiteReport>>>{};

    for (var report in limitedReports) {
      final reportDate = DateUtils.parseDate(report.date);
      if (!groupedByDate.containsKey(reportDate)) {
        groupedByDate[reportDate] = {};
      }
      final submittedBy = report.submittedBy;
      if (!groupedByDate[reportDate]!.containsKey(submittedBy)) {
        groupedByDate[reportDate]![submittedBy] = [];
      }
      groupedByDate[reportDate]![submittedBy]!.add(report);
    }

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

    final reportsList = <Map<String, dynamic>>[];
    groupedByDate.forEach((date, reportsByEmployee) {
      final formattedDate = DateUtils.formatDate(date);
      reportsList.add({"date": formattedDate, "type": "date"});
      reportsByEmployee.forEach((submittedBy, employeeReports) {
        final firstName = submittedBy.split('@')[0];
        final capitalizedFirstName =
            firstName[0].toUpperCase() + firstName.substring(1).toLowerCase();
        reportsList.add({"name": capitalizedFirstName, "type": "employee"});
        for (var report in employeeReports) {
          reportsList.add({"report": report, "type": "report"});
        }
        reportsList.add({"divider": true, "type": "divider"});
      });
    });

    return reportsList;
  }

  @override
  Widget build(BuildContext context) {
    final reportsAsyncValue = ref.watch(allSiteReportsStreamProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(
          "Recent Site Reports",
          style: GoogleFonts.montserrat(
              fontSize: 18, color: Colors.black, fontWeight: FontWeight.w500),
        ),
        toolbarHeight: 25,
        backgroundColor: Colors.green.shade100,
        elevation: 0,
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.refresh(allSiteReportsStreamProvider),
        child: reportsAsyncValue.when(
          data: (reports) {
            final reportsList = _groupReports(reports);
            return ListView.builder(
              itemCount: reportsList.length,
              itemBuilder: (context, index) {
                final item = reportsList[index];
                switch (item['type']) {
                  case 'date':
                    return DateHeader(date: item['date']);
                  case 'employee':
                    return EmployeeHeader(name: item['name']);
                  case 'divider':
                    return const Divider(thickness: 2);
                  case 'report':
                    return ReportCard(report: item['report']);
                  default:
                    return const SizedBox.shrink();
                }
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Error: $error',
                    style: GoogleFonts.montserrat(fontSize: 16)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.refresh(allSiteReportsStreamProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
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
        items: [
          Bubble(
            title: "Site Report",
            iconColor: Colors.white,
            bubbleColor: const Color.fromARGB(255, 59, 82, 73),
            icon: Icons.note_add_outlined,
            titleStyle: const TextStyle(fontSize: 16, color: Colors.white),
            onPress: () {
              _animationController.reverse();
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const AddSiteReport()));
            },
          ),
          Bubble(
            title: "Winter Report",
            iconColor: Colors.white,
            bubbleColor: const Color.fromARGB(255, 59, 82, 73),
            icon: Icons.cloudy_snowing,
            titleStyle: const TextStyle(fontSize: 16, color: Colors.white),
            onPress: () {
              _animationController.reverse();
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const AddWinterReport()));
            },
          ),
        ],
      ),
    );
  }
}
