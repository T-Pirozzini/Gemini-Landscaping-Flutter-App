import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gemini_landscaping_app/models/site_report.dart';
import 'package:gemini_landscaping_app/services/firestore_service.dart';

/// Stream of all draft reports (visible to all employees).
final draftsStreamProvider = StreamProvider<List<SiteReport>>((ref) {
  final firestoreService = FirestoreService();
  return firestoreService.fetchDraftsStream();
});
