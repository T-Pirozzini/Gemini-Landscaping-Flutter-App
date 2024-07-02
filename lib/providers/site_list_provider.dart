import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gemini_landscaping_app/models/site_info.dart';
import 'package:gemini_landscaping_app/services/firestore_service.dart';

final siteListProvider = FutureProvider<List<SiteInfo>>((ref) async {
  final firestoreService = FirestoreService();
  return firestoreService.fetchAllSites();
});