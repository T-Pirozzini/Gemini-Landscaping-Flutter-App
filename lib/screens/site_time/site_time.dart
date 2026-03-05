import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gemini_landscaping_app/models/site_info.dart';
import 'package:gemini_landscaping_app/models/site_report.dart';
import 'package:gemini_landscaping_app/providers/report_provider.dart';
import 'package:gemini_landscaping_app/providers/site_list_provider.dart';
import 'package:gemini_landscaping_app/screens/site_time/edit_site_info_dialog.dart';
import 'package:gemini_landscaping_app/screens/site_time/site_detail_analytics.dart';
import 'package:gemini_landscaping_app/screens/site_time/inactive_sites.dart';
import 'package:gemini_landscaping_app/screens/site_time/number_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

final selectedMonthProvider = StateProvider<DateTime>((ref) => DateTime.now());

enum _TimePeriod { monthly, quarterly, annual }

class SiteTime extends ConsumerStatefulWidget {
  const SiteTime({super.key});

  @override
  _SiteTimeState createState() => _SiteTimeState();
}

class _SiteTimeState extends ConsumerState<SiteTime> {
  static const _darkGreen = Color.fromARGB(255, 59, 82, 73);
  static const _greenAccent = Color.fromARGB(255, 31, 182, 77);

  _TimePeriod _timePeriod = _TimePeriod.monthly;

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

  // ── Navigation helpers ─────────────────────────────────────

  void _incrementPeriod() {
    final current = ref.read(selectedMonthProvider);
    DateTime next;
    switch (_timePeriod) {
      case _TimePeriod.monthly:
        next = DateTime(current.year, current.month + 1, 1);
        break;
      case _TimePeriod.quarterly:
        next = DateTime(current.year, current.month + 3, 1);
        break;
      case _TimePeriod.annual:
        next = DateTime(current.year + 1, current.month, 1);
        break;
    }
    ref.read(selectedMonthProvider.notifier).state = next;
  }

  void _decrementPeriod() {
    final current = ref.read(selectedMonthProvider);
    DateTime prev;
    switch (_timePeriod) {
      case _TimePeriod.monthly:
        prev = DateTime(current.year, current.month - 1, 1);
        break;
      case _TimePeriod.quarterly:
        prev = DateTime(current.year, current.month - 3, 1);
        break;
      case _TimePeriod.annual:
        prev = DateTime(current.year - 1, current.month, 1);
        break;
    }
    ref.read(selectedMonthProvider.notifier).state = prev;
  }

  // ── Date range for the current period ──────────────────────

  DateTime _periodStart(DateTime selected) {
    switch (_timePeriod) {
      case _TimePeriod.monthly:
        return DateTime(selected.year, selected.month, 1);
      case _TimePeriod.quarterly:
        final qm = ((selected.month - 1) ~/ 3) * 3 + 1;
        return DateTime(selected.year, qm, 1);
      case _TimePeriod.annual:
        return DateTime(selected.year, 1, 1);
    }
  }

  DateTime _periodEnd(DateTime selected) {
    switch (_timePeriod) {
      case _TimePeriod.monthly:
        return DateTime(selected.year, selected.month + 1, 0, 23, 59, 59);
      case _TimePeriod.quarterly:
        final qm = ((selected.month - 1) ~/ 3) * 3 + 1;
        return DateTime(selected.year, qm + 3, 0, 23, 59, 59);
      case _TimePeriod.annual:
        return DateTime(selected.year, 12, 31, 23, 59, 59);
    }
  }

  int _periodMonthCount() {
    switch (_timePeriod) {
      case _TimePeriod.monthly:
        return 1;
      case _TimePeriod.quarterly:
        return 3;
      case _TimePeriod.annual:
        return 12;
    }
  }

  String _periodTitle(DateTime selected) {
    switch (_timePeriod) {
      case _TimePeriod.monthly:
        return DateFormat('MMMM yyyy').format(selected);
      case _TimePeriod.quarterly:
        final quarter = ((selected.month - 1) ~/ 3) + 1;
        return 'Q$quarter ${selected.year}';
      case _TimePeriod.annual:
        return '${selected.year}';
    }
  }

  // ── Site actions ───────────────────────────────────────────

