import 'package:gemini_landscaping_app/models/site_info.dart';

class ScheduleEntry {
  final SiteInfo site;
  final DateTime startTime;
  final DateTime endTime;
  final String? notes; // Optional for now
  final String? truckId; // Optional for truck assignment later

  ScheduleEntry({
    required this.site,
    required this.startTime,
    required this.endTime,
    this.notes,
    this.truckId,
  });
}