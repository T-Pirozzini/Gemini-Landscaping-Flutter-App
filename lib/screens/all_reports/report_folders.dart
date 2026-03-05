import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gemini_landscaping_app/models/site_info.dart';
import 'package:gemini_landscaping_app/models/site_report.dart';
import 'package:gemini_landscaping_app/screens/all_reports/manage_companies_screen.dart';
import 'package:gemini_landscaping_app/screens/all_reports/report_files.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gemini_landscaping_app/providers/site_list_provider.dart';
import 'package:gemini_landscaping_app/providers/report_provider.dart';
import 'package:gemini_landscaping_app/providers/management_company_provider.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

enum _SortMode { name, reportCount, recentReport }

enum _SiteFilter { active, inactive, all }

class _SiteWithMeta {
  final SiteInfo site;
  final int reportCount;
  final DateTime? lastReportDate;
  _SiteWithMeta(
      {required this.site, required this.reportCount, this.lastReportDate});
}

class ReportFolders extends ConsumerStatefulWidget {
  const ReportFolders({super.key});

  @override
  ConsumerState<ReportFolders> createState() => _ReportFoldersState();
}

class _ReportFoldersState extends ConsumerState<ReportFolders> {
  static const _darkGreen = Color.fromARGB(255, 59, 82, 73);
  static const _greenAccent = Color.fromARGB(255, 31, 182, 77);

