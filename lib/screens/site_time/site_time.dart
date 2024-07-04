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
                        0, (sum, report) => sum + report.totalCombinedDuration);
                    final progress = totalDuration / site.target;

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
                        const SizedBox(height: 10),
                        Expanded(
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              site.imageUrl.isNotEmpty
                                  ? Opacity(
                                      opacity: 0.5,
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
                                      opacity: 0.5,
                                      child: const Icon(
                                        Icons.grass_rounded,
                                        size: 100,
                                        color: Colors.green,
                                      ),
                                    ),
                              SizedBox(
                                height: 100, // Adjust size
                                width: 100, // Adjust size
                                child: CircularProgressIndicator(
                                  value: progress,
                                  backgroundColor: Colors.grey[300],
                                  color: Colors.blue,
                                  strokeWidth: 10,
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
