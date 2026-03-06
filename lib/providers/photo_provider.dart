import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gemini_landscaping_app/models/site_photo.dart';
import 'package:gemini_landscaping_app/services/photo_service.dart';

final photoServiceProvider = Provider((_) => PhotoService());

final allPhotosStreamProvider = StreamProvider<List<SitePhoto>>((ref) {
  return ref.watch(photoServiceProvider).streamAllPhotos();
});

final sitePhotosStreamProvider =
    StreamProvider.family<List<SitePhoto>, String>((ref, siteId) {
  return ref.watch(photoServiceProvider).streamPhotosBySite(siteId);
});

final categoryPhotosStreamProvider =
    StreamProvider.family<List<SitePhoto>, String>((ref, category) {
  return ref.watch(photoServiceProvider).streamPhotosByCategory(category);
});

final equipmentPhotosStreamProvider =
    StreamProvider.family<List<SitePhoto>, String>((ref, equipmentId) {
  return ref.watch(photoServiceProvider).streamPhotosByEquipment(equipmentId);
});

final reportPhotosStreamProvider =
    StreamProvider.family<List<SitePhoto>, String>((ref, reportId) {
  return ref.watch(photoServiceProvider).streamPhotosByReport(reportId);
});

final projectPhotosStreamProvider =
    StreamProvider.family<List<SitePhoto>, String>((ref, projectId) {
  return ref.watch(photoServiceProvider).streamPhotosByProject(projectId);
});

final instructionPhotosStreamProvider =
    StreamProvider.family<List<SitePhoto>, String>((ref, scheduleEntryId) {
  return ref
      .watch(photoServiceProvider)
      .streamInstructionPhotos(scheduleEntryId);
});

final pinnedPhotosStreamProvider =
    StreamProvider.family<List<SitePhoto>, String>((ref, siteId) {
  return ref.watch(photoServiceProvider).streamPinnedPhotos(siteId);
});

final photoProjectsStreamProvider =
    StreamProvider<List<PhotoProject>>((ref) {
  return ref.watch(photoServiceProvider).streamProjects();
});
