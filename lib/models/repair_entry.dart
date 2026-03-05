import 'package:cloud_firestore/cloud_firestore.dart';

class RepairEntry {
  final String id;
  final DateTime dateTime;
  final String description;
  final String priority; // 'low', 'medium', 'high', 'resolved'
  final String reportedBy;
  final String? linkedReportId;
  final String? linkedSiteName;
  final String? resolvedBy;
  final DateTime? resolvedDate;
  final String? resolutionNotes;
  final String? cost;
  final int? mileageAtReport;

  RepairEntry({
    required this.id,
    required this.dateTime,
    required this.description,
    required this.priority,
    required this.reportedBy,
    this.linkedReportId,
    this.linkedSiteName,
    this.resolvedBy,
    this.resolvedDate,
    this.resolutionNotes,
    this.cost,
    this.mileageAtReport,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'dateTime': Timestamp.fromDate(dateTime),
      'description': description,
      'priority': priority,
      'reportedBy': reportedBy,
    };
    if (linkedReportId != null) map['linkedReportId'] = linkedReportId;
    if (linkedSiteName != null) map['linkedSiteName'] = linkedSiteName;
    if (resolvedBy != null) map['resolvedBy'] = resolvedBy;
    if (resolvedDate != null) {
      map['resolvedDate'] = Timestamp.fromDate(resolvedDate!);
    }
    if (resolutionNotes != null) map['resolutionNotes'] = resolutionNotes;
    if (cost != null) map['cost'] = cost;
    if (mileageAtReport != null) map['mileageAtReport'] = mileageAtReport;
    return map;
  }

  factory RepairEntry.fromMap(String id, Map<String, dynamic> data) {
    // Handle old format where dateTime was stored as a formatted string
    DateTime parsedDateTime;
    final dtValue = data['dateTime'];
    if (dtValue is Timestamp) {
      parsedDateTime = dtValue.toDate();
    } else if (dtValue is String) {
      parsedDateTime = DateTime.tryParse(dtValue) ?? DateTime.now();
    } else {
      parsedDateTime = DateTime.now();
    }

    return RepairEntry(
      id: id,
      dateTime: parsedDateTime,
      description: data['description'] as String? ?? '',
      priority: data['priority'] as String? ?? 'low',
      reportedBy: data['reportedBy'] as String? ?? '',
      linkedReportId: data['linkedReportId'] as String?,
      linkedSiteName: data['linkedSiteName'] as String?,
      resolvedBy: data['resolvedBy'] as String?,
      resolvedDate: data['resolvedDate'] != null
          ? (data['resolvedDate'] as Timestamp).toDate()
          : null,
      resolutionNotes: data['resolutionNotes'] as String?,
      cost: data['cost'] as String?,
      mileageAtReport: data['mileageAtReport'] as int?,
    );
  }

  RepairEntry copyWith({
    String? id,
    DateTime? dateTime,
    String? description,
    String? priority,
    String? reportedBy,
    String? linkedReportId,
    String? linkedSiteName,
    String? resolvedBy,
    DateTime? resolvedDate,
    String? resolutionNotes,
    String? cost,
    int? mileageAtReport,
  }) {
    return RepairEntry(
      id: id ?? this.id,
      dateTime: dateTime ?? this.dateTime,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      reportedBy: reportedBy ?? this.reportedBy,
      linkedReportId: linkedReportId ?? this.linkedReportId,
      linkedSiteName: linkedSiteName ?? this.linkedSiteName,
      resolvedBy: resolvedBy ?? this.resolvedBy,
      resolvedDate: resolvedDate ?? this.resolvedDate,
      resolutionNotes: resolutionNotes ?? this.resolutionNotes,
      cost: cost ?? this.cost,
      mileageAtReport: mileageAtReport ?? this.mileageAtReport,
    );
  }
}
