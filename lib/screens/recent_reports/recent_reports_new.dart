import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gemini_landscaping_app/screens/view_reports/report_preview.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:gemini_landscaping_app/models/site_report.dart';
import 'package:gemini_landscaping_app/providers/report_provider.dart';
import 'package:gemini_landscaping_app/screens/add_report/add_site_report.dart';
import 'package:gemini_landscaping_app/screens/utility_screens/equipment_report_form.dart';
import 'package:gemini_landscaping_app/screens/winter_reports/addWinterReport.dart';
import 'package:timezone/data/latest.dart' as tz;

// --- Date Utils ---
class DateUtils {
  static final vancouver = tz.getLocation('America/Vancouver');
  static String formatDate(DateTime date) =>
      DateFormat('MMMM d, yyyy').format(date);
  static String formatTime(DateTime time) => DateFormat('h:mm a')
      .format(tz.TZDateTime.from(time, vancouver));
  static DateTime parseDate(String dateStr) =>
      DateFormat('MMMM d, yyyy').parse(dateStr);
  static String formatDuration(int totalMinutes) {
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    return '${hours}h ${minutes}m';
  }
}

// --- Friendly display name from submittedBy ---
String _displayName(String submittedBy) {
  final name = submittedBy.contains('@')
      ? submittedBy.split('@')[0]
      : submittedBy;
  if (name.isEmpty) return 'Unknown';
  return name[0].toUpperCase() + name.substring(1).toLowerCase();
}

// --- Filter options ---
enum ReportFilter { all, regular, additional, pending, filed, draft }

