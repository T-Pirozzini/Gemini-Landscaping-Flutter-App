import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gemini_landscaping_app/models/app_user.dart';

final activeUsersProvider = StreamProvider<List<AppUser>>((ref) {
  return FirebaseFirestore.instance
      .collection('Users')
      .where('active', isEqualTo: true)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => AppUser.fromMap(doc.data(), doc.id))
          .toList()
        ..sort((a, b) => a.username.compareTo(b.username)));
});

final currentAppUserProvider = StreamProvider<AppUser?>((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return Stream.value(null);
  return FirebaseFirestore.instance
      .collection('Users')
      .doc(uid)
      .snapshots()
      .map((doc) =>
          doc.exists ? AppUser.fromMap(doc.data()!, doc.id) : null);
});
