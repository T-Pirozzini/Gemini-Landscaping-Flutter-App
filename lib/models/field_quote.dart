import 'package:cloud_firestore/cloud_firestore.dart';

class FieldQuote {
  final String id;
  final String siteName;
  final String siteId;
  final String clientName;
  final String date;
  final DateTime timestamp;
  final String description;
  final double subtotal;
  final double gstRate; // 0.05
  final double gstAmount;
  final double total;
  final String status; // 'created', 'signed', 'completed'
  final String? signatureBase64; // PNG as base64 string
  final String createdBy;
  final String createdByName;
  final DateTime? signedAt;
  final DateTime? completedAt;

  const FieldQuote({
    required this.id,
    required this.siteName,
    this.siteId = '',
    required this.clientName,
    required this.date,
    required this.timestamp,
    required this.description,
    required this.subtotal,
    this.gstRate = 0.05,
    required this.gstAmount,
    required this.total,
    this.status = 'created',
    this.signatureBase64,
    required this.createdBy,
    this.createdByName = '',
    this.signedAt,
    this.completedAt,
  });

  factory FieldQuote.fromMap(Map<String, dynamic> map, String id) {
    return FieldQuote(
      id: id,
      siteName: map['siteName'] ?? '',
      siteId: map['siteId'] ?? '',
      clientName: map['clientName'] ?? '',
      date: map['date'] ?? '',
      timestamp: map['timestamp'] != null
          ? (map['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
      description: map['description'] ?? '',
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0.0,
      gstRate: (map['gstRate'] as num?)?.toDouble() ?? 0.05,
      gstAmount: (map['gstAmount'] as num?)?.toDouble() ?? 0.0,
      total: (map['total'] as num?)?.toDouble() ?? 0.0,
      status: map['status'] ?? 'created',
      signatureBase64: map['signatureBase64'],
      createdBy: map['createdBy'] ?? '',
      createdByName: map['createdByName'] ?? '',
      signedAt: map['signedAt'] != null
          ? (map['signedAt'] as Timestamp).toDate()
          : null,
      completedAt: map['completedAt'] != null
          ? (map['completedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'siteName': siteName,
      'siteId': siteId,
      'clientName': clientName,
      'date': date,
      'timestamp': Timestamp.fromDate(timestamp),
      'description': description,
      'subtotal': subtotal,
      'gstRate': gstRate,
      'gstAmount': gstAmount,
      'total': total,
      'status': status,
      'signatureBase64': signatureBase64,
      'createdBy': createdBy,
      'createdByName': createdByName,
      'signedAt': signedAt != null ? Timestamp.fromDate(signedAt!) : null,
      'completedAt':
          completedAt != null ? Timestamp.fromDate(completedAt!) : null,
    };
  }

  FieldQuote copyWith({
    String? id,
    String? siteName,
    String? siteId,
    String? clientName,
    String? date,
    DateTime? timestamp,
    String? description,
    double? subtotal,
    double? gstRate,
    double? gstAmount,
    double? total,
    String? status,
    String? signatureBase64,
    String? createdBy,
    String? createdByName,
    DateTime? signedAt,
    DateTime? completedAt,
  }) {
    return FieldQuote(
      id: id ?? this.id,
      siteName: siteName ?? this.siteName,
      siteId: siteId ?? this.siteId,
      clientName: clientName ?? this.clientName,
      date: date ?? this.date,
      timestamp: timestamp ?? this.timestamp,
      description: description ?? this.description,
      subtotal: subtotal ?? this.subtotal,
      gstRate: gstRate ?? this.gstRate,
      gstAmount: gstAmount ?? this.gstAmount,
      total: total ?? this.total,
      status: status ?? this.status,
      signatureBase64: signatureBase64 ?? this.signatureBase64,
      createdBy: createdBy ?? this.createdBy,
      createdByName: createdByName ?? this.createdByName,
      signedAt: signedAt ?? this.signedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
