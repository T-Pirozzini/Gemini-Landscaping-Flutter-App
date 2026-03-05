import 'package:cloud_firestore/cloud_firestore.dart';

class MonthlyPayment {
  final String month; // "January", "February", etc.
  final double amount;
  final bool isServiceMonth;

  const MonthlyPayment({
    required this.month,
    required this.amount,
    required this.isServiceMonth,
  });

  factory MonthlyPayment.fromMap(Map<String, dynamic> map) {
    return MonthlyPayment(
      month: map['month'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      isServiceMonth: map['isServiceMonth'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'month': month,
      'amount': amount,
      'isServiceMonth': isServiceMonth,
    };
  }
}

class Proposal {
  final String id;
  final String status; // 'draft', 'sent', 'accepted', 'declined'
  final String siteName;
  final String siteAddress;
  final String contactName;
  final String managementCompany;
  final String paymentTerm;
  final String serviceTerm;
  final List<String> serviceMonths; // e.g. ['April', 'May', ..., 'November']
  final double monthlyRate;
  final double annualRate;
  final List<MonthlyPayment> paymentSchedule; // 12 months
  final bool hasGrass;
  final List<String> extraServices;
  final DateTime? dueDate;
  final String notes;
  final String createdBy;
  final DateTime createdAt;
  final DateTime? sentAt;
  final DateTime? acceptedAt;
  final DateTime? declinedAt;

  const Proposal({
    required this.id,
    this.status = 'draft',
    required this.siteName,
    this.siteAddress = '',
    this.contactName = '',
    this.managementCompany = '',
    this.paymentTerm = '',
    this.serviceTerm = '',
    this.serviceMonths = const [],
    this.monthlyRate = 0.0,
    this.annualRate = 0.0,
    this.paymentSchedule = const [],
    this.hasGrass = false,
    this.extraServices = const [],
    this.dueDate,
    this.notes = '',
    this.createdBy = '',
    required this.createdAt,
    this.sentAt,
    this.acceptedAt,
    this.declinedAt,
  });

  factory Proposal.fromMap(Map<String, dynamic> map, String id) {
    return Proposal(
      id: id,
      status: map['status'] ?? 'draft',
      siteName: map['siteName'] ?? '',
      siteAddress: map['siteAddress'] ?? '',
      contactName: map['contactName'] ?? '',
      managementCompany: map['managementCompany'] ?? '',
      paymentTerm: map['paymentTerm'] ?? '',
      serviceTerm: map['serviceTerm'] ?? '',
      serviceMonths: List<String>.from(map['serviceMonths'] ?? []),
      monthlyRate: (map['monthlyRate'] as num?)?.toDouble() ?? 0.0,
      annualRate: (map['annualRate'] as num?)?.toDouble() ?? 0.0,
      paymentSchedule: (map['paymentSchedule'] as List<dynamic>?)
              ?.map(
                  (m) => MonthlyPayment.fromMap(m as Map<String, dynamic>))
              .toList() ??
          [],
      hasGrass: map['hasGrass'] ?? false,
      extraServices: List<String>.from(map['extraServices'] ?? []),
      dueDate: map['dueDate'] != null
          ? (map['dueDate'] as Timestamp).toDate()
          : null,
      notes: map['notes'] ?? '',
      createdBy: map['createdBy'] ?? '',
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      sentAt: map['sentAt'] != null
          ? (map['sentAt'] as Timestamp).toDate()
          : null,
      acceptedAt: map['acceptedAt'] != null
          ? (map['acceptedAt'] as Timestamp).toDate()
          : null,
      declinedAt: map['declinedAt'] != null
          ? (map['declinedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'status': status,
      'siteName': siteName,
      'siteAddress': siteAddress,
      'contactName': contactName,
      'managementCompany': managementCompany,
      'paymentTerm': paymentTerm,
      'serviceTerm': serviceTerm,
      'serviceMonths': serviceMonths,
      'monthlyRate': monthlyRate,
      'annualRate': annualRate,
      'paymentSchedule': paymentSchedule.map((m) => m.toMap()).toList(),
      'hasGrass': hasGrass,
      'extraServices': extraServices,
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'notes': notes,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'sentAt': sentAt != null ? Timestamp.fromDate(sentAt!) : null,
      'acceptedAt':
          acceptedAt != null ? Timestamp.fromDate(acceptedAt!) : null,
      'declinedAt':
          declinedAt != null ? Timestamp.fromDate(declinedAt!) : null,
    };
  }

  static const List<String> defaultExtraServices = [
    'Aeration',
    'Irrigation',
    'Fertilizer',
    'Bark Mulch',
    'Spring Cleanup',
    'Fall Cleanup',
  ];

  static const List<String> allMonths = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];
}
