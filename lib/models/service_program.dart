import 'package:cloud_firestore/cloud_firestore.dart';

class ServiceProgram {
  final String id;
  final String siteId;
  final String siteName;
  final String programName;
  final bool enabled;
  final bool completed;
  final DateTime? completedDate;
  final String season; // e.g. "2026"

  const ServiceProgram({
    required this.id,
    required this.siteId,
    required this.siteName,
    required this.programName,
    this.enabled = false,
    this.completed = false,
    this.completedDate,
    required this.season,
  });

  static const List<String> defaultPrograms = [
    'Aeration',
    'Irrigation',
    'Fertilizer',
    'Bark Mulch',
  ];

  factory ServiceProgram.fromMap(Map<String, dynamic> map, String id) {
    return ServiceProgram(
      id: id,
      siteId: map['siteId'] ?? '',
      siteName: map['siteName'] ?? '',
      programName: map['programName'] ?? '',
      enabled: map['enabled'] ?? false,
      completed: map['completed'] ?? false,
      completedDate: map['completedDate'] != null
          ? (map['completedDate'] as Timestamp).toDate()
          : null,
      season: map['season'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'siteId': siteId,
      'siteName': siteName,
      'programName': programName,
      'enabled': enabled,
      'completed': completed,
      'completedDate':
          completedDate != null ? Timestamp.fromDate(completedDate!) : null,
      'season': season,
    };
  }

  ServiceProgram copyWith({
    String? id,
    String? siteId,
    String? siteName,
    String? programName,
    bool? enabled,
    bool? completed,
    DateTime? completedDate,
    String? season,
  }) {
    return ServiceProgram(
      id: id ?? this.id,
      siteId: siteId ?? this.siteId,
      siteName: siteName ?? this.siteName,
      programName: programName ?? this.programName,
      enabled: enabled ?? this.enabled,
      completed: completed ?? this.completed,
      completedDate: completedDate ?? this.completedDate,
      season: season ?? this.season,
    );
  }
}
