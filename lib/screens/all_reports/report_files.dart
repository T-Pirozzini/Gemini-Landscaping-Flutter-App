import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gemini_landscaping_app/models/site_report.dart';
import 'package:gemini_landscaping_app/screens/view_reports/report_preview.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gemini_landscaping_app/providers/report_provider.dart';
import 'package:intl/intl.dart';

enum _ReportStatusFilter { all, submitted, draft }

class ReportFiles extends ConsumerStatefulWidget {
  final String siteName;
  final String imageUrl;

  const ReportFiles({
    super.key,
    required this.siteName,
    required this.imageUrl,
  });

  @override
  ConsumerState<ReportFiles> createState() => _ReportFilesState();
}

class _ReportFilesState extends ConsumerState<ReportFiles> {
  static const _darkGreen = Color.fromARGB(255, 59, 82, 73);
  static const _greenAccent = Color.fromARGB(255, 31, 182, 77);

  _ReportStatusFilter _statusFilter = _ReportStatusFilter.all;
  DateTimeRange? _dateRange;
  String? _selectedEmployee;

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _darkGreen,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _dateRange = picked);
    }
  }

  List<SiteReport> _applyFilters(List<SiteReport> reports) {
    var filtered = reports;

    // Status filter
    if (_statusFilter == _ReportStatusFilter.submitted) {
      filtered = filtered.where((r) => !r.isDraft).toList();
    } else if (_statusFilter == _ReportStatusFilter.draft) {
      filtered = filtered.where((r) => r.isDraft).toList();
    }

    // Date range filter
    if (_dateRange != null) {
      filtered = filtered.where((r) {
        try {
          final d = DateFormat('MMMM d, yyyy').parse(r.date);
          return !d.isBefore(_dateRange!.start) &&
              !d.isAfter(_dateRange!.end.add(const Duration(days: 1)));
        } catch (_) {
          return false;
        }
      }).toList();
    }

    // Employee filter
    if (_selectedEmployee != null) {
      filtered = filtered
          .where(
              (r) => r.employees.any((e) => e.name == _selectedEmployee))
          .toList();
    }

    return filtered;
  }

  Color _getTagColor(String tag) {
    switch (tag) {
      case 'Equipment issue':
        return Colors.red.shade700;
      case 'Weather delay':
        return Colors.blue.shade700;
      case 'Ran out of time':
        return Colors.orange.shade700;
      case 'Irrigation issue':
        return Colors.blue.shade900;
      case 'Resident feedback':
        return Colors.purple.shade700;
      case 'Focused on specific area':
        return Colors.teal.shade700;
      case 'Extra work needed next visit':
        return Colors.amber.shade800;
      default:
        return Colors.grey.shade700;
    }
  }

  String _formatDuration(int totalMinutes) {
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    if (hours == 0) return '${minutes}m';
    if (minutes == 0) return '${hours}h';
    return '${hours}h ${minutes}m';
  }

  @override
  Widget build(BuildContext context) {
    final reportsAsyncValue = ref.watch(allSiteReportsStreamProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: _darkGreen,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.network(
                widget.imageUrl,
                height: 24,
                width: 24,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Icon(Icons.grass_outlined, color: Colors.green.shade300, size: 24),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                widget.siteName,
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: reportsAsyncValue.when(
        data: (reports) {
          final siteReports = reports
              .where((report) => report.siteName == widget.siteName)
              .toList();
          siteReports.sort((a, b) {
            try {
              final dateA = DateFormat('MMMM d, yyyy').parse(a.date);
              final dateB = DateFormat('MMMM d, yyyy').parse(b.date);
              return dateB.compareTo(dateA);
            } catch (_) {
              return 0;
            }
          });

          // Derive employee list from all reports (before filtering)
          final allEmployees = siteReports
              .expand((r) => r.employees.map((e) => e.name))
              .toSet()
              .toList()
            ..sort();

          // Clear selected employee if no longer valid
          if (_selectedEmployee != null &&
              !allEmployees.contains(_selectedEmployee)) {
            _selectedEmployee = null;
          }

          final filteredReports = _applyFilters(siteReports);
          final hasActiveFilters = _statusFilter != _ReportStatusFilter.all ||
              _dateRange != null ||
              _selectedEmployee != null;

          return Column(
            children: [
              _buildFilterBar(allEmployees),
              if (_dateRange != null) _buildDateRangeChip(),
              Expanded(
                child: filteredReports.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.description_outlined,
                                size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 8),
                            Text(
                              hasActiveFilters
                                  ? 'No reports match filters'
                                  : 'No reports for this site',
                              style: GoogleFonts.montserrat(
                                  fontSize: 14, color: Colors.grey.shade500),
                            ),
                            if (hasActiveFilters) ...[
                              const SizedBox(height: 12),
                              TextButton(
                                onPressed: () => setState(() {
                                  _statusFilter = _ReportStatusFilter.all;
                                  _dateRange = null;
                                  _selectedEmployee = null;
                                }),
                                child: Text('Clear filters',
                                    style: GoogleFonts.montserrat(
                                        color: _greenAccent,
                                        fontWeight: FontWeight.w600)),
                              ),
                            ],
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(10),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 0.78,
                        ),
                        itemCount: filteredReports.length,
                        itemBuilder: (context, index) =>
                            _buildReportTile(filteredReports[index]),
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }

  // ── Filter Bar ─────────────────────────────────────────────

  Widget _buildFilterBar(List<String> employees) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
      child: Column(
        children: [
          // Status chips + date range button
          Row(
            children: [
              ..._ReportStatusFilter.values.map((filter) {
                final isSelected = _statusFilter == filter;
                String label;
                switch (filter) {
                  case _ReportStatusFilter.all:
                    label = 'All';
                    break;
                  case _ReportStatusFilter.submitted:
                    label = 'Submitted';
                    break;
                  case _ReportStatusFilter.draft:
                    label = 'Drafts';
                    break;
                }
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(
                      label,
                      style: GoogleFonts.montserrat(
                        fontSize: 11,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected ? Colors.white : _darkGreen,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: _darkGreen,
                    backgroundColor: Colors.white,
                    side: BorderSide(
                        color:
                            isSelected ? _darkGreen : Colors.grey.shade300),
                    onSelected: (_) =>
                        setState(() => _statusFilter = filter),
                    showCheckmark: false,
                  ),
                );
              }),
              const Spacer(),
              IconButton(
                icon: Icon(
                  Icons.date_range,
                  size: 20,
                  color: _dateRange != null
                      ? _greenAccent
                      : Colors.grey.shade600,
                ),
                onPressed: _pickDateRange,
                tooltip: 'Filter by date range',
              ),
            ],
          ),
          // Employee dropdown
          if (employees.length > 1) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.person_outline,
                      size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String?>(
                        value: _selectedEmployee,
                        isExpanded: true,
                        hint: Text('All Employees',
                            style: GoogleFonts.montserrat(
                                fontSize: 12,
                                color: Colors.grey.shade500)),
                        style: GoogleFonts.montserrat(
                            fontSize: 12, color: _darkGreen),
                        items: [
                          DropdownMenuItem<String?>(
                            value: null,
                            child: Text('All Employees',
                                style: GoogleFonts.montserrat(fontSize: 12)),
                          ),
                          ...employees.map((e) => DropdownMenuItem(
                                value: e,
                                child: Text(e,
                                    style:
                                        GoogleFonts.montserrat(fontSize: 12)),
                              )),
                        ],
                        onChanged: (value) =>
                            setState(() => _selectedEmployee = value),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDateRangeChip() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 4),
      child: Row(
        children: [
          Chip(
            label: Text(
              '${DateFormat('MMM d').format(_dateRange!.start)} - ${DateFormat('MMM d').format(_dateRange!.end)}',
              style:
                  GoogleFonts.montserrat(fontSize: 11, color: _darkGreen),
            ),
            deleteIcon: const Icon(Icons.close, size: 16),
            onDeleted: () => setState(() => _dateRange = null),
            backgroundColor: _greenAccent.withValues(alpha: 0.1),
            side: const BorderSide(color: _greenAccent),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
          ),
        ],
      ),
    );
  }

  // ── Report Tile ───────────────────────────────────────────

  Widget _buildReportTile(SiteReport report) {
    final isDraft = report.isDraft;
    final accentColor = isDraft ? Colors.amber.shade700 : _greenAccent;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ReportPreview(report: report)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top color bar
            Container(
              height: 6,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date
                    Text(
                      report.date,
                      style: GoogleFonts.montserrat(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _darkGreen,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Status chip
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDraft ? Colors.amber[50] : Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDraft
                              ? Colors.amber[600]!
                              : Colors.green[300]!,
                        ),
                      ),
                      child: Text(
                        isDraft ? 'DRAFT' : 'Submitted',
                        style: GoogleFonts.montserrat(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color:
                              isDraft ? Colors.amber[800] : Colors.green[700],
                        ),
                      ),
                    ),
                    // Services summary
                    if (report.services.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.checklist,
                              size: 13, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              report.services.keys.take(2).join(', '),
                              style: GoogleFonts.montserrat(
                                fontSize: 10,
                                color: Colors.grey.shade600,
                                fontStyle: FontStyle.italic,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    // Note tags
                    if (report.noteTags.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 4,
                        runSpacing: 2,
                        children: report.noteTags.take(2).map((tag) {
                          final tagColor = _getTagColor(tag);
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: tagColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                  color: tagColor.withValues(alpha: 0.4)),
                            ),
                            child: Text(
                              tag,
                              style: GoogleFonts.montserrat(
                                fontSize: 9,
                                fontWeight: FontWeight.w500,
                                color: tagColor,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                    const Spacer(),
                    // Submitted by
                    if (report.submittedBy.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Icon(Icons.person_outline,
                                size: 14, color: Colors.grey.shade600),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                report.submittedBy,
                                style: GoogleFonts.montserrat(
                                    fontSize: 11,
                                    color: Colors.grey.shade700),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    // Employee count
                    Row(
                      children: [
                        Icon(Icons.people_outline,
                            size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          '${report.employees.length} employees',
                          style: GoogleFonts.montserrat(
                              fontSize: 11, color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    // Duration
                    Row(
                      children: [
                        Icon(Icons.schedule,
                            size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          _formatDuration(report.totalCombinedDuration),
                          style: GoogleFonts.montserrat(
                              fontSize: 11, color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
