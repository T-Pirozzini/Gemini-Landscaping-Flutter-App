import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gemini_landscaping_app/providers/report_provider.dart';
import 'package:gemini_landscaping_app/providers/site_list_provider.dart';

class SiteTime extends ConsumerStatefulWidget {
  const SiteTime({super.key});

  @override
  _SiteTimeState createState() => _SiteTimeState();
}

class _SiteTimeState extends ConsumerState<SiteTime> {
  List<Color> colors = [
    Colors.red,
    Colors.green,
    Colors.blue,
    Colors.orange,
    Colors.purple,
    Colors.yellow,
    Colors.brown,
    Colors.pink,
    Colors.cyan,
    Colors.lime,
  ];

  @override
  Widget build(BuildContext context) {
    final sitesAsyncValue = ref.watch(siteListProvider);
    final reportsAsyncValue = ref.watch(currentMonthsitereportProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Site Times'),
        backgroundColor: const Color.fromARGB(255, 31, 182, 77),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: sitesAsyncValue.when(
          data: (siteList) {
            return reportsAsyncValue.when(
              data: (reportList) {
                return GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
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
                            style: const TextStyle(
                              fontSize: 14,
                            ),
                          ),
                        ),
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
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    '${(progress * 100).toStringAsFixed(1)}%',
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
                                            size: 100,
                                            color: Colors.green,
                                          );
                                        },
                                      ),
                                    )
                                  : Opacity(
                                      opacity: 0.3,
                                      child: const Icon(
                                        Icons.grass_rounded,
                                        size: 100,
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
