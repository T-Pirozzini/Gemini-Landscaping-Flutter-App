import 'package:cloud_firestore/cloud_firestore.dart';
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
      final employeeTimes = doc['employeeTimes'] as Map<String, dynamic>;
      final employees = employeeTimes.entries.map((entry) {
        final employeeData = entry.value as Map<String, dynamic>;
        return EmployeeTime(
          name: entry.key,
          timeOn: (employeeData['timeOn'] as Timestamp).toDate(),
          timeOff: (employeeData['timeOff'] as Timestamp).toDate(),
          duration: employeeData['duration'],
        );
      }).toList();

      final services = doc['services'] as Map<String, dynamic>;
      final mappedServices =
          services.map((key, value) => MapEntry(key, List<String>.from(value)));

      final materialsList = doc['materials'] as List<dynamic>;
      final materials = materialsList.map((material) {
        final materialData = material as Map<String, dynamic>;
        return MaterialList(
          cost: materialData['cost'],
          description: materialData['description'],
          vendor: materialData['vendor'],
        );
      }).toList();

      return SiteReport(
        id: doc.id,
        siteName: doc['siteInfo']['siteName'],
        totalCombinedDuration: doc['totalCombinedDuration'],
        date: doc['siteInfo']['date'],
        employees: employees,
        filed: doc['filed'] ?? false,
        address: doc['siteInfo']['address'],
        services: mappedServices,
        materials: materials,
        description: doc['description'],
        submittedBy: doc['submittedBy'],
        timestamp: (doc['timestamp'] as Timestamp).toDate(),
        isRegularMaintenance: doc['isRegularMaintenance'],
      );
    }).toList();
  }

  // fetch all reports stream
  Stream<List<SiteReport>> fetchAllReportsStream() {
    return _db.collection('SiteReports').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final employeeTimes = doc['employeeTimes'] as Map<String, dynamic>;
        final employees = employeeTimes.entries.map((entry) {
          final employeeData = entry.value as Map<String, dynamic>;
          return EmployeeTime(
            name: entry.key,
            timeOn: (employeeData['timeOn'] as Timestamp).toDate(),
            timeOff: (employeeData['timeOff'] as Timestamp).toDate(),
            duration: employeeData['duration'],
          );
        }).toList();

        final services = doc['services'] as Map<String, dynamic>;
        final mappedServices = services
            .map((key, value) => MapEntry(key, List<String>.from(value)));

        final materialsList = doc['materials'] as List<dynamic>;
        final materials = materialsList.map((material) {
          final materialData = material as Map<String, dynamic>;
          return MaterialList(
            cost: materialData['cost'],
            description: materialData['description'],
            vendor: materialData['vendor'],
          );
        }).toList();

        return SiteReport(
          id: doc.id,
          siteName: doc['siteInfo']['siteName'],
          totalCombinedDuration: doc['totalCombinedDuration'],
          date: doc['siteInfo']['date'],
          employees: employees,
          filed: doc['filed'] ?? false,
          address: doc['siteInfo']['address'],
          services: mappedServices,
          materials: materials,
          description: doc['description'],
          submittedBy: doc['submittedBy'],
          timestamp: (doc['timestamp'] as Timestamp).toDate(),
          isRegularMaintenance: doc['isRegularMaintenance'],
        );
      }).toList();
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
    final List<DocumentSnapshot> documents = snapshot.docs;

    return documents.map((doc) {
      final employeeTimes = doc['employeeTimes'] as Map<String, dynamic>;
      final employees = employeeTimes.entries.map((entry) {
        final employeeData = entry.value as Map<String, dynamic>;
        return EmployeeTime(
          name: entry.key,
          timeOn: (employeeData['timeOn'] as Timestamp).toDate(),
          timeOff: (employeeData['timeOff'] as Timestamp).toDate(),
          duration: employeeData['duration'],
        );
      }).toList();

      final services = doc['services'] as Map<String, dynamic>;
      final mappedServices =
          services.map((key, value) => MapEntry(key, List<String>.from(value)));

      final materialsList = doc['materials'] as List<dynamic>;
      final materials = materialsList.map((material) {
        final materialData = material as Map<String, dynamic>;
        return MaterialList(
          cost: materialData['cost'],
          description: materialData['description'],
          vendor: materialData['vendor'],
        );
      }).toList();

      return SiteReport(
        id: doc.id,
        siteName: doc['siteInfo']['siteName'],
        totalCombinedDuration: doc['totalCombinedDuration'],
        date: doc['siteInfo']['date'],
        employees: employees,
        filed: doc['filed'] ?? false,
        address: doc['siteInfo']['address'],
        services: mappedServices,
        materials: materials,
        description: doc['description'],
        submittedBy: doc['submittedBy'],
        timestamp: (doc['timestamp'] as Timestamp).toDate(),
        isRegularMaintenance: doc['isRegularMaintenance'],
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
        .where("isRegularMaintenance", isEqualTo: true)
        .get();
    final List<DocumentSnapshot> documents = snapshot.docs;

    return documents.map((doc) {
      final employeeTimes = doc['employeeTimes'] as Map<String, dynamic>;
      final employees = employeeTimes.entries.map((entry) {
        final employeeData = entry.value as Map<String, dynamic>;
        return EmployeeTime(
          name: entry.key,
          timeOn: (employeeData['timeOn'] as Timestamp).toDate(),
          timeOff: (employeeData['timeOff'] as Timestamp).toDate(),
          duration: employeeData['duration'],
        );
      }).toList();

      final services = doc['services'] as Map<String, dynamic>;
      final mappedServices =
          services.map((key, value) => MapEntry(key, List<String>.from(value)));

      final materialsList = doc['materials'] as List<dynamic>;
      final materials = materialsList.map((material) {
        final materialData = material as Map<String, dynamic>;
        return MaterialList(
          cost: materialData['cost'],
          description: materialData['description'],
          vendor: materialData['vendor'],
        );
      }).toList();

      return SiteReport(
        id: doc.id,
        siteName: doc['siteInfo']['siteName'],
        totalCombinedDuration: doc['totalCombinedDuration'],
        date: doc['siteInfo']['date'],
        employees: employees,
        filed: doc['filed'] ?? false,
        address: doc['siteInfo']['address'],
        services: mappedServices,
        materials: materials,
        description: doc['description'],
        submittedBy: doc['submittedBy'],
        timestamp: (doc['timestamp'] as Timestamp).toDate(),
        isRegularMaintenance: doc['isRegularMaintenance'],
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
        program: doc['program'] ?? true,
      );
    }).toList();
  }
}
