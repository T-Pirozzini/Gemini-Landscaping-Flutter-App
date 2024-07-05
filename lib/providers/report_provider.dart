import 'package:gemini_landscaping_app/models/site_report.dart';
import 'package:riverpod/riverpod.dart';
import 'package:gemini_landscaping_app/services/firestore_service.dart';

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