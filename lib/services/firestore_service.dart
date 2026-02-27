import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gemini_landscaping_app/models/site_info.dart';
import 'package:gemini_landscaping_app/models/site_report.dart';

class FirestoreService extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Shared helper to parse a Firestore document into a SiteReport.
  // Handles both v1 (legacy flat) and v2 (dual-phase) formats.
  // Tolerant of missing fields to support drafts.
  SiteReport _parseReport(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    final version = data['version'] as int? ?? 1;
    final status = data['status'] as String? ?? 'submitted';
    final draftOwnerId = data['draftOwnerId'] as String?;

    // Parse flat employee times (present in both v1 and v2)
    final employeeTimesData =
        data['employeeTimes'] as Map<String, dynamic>? ?? {};
    final employees = employeeTimesData.entries.map((entry) {
      final employeeData = entry.value as Map<String, dynamic>;
      return EmployeeTime(
        name: entry.key,
        timeOn: (employeeData['timeOn'] as Timestamp).toDate(),
        timeOff: (employeeData['timeOff'] as Timestamp).toDate(),
        duration: employeeData['duration'] as int,
      );
    }).toList();

    // Parse flat services
    final servicesData = data['services'] as Map<String, dynamic>? ?? {};
    final mappedServices =
        servicesData.map((key, value) => MapEntry(key, List<String>.from(value)));

    // Parse materials
    final materialsList = data['materials'] as List<dynamic>? ?? [];
    final materials = materialsList.map((material) {
      return MaterialList.fromMap(material as Map<String, dynamic>);
    }).toList();

    final disposalData = data.containsKey('disposal')
        ? Disposal.fromMap(data['disposal'] as Map<String, dynamic>)
        : null;

    final noteTags = data.containsKey('noteTags')
        ? List<String>.from(data['noteTags'])
        : <String>[];

    final siteInfo = data['siteInfo'] as Map<String, dynamic>? ?? {};

    // Parse v2 phase data if present
    ReportPhase? regularPhase;
    ReportPhase? additionalPhase;
    if (version >= 2) {
      if (data.containsKey('regularPhase') && data['regularPhase'] != null) {
        regularPhase =
            ReportPhase.fromMap(data['regularPhase'] as Map<String, dynamic>);
      }
      if (data.containsKey('additionalPhase') &&
          data['additionalPhase'] != null) {
        additionalPhase = ReportPhase.fromMap(
            data['additionalPhase'] as Map<String, dynamic>);
      }
    }

    return SiteReport(
      id: doc.id,
      version: version,
      status: status,
      draftOwnerId: draftOwnerId,
      siteName: siteInfo['siteName'] ?? '',
      totalCombinedDuration: data['totalCombinedDuration'] ?? 0,
      date: siteInfo['date'] ?? '',
      employees: employees,
      filed: data['filed'] ?? false,
      address: siteInfo['address'] ?? '',
      services: mappedServices,
      materials: materials,
      description: data['description'] ?? '',
      noteTags: noteTags,
      submittedBy: data['submittedBy'] ?? '',
      timestamp: data['timestamp'] != null
          ? (data['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
      isRegularMaintenance: data['isRegularMaintenance'] ?? true,
      disposal: disposalData,
      regularPhase: regularPhase,
      additionalPhase: additionalPhase,
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

  // --- Draft methods ---

  /// Save or update a draft report. Returns the document ID.
  Future<String> saveDraft(Map<String, dynamic> data) async {
    final collection = _db.collection('SiteReports');
    final docId = data.remove('id') as String?;

    data['status'] = 'draft';
    data['version'] = 2;
    data['timestamp'] = Timestamp.fromDate(DateTime.now());

    if (docId != null && docId.isNotEmpty) {
      await collection.doc(docId).set(data);
      return docId;
    } else {
      final docRef = await collection.add(data);
      return docRef.id;
    }
  }

  /// Mark a draft as submitted.
  Future<void> submitReport(String docId) async {
    await _db.collection('SiteReports').doc(docId).update({
      'status': 'submitted',
      'timestamp': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Delete a draft document.
  Future<void> deleteDraft(String docId) async {
    await _db.collection('SiteReports').doc(docId).delete();
  }

  /// Stream all drafts (visible to all employees).
  Stream<List<SiteReport>> fetchDraftsStream() {
    return _db
        .collection('SiteReports')
        .where('status', isEqualTo: 'draft')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map(_parseReport).toList();
    });
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
