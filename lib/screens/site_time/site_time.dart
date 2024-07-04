import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gemini_landscaping_app/providers/report_provider.dart';
import 'package:gemini_landscaping_app/providers/site_list_provider.dart';
import 'package:gemini_landscaping_app/screens/site_time/number_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:numberpicker/numberpicker.dart';

final selectedMonthProvider = StateProvider<DateTime>((ref) => DateTime.now());

class SiteTime extends ConsumerStatefulWidget {
  const SiteTime({super.key});

  @override
  _SiteTimeState createState() => _SiteTimeState();
}

class _SiteTimeState extends ConsumerState<SiteTime> {
  List<Color> colors = [
    Colors.redAccent,
    Colors.greenAccent,
    Colors.blueAccent,
    Colors.orangeAccent,
    Colors.purpleAccent,
    Colors.yellowAccent,
    Colors.lightBlueAccent,
    Colors.pinkAccent,
    Colors.cyanAccent,
    Colors.limeAccent,
    Colors.indigoAccent,
    Colors.tealAccent,
    Colors.amberAccent,
  ];

  DateTime _selectedMonth = DateTime.now();

  void _incrementMonth() {
    ref.read(selectedMonthProvider.notifier).state = DateTime(
      ref.read(selectedMonthProvider).year,
      ref.read(selectedMonthProvider).month + 1,
      1,
    );
  }

  void _decrementMonth() {
    ref.read(selectedMonthProvider.notifier).state = DateTime(
      ref.read(selectedMonthProvider).year,
      ref.read(selectedMonthProvider).month - 1,
      1,
    );
  }

  void _adjustSiteTarget(BuildContext context, WidgetRef ref, String siteId,
      String name, double target) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AdjustSiteTargetDialog(
          siteId: siteId,
          currentName: name,
          currentTarget: target,
          onConfirm: () {
            // Invalidate the provider to refresh the data
            ref.invalidate(siteListProvider);
            ref.invalidate(specificMonthSitereportProvider(
                ref.read(selectedMonthProvider)));
          },
        );
      },
    );
  }

  Future<void> _setSiteToInactive(BuildContext context, String siteId) async {
    final shouldSetInactive = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm'),
          content: Text('Are you sure you want to set this site to inactive?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: Text('Confirm'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );

    if (shouldSetInactive == true) {
      await FirebaseFirestore.instance
          .collection('SiteList')
          .doc(siteId)
          .update({'status': false});
      // Invalidate the provider to refresh the data
      ref.invalidate(siteListProvider);
      ref.invalidate(
        specificMonthSitereportProvider(
          ref.read(selectedMonthProvider),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedMonth = ref.watch(selectedMonthProvider);
    final sitesAsyncValue = ref.watch(siteListProvider);
    final reportsAsyncValue =
        ref.watch(specificMonthSitereportProvider(selectedMonth));

    return Scaffold(
      appBar: AppBar(
        title: Text(DateFormat("MMMM yyyy").format(_selectedMonth)),
        backgroundColor: const Color.fromARGB(255, 31, 182, 77),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: _decrementMonth,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios),
            onPressed: _incrementMonth,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: sitesAsyncValue.when(
          data: (siteList) {
            return reportsAsyncValue.when(
              data: (reportList) {
                return GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1,
                  ),
                  itemCount: siteList.length,
                  itemBuilder: (context, index) {
                    final site = siteList[index];
                    final siteReports = reportList
                        .where((report) => report.siteName == site.name)
                        .toList();
                    final totalDuration = siteReports.fold<double>(
                        0,
                        (sum, report) =>
                            sum + report.totalCombinedDuration.toDouble());
                    final progress = totalDuration / site.target;
                    final reportCount = siteReports.length;

                    // Aggregate durations by date
                    Map<String, double> dateDurations = {};
                    for (var report in siteReports) {
                      dateDurations.update(
                        report.date,
                        (existing) =>
                            existing + report.totalCombinedDuration.toDouble(),
                        ifAbsent: () => report.totalCombinedDuration.toDouble(),
                      );
                    }

                    Map<String, Color> dateColorMap = {};
                    List<PieChartSectionData> sections = [];
                    double totalPercent = 0;
                    int colorIndex = 0;

                    dateDurations.forEach((date, duration) {
                      final percentage = (duration / site.target) * 100;
                      totalPercent += percentage;
                      if (!dateColorMap.containsKey(date)) {
                        dateColorMap[date] = colors[colorIndex % colors.length];
                        colorIndex++;
                      }
                      final color = dateColorMap[date]!;
                      sections.add(
                        PieChartSectionData(
                          value: percentage,
                          color: color,
                          title: '${(duration / 60).toStringAsFixed(1)}h',
                          radius: 50,
                          showTitle: false,
                        ),
                      );
                    });

                    // Add remaining part of the chart to show uncompleted portion
                    if (totalPercent < 100) {
                      sections.add(
                        PieChartSectionData(
                          value: 100 - totalPercent,
                          color: Colors.grey[300],
                          title: '',
                          radius: 50,
                          showTitle: false,
                        ),
                      );
                    }

                    return Column(
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            site.name,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(height: 4),
                        Expanded(
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                height: 250,
                                width: 250,
                                child: PieChart(
                                  PieChartData(
                                    sections: sections,
                                    centerSpaceRadius: double.infinity,
                                    borderData: FlBorderData(show: false),
                                  ),
                                ),
                              ),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '${(totalDuration / 60).toStringAsFixed(1)} / ${(site.target / 60).toStringAsFixed(1)} hrs',
                                    style: GoogleFonts.openSans(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    '${(progress * 100).toStringAsFixed(1)}%',
                                    style: GoogleFonts.openSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                              site.imageUrl.isNotEmpty
                                  ? Opacity(
                                      opacity: 0.3,
                                      child: Image.network(
                                        site.imageUrl,
                                        height: 80,
                                        width: 80,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return const Icon(
                                            Icons.grass_rounded,
                                            size: 80,
                                            color: Colors.green,
                                          );
                                        },
                                      ),
                                    )
                                  : Opacity(
                                      opacity: 0.3,
                                      child: const Icon(
                                        Icons.grass_rounded,
                                        size: 80,
                                        color: Colors.green,
                                      ),
                                    ),
                            ],
                          ),
                        ),
                        Text(
                          'Reports: $reportCount',
                          style: const TextStyle(
                            fontSize: 12,
                          ),
                        ),
                        SizedBox(
                          height: 20,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.track_changes),
                                onPressed: () => _adjustSiteTarget(context, ref,
                                    site.id, site.name, site.target),
                                iconSize: 18,
                                color: Colors.blueGrey,
                                tooltip: "Adjust the target",
                              ),
                              IconButton(
                                icon: Icon(Icons.toggle_off),
                                onPressed: () =>
                                    _setSiteToInactive(context, site.id),
                                iconSize: 18,
                                color: Colors.blueGrey,
                                tooltip: "Set site to inactive",
                              ),
                            ],
                          ),
                        ),
                        Divider(thickness: 2, color: Colors.black),
                      ],
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) =>
                  Center(child: Text('Error: $error')),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(child: Text('Error: $error')),
        ),
      ),
    );
  }
}
