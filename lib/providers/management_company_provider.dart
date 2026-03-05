import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gemini_landscaping_app/models/management_company.dart';
import 'package:gemini_landscaping_app/services/firestore_service.dart';

final managementCompaniesStreamProvider =
    StreamProvider<List<ManagementCompany>>((ref) {
  final firestoreService = FirestoreService();
  return firestoreService.fetchManagementCompaniesStream();
});
