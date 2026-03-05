import 'package:gemini_landscaping_app/models/site_report.dart';
import 'package:riverpod/riverpod.dart';
import 'package:gemini_landscaping_app/services/firestore_service.dart';
import 'package:gemini_landscaping_app/models/site_info.dart';

// fetch site report data for current month
final currentMonthSitereportProvider = FutureProvider<List<SiteReport>>((ref) async {
  final firestoreService = FirestoreService();
  return firestoreService.fetchCurrentMonthSiteReports();
});

// fetch site report data for specific month
final specificMonthSitereportProvider = FutureProvider.family<List<SiteReport>, DateTime>((ref, date) async {
  final firestoreService = FirestoreService();
  return firestoreService.fetchSpecificMonthSiteReports(date);
});

final allSiteReportsProvider = FutureProvider<List<SiteReport>>((ref) async {
  final firestoreService = FirestoreService();
  return firestoreService.fetchAllReports();
});

// Recent reports with server-side limit (for Recent tab)
final recentSiteReportsStreamProvider = StreamProvider<List<SiteReport>>((ref) {
  final firestoreService = FirestoreService();
  return firestoreService.fetchRecentReportsStream(limit: 80);
});

// All reports unlimited (for admin All Reports tab)
final allSiteReportsStreamProvider = StreamProvider<List<SiteReport>>((ref) {
  final firestoreService = FirestoreService();
  return firestoreService.fetchAllReportsStream();
});

final allSiteInfoProvider = FutureProvider<List<SiteInfo>>((ref) {
  final firestoreService = FirestoreService();
  return firestoreService.fetchAllSites();
});

// Parameter class for date range report queries
class DateRangeParams {
  final DateTime start;
  final DateTime end;
  final bool? isRegularMaintenance;

  const DateRangeParams({
    required this.start,
    required this.end,
    this.isRegularMaintenance,
  });

  @override
  bool operator ==(Object other) =>
      other is DateRangeParams &&
      start == other.start &&
      end == other.end &&
      isRegularMaintenance == other.isRegularMaintenance;

  @override
  int get hashCode => Object.hash(start, end, isRegularMaintenance);
}

// Fetch reports for a date range with optional isRegularMaintenance filter
final dateRangeReportsProvider =
    FutureProvider.family<List<SiteReport>, DateRangeParams>(
  (ref, params) async {
    final firestoreService = FirestoreService();
    return firestoreService.fetchReportsForDateRange(
      params.start,
      params.end,
      isRegularMaintenance: params.isRegularMaintenance,
    );
  },
);