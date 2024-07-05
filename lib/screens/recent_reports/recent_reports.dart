import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gemini_landscaping_app/providers/report_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class RecentReports extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsyncValue = ref.watch(allSiteReportsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text("Most Recent Reports",
            style: GoogleFonts.montserrat(
                fontSize: 18,
                color: Colors.black,
                fontWeight: FontWeight.w500)),
        toolbarHeight: 25,
        backgroundColor: Colors.green.shade100,
        elevation: 0,
        centerTitle: true,
      ),
      body: reportsAsyncValue.when(
        data: (reports) {
          reports.sort((a, b) {
            final dateA = DateFormat('MMMM d, yyyy').parse(a.date);
            final dateB = DateFormat('MMMM d, yyyy').parse(b.date);
            return dateB.compareTo(dateA); // Sort in descending order
          });

          // Limit the number of reports to 50
          final limitedReports = reports.take(50).toList();

          return ListView.builder(
            itemCount: limitedReports.length,
            itemBuilder: (context, index) {
              final report = reports[index];
              // Convert duration from minutes to hours
              final durationInHours = report.totalCombinedDuration / 60;
              final formattedDuration = durationInHours.toStringAsFixed(1);
              return Padding(
                padding: const EdgeInsets.all(4),
                child: Container(
                  height: 65,
                  child: ListTile(
                    tileColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: const BorderSide(
                        width: 2.0,
                        color: Colors.green,
                      ),
                    ),
                    title: Text(
                      report.siteName,
                      style: TextStyle(
                        fontSize: 22,
                      ),
                    ),
                    subtitle: Row(
                      children: [
                        Text(
                          'ID: ${report.id.substring(0, 5)}',
                        ),
                        report.filed
                            ? Row(
                                children: [
                                  Text(
                                    ' - filed ',
                                    style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.green.shade200),
                                  ),
                                  Icon(
                                    Icons.task_alt_outlined,
                                    color: Colors.green.shade200,
                                  )
                                ],
                              )
                            : Row(
                                children: [
                                  Text(
                                    ' - in progress ',
                                    style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.blueGrey.shade200),
                                  ),
                                  Icon(
                                    Icons.pending_outlined,
                                    color: Colors.blueGrey.shade200,
                                  )
                                ],
                              ),
                      ],
                    ),
                    trailing: Text(
                      'Date: ${report.date}\nDuration: $formattedDuration hrs\nEmployees: ${report.employees.length}',
                      style: TextStyle(
                        fontSize: 14,
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
