import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gemini_landscaping_app/models/site_info.dart';
import 'package:gemini_landscaping_app/models/site_report.dart';

class FirestoreService extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // fetch all report data
  Future<List<SiteReport>> fetchAllReports() async {
    final QuerySnapshot snapshot = await _db.collection('SiteReports').get();
    final List<DocumentSnapshot> documents = snapshot.docs;

    return documents.map((doc) {
      return SiteReport(
        id: doc.id,
        title: doc['title'],
        description: doc['description'],
        date: doc['date'],
        imageUrl: doc['imageUrl'],
      );
    }).toList();
  }

  Future<List<SiteInfo>> fetchAllSites() async {
    final QuerySnapshot snapshot = await _db.collection('SiteList').get();
    final List<DocumentSnapshot> documents = snapshot.docs;

    return documents.map((doc) {
      return SiteInfo(
        address: doc['address'],
        imageUrl: doc['imageUrl'],
        management: doc['management'],
        name: doc['name'],
        status: doc['status'],
      );
    }).toList();
  }
}
