import 'package:cloud_firestore/cloud_firestore.dart';

/// Unified photo model for all photo types in the app.
class SitePhoto {
  final String id;
  final String url;
  final String storageRef; // Firebase Storage path for deletion
  final String category; // site, equipment, quote, proposal, project, instruction
  final String? siteId;
  final String? siteName;
  final String? equipmentId;
  final String? equipmentName;
  final String? reportId;
  final String? quoteId;
  final String? proposalId;
  final String? projectId;
  final String? scheduleEntryId;
  final String uploadedBy; // user display name
  final String uploadedByUid;
  final DateTime uploadedAt;
  final String? caption;
  final String? beforeAfter; // 'before', 'after', or null
  final bool pinned;
  final List<String> tags; // searchable tags

  SitePhoto({
    required this.id,
    required this.url,
    required this.storageRef,
    required this.category,
    this.siteId,
    this.siteName,
    this.equipmentId,
    this.equipmentName,
    this.reportId,
    this.quoteId,
    this.proposalId,
    this.projectId,
    this.scheduleEntryId,
    required this.uploadedBy,
    required this.uploadedByUid,
    required this.uploadedAt,
    this.caption,
    this.beforeAfter,
    this.pinned = false,
    this.tags = const [],
  });

  factory SitePhoto.fromMap(String id, Map<String, dynamic> map) {
    return SitePhoto(
      id: id,
      url: map['url'] ?? '',
      storageRef: map['storageRef'] ?? '',
      category: map['category'] ?? 'site',
      siteId: map['siteId'],
      siteName: map['siteName'],
      equipmentId: map['equipmentId'],
      equipmentName: map['equipmentName'],
      reportId: map['reportId'],
      quoteId: map['quoteId'],
      proposalId: map['proposalId'],
      projectId: map['projectId'],
      scheduleEntryId: map['scheduleEntryId'],
      uploadedBy: map['uploadedBy'] ?? '',
      uploadedByUid: map['uploadedByUid'] ?? '',
      uploadedAt: map['uploadedAt'] is Timestamp
          ? (map['uploadedAt'] as Timestamp).toDate()
          : DateTime.now(),
      caption: map['caption'],
      beforeAfter: map['beforeAfter'],
      pinned: map['pinned'] ?? false,
      tags: List<String>.from(map['tags'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'url': url,
      'storageRef': storageRef,
      'category': category,
      'uploadedBy': uploadedBy,
      'uploadedByUid': uploadedByUid,
      'uploadedAt': Timestamp.fromDate(uploadedAt),
      'pinned': pinned,
      'tags': tags,
    };
    if (siteId != null) map['siteId'] = siteId;
    if (siteName != null) map['siteName'] = siteName;
    if (equipmentId != null) map['equipmentId'] = equipmentId;
    if (equipmentName != null) map['equipmentName'] = equipmentName;
    if (reportId != null) map['reportId'] = reportId;
    if (quoteId != null) map['quoteId'] = quoteId;
    if (proposalId != null) map['proposalId'] = proposalId;
    if (projectId != null) map['projectId'] = projectId;
    if (scheduleEntryId != null) map['scheduleEntryId'] = scheduleEntryId;
    if (caption != null) map['caption'] = caption;
    if (beforeAfter != null) map['beforeAfter'] = beforeAfter;
    return map;
  }

  SitePhoto copyWith({
    String? id,
    String? url,
    String? storageRef,
    String? category,
    String? siteId,
    String? siteName,
    String? equipmentId,
    String? equipmentName,
    String? reportId,
    String? quoteId,
    String? proposalId,
    String? projectId,
    String? scheduleEntryId,
    String? uploadedBy,
    String? uploadedByUid,
    DateTime? uploadedAt,
    String? caption,
    String? beforeAfter,
    bool? pinned,
    List<String>? tags,
  }) {
    return SitePhoto(
      id: id ?? this.id,
      url: url ?? this.url,
      storageRef: storageRef ?? this.storageRef,
      category: category ?? this.category,
      siteId: siteId ?? this.siteId,
      siteName: siteName ?? this.siteName,
      equipmentId: equipmentId ?? this.equipmentId,
      equipmentName: equipmentName ?? this.equipmentName,
      reportId: reportId ?? this.reportId,
      quoteId: quoteId ?? this.quoteId,
      proposalId: proposalId ?? this.proposalId,
      projectId: projectId ?? this.projectId,
      scheduleEntryId: scheduleEntryId ?? this.scheduleEntryId,
      uploadedBy: uploadedBy ?? this.uploadedBy,
      uploadedByUid: uploadedByUid ?? this.uploadedByUid,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      caption: caption ?? this.caption,
      beforeAfter: beforeAfter ?? this.beforeAfter,
      pinned: pinned ?? this.pinned,
      tags: tags ?? this.tags,
    );
  }

  static const List<String> categories = [
    'site',
    'equipment',
    'quote',
    'proposal',
    'project',
    'instruction',
  ];
}

/// Named project album for grouping photos.
class PhotoProject {
  final String id;
  final String name;
  final String? siteId;
  final String? siteName;
  final String? description;
  final String createdBy;
  final DateTime createdAt;
  final int photoCount;

  PhotoProject({
    required this.id,
    required this.name,
    this.siteId,
    this.siteName,
    this.description,
    required this.createdBy,
    required this.createdAt,
    this.photoCount = 0,
  });

  factory PhotoProject.fromMap(String id, Map<String, dynamic> map) {
    return PhotoProject(
      id: id,
      name: map['name'] ?? '',
      siteId: map['siteId'],
      siteName: map['siteName'],
      description: map['description'],
      createdBy: map['createdBy'] ?? '',
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      photoCount: map['photoCount'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'name': name,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'photoCount': photoCount,
    };
    if (siteId != null) map['siteId'] = siteId;
    if (siteName != null) map['siteName'] = siteName;
    if (description != null) map['description'] = description;
    return map;
  }
}
