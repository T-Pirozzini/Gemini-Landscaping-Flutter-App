import 'package:gemini_landscaping_app/models/service_program.dart';
import 'package:gemini_landscaping_app/services/firestore_service.dart';
import 'package:riverpod/riverpod.dart';

class SiteSeason {
  final String siteId;
  final String season;

  const SiteSeason({required this.siteId, required this.season});

  @override
  bool operator ==(Object other) =>
      other is SiteSeason &&
      siteId == other.siteId &&
      season == other.season;

  @override
  int get hashCode => Object.hash(siteId, season);
}

final serviceProgramsStreamProvider =
    StreamProvider.family<List<ServiceProgram>, SiteSeason>((ref, params) {
  final firestoreService = FirestoreService();
  return firestoreService.fetchServiceProgramsStream(
      params.siteId, params.season);
});