  void _adjustSiteTarget(String siteId, String name, double target) {
    showDialog(
      context: context,
      builder: (_) => AdjustSiteTargetDialog(
        siteId: siteId,
        currentName: name,
        currentTarget: target,
        onConfirm: () {
          ref.invalidate(siteListProvider);
          ref.invalidate(
              specificMonthSitereportProvider(ref.read(selectedMonthProvider)));
        },
      ),
    );
  }

  Future<void> _setSiteToInactive(String siteId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm'),
        content: const Text('Set this site to inactive?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirm')),
        ],
      ),
    );
    if (confirmed == true) {
      await FirebaseFirestore.instance
          .collection('SiteList')
          .doc(siteId)
          .update({'status': false});
      ref.invalidate(siteListProvider);
    }
  }

  Future<void> _editSiteInfo(String siteId) async {
    final siteDoc = await FirebaseFirestore.instance
        .collection('SiteList')
        .doc(siteId)
        .get();

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (_) => EditSiteInfoDialog(
        siteId: siteId,
        currentName: siteDoc.data()?['name'] ?? '',
        currentAddress: siteDoc.data()?['address'] ?? '',
        currentProgram: siteDoc.data()?['program'] ?? true,
        currentManagement: siteDoc.data()?['management'] ?? '',
        currentImageUrl: siteDoc.data()?['imageUrl'] ?? '',
      ),
    );

    ref.invalidate(siteListProvider);
    ref.invalidate(
        specificMonthSitereportProvider(ref.read(selectedMonthProvider)));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    setState(() {
      ref.invalidate(siteListProvider);
    });
  }

  // ── Build ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final selectedMonth = ref.watch(selectedMonthProvider);
    final sitesAsyncValue = ref.watch(siteListProvider);
    final monthCount = _periodMonthCount();

    // Regular maintenance reports
    final AsyncValue<List<SiteReport>> reportsAsyncValue;
    if (_timePeriod == _TimePeriod.monthly) {
      reportsAsyncValue =
          ref.watch(specificMonthSitereportProvider(selectedMonth));
    } else {
      reportsAsyncValue = ref.watch(dateRangeReportsProvider(
        DateRangeParams(
          start: _periodStart(selectedMonth),
          end: _periodEnd(selectedMonth),
          isRegularMaintenance: true,
        ),
      ));
    }

    // Additional service reports (for extras badge)
    final extrasAsyncValue = ref.watch(dateRangeReportsProvider(
      DateRangeParams(
        start: _periodStart(selectedMonth),
        end: _periodEnd(selectedMonth),
        isRegularMaintenance: false,
      ),
    ));

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: _darkGreen,
        toolbarHeight: 44,
        title: Text(
          _periodTitle(selectedMonth),
          style: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18, color: Colors.white),
          onPressed: _decrementPeriod,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios,
                size: 18, color: Colors.white),
            onPressed: _incrementPeriod,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildTimePeriodToggle(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: sitesAsyncValue.when(
                data: (siteList) {
                  final programSites =
                      siteList.where((s) => s.program == true).toList();
                  // Build extras count map per site
                  final Map<String, int> extrasCountMap = {};
                  extrasAsyncValue.whenData((extras) {
                    for (var r in extras) {
                      extrasCountMap.update(
                          r.siteName, (c) => c + 1,
                          ifAbsent: () => 1);
                    }
                  });
                  return reportsAsyncValue.when(
                    data: (reportList) => _buildSiteGrid(
                        programSites, reportList, monthCount,
                        extrasCountMap: extrasCountMap),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('Error: $e')),
                  );
                },
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _darkGreen,
        child: const Icon(Icons.visibility_off, color: Colors.white),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => InactiveSitesScreen()),
        ),
      ),
    );
  }

  // ── Time Period Toggle ─────────────────────────────────────

  Widget _buildTimePeriodToggle() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: _TimePeriod.values.map((period) {
          final isSelected = _timePeriod == period;
          String label;
          switch (period) {
            case _TimePeriod.monthly:
              label = 'Monthly';
              break;
            case _TimePeriod.quarterly:
              label = 'Quarterly';
              break;
            case _TimePeriod.annual:
              label = 'Annual';
              break;
          }
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: ChoiceChip(
                label: SizedBox(
                  width: double.infinity,
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected ? Colors.white : _darkGreen,
                    ),
                  ),
                ),
                selected: isSelected,
                selectedColor: _darkGreen,
                backgroundColor: Colors.white,
                side: BorderSide(
                    color: isSelected ? _darkGreen : Colors.grey.shade300),
                onSelected: (_) => setState(() => _timePeriod = period),
                showCheckmark: false,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Site Grid ──────────────────────────────────────────────

  Widget _buildSiteGrid(
      List<SiteInfo> sites, List<SiteReport> reports, int monthCount,
      {Map<String, int> extrasCountMap = const {}}) {
    if (sites.isEmpty) {
      return Center(
        child: Text(
          'No program sites found',
          style: GoogleFonts.montserrat(
              fontSize: 14, color: Colors.grey.shade500),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.only(top: 6, bottom: 80),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 0.85,
      ),
      itemCount: sites.length,
      itemBuilder: (context, index) => _buildSiteCard(
          sites[index], reports, monthCount,
          extrasCount: extrasCountMap[sites[index].name] ?? 0),
    );
  }

  Widget _buildSiteCard(
      SiteInfo site, List<SiteReport> allReports, int monthCount,
      {int extrasCount = 0}) {
    final siteReports =
        allReports.where((r) => r.siteName == site.name).toList();
    final totalDuration = siteReports.fold<double>(
        0, (sum, r) => sum + r.totalCombinedDuration.toDouble());
    final periodTarget = site.target * monthCount;
    final progress = periodTarget > 0 ? totalDuration / periodTarget : 0.0;
    final reportCount = siteReports.length;

    // Aggregate durations by date for pie chart slices
    final Map<String, double> dateDurations = {};
    for (var report in siteReports) {
      dateDurations.update(
        report.date,
        (existing) => existing + report.totalCombinedDuration.toDouble(),
        ifAbsent: () => report.totalCombinedDuration.toDouble(),
      );
    }

    final List<PieChartSectionData> sections = [];
    double totalPercent = 0;
    int colorIndex = 0;

    dateDurations.forEach((date, duration) {
      final percentage =
          periodTarget > 0 ? (duration / periodTarget) * 100 : 0.0;
      totalPercent += percentage;
      sections.add(PieChartSectionData(
        value: percentage,
        color: _chartColors[colorIndex % _chartColors.length],
        title: '',
        radius: 36,
        showTitle: false,
      ));
      colorIndex++;
    });

    if (totalPercent < 100) {
      sections.add(PieChartSectionData(
        value: 100 - totalPercent,
        color: Colors.grey.shade200,
        title: '',
        radius: 36,
        showTitle: false,
      ));
    }

    // Progress color
    Color progressColor;
    if (progress >= 0.95) {
      progressColor = _greenAccent;
    } else if (progress >= 0.7) {
      progressColor = Colors.orange;
    } else {
      progressColor = Colors.red.shade400;
    }

    return GestureDetector(
      onTap: () {
        final selected = ref.read(selectedMonthProvider);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SiteDetailAnalytics(
              site: site,
              periodStart: _periodStart(selected),
              periodEnd: _periodEnd(selected),
              monthCount: monthCount,
              periodLabel: _periodTitle(selected),
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: const BoxDecoration(
                color: _darkGreen,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(14),
                  topRight: Radius.circular(14),
                ),
              ),
              child: Text(
                site.name,
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
            // Pie chart
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        sections: sections,
                        centerSpaceRadius: double.infinity,
                        borderData: FlBorderData(show: false),
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${(totalDuration / 60).toStringAsFixed(0)} / ${(periodTarget / 60).toStringAsFixed(0)}',
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _darkGreen,
                          ),
                        ),
                        Text(
                          'hrs',
                          style: GoogleFonts.montserrat(
                            fontSize: 10,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: progressColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${(progress * 100).toStringAsFixed(0)}%',
                            style: GoogleFonts.montserrat(
                              fontSize: 13,
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
            ),
            // Footer: report count + extras badge + actions
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 0, 6, 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$reportCount reports',
                        style: GoogleFonts.montserrat(
                          fontSize: 10,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      if (extrasCount > 0) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '+$extrasCount',
                            style: GoogleFonts.montserrat(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _actionIcon(Icons.track_changes, Colors.orange.shade700,
                          () => _adjustSiteTarget(
                              site.id, site.name, site.target)),
                      _actionIcon(Icons.toggle_off, Colors.grey.shade600,
                          () => _setSiteToInactive(site.id)),
                      _actionIcon(Icons.edit, Colors.grey.shade600,
                          () => _editSiteInfo(site.id)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionIcon(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}
