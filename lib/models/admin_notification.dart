import 'package:cloud_firestore/cloud_firestore.dart';

class AdminNotification {
  final String id;
  final String type; // 'service_program_detected'
  final String status; // 'pending', 'approved', 'dismissed'
  final String siteId;
  final String siteName;
  final String programName;
  final String season;
  final String reportId;
  final String reportDate;
  final String detectedService; // the service string that matched
  final DateTime createdAt;
  final DateTime? resolvedAt;

  const AdminNotification({
    required this.id,
    required this.type,
    required this.status,
    required this.siteId,
    required this.siteName,
    required this.programName,
    required this.season,
    required this.reportId,
    required this.reportDate,
    required this.detectedService,
    required this.createdAt,
    this.resolvedAt,
  });

  factory AdminNotification.fromMap(Map<String, dynamic> map, String id) {
    return AdminNotification(
      id: id,
      type: map['type'] ?? '',
      status: map['status'] ?? 'pending',
      siteId: map['siteId'] ?? '',
      siteName: map['siteName'] ?? '',
      programName: map['programName'] ?? '',
      season: map['season'] ?? '',
      reportId: map['reportId'] ?? '',
      reportDate: map['reportDate'] ?? '',
      detectedService: map['detectedService'] ?? '',
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      resolvedAt: map['resolvedAt'] != null
          ? (map['resolvedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'status': status,
      'siteId': siteId,
      'siteName': siteName,
      'programName': programName,
      'season': season,
      'reportId': reportId,
      'reportDate': reportDate,
      'detectedService': detectedService,
      'createdAt': Timestamp.fromDate(createdAt),
      'resolvedAt':
          resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
    };
  }
}
