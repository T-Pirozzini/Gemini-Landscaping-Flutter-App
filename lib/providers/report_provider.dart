import 'package:gemini_landscaping_app/models/site_report.dart';
import 'package:riverpod/riverpod.dart';
import 'package:gemini_landscaping_app/services/firestore_service.dart';


final currentMonthsitereportProvider = FutureProvider<List<SiteReport>>((ref) async {
  final firestoreService = FirestoreService();
  return firestoreService.fetchCurrentMonthSiteReports();
});