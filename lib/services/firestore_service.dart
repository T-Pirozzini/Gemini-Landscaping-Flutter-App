import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gemini_landscaping_app/models/site_info.dart';
import 'package:gemini_landscaping_app/models/site_report.dart';

class FirestoreService extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Shared helper to parse a Firestore document into a SiteReport
  SiteReport _parseReport(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    final employeeTimes = data['employeeTimes'] as Map<String, dynamic>;
    final employees = employeeTimes.entries.map((entry) {
      final employeeData = entry.value as Map<String, dynamic>;
      return EmployeeTime(
        name: entry.key,
        timeOn: (employeeData['timeOn'] as Timestamp).toDate(),
        timeOff: (employeeData['timeOff'] as Timestamp).toDate(),
        duration: employeeData['duration'],
      );
    }).toList();

    final services = data['services'] as Map<String, dynamic>;
    final mappedServices =
        services.map((key, value) => MapEntry(key, List<String>.from(value)));

    final materialsList = data['materials'] as List<dynamic>;
    final materials = materialsList.map((material) {
      final materialData = material as Map<String, dynamic>;
      return MaterialList(
        cost: materialData['cost'],
        description: materialData['description'],
        vendor: materialData['vendor'],
      );
    }).toList();

    final disposalData = data.containsKey('disposal')
        ? Disposal.fromMap(data['disposal'] as Map<String, dynamic>)
        : null;

    final noteTags = data.containsKey('noteTags')
        ? List<String>.from(data['noteTags'])
        : <String>[];

    return SiteReport(
      id: doc.id,
      siteName: data['siteInfo']['siteName'],
      totalCombinedDuration: data['totalCombinedDuration'],
      date: data['siteInfo']['date'],
      employees: employees,
      filed: data['filed'] ?? false,
      address: data['siteInfo']['address'],
      services: mappedServices,
      materials: materials,
      description: data['description'],
      noteTags: noteTags,
      submittedBy: data['submittedBy'],
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      isRegularMaintenance: data['isRegularMaintenance'],
      disposal: disposalData,
    );
  }

  // fetch all report data
  Future<List<SiteReport>> fetchAllReports() async {
    final QuerySnapshot snapshot = await _db.collection('SiteReports').get();
    return snapshot.docs.map(_parseReport).toList();
  }

  // fetch all reports stream (unlimited — for admin "All Reports" tab)
  Stream<List<SiteReport>> fetchAllReportsStream() {
    return _db.collection('SiteReports').snapshots().map((snapshot) {
      return snapshot.docs.map(_parseReport).toList();
    });
  }

  // fetch recent reports stream with server-side ordering and limit
  Stream<List<SiteReport>> fetchRecentReportsStream({int limit = 80}) {
    return _db
        .collection('SiteReports')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map(_parseReport).toList();
    });
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

    return snapshot.docs.map(_parseReport).toList();
  }

  // fetch specific month report data
  Future<List<SiteReport>> fetchSpecificMonthSiteReports(DateTime date) async {
    final DateTime startOfMonth = DateTime(date.year, date.month, 1);
    final DateTime endOfMonth = DateTime(date.year, date.month + 1, 0);

    final QuerySnapshot snapshot = await _db
        .collection('SiteReports')
        .where('timestamp', isGreaterThan: startOfMonth)
        .where('timestamp', isLessThanOrEqualTo: endOfMonth)
        .where("isRegularMaintenance", isEqualTo: true)
        .get();

    return snapshot.docs.map(_parseReport).toList();
  }

  Future<List<SiteInfo>> fetchAllSites() async {
    final QuerySnapshot snapshot =
        await _db.collection('SiteList').where("status", isEqualTo: true).get();
    final List<DocumentSnapshot> documents = snapshot.docs;

    return documents.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return SiteInfo.fromMap(data, doc.id);
    }).toList();
  }
}
