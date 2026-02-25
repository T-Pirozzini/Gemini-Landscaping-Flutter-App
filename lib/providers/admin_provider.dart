import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gemini_landscaping_app/providers/user_provider.dart';

final isAdminProvider = Provider<bool>((ref) {
  final userAsync = ref.watch(currentAppUserProvider);
  return userAsync.whenOrNull(data: (user) => user?.role == 'admin') ?? false;
});
