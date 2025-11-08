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

// --- Date Utils ---
class DateUtils {
  static final vancouver = tz.getLocation('America/Vancouver');
  static String formatDate(DateTime date) =>
      DateFormat('MMMM d, yyyy').format(date);
  static String formatTime(DateTime time) => DateFormat('h:mm a')
      .format(tz.TZDateTime.from(time, vancouver)); // Removed leading zeros
  static DateTime parseDate(String dateStr) =>
      DateFormat('MMMM d, yyyy').parse(dateStr);
  static String formatDuration(int totalMinutes) {
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    return '${hours}hrs ${minutes}mins';
  }
}

// --- Date Header ---
class DateHeader extends StatelessWidget {
  final String date;
  const DateHeader({super.key, required this.date});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.grey.shade700, Colors.grey.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.symmetric(
          vertical: 6.0, horizontal: 12.0), // Reduced vertical padding
      child: Text(
        date,
        style: GoogleFonts.montserrat(
          fontSize: 13, // Smaller font
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}

// --- Employee Header ---
class EmployeeHeader extends StatelessWidget {
  final String name;
  const EmployeeHeader({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.fromLTRB(12.0, 6.0, 12.0, 2.0), // Tighter padding
      child: Text(
        'Submitted by: $name',
        style: GoogleFonts.montserrat(
          fontSize: 11, // Smaller font
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade800,
        ),
      ),
    );
  }
}

// --- RECENT REPORTS SCREEN ---
class RecentReports extends ConsumerStatefulWidget {
  const RecentReports({super.key});

  @override
  _RecentReportsState createState() => _RecentReportsState();
}

class _RecentReportsState extends ConsumerState<RecentReports>
    with SingleTickerProviderStateMixin {
  late Animation<double> _animation;
  late AnimationController _animationController;
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

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

  // --- Group Reports ---
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
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text("Recent Site Reports",
            style: GoogleFonts.montserrat(
                fontSize: 16,
                color: Colors.black,
                fontWeight: FontWeight.w500)),
        toolbarHeight: 25,
        backgroundColor: Colors.green.shade100,
        elevation: 0,
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.refresh(allSiteReportsStreamProvider);
        },
        child: reportsAsyncValue.when(
          data: (reports) {
            final reportsList = _groupReports(reports);
            return AnimatedList(
              key: _listKey,
              initialItemCount: reportsList.length,
              itemBuilder: (context, index, animation) {
                final item = reportsList[index];
                Widget child;
                switch (item['type']) {
                  case 'date':
                    child = DateHeader(date: item['date']);
                    break;
                  case 'employee':
                    child = EmployeeHeader(name: item['name']);
                    break;
                  case 'report':
                    child = MinimalReportTile(report: item['report']);
                    break;
                  case 'divider':
                    child = Divider(
                      thickness: 0.5,
                      color: Colors.grey.shade300,
                      indent: 12,
                      endIndent: 12,
                    );
                    break;
                  default:
                    child = const SizedBox.shrink();
                }
                return FadeTransition(
                  opacity: animation,
                  child: SizeTransition(
                    sizeFactor: animation,
                    child: child,
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => _ErrorWidget(error: error, ref: ref),
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

// --- ERROR WIDGET ---
class _ErrorWidget extends StatelessWidget {
  const _ErrorWidget({
    required this.error,
    required this.ref,
  });

  final Object error;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Error: $error', style: GoogleFonts.montserrat(fontSize: 16)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              ref.refresh(allSiteReportsStreamProvider);
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

// --- Modern Report Tile ---
class MinimalReportTile extends StatelessWidget {
  final SiteReport report;
  const MinimalReportTile({super.key, required this.report});

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
    final formattedDuration =
        DateUtils.formatDuration(report.totalCombinedDuration);
    final initial = report.submittedBy.split('@')[0][0].toUpperCase();

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ReportPreview(report: report)),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 1, horizontal: 6),
        child: Card(
          elevation: 1,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          color: Colors.white,
          child: Stack(
            children: [
              ListTile(
                dense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                leading: CircleAvatar(
                  radius: 16,
                  backgroundColor: report.isRegularMaintenance
                      ? Colors.green[400]
                      : Colors.blueGrey[400],
                  child: Icon(
                    report.isRegularMaintenance
                        ? Icons.grass
                        : Icons.add_circle_outline,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                title: Text(
                  report.siteName,
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  'ID: ${report.id.substring(0, 5)}',
                  style: GoogleFonts.montserrat(
                      fontSize: 10, color: Colors.grey.shade600),
                ),
                trailing: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Employees: ${report.employees.length}',
                      style: GoogleFonts.montserrat(
                          fontSize: 10, color: Colors.grey.shade800),
                    ),
                    Text(
                      '$timeOn - $timeOff',
                      style: GoogleFonts.montserrat(
                          fontSize: 10, color: Colors.grey.shade800),
                    ),
                    Text(
                      formattedDuration,
                      style: GoogleFonts.montserrat(
                          fontSize: 10, color: Colors.grey.shade800),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 1,
                right: 1,
                child: Badge(
                  backgroundColor:
                      report.filed ? Colors.green[300] : Colors.blueGrey[300],
                  label: Text(
                    report.filed ? 'Filed' : 'Pending',
                    style: GoogleFonts.montserrat(
                        fontSize: 6, color: Colors.white),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
