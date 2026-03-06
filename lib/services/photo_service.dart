import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:gemini_landscaping_app/models/site_photo.dart';

class PhotoService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  CollectionReference get _photosCol => _db.collection('Photos');
  CollectionReference get _projectsCol => _db.collection('PhotoProjects');

  // ─── Upload ───────────────────────────────────────────

  /// Upload a photo file and create the Firestore document.
  /// Returns the created SitePhoto.
  Future<SitePhoto> uploadPhoto({
    required File file,
    required String category,
    required String uploadedBy,
    required String uploadedByUid,
    String? siteId,
    String? siteName,
    String? equipmentId,
    String? equipmentName,
    String? reportId,
    String? quoteId,
    String? proposalId,
    String? projectId,
    String? scheduleEntryId,
    String? caption,
    String? beforeAfter,
    List<String> tags = const [],
  }) async {
    final timestamp = DateTime.now();
    final fileName = '${timestamp.millisecondsSinceEpoch}.jpg';

    // Build storage path based on category
    String storagePath;
    if (category == 'equipment' && equipmentId != null) {
      storagePath = 'photos/equipment/$equipmentId/$fileName';
    } else if (siteId != null) {
      storagePath = 'photos/sites/$siteId/$fileName';
    } else {
      storagePath = 'photos/general/$fileName';
    }

    // Upload to Firebase Storage
    final ref = _storage.ref().child(storagePath);
    await ref.putFile(file);
    final url = await ref.getDownloadURL();

    // Create Firestore document
    final photo = SitePhoto(
      id: '',
      url: url,
      storageRef: storagePath,
      category: category,
      siteId: siteId,
      siteName: siteName,
      equipmentId: equipmentId,
      equipmentName: equipmentName,
      reportId: reportId,
      quoteId: quoteId,
      proposalId: proposalId,
      projectId: projectId,
      scheduleEntryId: scheduleEntryId,
      uploadedBy: uploadedBy,
      uploadedByUid: uploadedByUid,
      uploadedAt: timestamp,
      caption: caption,
      beforeAfter: beforeAfter,
      tags: tags,
    );

    final docRef = await _photosCol.add(photo.toMap());

    // Increment project photo count if applicable
    if (projectId != null) {
      await _projectsCol
          .doc(projectId)
          .update({'photoCount': FieldValue.increment(1)});
    }

    return photo.copyWith(id: docRef.id);
  }

  /// Upload multiple photos in batch (e.g. from report submission).
  Future<List<SitePhoto>> uploadMultiple({
    required List<File> files,
    required String category,
    required String uploadedBy,
    required String uploadedByUid,
    String? siteId,
    String? siteName,
    String? reportId,
    String? beforeAfter,
    List<String> tags = const [],
  }) async {
    final results = <SitePhoto>[];
    for (final file in files) {
      final photo = await uploadPhoto(
        file: file,
        category: category,
        uploadedBy: uploadedBy,
        uploadedByUid: uploadedByUid,
        siteId: siteId,
        siteName: siteName,
        reportId: reportId,
        beforeAfter: beforeAfter,
        tags: tags,
      );
      results.add(photo);
    }
    return results;
  }

  // ─── Fetch ────────────────────────────────────────────

  /// Stream all photos, newest first.
  Stream<List<SitePhoto>> streamAllPhotos() {
    return _photosCol
        .orderBy('uploadedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) =>
                SitePhoto.fromMap(doc.id, doc.data() as Map<String, dynamic>))
            .toList());
  }

  /// Stream photos for a specific site.
  Stream<List<SitePhoto>> streamPhotosBySite(String siteId) {
    return _photosCol
        .where('siteId', isEqualTo: siteId)
        .orderBy('uploadedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) =>
                SitePhoto.fromMap(doc.id, doc.data() as Map<String, dynamic>))
            .toList());
  }

  /// Stream photos for a specific category.
  Stream<List<SitePhoto>> streamPhotosByCategory(String category) {
    return _photosCol
        .where('category', isEqualTo: category)
        .orderBy('uploadedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) =>
                SitePhoto.fromMap(doc.id, doc.data() as Map<String, dynamic>))
            .toList());
  }

  /// Stream photos for specific equipment.
  Stream<List<SitePhoto>> streamPhotosByEquipment(String equipmentId) {
    return _photosCol
        .where('equipmentId', isEqualTo: equipmentId)
        .orderBy('uploadedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) =>
                SitePhoto.fromMap(doc.id, doc.data() as Map<String, dynamic>))
            .toList());
  }

  /// Stream photos for a specific report.
  Stream<List<SitePhoto>> streamPhotosByReport(String reportId) {
    return _photosCol
        .where('reportId', isEqualTo: reportId)
        .orderBy('uploadedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) =>
                SitePhoto.fromMap(doc.id, doc.data() as Map<String, dynamic>))
            .toList());
  }

  /// Stream photos for a project album.
  Stream<List<SitePhoto>> streamPhotosByProject(String projectId) {
    return _photosCol
        .where('projectId', isEqualTo: projectId)
        .orderBy('uploadedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) =>
                SitePhoto.fromMap(doc.id, doc.data() as Map<String, dynamic>))
            .toList());
  }

  /// Stream work instruction photos for a schedule entry.
  Stream<List<SitePhoto>> streamInstructionPhotos(String scheduleEntryId) {
    return _photosCol
        .where('scheduleEntryId', isEqualTo: scheduleEntryId)
        .where('category', isEqualTo: 'instruction')
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) =>
                SitePhoto.fromMap(doc.id, doc.data() as Map<String, dynamic>))
            .toList());
  }

  /// Fetch pinned photos for a site.
  Stream<List<SitePhoto>> streamPinnedPhotos(String siteId) {
    return _photosCol
        .where('siteId', isEqualTo: siteId)
        .where('pinned', isEqualTo: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) =>
                SitePhoto.fromMap(doc.id, doc.data() as Map<String, dynamic>))
            .toList());
  }

  // ─── Update ───────────────────────────────────────────

  Future<void> updateCaption(String photoId, String caption) {
    return _photosCol.doc(photoId).update({'caption': caption});
  }

  Future<void> togglePin(String photoId, bool pinned) {
    return _photosCol.doc(photoId).update({'pinned': pinned});
  }

  Future<void> setBeforeAfter(String photoId, String? beforeAfter) {
    return _photosCol.doc(photoId).update({'beforeAfter': beforeAfter});
  }

  Future<void> updateTags(String photoId, List<String> tags) {
    return _photosCol.doc(photoId).update({'tags': tags});
  }

  // ─── Delete ───────────────────────────────────────────

  Future<void> deletePhoto(SitePhoto photo) async {
    // Delete from Storage
    try {
      await _storage.ref().child(photo.storageRef).delete();
    } catch (_) {
      // Storage file may already be deleted
    }
    // Delete Firestore doc
    await _photosCol.doc(photo.id).delete();
    // Decrement project count
    if (photo.projectId != null) {
      await _projectsCol
          .doc(photo.projectId)
          .update({'photoCount': FieldValue.increment(-1)});
    }
  }

  // ─── Projects ─────────────────────────────────────────

  Stream<List<PhotoProject>> streamProjects() {
    return _projectsCol
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) =>
                PhotoProject.fromMap(doc.id, doc.data() as Map<String, dynamic>))
            .toList());
  }

  Future<PhotoProject> createProject({
    required String name,
    String? siteId,
    String? siteName,
    String? description,
    required String createdBy,
  }) async {
    final project = PhotoProject(
      id: '',
      name: name,
      siteId: siteId,
      siteName: siteName,
      description: description,
      createdBy: createdBy,
      createdAt: DateTime.now(),
    );
    final docRef = await _projectsCol.add(project.toMap());
    return PhotoProject(
      id: docRef.id,
      name: name,
      siteId: siteId,
      siteName: siteName,
      description: description,
      createdBy: createdBy,
      createdAt: project.createdAt,
    );
  }

  Future<void> deleteProject(String projectId) async {
    // Delete all photos in the project
    final photos = await _photosCol
        .where('projectId', isEqualTo: projectId)
        .get();
    for (final doc in photos.docs) {
      final photo =
          SitePhoto.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      try {
        await _storage.ref().child(photo.storageRef).delete();
      } catch (_) {}
      await doc.reference.delete();
    }
    await _projectsCol.doc(projectId).delete();
  }
}
