import 'package:gemini_landscaping_app/models/field_quote.dart';
import 'package:gemini_landscaping_app/services/firestore_service.dart';
import 'package:riverpod/riverpod.dart';

final fieldQuotesStreamProvider = StreamProvider<List<FieldQuote>>((ref) {
  final firestoreService = FirestoreService();
  return firestoreService.fetchFieldQuotesStream();
});
