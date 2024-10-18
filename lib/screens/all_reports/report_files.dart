import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gemini_landscaping_app/screens/view_reports/report_preview.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gemini_landscaping_app/providers/report_provider.dart';
import 'package:intl/intl.dart';

class ReportFiles extends ConsumerWidget {
  final String siteName;
  final String imageUrl;

  const ReportFiles({
    super.key,
    required this.siteName,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsyncValue = ref.watch(allSiteReportsStreamProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 31, 182, 77),
        leading: MaterialButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Row(
            children: const [
              Icon(Icons.arrow_circle_left_outlined,
                  color: Colors.white, size: 18),
              Text(
                " Back",
                style: TextStyle(
                  fontSize: 15,
                  color: Color.fromARGB(255, 251, 251, 251),
                ),
              ),
            ],
          ),
        ),
        leadingWidth: 100,
        title: Image.asset("assets/gemini-icon-transparent.png",
            color: Colors.white, fit: BoxFit.contain, height: 50),
        centerTitle: true,
      ),
      body: reportsAsyncValue.when(
        data: (reports) {
          final siteReports =
              reports.where((report) => report.siteName == siteName).toList();
          siteReports.sort((a, b) {
            final dateA = DateFormat('MMMM d, yyyy').parse(a.date);
            final dateB = DateFormat('MMMM d, yyyy').parse(b.date);
            return dateB.compareTo(dateA); // Sort by most recent date
          });

          return GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
            ),
            itemCount: siteReports.length,
            itemBuilder: (BuildContext context, int index) {
              final report = siteReports[index];
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ReportPreview(report: report),
                      ),
                    );
                  },
                  child: Container(
                    padding: EdgeInsets.all(8),
                    height: 500,
                    width: 500,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.grey.shade400,
                        width: 2,
                      ),
                      color: Colors.white,
                    ),
                    child: GridTile(
                      header: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            report.siteName,
                            style: GoogleFonts.montserrat(
                              fontSize: 14,
                              letterSpacing: .5,
                            ),
                          ),
                        ),
                      ),
                      footer: Center(
                        child: Text(
                          report.date,
                          style: GoogleFonts.montserrat(fontSize: 12),
                        ),
                      ),
                      child: Center(
                        child: Image.network(
                          imageUrl, // Use the imageUrl from the management field
                          fit: BoxFit.contain,
                          height: 100,
                          width: 100,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(Icons.grass_outlined,
                                color: Colors.green, size: 40);
                          },
                        ),
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
      ),
    );
  }
}
