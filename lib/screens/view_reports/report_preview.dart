import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gemini_landscaping_app/providers/admin_provider.dart';
import 'package:gemini_landscaping_app/screens/home/home_page.dart';
import 'package:gemini_landscaping_app/screens/print_save_report/print_save_report.dart';
import 'package:gemini_landscaping_app/screens/view_reports/edit_report.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:gemini_landscaping_app/models/site_report.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class ReportPreview extends ConsumerStatefulWidget {
  final SiteReport report;
  ReportPreview({required this.report});

  @override
  ConsumerState<ReportPreview> createState() => _ReportPreviewState();
}

class _ReportPreviewState extends ConsumerState<ReportPreview> {
  late SiteReport report;

  @override
  void initState() {
    super.initState();
    tz.initializeTimeZones();
    report = widget.report;
  }

  void _deleteReport() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Deletion'),
          content:
              Text('Are you sure you would like to delete this site report?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await FirebaseFirestore.instance
                      .collection('SiteReports')
                      .doc(widget.report.id)
                      .delete();
                  Navigator.pop(context);
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => Home()),
                    (route) => false,
                  );
                } catch (e) {
                  print('Error deleting report: $e');
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content:
                          Text('Failed to delete report. Please try again.'),
                    ),
                  );
                }
              },
              child: Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _navigateToEditReport() async {
    final updatedReport = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditReport(report: report),
      ),
    );

    if (updatedReport != null) {
      setState(() {
        report = updatedReport;
      });
    }
  }

  Future<void> _navigateToPrintSaveReport() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PrintSaveReport(report: report),
      ),
    );
  }

  // Reusable section card
  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, size: 18, color: Colors.grey.shade700),
                SizedBox(width: 8),
                Text(
                  title,
                  style: GoogleFonts.montserrat(
                      fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(12),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeesTable(
      List<EmployeeTime> employees, int totalDuration, Color accentColor) {
    final vancouver = tz.getLocation('America/Vancouver');
    return Column(
      children: [
        Table(
          border: TableBorder.all(color: Colors.grey.shade300),
          children: [
            TableRow(
              decoration: BoxDecoration(color: accentColor),
              children: [
                _tableHeader('Name'),
                _tableHeader('On'),
                _tableHeader('Off'),
                _tableHeader('Hours'),
              ],
            ),
            ...employees.map((employee) {
              return TableRow(
                children: [
                  _tableCell(employee.name),
                  _tableCell(DateFormat('h:mm a')
                      .format(tz.TZDateTime.from(employee.timeOn, vancouver))),
                  _tableCell(DateFormat('h:mm a')
                      .format(tz.TZDateTime.from(employee.timeOff, vancouver))),
                  _tableCell(
                      '${(employee.duration / 60).toStringAsFixed(1)}'),
                ],
              );
            }).toList(),
            TableRow(
              decoration: BoxDecoration(color: Colors.grey.shade50),
              children: [
                _tableCell(''),
                _tableCell(''),
                Container(
                  alignment: Alignment.centerRight,
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Text('Total:',
                      style: GoogleFonts.montserrat(
                          fontSize: 12, fontWeight: FontWeight.bold)),
                ),
                Container(
                  alignment: Alignment.center,
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    '${(totalDuration / 60).toStringAsFixed(1)} hrs',
                    style: GoogleFonts.montserrat(
                        fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildServicesContent(
      Map<String, List<String>> services, Color accentColor) {
    if (services.isEmpty ||
        services.values.every((items) => items.isEmpty)) {
      return Text('No services were specified',
          style: GoogleFonts.montserrat(fontSize: 13, color: Colors.grey));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: services.entries
          .where((entry) => entry.value.isNotEmpty)
          .map((entry) {
        return Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.key.toUpperCase(),
                style: GoogleFonts.montserrat(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700),
              ),
              SizedBox(height: 4),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: entry.value.map<Widget>((item) {
                  return Chip(
                    label: Text(item,
                        style: GoogleFonts.montserrat(fontSize: 11)),
                    backgroundColor: accentColor.withAlpha(25),
                    side: BorderSide(color: accentColor.withAlpha(80)),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding:
                        EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final report = this.report;
    final isAdmin = ref.watch(isAdminProvider);

    final accentColor = report.isRegularMaintenance
        ? Color.fromARGB(255, 31, 182, 77)
        : Colors.blueGrey;

    // Display-friendly submittedBy
    final submitterName = report.submittedBy.contains('@')
        ? report.submittedBy.split('@')[0]
        : report.submittedBy;
    final capitalizedName = submitterName.isNotEmpty
        ? submitterName[0].toUpperCase() +
            submitterName.substring(1).toLowerCase()
        : 'Unknown';

    // Format timestamp
    final formattedTimestamp =
        DateFormat('MMM d, yyyy \'at\' h:mm a').format(report.timestamp);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 31, 182, 77),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Image.asset("assets/gemini-icon-transparent.png",
            color: Colors.white, fit: BoxFit.contain, height: 50),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(12),
              child: Column(
                children: [
                  // Filed status banner
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                    decoration: BoxDecoration(
                      color: report.filed
                          ? Colors.green.shade50
                          : Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: report.filed
                            ? Colors.green.shade300
                            : Colors.orange.shade300,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          report.filed
                              ? Icons.check_circle
                              : Icons.pending_outlined,
                          size: 16,
                          color: report.filed
                              ? Colors.green.shade700
                              : Colors.orange.shade700,
                        ),
                        SizedBox(width: 8),
                        Text(
                          report.filed ? 'Filed' : 'Pending Review',
                          style: GoogleFonts.montserrat(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: report.filed
                                ? Colors.green.shade700
                                : Colors.orange.shade700,
                          ),
                        ),
                        Spacer(),
                        Text(
                          report.hasBothPhases
                              ? 'Regular + Additional'
                              : report.isRegularMaintenance
                                  ? 'Regular Maintenance'
                                  : 'Additional Service',
                          style: GoogleFonts.montserrat(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: accentColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 10),

                  // Site info card
                  _sectionCard(
                    title: 'Site Information',
                    icon: Icons.location_on_outlined,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          report.siteName.toUpperCase(),
                          style: GoogleFonts.montserrat(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 2),
                        Text(report.address,
                            style: GoogleFonts.montserrat(
                                fontSize: 14, color: Colors.grey.shade700)),
                        SizedBox(height: 6),
                        Row(
                          children: [
                            Text(report.date,
                                style: GoogleFonts.montserrat(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500)),
                            Spacer(),
                            Text(
                              '#${report.id.substring(report.id.length - 5)}',
                              style: GoogleFonts.montserrat(
                                  fontSize: 12, color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Team & Time + Services (phase-aware)
                  if (report.hasBothPhases) ...[
                    _sectionCard(
                      title: 'Regular Maintenance — Team & Time',
                      icon: Icons.people_outline,
                      child: _buildEmployeesTable(
                        report.regularPhase!.employees,
                        report.regularPhase!.totalDuration,
                        Color.fromARGB(255, 31, 182, 77),
                      ),
                    ),
                    _sectionCard(
                      title: 'Regular Maintenance — Services',
                      icon: Icons.checklist,
                      child: _buildServicesContent(
                        report.regularPhase!.services,
                        Color.fromARGB(255, 31, 182, 77),
                      ),
                    ),
                    _sectionCard(
                      title: 'Additional Services — Team & Time',
                      icon: Icons.people_outline,
                      child: _buildEmployeesTable(
                        report.additionalPhase!.employees,
                        report.additionalPhase!.totalDuration,
                        Colors.blueGrey,
                      ),
                    ),
                    _sectionCard(
                      title: 'Additional Services — Services',
                      icon: Icons.checklist,
                      child: _buildServicesContent(
                        report.additionalPhase!.services,
                        Colors.blueGrey,
                      ),
                    ),
                  ] else ...[
                    _sectionCard(
                      title: 'Team & Time',
                      icon: Icons.people_outline,
                      child: _buildEmployeesTable(
                        report.employees,
                        report.totalCombinedDuration,
                        accentColor,
                      ),
                    ),
                    _sectionCard(
                      title: 'Services Provided',
                      icon: Icons.checklist,
                      child: _buildServicesContent(
                        report.services,
                        accentColor,
                      ),
                    ),
                  ],

                  // Materials card
                  if (report.materials.isNotEmpty)
                    _sectionCard(
                      title: 'Materials',
                      icon: Icons.inventory_2_outlined,
                      child: Column(
                        children: [
                          ...report.materials.map((material) {
                            return Padding(
                              padding: EdgeInsets.only(bottom: 6),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Text(material.description,
                                        style: GoogleFonts.montserrat(
                                            fontSize: 13)),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(material.vendor,
                                        style: GoogleFonts.montserrat(
                                            fontSize: 12,
                                            color: Colors.grey.shade600)),
                                  ),
                                  Text('\$${material.cost}',
                                      style: GoogleFonts.montserrat(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500)),
                                ],
                              ),
                            );
                          }).toList(),
                          Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text('Total: ',
                                  style: GoogleFonts.montserrat(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600)),
                              Text(
                                '\$${report.materials.fold<double>(0.0, (sum, m) => sum + (double.tryParse(m.cost) ?? 0.0)).toStringAsFixed(2)}',
                                style: GoogleFonts.montserrat(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                  // Disposal card
                  if (report.disposal != null &&
                      report.disposal!.hasDisposal)
                    _sectionCard(
                      title: 'Disposal',
                      icon: Icons.delete_outline,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text('Location: ',
                                  style: GoogleFonts.montserrat(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500)),
                              Text(report.disposal!.location,
                                  style:
                                      GoogleFonts.montserrat(fontSize: 13)),
                            ],
                          ),
                          SizedBox(height: 4),
                          Row(
                            children: [
                              Text('Cost: ',
                                  style: GoogleFonts.montserrat(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500)),
                              Text('\$${report.disposal!.cost}',
                                  style:
                                      GoogleFonts.montserrat(fontSize: 13)),
                            ],
                          ),
                        ],
                      ),
                    ),

                  // Shift Notes card
                  if (report.noteTags.isNotEmpty ||
                      report.description.isNotEmpty)
                    _sectionCard(
                      title: 'Shift Notes',
                      icon: Icons.notes,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (report.noteTags.isNotEmpty)
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: report.noteTags
                                  .map((tag) => Chip(
                                        label: Text(tag,
                                            style: GoogleFonts.montserrat(
                                                fontSize: 11)),
                                        backgroundColor: Colors.green[50],
                                        visualDensity: VisualDensity.compact,
                                        materialTapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 4, vertical: 0),
                                      ))
                                  .toList(),
                            ),
                          if (report.description.isNotEmpty) ...[
                            if (report.noteTags.isNotEmpty) SizedBox(height: 8),
                            Text(report.description,
                                style: GoogleFonts.montserrat(fontSize: 13)),
                          ],
                        ],
                      ),
                    ),

                  // Submitted by
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      children: [
                        Text('Submitted by: $capitalizedName',
                            style: GoogleFonts.montserrat(
                                fontSize: 12, color: Colors.grey.shade600)),
                        SizedBox(height: 2),
                        Text(formattedTimestamp,
                            style: GoogleFonts.montserrat(
                                fontSize: 11,
                                color: Colors.grey.shade500,
                                fontStyle: FontStyle.italic)),
                      ],
                    ),
                  ),
                  SizedBox(height: 80), // Space for bottom bar
                ],
              ),
            ),
          ),

          // Bottom action bar
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade300,
                  blurRadius: 6,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  if (isAdmin) ...[
                    // Delete button
                    IconButton(
                      onPressed: _deleteReport,
                      icon: Icon(Icons.delete_outline, color: Colors.red[400]),
                      tooltip: 'Delete',
                    ),
                    SizedBox(width: 8),
                    // Edit button
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _navigateToEditReport,
                        icon: Icon(Icons.edit_outlined, size: 18),
                        label: Text('Edit',
                            style: GoogleFonts.montserrat(fontSize: 13)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Color.fromARGB(255, 31, 182, 77),
                          side: BorderSide(
                              color: Color.fromARGB(255, 31, 182, 77)),
                          padding: EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    // Generate PDF button
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          _navigateToPrintSaveReport();
                          try {
                            await FirebaseFirestore.instance
                                .collection('SiteReports')
                                .doc(report.id)
                                .set(
                              {'filed': true},
                              SetOptions(merge: true),
                            );
                          } catch (error) {
                            print('Error updating document: $error');
                          }
                        },
                        icon: Icon(Icons.picture_as_pdf, size: 18),
                        label: Text('Generate PDF',
                            style: GoogleFonts.montserrat(fontSize: 13)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color.fromARGB(255, 31, 182, 77),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ] else ...[
                    // Non-admin: view PDF only
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _navigateToPrintSaveReport,
                        icon: Icon(Icons.picture_as_pdf, size: 18),
                        label: Text('View PDF',
                            style: GoogleFonts.montserrat(fontSize: 13)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color.fromARGB(255, 31, 182, 77),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tableHeader(String text) {
    return Container(
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Text(text,
          style: GoogleFonts.montserrat(
              fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600)),
    );
  }

  Widget _tableCell(String text) {
    return Container(
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      child:
          Text(text, style: GoogleFonts.montserrat(fontSize: 12)),
    );
  }
}