  String _searchQuery = '';
  _SortMode _sortMode = _SortMode.name;
  _SiteFilter _siteFilter = _SiteFilter.active;
  DateTimeRange? _dateRange;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_SiteWithMeta> _filterAndSort(
      List<SiteInfo> sites, List<SiteReport> reports) {
    final result = sites.map((site) {
      var siteReports =
          reports.where((r) => r.siteName == site.name).toList();

      if (_dateRange != null) {
        siteReports = siteReports.where((r) {
          try {
            final d = DateFormat('MMMM d, yyyy').parse(r.date);
            return !d.isBefore(_dateRange!.start) &&
                !d.isAfter(
                    _dateRange!.end.add(const Duration(days: 1)));
          } catch (_) {
            return false;
          }
        }).toList();
      }

      DateTime? lastReportDate;
      for (var r in siteReports) {
        try {
          final d = DateFormat('MMMM d, yyyy').parse(r.date);
          if (lastReportDate == null || d.isAfter(lastReportDate)) {
            lastReportDate = d;
          }
        } catch (_) {}
      }

      return _SiteWithMeta(
        site: site,
        reportCount: siteReports.length,
        lastReportDate: lastReportDate,
      );
    }).toList();

    // Site status filter
    final statusFiltered = _siteFilter == _SiteFilter.all
        ? result
        : result
            .where((s) => _siteFilter == _SiteFilter.active
                ? s.site.status == true
                : s.site.status == false)
            .toList();

    // Search filter
    final filtered = _searchQuery.isEmpty
        ? statusFiltered
        : statusFiltered
            .where((s) =>
                s.site.name.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();

    // Hide sites with 0 reports when date range active
    final visible = _dateRange != null
        ? filtered.where((s) => s.reportCount > 0).toList()
        : filtered;

    // Sort
    switch (_sortMode) {
      case _SortMode.name:
        visible.sort((a, b) => a.site.name.compareTo(b.site.name));
        break;
      case _SortMode.reportCount:
        visible.sort((a, b) => b.reportCount.compareTo(a.reportCount));
        break;
      case _SortMode.recentReport:
        visible.sort((a, b) {
          if (a.lastReportDate == null && b.lastReportDate == null) return 0;
          if (a.lastReportDate == null) return 1;
          if (b.lastReportDate == null) return -1;
          return b.lastReportDate!.compareTo(a.lastReportDate!);
        });
    }

    return visible;
  }

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

  @override
  Widget build(BuildContext context) {
    final siteListAsyncValue = ref.watch(allSitesIncludingInactiveProvider);
    final reportsAsyncValue = ref.watch(allSiteReportsStreamProvider);
    final companiesAsyncValue = ref.watch(managementCompaniesStreamProvider);

    // Build management company name → imageUrl lookup
    final Map<String, String> companyImageLookup = {};
    companiesAsyncValue.whenData((companies) {
      for (final c in companies) {
        companyImageLookup[c.name] = c.imageUrl;
      }
    });

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: siteListAsyncValue.when(
        data: (siteList) {
          return reportsAsyncValue.when(
            data: (reports) {
              final filteredSites = _filterAndSort(siteList, reports);

              return Column(
                children: [
                  _buildDashboardStats(reports, siteList),
                  _buildSiteFilterChips(),
                  _buildSearchAndSortBar(),
                  if (_dateRange != null) _buildDateRangeChip(),
                  Expanded(
                      child: _buildSiteGrid(
                          filteredSites, companyImageLookup)),
                ],
              );
            },
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (error, stack) =>
                Center(child: Text('Error: $error')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }

  // ── Dashboard Stats ──────────────────────────────────────────

  Widget _buildDashboardStats(
      List<SiteReport> reports, List<SiteInfo> siteList) {
    final submittedReports = reports.where((r) => !r.isDraft).toList();
    final now = DateTime.now();

    int displayReports;
    String secondLabel;
    int secondValue;

    if (_dateRange != null) {
      // When date range active, total = filtered count
      displayReports = submittedReports.where((r) {
        try {
          final d = DateFormat('MMMM d, yyyy').parse(r.date);
          return !d.isBefore(_dateRange!.start) &&
              !d.isAfter(_dateRange!.end.add(const Duration(days: 1)));
        } catch (_) {
          return false;
        }
      }).length;
      secondLabel = 'In Range';
      secondValue = displayReports;
    } else {
      displayReports = submittedReports.length;
      secondLabel = 'This Month';
      secondValue = submittedReports.where((r) {
        try {
          final d = DateFormat('MMMM d, yyyy').parse(r.date);
          return d.month == now.month && d.year == now.year;
        } catch (_) {
          return false;
        }
      }).length;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
      child: Row(
        children: [
          _buildStatCard('Total Reports', '$displayReports',
              Icons.description_outlined),
          _buildStatCard(
              secondLabel, '$secondValue', Icons.calendar_today_outlined),
          _buildStatCard('Sites', '${siteList.length}',
              Icons.location_on_outlined),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const ManageCompaniesScreen()),
            ),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.business_outlined,
                  color: _darkGreen, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: _greenAccent, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _darkGreen,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.montserrat(
                fontSize: 10,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Site Filter Chips ───────────────────────────────────────

  Widget _buildSiteFilterChips() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
      child: Row(
        children: _SiteFilter.values.map((filter) {
          final isSelected = _siteFilter == filter;
          String label;
          switch (filter) {
            case _SiteFilter.active:
              label = 'Active';
              break;
            case _SiteFilter.inactive:
              label = 'Inactive';
              break;
            case _SiteFilter.all:
              label = 'All';
              break;
          }
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(
                label,
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? Colors.white : _darkGreen,
                ),
              ),
              selected: isSelected,
              selectedColor: _darkGreen,
              backgroundColor: Colors.white,
              side: BorderSide(
                  color: isSelected ? _darkGreen : Colors.grey.shade300),
              onSelected: (_) => setState(() => _siteFilter = filter),
              showCheckmark: false,
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Search & Sort Bar ────────────────────────────────────────

  Widget _buildSearchAndSortBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              style: GoogleFonts.montserrat(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search sites...',
                hintStyle: GoogleFonts.montserrat(
                    fontSize: 13, color: Colors.grey.shade500),
                prefixIcon:
                    Icon(Icons.search, size: 20, color: Colors.grey.shade600),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_searchQuery.isNotEmpty)
                      IconButton(
                        icon: Icon(Icons.close,
                            size: 18, color: Colors.grey.shade400),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      ),
                    IconButton(
                      icon: Icon(
                        Icons.date_range,
                        size: 20,
                        color: _dateRange != null
                            ? _greenAccent
                            : Colors.grey.shade600,
                      ),
                      onPressed: _pickDateRange,
                    ),
                  ],
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _greenAccent, width: 2),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _buildSortButton(),
        ],
      ),
    );
  }

  Widget _buildSortButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: PopupMenuButton<_SortMode>(
        onSelected: (mode) => setState(() => _sortMode = mode),
        icon: const Icon(Icons.sort, color: _darkGreen),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        itemBuilder: (context) => [
          _sortMenuItem(_SortMode.name, 'Name (A-Z)', Icons.sort_by_alpha),
          _sortMenuItem(
              _SortMode.reportCount, 'Report Count', Icons.bar_chart),
          _sortMenuItem(
              _SortMode.recentReport, 'Most Recent', Icons.access_time),
        ],
      ),
    );
  }

  PopupMenuItem<_SortMode> _sortMenuItem(
      _SortMode mode, String label, IconData icon) {
    final isSelected = _sortMode == mode;
    return PopupMenuItem(
      value: mode,
      child: Row(
        children: [
          Icon(icon,
              size: 18,
              color: isSelected ? _greenAccent : Colors.grey.shade600),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.montserrat(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected ? _greenAccent : Colors.black87,
            ),
          ),
          if (isSelected) ...[
            const Spacer(),
            const Icon(Icons.check, size: 16, color: _greenAccent),
          ],
        ],
      ),
    );
  }

  Widget _buildDateRangeChip() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: Row(
        children: [
          Chip(
            label: Text(
              '${DateFormat('MMM d').format(_dateRange!.start)} - ${DateFormat('MMM d').format(_dateRange!.end)}',
              style: GoogleFonts.montserrat(
                  fontSize: 11, color: _darkGreen),
            ),
            deleteIcon: const Icon(Icons.close, size: 16),
            onDeleted: () => setState(() => _dateRange = null),
            backgroundColor: _greenAccent.withValues(alpha: 0.1),
            side: const BorderSide(color: _greenAccent),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ],
      ),
    );
  }

