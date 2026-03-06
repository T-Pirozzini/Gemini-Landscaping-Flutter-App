import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gemini_landscaping_app/models/site_photo.dart';
import 'package:gemini_landscaping_app/providers/photo_provider.dart';
import 'package:gemini_landscaping_app/providers/site_list_provider.dart';
import 'package:gemini_landscaping_app/screens/photos/photo_viewer.dart';
import 'package:gemini_landscaping_app/screens/photos/upload_photo_sheet.dart';
import 'package:gemini_landscaping_app/services/photo_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class PhotoBrowser extends ConsumerStatefulWidget {
  const PhotoBrowser({super.key});

  @override
  ConsumerState<PhotoBrowser> createState() => _PhotoBrowserState();
}

class _PhotoBrowserState extends ConsumerState<PhotoBrowser>
    with SingleTickerProviderStateMixin {
  static const _darkGreen = Color.fromARGB(255, 59, 82, 73);
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: _darkGreen,
        toolbarHeight: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey[400],
          indicatorColor: Colors.white,
          isScrollable: true,
          labelStyle: GoogleFonts.montserrat(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          tabs: const [
            Tab(text: 'Recent'),
            Tab(text: 'By Site'),
            Tab(text: 'Equipment'),
            Tab(text: 'Projects'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _RecentTab(),
          _BySiteTab(),
          _EquipmentTab(),
          _ProjectsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _darkGreen,
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          builder: (_) => const UploadPhotoSheet(),
        ),
        child: const Icon(Icons.add_a_photo, color: Colors.white),
      ),
    );
  }
}

// ─── Recent Tab ─────────────────────────────────────────

class _RecentTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photosAsync = ref.watch(allPhotosStreamProvider);
    return photosAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (photos) {
        if (photos.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.photo_library, size: 48, color: Colors.grey[300]),
                const SizedBox(height: 8),
                Text('No photos yet',
                    style: GoogleFonts.montserrat(
                        fontSize: 14, color: Colors.grey[400])),
                const SizedBox(height: 4),
                Text('Photos from reports will appear here',
                    style: GoogleFonts.montserrat(
                        fontSize: 11, color: Colors.grey[400])),
              ],
            ),
          );
        }
        // Group by date
        final grouped = <String, List<SitePhoto>>{};
        for (final photo in photos) {
          final key = DateFormat('MMMM d, yyyy').format(photo.uploadedAt);
          grouped.putIfAbsent(key, () => []);
          grouped[key]!.add(photo);
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: grouped.length,
          itemBuilder: (context, index) {
            final dateKey = grouped.keys.elementAt(index);
            final datePhotos = grouped[dateKey]!;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    dateKey,
                    style: GoogleFonts.montserrat(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
                _PhotoGrid(photos: datePhotos),
              ],
            );
          },
        );
      },
    );
  }
}

// ─── By Site Tab ────────────────────────────────────────

class _BySiteTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photosAsync = ref.watch(allPhotosStreamProvider);
    return photosAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (photos) {
        // Group by site
        final bySite = <String, List<SitePhoto>>{};
        for (final photo in photos) {
          if (photo.siteName != null && photo.siteName!.isNotEmpty) {
            bySite.putIfAbsent(photo.siteName!, () => []);
            bySite[photo.siteName!]!.add(photo);
          }
        }
        if (bySite.isEmpty) {
          return Center(
            child: Text('No site photos yet',
                style: GoogleFonts.montserrat(
                    fontSize: 14, color: Colors.grey[400])),
          );
        }
        final siteNames = bySite.keys.toList()..sort();
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: siteNames.length,
          itemBuilder: (context, index) {
            final siteName = siteNames[index];
            final sitePhotos = bySite[siteName]!;
            return _SitePhotoCard(
              siteName: siteName,
              photos: sitePhotos,
            );
          },
        );
      },
    );
  }
}

class _SitePhotoCard extends StatelessWidget {
  final String siteName;
  final List<SitePhoto> photos;

  const _SitePhotoCard({required this.siteName, required this.photos});

  @override
  Widget build(BuildContext context) {
    final previewPhotos = photos.take(4).toList();
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              _SitePhotoGallery(siteName: siteName, photos: photos),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    siteName,
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  '${photos.length} photo${photos.length == 1 ? '' : 's'}',
                  style: GoogleFonts.montserrat(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right, size: 18, color: Colors.grey[400]),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 70,
              child: Row(
                children: previewPhotos.map((photo) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: CachedNetworkImage(
                        imageUrl: photo.url,
                        width: 70,
                        height: 70,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          width: 70,
                          height: 70,
                          color: Colors.grey[200],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SitePhotoGallery extends StatelessWidget {
  final String siteName;
  final List<SitePhoto> photos;

  const _SitePhotoGallery({required this.siteName, required this.photos});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 59, 82, 73),
        title: Text(
          siteName,
          style: GoogleFonts.montserrat(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: _PhotoGrid(photos: photos),
      ),
    );
  }
}

// ─── Equipment Tab ──────────────────────────────────────

class _EquipmentTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photosAsync = ref.watch(categoryPhotosStreamProvider('equipment'));
    return photosAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (photos) {
        if (photos.isEmpty) {
          return Center(
            child: Text('No equipment photos yet',
                style: GoogleFonts.montserrat(
                    fontSize: 14, color: Colors.grey[400])),
          );
        }
        // Group by equipment name
        final byEquip = <String, List<SitePhoto>>{};
        for (final photo in photos) {
          final name = photo.equipmentName ?? 'Unknown';
          byEquip.putIfAbsent(name, () => []);
          byEquip[name]!.add(photo);
        }
        final names = byEquip.keys.toList()..sort();
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: names.length,
          itemBuilder: (context, index) {
            final name = names[index];
            final equipPhotos = byEquip[name]!;
            return _SitePhotoCard(
              siteName: name,
              photos: equipPhotos,
            );
          },
        );
      },
    );
  }
}

