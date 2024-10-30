import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gemini_landscaping_app/screens/all_reports/report_files.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gemini_landscaping_app/providers/site_list_provider.dart';
import 'package:gemini_landscaping_app/providers/report_provider.dart';

class ReportFolders extends ConsumerWidget {
  const ReportFolders({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final siteListAsyncValue = ref.watch(siteListProvider);
    final reportsAsyncValue = ref.watch(allSiteReportsStreamProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      appBar: AppBar(
        title: Text("Site Reports",
            style: GoogleFonts.montserrat(
                fontSize: 18,
                color: Colors.black,
                fontWeight: FontWeight.w500)),
        toolbarHeight: 25,
        backgroundColor: Colors.green.shade100,
        elevation: 0,
        centerTitle: true,
      ),
      body: siteListAsyncValue.when(
        data: (siteList) {
          siteList.sort((a, b) => a.name.compareTo(b.name));
          return reportsAsyncValue.when(
            data: (reports) {
              return GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, 
                  crossAxisSpacing: 0.0,
                  mainAxisSpacing: 0.0,
                  childAspectRatio: 1, 
                ),
                itemCount: siteList.length,
                itemBuilder: (BuildContext context, int index) {
                  final site = siteList[index];
                  final siteReports = reports
                      .where((report) => report.siteName == site.name)
                      .toList();
                  final imageUrl = site.imageUrl;

                  return Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ReportFiles(
                              siteName: site.name,
                              imageUrl: imageUrl,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.network(
                                imageUrl,
                                fit: BoxFit.contain,
                                height: 40,
                                width: 40,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(Icons.grass_outlined,
                                      color: Colors.green, size: 40);
                                },
                              ),
                              const SizedBox(height: 8),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  '${site.name}',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 14,
                                    color: Colors.white,
                                    letterSpacing: .5,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${siteReports.length} reports',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 12),
                              ),
                            ],
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
          );
        },
        loading: () => Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }
}
