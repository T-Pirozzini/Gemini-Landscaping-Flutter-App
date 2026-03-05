import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gemini_landscaping_app/models/admin_notification.dart';
import 'package:gemini_landscaping_app/models/field_quote.dart';
import 'package:gemini_landscaping_app/models/management_company.dart';
import 'package:gemini_landscaping_app/models/proposal.dart';
import 'package:gemini_landscaping_app/models/service_program.dart';
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

  Future<List<SiteInfo>> fetchAllSitesIncludingInactive() async {
    final QuerySnapshot snapshot = await _db.collection('SiteList').get();
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return SiteInfo.fromMap(data, doc.id);
    }).toList();
  }

  // Fetch reports for a date range (used for quarterly/annual views)
  Future<List<SiteReport>> fetchReportsForDateRange(
    DateTime start,
    DateTime end, {
    bool? isRegularMaintenance,
  }) async {
    Query query = _db
        .collection('SiteReports')
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(end));

    if (isRegularMaintenance != null) {
      query =
          query.where('isRegularMaintenance', isEqualTo: isRegularMaintenance);
    }

    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => _parseReport(doc as DocumentSnapshot))
        .toList();
  }

  // ── Management Companies ──────────────────────────────────────

  Stream<List<ManagementCompany>> fetchManagementCompaniesStream() {
    return _db
        .collection('ManagementCompanies')
        .orderBy('name')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return ManagementCompany.fromMap(data, doc.id);
      }).toList();
    });
  }

  Future<String> addManagementCompany(ManagementCompany company) async {
    final docRef =
        await _db.collection('ManagementCompanies').add(company.toMap());
    return docRef.id;
  }

  Future<void> deleteManagementCompany(String id) async {
    await _db.collection('ManagementCompanies').doc(id).delete();
  }

  // ── Service Programs ──────────────────────────────────────────

  Stream<List<ServiceProgram>> fetchServiceProgramsStream(
      String siteId, String season) {
    return _db
        .collection('ServicePrograms')
        .where('siteId', isEqualTo: siteId)
        .where('season', isEqualTo: season)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ServiceProgram.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  /// Initialize default programs for a site/season if none exist yet.
  Future<void> initializeServicePrograms(
      String siteId, String siteName, String season) async {
    final existing = await _db
        .collection('ServicePrograms')
        .where('siteId', isEqualTo: siteId)
        .where('season', isEqualTo: season)
        .get();

    if (existing.docs.isNotEmpty) return;

    final batch = _db.batch();
    for (final name in ServiceProgram.defaultPrograms) {
      final docRef = _db.collection('ServicePrograms').doc();
      batch.set(
          docRef,
          ServiceProgram(
            id: docRef.id,
            siteId: siteId,
            siteName: siteName,
            programName: name,
            season: season,
          ).toMap());
    }
    await batch.commit();
  }

  Future<void> toggleServiceProgramEnabled(String programId, bool enabled) async {
    await _db.collection('ServicePrograms').doc(programId).update({
      'enabled': enabled,
    });
  }

  Future<void> toggleServiceProgramCompleted(
      String programId, bool completed) async {
    await _db.collection('ServicePrograms').doc(programId).update({
      'completed': completed,
      'completedDate': completed ? Timestamp.now() : null,
    });
  }

  Future<String> addCustomServiceProgram(ServiceProgram program) async {
    final docRef =
        await _db.collection('ServicePrograms').add(program.toMap());
    return docRef.id;
  }

  Future<void> deleteServiceProgram(String programId) async {
    await _db.collection('ServicePrograms').doc(programId).delete();
  }

  // ── Admin Notifications ──────────────────────────────────────

  Stream<List<AdminNotification>> fetchAdminNotificationsStream() {
    return _db
        .collection('AdminNotifications')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => AdminNotification.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Stream<int> fetchPendingNotificationCount() {
    return _db
        .collection('AdminNotifications')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Future<void> approveNotification(String notificationId,
      String serviceProgramId) async {
    final batch = _db.batch();
    // Mark notification as approved
    batch.update(_db.collection('AdminNotifications').doc(notificationId), {
      'status': 'approved',
      'resolvedAt': Timestamp.now(),
    });
    // Mark service program as completed
    batch.update(_db.collection('ServicePrograms').doc(serviceProgramId), {
      'completed': true,
      'completedDate': Timestamp.now(),
    });
    await batch.commit();
  }

  Future<void> dismissNotification(String notificationId) async {
    await _db.collection('AdminNotifications').doc(notificationId).update({
      'status': 'dismissed',
      'resolvedAt': Timestamp.now(),
    });
  }

  /// Find and approve the matching service program for a notification.
  Future<void> approveNotificationWithLookup(
      AdminNotification notification) async {
    final programSnap = await _db
        .collection('ServicePrograms')
        .where('siteId', isEqualTo: notification.siteId)
        .where('programName', isEqualTo: notification.programName)
        .where('season', isEqualTo: notification.season)
        .limit(1)
        .get();

    if (programSnap.docs.isNotEmpty) {
      await approveNotification(notification.id, programSnap.docs.first.id);
    } else {
      await dismissNotification(notification.id);
    }
  }

  /// Check submitted report services against enabled service programs for
  /// the site, and create notifications for any matches found.
  Future<void> detectServiceProgramMatches({
    required String reportId,
    required String siteName,
    required String reportDate,
    required Map<String, List<String>> services,
  }) async {
    // Look up siteId from name
    final siteSnap = await _db
        .collection('SiteList')
        .where('name', isEqualTo: siteName)
        .limit(1)
        .get();
    if (siteSnap.docs.isEmpty) return;

    final siteId = siteSnap.docs.first.id;
    final season = DateTime.now().year.toString();

    // Fetch enabled, non-completed programs for this site/season
    final programSnap = await _db
        .collection('ServicePrograms')
        .where('siteId', isEqualTo: siteId)
        .where('season', isEqualTo: season)
        .where('enabled', isEqualTo: true)
        .where('completed', isEqualTo: false)
        .get();

    if (programSnap.docs.isEmpty) return;

    // Flatten all service items from the report
    final allServiceItems = <String>[];
    for (final items in services.values) {
      allServiceItems.addAll(items);
    }
    final lowerItems = allServiceItems.map((s) => s.toLowerCase()).toList();

    // Check each program for a match
    for (final doc in programSnap.docs) {
      final program = ServiceProgram.fromMap(doc.data(), doc.id);
      final programLower = program.programName.toLowerCase();

      // Check if any service item contains the program name
      final match = lowerItems.firstWhere(
        (item) => item.contains(programLower) || programLower.contains(item),
        orElse: () => '',
      );

      if (match.isNotEmpty) {
        // Check for existing pending notification to avoid duplicates
        final existing = await _db
            .collection('AdminNotifications')
            .where('siteId', isEqualTo: siteId)
            .where('programName', isEqualTo: program.programName)
            .where('season', isEqualTo: season)
            .where('status', isEqualTo: 'pending')
            .limit(1)
            .get();

        if (existing.docs.isEmpty) {
          await _db.collection('AdminNotifications').add(
            AdminNotification(
              id: '',
              type: 'service_program_detected',
              status: 'pending',
              siteId: siteId,
              siteName: siteName,
              programName: program.programName,
              season: season,
              reportId: reportId,
              reportDate: reportDate,
              detectedService: match,
              createdAt: DateTime.now(),
            ).toMap(),
          );
        }
      }
    }
  }

  // ── Field Quotes ─────────────────────────────────────────────

  Stream<List<FieldQuote>> fetchFieldQuotesStream() {
    return _db
        .collection('FieldQuotes')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => FieldQuote.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Future<String> addFieldQuote(FieldQuote quote) async {
    final docRef = await _db.collection('FieldQuotes').add(quote.toMap());
    return docRef.id;
  }

  Future<void> updateFieldQuoteStatus(
      String quoteId, String status) async {
    final updates = <String, dynamic>{'status': status};
    if (status == 'signed') {
      updates['signedAt'] = Timestamp.now();
    } else if (status == 'completed') {
      updates['completedAt'] = Timestamp.now();
    }
    await _db.collection('FieldQuotes').doc(quoteId).update(updates);
  }

  Future<void> updateFieldQuoteSignature(
      String quoteId, String signatureBase64) async {
    await _db.collection('FieldQuotes').doc(quoteId).update({
      'signatureBase64': signatureBase64,
      'status': 'signed',
      'signedAt': Timestamp.now(),
    });
  }

  // ── Proposals ────────────────────────────────────────────────

  Stream<List<Proposal>> fetchProposalsStream() {
    return _db
        .collection('Proposals')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Proposal.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Future<String> addProposal(Proposal proposal) async {
    final docRef = await _db.collection('Proposals').add(proposal.toMap());
    return docRef.id;
  }

  Future<void> updateProposal(String proposalId, Map<String, dynamic> data) async {
    await _db.collection('Proposals').doc(proposalId).update(data);
  }

  Future<void> updateProposalStatus(String proposalId, String status) async {
    final updates = <String, dynamic>{'status': status};
    if (status == 'sent') {
      updates['sentAt'] = Timestamp.now();
    } else if (status == 'accepted') {
      updates['acceptedAt'] = Timestamp.now();
    } else if (status == 'declined') {
      updates['declinedAt'] = Timestamp.now();
    }
    await _db.collection('Proposals').doc(proposalId).update(updates);
  }

  Future<void> deleteProposal(String proposalId) async {
    await _db.collection('Proposals').doc(proposalId).delete();
  }
}
