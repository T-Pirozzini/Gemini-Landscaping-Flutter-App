import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gemini_landscaping_app/models/site_info.dart';
import 'package:gemini_landscaping_app/models/site_report.dart';

class FirestoreService extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // fetch all report data
  Future<List<SiteReport>> fetchAllReports() async {
    final QuerySnapshot snapshot = await _db
        .collection('SiteReports')        
        .get();
    final List<DocumentSnapshot> documents = snapshot.docs;

    return documents.map((doc) {
      final employeeTimes = doc['employeeTimes'] as Map<String, dynamic>;
      final employees = employeeTimes.keys.toList();

      return SiteReport(
        id: doc.id,
        siteName: doc['siteInfo']['siteName'],
        totalCombinedDuration: doc['totalCombinedDuration'],
        date: doc['siteInfo']['date'],
        employees: employees,
        filed: doc['filed'] ?? false,
      );
    }).toList();
  }

  // fetch current month report data
  Future<List<SiteReport>> fetchCurrentMonthSiteReports() async {
    final DateTime now = DateTime.now();
    final DateTime startOfCurrentMonth = DateTime(now.year, now.month, 1);
    final DateTime endOfCurrentMonth = DateTime(now.year, now.month + 1, 0);

    final QuerySnapshot snapshot = await _db
        .collection('SiteReports')
        .where('timestamp', isGreaterThan: startOfCurrentMonth)
        .where('timestamp', isLessThanOrEqualTo: endOfCurrentMonth)
        .get();
    final List<DocumentSnapshot> documents = snapshot.docs;

    return documents.map((doc) {
      final employeeTimes = doc['employeeTimes'] as Map<String, dynamic>;
      final employees = employeeTimes.keys.toList();

      return SiteReport(
        id: doc.id,
        siteName: doc['siteInfo']['siteName'],
        totalCombinedDuration: doc['totalCombinedDuration'],
        date: doc['siteInfo']['date'],
        employees: employees,
        filed: doc['filed'] ?? false,
      );
    }).toList();
  }

  // fetch specific month report data
  Future<List<SiteReport>> fetchSpecificMonthSiteReports(DateTime date) async {
    final DateTime startOfMonth = DateTime(date.year, date.month, 1);
    final DateTime endOfMonth = DateTime(date.year, date.month + 1, 0);

    final QuerySnapshot snapshot = await _db
        .collection('SiteReports')
        .where('timestamp', isGreaterThan: startOfMonth)
        .where('timestamp', isLessThanOrEqualTo: endOfMonth)
        .get();
    final List<DocumentSnapshot> documents = snapshot.docs;

    return documents.map((doc) {
      final employeeTimes = doc['employeeTimes'] as Map<String, dynamic>;
      final employees = employeeTimes.keys.toList();

      return SiteReport(
        id: doc.id,
        siteName: doc['siteInfo']['siteName'],
        totalCombinedDuration: doc['totalCombinedDuration'],
        date: doc['siteInfo']['date'],
        employees: employees,
        filed: doc['filed'] ?? false,
      );
    }).toList();
  }

  Future<List<SiteInfo>> fetchAllSites() async {
    final QuerySnapshot snapshot =
        await _db.collection('SiteList').where("status", isEqualTo: true).get();
    final List<DocumentSnapshot> documents = snapshot.docs;

    return documents.map((doc) {
      return SiteInfo(
        address: doc['address'],
        imageUrl: doc['imageUrl'],
        management: doc['management'],
        name: doc['name'],
        status: doc['status'],
        target: doc['target'].toDouble(),
        id: doc.id,
      );
    }).toList();
  }
}
