import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gemini_landscaping_app/models/service_program.dart';
import 'package:gemini_landscaping_app/models/site_info.dart';
import 'package:gemini_landscaping_app/models/site_report.dart';
import 'package:gemini_landscaping_app/providers/report_provider.dart';
import 'package:gemini_landscaping_app/providers/service_program_provider.dart';
import 'package:gemini_landscaping_app/screens/view_reports/report_preview.dart';
import 'package:gemini_landscaping_app/services/firestore_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class SiteDetailAnalytics extends ConsumerStatefulWidget {
  final SiteInfo site;
  final DateTime periodStart;
  final DateTime periodEnd;
  final int monthCount;
  final String periodLabel;

  const SiteDetailAnalytics({
    super.key,
    required this.site,
    required this.periodStart,
    required this.periodEnd,
    required this.monthCount,
    required this.periodLabel,
  });

  @override
  ConsumerState<SiteDetailAnalytics> createState() =>
      _SiteDetailAnalyticsState();
}

class _SiteDetailAnalyticsState extends ConsumerState<SiteDetailAnalytics>
    with SingleTickerProviderStateMixin {
  static const _darkGreen = Color.fromARGB(255, 59, 82, 73);
  static const _greenAccent = Color.fromARGB(255, 31, 182, 77);

  late TabController _tabController;

  final List<Color> _chartColors = [
    Colors.cyanAccent,
    Colors.lightBlueAccent,
    Colors.indigoAccent,
    Colors.greenAccent,
    Colors.yellowAccent,
    Colors.orangeAccent,
    Colors.deepOrangeAccent,
    Colors.redAccent,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Previous year same period
  DateTime get _prevStart => DateTime(
      widget.periodStart.year - 1,
      widget.periodStart.month,
      widget.periodStart.day);
  DateTime get _prevEnd => DateTime(
      widget.periodEnd.year - 1,
      widget.periodEnd.month,
      widget.periodEnd.day,
      widget.periodEnd.hour,
      widget.periodEnd.minute,
      widget.periodEnd.second);

  @override
  Widget build(BuildContext context) {
    // Current period — regular maintenance
    final regularParams = DateRangeParams(
      start: widget.periodStart,
      end: widget.periodEnd,
      isRegularMaintenance: true,
    );
    final regularAsync = ref.watch(dateRangeReportsProvider(regularParams));

    // Current period — additional services
    final additionalParams = DateRangeParams(
      start: widget.periodStart,
      end: widget.periodEnd,
      isRegularMaintenance: false,
    );
    final additionalAsync = ref.watch(dateRangeReportsProvider(additionalParams));

    // Previous year — regular maintenance (for comparison)
    final prevRegularParams = DateRangeParams(
      start: _prevStart,
      end: _prevEnd,
      isRegularMaintenance: true,
    );
    final prevRegularAsync = ref.watch(dateRangeReportsProvider(prevRegularParams));

    // Previous year — additional services (for comparison)
    final prevAdditionalParams = DateRangeParams(
      start: _prevStart,
      end: _prevEnd,
      isRegularMaintenance: false,
    );
    final prevAdditionalAsync =
        ref.watch(dateRangeReportsProvider(prevAdditionalParams));

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: _darkGreen,
        toolbarHeight: 44,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 20, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.site.name,
          style: GoogleFonts.montserrat(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: _greenAccent,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w600),
          unselectedLabelStyle: GoogleFonts.montserrat(fontSize: 11),
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Extras'),
            Tab(text: 'Programs'),
            Tab(text: 'Compare'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Overview
          regularAsync.when(
            data: (reports) => _buildOverviewTab(
              reports.where((r) => r.siteName == widget.site.name).toList(),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
          // Tab 2: Additional Services
          additionalAsync.when(
            data: (reports) => _buildExtrasTab(
              reports.where((r) => r.siteName == widget.site.name).toList(),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
          // Tab 3: Service Programs
          _buildProgramsTab(),
          // Tab 4: Season Comparison
          _buildCompareTab(
            regularAsync, additionalAsync,
            prevRegularAsync, prevAdditionalAsync,
          ),
        ],
      ),
    );
  }

  // ── Overview Tab ──────────────────────────────────────────

  Widget _buildOverviewTab(List<SiteReport> siteReports) {
    final periodTarget = widget.site.target * widget.monthCount;
    final totalDuration = siteReports.fold<double>(
        0, (sum, r) => sum + r.totalCombinedDuration.toDouble());
    final progress = periodTarget > 0 ? totalDuration / periodTarget : 0.0;

    // Aggregate by date
    final Map<String, double> dateDurations = {};
    for (var report in siteReports) {
      dateDurations.update(
        report.date,
        (existing) => existing + report.totalCombinedDuration.toDouble(),
        ifAbsent: () => report.totalCombinedDuration.toDouble(),
      );
    }

    final sections = <PieChartSectionData>[];
    double totalPercent = 0;
    int colorIndex = 0;
    dateDurations.forEach((date, duration) {
      final pct = periodTarget > 0 ? (duration / periodTarget) * 100 : 0.0;
      totalPercent += pct;
      sections.add(PieChartSectionData(
        value: pct,
        color: _chartColors[colorIndex % _chartColors.length],
        title: '',
        radius: 50,
        showTitle: false,
      ));
      colorIndex++;
    });
    if (totalPercent < 100) {
      sections.add(PieChartSectionData(
        value: 100 - totalPercent,
        color: Colors.grey.shade200,
        title: '',
        radius: 50,
        showTitle: false,
      ));
    }

    Color progressColor;
    if (progress >= 0.95) {
      progressColor = _greenAccent;
    } else if (progress >= 0.7) {
      progressColor = Colors.orange;
    } else {
      progressColor = Colors.red.shade400;
    }

    // Sort reports newest first
    final sorted = List<SiteReport>.from(siteReports)
      ..sort((a, b) => b.date.compareTo(a.date));

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // Period label
        Center(
          child: Text(
            widget.periodLabel,
            style: GoogleFonts.montserrat(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _darkGreen,
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Pie chart card
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              SizedBox(
                height: 180,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(PieChartData(
                      sections: sections,
                      centerSpaceRadius: 55,
                      borderData: FlBorderData(show: false),
                    )),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${(totalDuration / 60).toStringAsFixed(1)} / ${(periodTarget / 60).toStringAsFixed(0)}',
                          style: GoogleFonts.montserrat(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: _darkGreen,
                          ),
                        ),
                        Text('hours',
                            style: GoogleFonts.montserrat(
                                fontSize: 11, color: Colors.grey.shade500)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: progressColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${(progress * 100).toStringAsFixed(0)}%',
                            style: GoogleFonts.montserrat(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: progressColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Legend
              Wrap(
                spacing: 12,
                runSpacing: 4,
                children: dateDurations.entries.toList().asMap().entries.map((e) {
                  final idx = e.key;
                  final entry = e.value;
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: _chartColors[idx % _chartColors.length],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${entry.key} (${(entry.value / 60).toStringAsFixed(1)}h)',
                        style: GoogleFonts.montserrat(fontSize: 10),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Summary row
        Row(
          children: [
            _summaryChip(
              '${siteReports.length}',
              'visits',
              Icons.calendar_today,
              _darkGreen,
            ),
            const SizedBox(width: 8),
            _summaryChip(
              '${(totalDuration / 60).toStringAsFixed(1)}h',
              'total time',
              Icons.access_time,
              Colors.blueGrey,
            ),
            const SizedBox(width: 8),
            _summaryChip(
              '${(periodTarget / 60).toStringAsFixed(0)}h',
              'target',
              Icons.track_changes,
              Colors.orange.shade700,
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Visit list header
        Text(
          'Visits',
          style: GoogleFonts.montserrat(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _darkGreen,
          ),
        ),
        const SizedBox(height: 6),
        if (sorted.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Text('No visits this period',
                  style: GoogleFonts.montserrat(
                      fontSize: 13, color: Colors.grey.shade500)),
            ),
          )
        else
          ...sorted.map((report) => _buildVisitTile(report)),
      ],
    );
  }

  Widget _summaryChip(
      String value, String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(height: 2),
            Text(value,
                style: GoogleFonts.montserrat(
                    fontSize: 14, fontWeight: FontWeight.w700, color: color)),
            Text(label,
                style: GoogleFonts.montserrat(
                    fontSize: 9, color: Colors.grey.shade500)),
          ],
        ),
      ),
    );
  }

  Widget _buildVisitTile(SiteReport report) {
    final durationHrs = (report.totalCombinedDuration / 60).toStringAsFixed(1);
    final employeeNames = report.employees.map((e) => e.name).join(', ');

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ReportPreview(report: report)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            // Date
            Container(
              width: 48,
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: _darkGreen.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Column(
                children: [
                  Text(
                    _dayFromDate(report.date),
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _darkGreen,
                    ),
                  ),
                  Text(
                    _monthAbbr(report.date),
                    style: GoogleFonts.montserrat(
                      fontSize: 9,
                      color: _darkGreen,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    employeeNames,
                    style: GoogleFonts.montserrat(
                        fontSize: 12, fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _servicesSummary(report),
                    style: GoogleFonts.montserrat(
                        fontSize: 10, color: Colors.grey.shade600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Text(
              '${durationHrs}h',
              style: GoogleFonts.montserrat(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _darkGreen,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Extras Tab ────────────────────────────────────────────

  Widget _buildExtrasTab(List<SiteReport> additionalReports) {
    if (additionalReports.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_business, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 8),
            Text(
              'No additional services this period',
              style: GoogleFonts.montserrat(
                  fontSize: 13, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    // Aggregate services across all additional reports
    final Map<String, int> serviceCount = {};
    double totalExtraHours = 0;
    for (var r in additionalReports) {
      totalExtraHours += r.totalCombinedDuration / 60.0;
      // Use additionalPhase services if available, else fall back to flat services
      final services = r.additionalPhase?.services ?? r.services;
      for (var category in services.keys) {
        for (var item in services[category]!) {
          serviceCount.update(item, (c) => c + 1, ifAbsent: () => 1);
        }
      }
    }

    final sortedServices = serviceCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Sort reports newest first
    final sorted = List<SiteReport>.from(additionalReports)
      ..sort((a, b) => b.date.compareTo(a.date));

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // Summary
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Additional Services Summary',
                style: GoogleFonts.montserrat(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _darkGreen,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _summaryChip(
                    '${additionalReports.length}',
                    'reports',
                    Icons.description,
                    _darkGreen,
                  ),
                  const SizedBox(width: 8),
                  _summaryChip(
                    '${totalExtraHours.toStringAsFixed(1)}h',
                    'extra time',
                    Icons.access_time,
                    Colors.orange.shade700,
                  ),
                ],
              ),
              if (sortedServices.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Service Frequency',
                  style: GoogleFonts.montserrat(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 6),
                ...sortedServices.map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(e.key,
                                style: GoogleFonts.montserrat(fontSize: 12)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _greenAccent.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${e.value}x',
                              style: GoogleFonts.montserrat(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _darkGreen,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Reports',
          style: GoogleFonts.montserrat(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _darkGreen,
          ),
        ),
        const SizedBox(height: 6),
        ...sorted.map((report) => _buildVisitTile(report)),
      ],
    );
  }

  // ── Programs Tab ───────────────────────────────────────────

  Widget _buildProgramsTab() {
    final season = '${widget.periodStart.year}';
    final params = SiteSeason(siteId: widget.site.id, season: season);
    final programsAsync = ref.watch(serviceProgramsStreamProvider(params));

    return programsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (programs) {
        // Auto-initialize defaults if empty
        if (programs.isEmpty) {
          FirestoreService().initializeServicePrograms(
            widget.site.id,
            widget.site.name,
            season,
          );
          return const Center(child: CircularProgressIndicator());
        }

        final enabled = programs.where((p) => p.enabled).toList();
        final disabled = programs.where((p) => !p.enabled).toList();
        final completedCount = enabled.where((p) => p.completed).length;

        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            // Season header + summary
            Row(
              children: [
                Expanded(
                  child: Text(
                    '$season Season Programs',
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _darkGreen,
                    ),
                  ),
                ),
                if (enabled.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _greenAccent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$completedCount / ${enabled.length} done',
                      style: GoogleFonts.montserrat(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _darkGreen,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            // Enabled programs
            if (enabled.isNotEmpty) ...[
              Text(
                'Active Programs',
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 6),
              ...enabled.map((p) => _buildProgramTile(p, isEnabled: true)),
              const SizedBox(height: 16),
            ],
            // Disabled programs
            if (disabled.isNotEmpty) ...[
              Text(
                'Available Programs',
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade500,
                ),
              ),
              const SizedBox(height: 6),
              ...disabled.map((p) => _buildProgramTile(p, isEnabled: false)),
              const SizedBox(height: 16),
            ],
            // Add custom program
            Center(
              child: TextButton.icon(
                onPressed: () => _showAddCustomProgramDialog(season),
                icon: Icon(Icons.add, size: 16, color: _darkGreen),
                label: Text(
                  'Add Custom Program',
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    color: _darkGreen,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProgramTile(ServiceProgram program, {required bool isEnabled}) {
    final firestoreService = FirestoreService();

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isEnabled
              ? (program.completed
                  ? _greenAccent.withValues(alpha: 0.4)
                  : Colors.orange.withValues(alpha: 0.3))
              : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          // Enable/disable toggle
          GestureDetector(
            onTap: () => firestoreService.toggleServiceProgramEnabled(
                program.id, !program.enabled),
            child: Icon(
              isEnabled ? Icons.check_circle : Icons.circle_outlined,
              size: 20,
              color: isEnabled ? _greenAccent : Colors.grey.shade400,
            ),
          ),
          const SizedBox(width: 10),
          // Name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  program.programName,
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isEnabled ? _darkGreen : Colors.grey.shade500,
                    decoration: program.completed
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
                if (program.completed && program.completedDate != null)
                  Text(
                    'Completed ${DateFormat('MMM d, yyyy').format(program.completedDate!)}',
                    style: GoogleFonts.montserrat(
                      fontSize: 9,
                      color: _greenAccent,
                    ),
                  ),
              ],
            ),
          ),
          // Completion toggle (only for enabled programs)
          if (isEnabled)
            GestureDetector(
              onTap: () => firestoreService.toggleServiceProgramCompleted(
                  program.id, !program.completed),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: program.completed
                      ? _greenAccent.withValues(alpha: 0.12)
                      : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  program.completed ? 'Done' : 'Pending',
                  style: GoogleFonts.montserrat(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: program.completed
                        ? _greenAccent
                        : Colors.orange.shade700,
                  ),
                ),
              ),
            ),
          // Delete for custom (non-default) programs
          if (!ServiceProgram.defaultPrograms.contains(program.programName))
            GestureDetector(
              onTap: () =>
                  firestoreService.deleteServiceProgram(program.id),
              child: Padding(
                padding: const EdgeInsets.only(left: 6),
                child:
                    Icon(Icons.close, size: 14, color: Colors.grey.shade400),
              ),
            ),
        ],
      ),
    );
  }

  void _showAddCustomProgramDialog(String season) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Add Custom Program',
            style: GoogleFonts.montserrat(fontSize: 16)),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Program Name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isEmpty) return;
              await FirestoreService().addCustomServiceProgram(
                ServiceProgram(
                  id: '',
                  siteId: widget.site.id,
                  siteName: widget.site.name,
                  programName: name,
                  enabled: true,
                  season: season,
                ),
              );
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  // ── Compare Tab ───────────────────────────────────────────

  Widget _buildCompareTab(
    AsyncValue<List<SiteReport>> currentRegular,
    AsyncValue<List<SiteReport>> currentAdditional,
    AsyncValue<List<SiteReport>> prevRegular,
    AsyncValue<List<SiteReport>> prevAdditional,
  ) {
    // Wait for all four providers
    if (currentRegular is AsyncLoading ||
        currentAdditional is AsyncLoading ||
        prevRegular is AsyncLoading ||
        prevAdditional is AsyncLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (currentRegular is AsyncError) {
      return Center(child: Text('Error: ${currentRegular.error}'));
    }

    final curReg = (currentRegular.value ?? [])
        .where((r) => r.siteName == widget.site.name)
        .toList();
    final curAdd = (currentAdditional.value ?? [])
        .where((r) => r.siteName == widget.site.name)
        .toList();
    final prvReg = (prevRegular.value ?? [])
        .where((r) => r.siteName == widget.site.name)
        .toList();
    final prvAdd = (prevAdditional.value ?? [])
        .where((r) => r.siteName == widget.site.name)
        .toList();

    final periodTarget = widget.site.target * widget.monthCount;

    // Current
    final curRegHours = curReg.fold<double>(
            0, (s, r) => s + r.totalCombinedDuration) / 60;
    final curAddHours = curAdd.fold<double>(
            0, (s, r) => s + r.totalCombinedDuration) / 60;
    final curVisits = curReg.length + curAdd.length;

    // Previous
    final prvRegHours = prvReg.fold<double>(
            0, (s, r) => s + r.totalCombinedDuration) / 60;
    final prvAddHours = prvAdd.fold<double>(
            0, (s, r) => s + r.totalCombinedDuration) / 60;
    final prvVisits = prvReg.length + prvAdd.length;

    final targetHrs = periodTarget / 60;

    final prevYear = widget.periodStart.year - 1;
    final curYear = widget.periodStart.year;

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Center(
          child: Text(
            'Season Comparison',
            style: GoogleFonts.montserrat(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _darkGreen,
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Side by side comparison
        Row(
          children: [
            Expanded(
              child: _buildCompareCard(
                year: '$prevYear',
                regHours: prvRegHours,
                addHours: prvAddHours,
                visits: prvVisits,
                targetHrs: targetHrs,
                isCurrent: false,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildCompareCard(
                year: '$curYear',
                regHours: curRegHours,
                addHours: curAddHours,
                visits: curVisits,
                targetHrs: targetHrs,
                isCurrent: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Delta indicators
        _buildDeltaRow(
          'Regular Hours',
          prvRegHours,
          curRegHours,
        ),
        _buildDeltaRow(
          'Extra Hours',
          prvAddHours,
          curAddHours,
        ),
        _buildDeltaRow(
          'Total Visits',
          prvVisits.toDouble(),
          curVisits.toDouble(),
        ),
        if (targetHrs > 0) ...[
          _buildDeltaRow(
            'Target Completion',
            targetHrs > 0 ? (prvRegHours / targetHrs) * 100 : 0,
            targetHrs > 0 ? (curRegHours / targetHrs) * 100 : 0,
            suffix: '%',
          ),
        ],
      ],
    );
  }

  Widget _buildCompareCard({
    required String year,
    required double regHours,
    required double addHours,
    required int visits,
    required double targetHrs,
    required bool isCurrent,
  }) {
    final progress = targetHrs > 0 ? regHours / targetHrs : 0.0;
    Color progressColor;
    if (progress >= 0.95) {
      progressColor = _greenAccent;
    } else if (progress >= 0.7) {
      progressColor = Colors.orange;
    } else {
      progressColor = Colors.red.shade400;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isCurrent
            ? Border.all(color: _greenAccent, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            year,
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isCurrent ? _darkGreen : Colors.grey.shade600,
            ),
          ),
          if (isCurrent)
            Text('Current',
                style: GoogleFonts.montserrat(
                    fontSize: 9, color: _greenAccent)),
          const SizedBox(height: 10),
          // Progress ring
          SizedBox(
            height: 80,
            width: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  strokeWidth: 6,
                  backgroundColor: Colors.grey.shade200,
                  color: progressColor,
                ),
                Text(
                  '${(progress * 100).toStringAsFixed(0)}%',
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: progressColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _compareStatLine('Regular', '${regHours.toStringAsFixed(1)}h'),
          _compareStatLine('Extras', '${addHours.toStringAsFixed(1)}h'),
          _compareStatLine('Visits', '$visits'),
        ],
      ),
    );
  }

  Widget _compareStatLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.montserrat(
                  fontSize: 10, color: Colors.grey.shade600)),
          Text(value,
              style: GoogleFonts.montserrat(
                  fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildDeltaRow(String label, double prev, double current,
      {String suffix = ''}) {
    final delta = current - prev;
    final isPositive = delta > 0;
    final isZero = delta == 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: GoogleFonts.montserrat(
                    fontSize: 12, fontWeight: FontWeight.w500)),
          ),
          Text(
            '${prev.toStringAsFixed(1)}$suffix',
            style: GoogleFonts.montserrat(
                fontSize: 11, color: Colors.grey.shade600),
          ),
          const SizedBox(width: 6),
          Icon(Icons.arrow_forward, size: 12, color: Colors.grey.shade400),
          const SizedBox(width: 6),
          Text(
            '${current.toStringAsFixed(1)}$suffix',
            style: GoogleFonts.montserrat(
                fontSize: 11, fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 8),
          if (!isZero)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isPositive
                    ? _greenAccent.withValues(alpha: 0.12)
                    : Colors.red.shade50,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${isPositive ? '+' : ''}${delta.toStringAsFixed(1)}$suffix',
                style: GoogleFonts.montserrat(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isPositive ? _greenAccent : Colors.red.shade400,
                ),
              ),
            ),
          if (isZero)
            Text('—',
                style: GoogleFonts.montserrat(
                    fontSize: 10, color: Colors.grey.shade400)),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────

  String _dayFromDate(String dateStr) {
    try {
      final parts = dateStr.split('-');
      if (parts.length >= 3) return parts[2];
      return dateStr;
    } catch (_) {
      return dateStr;
    }
  }

  String _monthAbbr(String dateStr) {
    try {
      final dt = DateFormat('yyyy-MM-dd').parse(dateStr);
      return DateFormat('MMM').format(dt);
    } catch (_) {
      return '';
    }
  }

  String _servicesSummary(SiteReport report) {
    final allServices = <String>[];
    report.services.forEach((_, items) => allServices.addAll(items));
    if (allServices.isEmpty) return 'No services recorded';
    return allServices.take(3).join(', ') +
        (allServices.length > 3 ? ' +${allServices.length - 3}' : '');
  }
}