  // ── Site Grid ────────────────────────────────────────────────

  Widget _buildSiteGrid(
      List<_SiteWithMeta> sites, Map<String, String> companyImageLookup) {
    if (sites.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            Text(
              'No sites found',
              style: GoogleFonts.montserrat(
                  fontSize: 14, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.45,
      ),
      itemCount: sites.length,
      itemBuilder: (context, index) =>
          _buildSiteTile(sites[index], companyImageLookup),
    );
  }

  Widget _buildSiteTile(
      _SiteWithMeta meta, Map<String, String> companyImageLookup) {
    final site = meta.site;
    final lastDate = meta.lastReportDate != null
        ? DateFormat('MMM d, yyyy').format(meta.lastReportDate!)
        : 'No reports';

    // Resolve image: prefer management company logo, fall back to site imageUrl
    final managementImageUrl =
        site.management.isNotEmpty ? companyImageLookup[site.management] : null;
    final displayImageUrl = managementImageUrl ?? site.imageUrl;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              ReportFiles(siteName: site.name, imageUrl: displayImageUrl),
        ),
      ),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Green header with image + name
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: _darkGreen,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(14),
                  topRight: Radius.circular(14),
                ),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: displayImageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: displayImageUrl,
                            height: 30,
                            width: 30,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Icon(
                                Icons.grass_outlined,
                                color: Colors.green.shade300,
                                size: 30),
                            errorWidget: (_, __, ___) => Icon(
                                Icons.grass_outlined,
                                color: Colors.green.shade300,
                                size: 30),
                          )
                        : Icon(Icons.grass_outlined,
                            color: Colors.green.shade300, size: 30),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      site.name,
                      style: GoogleFonts.montserrat(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.chevron_right,
                      color: Colors.white54, size: 18),
                ],
              ),
            ),
            // Stats body
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.description_outlined,
                            size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          '${meta.reportCount} reports',
                          style: GoogleFonts.montserrat(
                              fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.access_time,
                            size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            lastDate,
                            style: GoogleFonts.montserrat(
                                fontSize: 11, color: Colors.grey.shade600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
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
