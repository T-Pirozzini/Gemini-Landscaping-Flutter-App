import 'package:gemini_landscaping_app/models/admin_notification.dart';
import 'package:gemini_landscaping_app/services/firestore_service.dart';
import 'package:riverpod/riverpod.dart';

final adminNotificationsStreamProvider =
    StreamProvider<List<AdminNotification>>((ref) {
  final firestoreService = FirestoreService();
  return firestoreService.fetchAdminNotificationsStream();
});

final pendingNotificationCountProvider = StreamProvider<int>((ref) {
  final firestoreService = FirestoreService();
  return firestoreService.fetchPendingNotificationCount();
});