// --- Date Header ---
class DateHeader extends StatelessWidget {
  final String date;
  final bool isDraftHeader;
  const DateHeader({super.key, required this.date, this.isDraftHeader = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDraftHeader
              ? [Colors.amber.shade700, Colors.amber.shade600]
              : [Colors.grey.shade700, Colors.grey.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 12.0),
      child: Text(
        date,
        style: GoogleFonts.montserrat(
          fontSize: 13,
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
      padding: const EdgeInsets.fromLTRB(12.0, 6.0, 12.0, 2.0),
      child: Text(
        'Submitted by: $name',
        style: GoogleFonts.montserrat(
          fontSize: 11,
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

class _RecentReportsState extends ConsumerState<RecentReports> {
  String _searchQuery = '';
  ReportFilter _activeFilter = ReportFilter.all;

  @override
  void initState() {
    super.initState();
    tz.initializeTimeZones();
  }

  void _showNewReportSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'New Report',
                  style: GoogleFonts.montserrat(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 12),
                _sheetOption(
                  icon: Icons.note_add_outlined,
                  label: 'Maintenance Program',
                  subtitle: 'Regular scheduled maintenance',
                  color: const Color.fromARGB(255, 31, 182, 77),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const AddSiteReport(isRegularMaintenance: true),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                _sheetOption(
                  icon: Icons.assignment_add,
                  label: 'Additional Service',
                  subtitle: 'One-time or extra work',
                  color: const Color.fromARGB(255, 97, 125, 140),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const AddSiteReport(isRegularMaintenance: false),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                _sheetOption(
                  icon: Icons.cloudy_snowing,
                  label: 'Winter Report',
                  subtitle: 'Snow and ice services',
                  color: const Color.fromARGB(255, 59, 82, 73),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const AddWinterReport()),
                    );
                  },
                ),
                const SizedBox(height: 8),
                _sheetOption(
                  icon: Icons.warning_amber_outlined,
                  label: 'Equipment Report',
                  subtitle: 'Report vehicle or equipment issues',
                  color: Colors.amber[700]!,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const EquipmentReportForm()),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _sheetOption({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade200),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.montserrat(
                        fontSize: 11,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
            ],
          ),
        ),
      ),
    );
  }

  // --- Filter reports ---
  List<SiteReport> _applyFilters(List<SiteReport> reports) {
    var filtered = reports;

    // Apply search
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((r) {
        return r.siteName.toLowerCase().contains(query) ||
            _displayName(r.submittedBy).toLowerCase().contains(query);
      }).toList();
    }

    // Apply filter chips
    switch (_activeFilter) {
      case ReportFilter.regular:
        filtered =
            filtered.where((r) => !r.isDraft && r.isRegularMaintenance).toList();
        break;
      case ReportFilter.additional:
        filtered =
            filtered.where((r) => !r.isDraft && !r.isRegularMaintenance).toList();
        break;
      case ReportFilter.pending:
        filtered = filtered.where((r) => !r.isDraft && !r.filed).toList();
        break;
      case ReportFilter.filed:
        filtered = filtered.where((r) => !r.isDraft && r.filed).toList();
        break;
      case ReportFilter.draft:
        filtered = filtered.where((r) => r.isDraft).toList();
        break;
      case ReportFilter.all:
        break;
    }

    return filtered;
  }

  // --- Group Reports ---
  List<Map<String, dynamic>> _groupReports(List<SiteReport> reports) {
    // Separate drafts from submitted reports
    final drafts = reports.where((r) => r.isDraft).toList();
    final submitted = reports.where((r) => !r.isDraft).toList();

    submitted.sort((a, b) {
      try {
        return DateUtils.parseDate(b.date)
            .compareTo(DateUtils.parseDate(a.date));
      } catch (_) {
        return 0;
      }
    });

    final groupedByDate = <DateTime, Map<String, List<SiteReport>>>{};
    for (var report in submitted) {
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
          if (a.employees.isEmpty || b.employees.isEmpty) return 0;
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

    // Drafts section at top
    if (drafts.isNotEmpty) {
      reportsList.add({"date": "Drafts", "type": "date", "isDraftHeader": true});
      for (var draft in drafts) {
        reportsList.add({"report": draft, "type": "report"});
      }
      reportsList.add({"divider": true, "type": "divider"});
    }

    // Grouped submitted reports
    groupedByDate.forEach((date, reportsByEmployee) {
      final formattedDate = DateUtils.formatDate(date);
      reportsList.add({"date": formattedDate, "type": "date"});
      reportsByEmployee.forEach((submittedBy, employeeReports) {
        reportsList
            .add({"name": _displayName(submittedBy), "type": "employee"});
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
    final reportsAsyncValue = ref.watch(recentSiteReportsStreamProvider);

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
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              style: GoogleFonts.montserrat(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search by site or employee...',
                hintStyle: GoogleFonts.montserrat(
                    fontSize: 13, color: Colors.grey.shade500),
                prefixIcon:
                    Icon(Icons.search, size: 20, color: Colors.grey.shade600),
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      BorderSide(color: Color.fromARGB(255, 31, 182, 77)),
                ),
              ),
            ),
          ),
          // Filter chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: ReportFilter.values.map((filter) {
                final isSelected = _activeFilter == filter;
                final label = {
                  ReportFilter.all: 'All',
                  ReportFilter.regular: 'Regular',
                  ReportFilter.additional: 'Additional',
                  ReportFilter.pending: 'Pending',
                  ReportFilter.filed: 'Filed',
                  ReportFilter.draft: 'Draft',
                }[filter]!;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _activeFilter = filter),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color.fromARGB(255, 31, 182, 77)
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? const Color.fromARGB(255, 31, 182, 77)
                              : Colors.grey.shade300,
                          width: 0.5,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        label,
                        style: GoogleFonts.montserrat(
                          fontSize: 11,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: isSelected ? Colors.white : Colors.grey[700],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          SizedBox(height: 4),
          // Reports list
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                // ignore: unused_result
                ref.refresh(recentSiteReportsStreamProvider);
              },
              child: reportsAsyncValue.when(
                data: (reports) {
                  final filtered = _applyFilters(reports);
                  final reportsList = _groupReports(filtered);
                  if (reportsList.isEmpty) {
                    return Center(
                      child: Text('No reports found',
                          style: GoogleFonts.montserrat(
                              fontSize: 14, color: Colors.grey.shade600)),
                    );
                  }
                  return ListView.builder(
                    itemCount: reportsList.length,
                    itemBuilder: (context, index) {
                      final item = reportsList[index];
                      switch (item['type']) {
                        case 'date':
                          return DateHeader(
                            date: item['date'],
                            isDraftHeader: item['isDraftHeader'] == true,
                          );
                        case 'employee':
                          return EmployeeHeader(name: item['name']);
                        case 'report':
                          return MinimalReportTile(report: item['report']);
                        case 'divider':
                          return Divider(
                            thickness: 0.5,
                            color: Colors.grey.shade300,
                            indent: 12,
                            endIndent: 12,
                          );
                        default:
                          return const SizedBox.shrink();
                      }
                    },
                  );
                },
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (error, stack) =>
                    _ErrorWidget(error: error, ref: ref),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showNewReportSheet,
        backgroundColor: const Color.fromARGB(255, 59, 82, 73),
        child: const Icon(Icons.add, color: Colors.white),
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
              // ignore: unused_result
              ref.refresh(recentSiteReportsStreamProvider);
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

// --- Report Tile ---
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

    // Get first 3 service categories that have items
    final serviceCategories = report.services.entries
        .where((e) => e.value.isNotEmpty)
        .take(3)
        .map((e) => e.key)
        .toList();

    // Employee names
    final employeeNames =
        report.employees.map((e) => e.name.split(' ')[0]).join(', ');

    final accentColor = report.isDraft
        ? Colors.amber.shade700
        : report.isRegularMaintenance
            ? Color.fromARGB(255, 31, 182, 77)
            : Colors.blueGrey;

    return GestureDetector(
      onTap: () {
        if (report.isDraft) {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => AddSiteReport(draftReport: report)),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ReportPreview(report: report)),
          );
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 6),
        child: Card(
          elevation: 1,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          color: Colors.white,
          child: IntrinsicHeight(
            child: Row(
              children: [
                // Color-coded left border
                Container(
                  width: 5,
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(10),
                      bottomLeft: Radius.circular(10),
                    ),
                  ),
                ),
                // Content
                Expanded(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top row: site name + status chip
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                report.siteName.isNotEmpty
                                    ? report.siteName
                                    : 'Untitled Report',
                                style: GoogleFonts.montserrat(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  fontStyle: report.siteName.isEmpty
                                      ? FontStyle.italic
                                      : FontStyle.normal,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: report.isDraft
                                    ? Colors.amber[50]
                                    : report.filed
                                        ? Colors.green[50]
                                        : Colors.orange[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: report.isDraft
                                      ? Colors.amber[600]!
                                      : report.filed
                                          ? Colors.green[300]!
                                          : Colors.orange[300]!,
                                ),
                              ),
                              child: Text(
                                report.isDraft
                                    ? 'DRAFT'
                                    : report.filed
                                        ? 'Filed'
                                        : 'Pending',
                                style: GoogleFonts.montserrat(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: report.isDraft
                                      ? Colors.amber[800]
                                      : report.filed
                                          ? Colors.green[700]
                                          : Colors.orange[700],
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 2),
                        // Report type label
                        Text(
                          report.isRegularMaintenance
                              ? 'Maintenance Program'
                              : 'Additional Service',
                          style: GoogleFonts.montserrat(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: report.isRegularMaintenance
                                ? Color.fromARGB(255, 31, 182, 77)
                                : Color.fromARGB(255, 97, 125, 140),
                          ),
                        ),
                        SizedBox(height: 2),
                        // Time + employees
                        Row(
                          children: [
                            Icon(Icons.schedule,
                                size: 13, color: Colors.grey.shade600),
                            SizedBox(width: 4),
                            Text(
                              '$timeOn – $timeOff  ($formattedDuration)',
                              style: GoogleFonts.montserrat(
                                  fontSize: 11, color: Colors.grey.shade700),
                            ),
                          ],
                        ),
                        SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.people_outline,
                                size: 13, color: Colors.grey.shade600),
                            SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                employeeNames,
                                style: GoogleFonts.montserrat(
                                    fontSize: 11,
                                    color: Colors.grey.shade700),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        // Service category chips
                        if (serviceCategories.isNotEmpty) ...[
                          SizedBox(height: 4),
                          Wrap(
                            spacing: 4,
                            runSpacing: 2,
                            children: serviceCategories.map((cat) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  cat,
                                  style: GoogleFonts.montserrat(
                                      fontSize: 9,
                                      color: Colors.grey.shade700),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