// ─── Projects Tab ───────────────────────────────────────

class _ProjectsTab extends ConsumerWidget {
  static const _darkGreen = Color.fromARGB(255, 59, 82, 73);

  void _showCreateProjectDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    String? selectedSiteId;
    String? selectedSiteName;

    showDialog(
      context: context,
      builder: (ctx) {
        final sitesAsync = ref.read(siteListProvider);
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: Text('New Project', style: GoogleFonts.montserrat()),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    style: GoogleFonts.montserrat(fontSize: 13),
                    decoration: InputDecoration(
                      labelText: 'Project Name',
                      labelStyle: GoogleFonts.montserrat(fontSize: 12),
                      isDense: true,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  sitesAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (sites) => DropdownButtonFormField<String>(
                      value: selectedSiteId,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Site (optional)',
                        labelStyle: GoogleFonts.montserrat(fontSize: 12),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 10),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      items: [
                        DropdownMenuItem<String>(
                          value: null,
                          child: Text('None',
                              style: GoogleFonts.montserrat(fontSize: 12)),
                        ),
                        ...sites.map((s) => DropdownMenuItem(
                              value: s.id,
                              child: Text(s.name,
                                  style: GoogleFonts.montserrat(fontSize: 12)),
                            )),
                      ],
                      onChanged: (val) {
                        setDialogState(() {
                          selectedSiteId = val;
                          selectedSiteName = val != null
                              ? sites.firstWhere((s) => s.id == val).name
                              : null;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: descController,
                    style: GoogleFonts.montserrat(fontSize: 13),
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Description (optional)',
                      labelStyle: GoogleFonts.montserrat(fontSize: 12),
                      isDense: true,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    if (name.isEmpty) return;
                    final user = FirebaseAuth.instance.currentUser;
                    await PhotoService().createProject(
                      name: name,
                      siteId: selectedSiteId,
                      siteName: selectedSiteName,
                      description: descController.text.trim().isEmpty
                          ? null
                          : descController.text.trim(),
                      createdBy:
                          user?.displayName ?? user?.email ?? '',
                    );
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: Text('Create',
                      style: TextStyle(color: _darkGreen)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(photoProjectsStreamProvider);
    return projectsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (projects) {
        if (projects.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.folder_open, size: 48, color: Colors.grey[300]),
                const SizedBox(height: 8),
                Text('No projects yet',
                    style: GoogleFonts.montserrat(
                        fontSize: 14, color: Colors.grey[400])),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  icon: const Icon(Icons.create_new_folder, size: 16),
                  label: Text('Create Project',
                      style: GoogleFonts.montserrat(
                          fontSize: 12, fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _darkGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () =>
                      _showCreateProjectDialog(context, ref),
                ),
              ],
            ),
          );
        }
        return Column(
          children: [
            // Create button header
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
              child: Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () =>
                      _showCreateProjectDialog(context, ref),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _darkGreen,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add, size: 14, color: Colors.white),
                        const SizedBox(width: 4),
                        Text('New Project',
                            style: GoogleFonts.montserrat(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            )),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: projects.length,
                itemBuilder: (context, index) {
                  final project = projects[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _darkGreen.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.folder, color: _darkGreen),
                      ),
                      title: Text(
                        project.name,
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        '${project.photoCount} photos${project.siteName != null ? ' • ${project.siteName}' : ''}',
                        style: GoogleFonts.montserrat(
                          fontSize: 11,
                          color: Colors.grey[500],
                        ),
                      ),
                      trailing: Icon(Icons.chevron_right,
                          color: Colors.grey[400]),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              _ProjectGallery(project: project),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ProjectGallery extends ConsumerWidget {
  final PhotoProject project;
  const _ProjectGallery({required this.project});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photosAsync = ref.watch(projectPhotosStreamProvider(project.id));
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 59, 82, 73),
        title: Text(
          project.name,
          style: GoogleFonts.montserrat(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: photosAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (photos) {
          if (photos.isEmpty) {
            return Center(
              child: Text('No photos in this project',
                  style: GoogleFonts.montserrat(
                      fontSize: 14, color: Colors.grey[400])),
            );
          }
          return Padding(
            padding: const EdgeInsets.all(12),
            child: _PhotoGrid(photos: photos),
          );
        },
      ),
    );
  }
}

// ─── Shared Photo Grid ──────────────────────────────────

class _PhotoGrid extends StatelessWidget {
  final List<SitePhoto> photos;
  const _PhotoGrid({required this.photos});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
      ),
      itemCount: photos.length,
      itemBuilder: (context, index) {
        final photo = photos[index];
        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PhotoViewer(photo: photo),
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: CachedNetworkImage(
                  imageUrl: photo.url,
                  fit: BoxFit.cover,
                  placeholder: (_, __) =>
                      Container(color: Colors.grey[200]),
                  errorWidget: (_, __, ___) =>
                      const Icon(Icons.broken_image),
                ),
              ),
              // Before/After badge
              if (photo.beforeAfter != null)
                Positioned(
                  top: 4,
                  left: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: photo.beforeAfter == 'before'
                          ? Colors.orange
                          : Colors.green,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      photo.beforeAfter == 'before' ? 'Before' : 'After',
                      style: GoogleFonts.montserrat(
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              // Pinned icon
              if (photo.pinned)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Icon(Icons.push_pin,
                      size: 14, color: Colors.amber[300]),
                ),
            ],
          ),
        );
      },
    );
  }
}
