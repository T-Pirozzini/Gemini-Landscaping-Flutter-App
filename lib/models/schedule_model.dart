import 'package:gemini_landscaping_app/models/site_info.dart';

class ScheduleEntry {
  final SiteInfo site;
  final DateTime startTime;
  final DateTime endTime;
  final String? notes;
  final String? truckId;
  final String? id;
  String status;

  ScheduleEntry({
    required this.site,
    required this.startTime,
    required this.endTime,
    this.notes,
    this.truckId,
    this.id,
    this.status = 'pending'
  });

  Map<String, dynamic> toMap() {
    return {
      'siteId': site.id,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'truckId': truckId,
      'notes': notes,
      'date': DateTime(startTime.year, startTime.month, startTime.day)
          .toIso8601String(),
          'status': status,
    };
  }

  factory ScheduleEntry.fromMap(
      String id, Map<String, dynamic> data, SiteInfo site) {
    return ScheduleEntry(
      id: id,
      site: site,
      startTime: DateTime.parse(data['startTime']),
      endTime: DateTime.parse(data['endTime']),
      truckId: data['truckId'],
      notes: data['notes'],
      status: data['status'] as String? ?? 'pending',
    );
  }
}
