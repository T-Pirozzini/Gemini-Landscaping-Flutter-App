import 'package:gemini_landscaping_app/models/proposal.dart';
import 'package:gemini_landscaping_app/services/firestore_service.dart';
import 'package:riverpod/riverpod.dart';

final proposalsStreamProvider = StreamProvider<List<Proposal>>((ref) {
  final firestoreService = FirestoreService();
  return firestoreService.fetchProposalsStream();
});
