import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gemini_landscaping_app/models/site_photo.dart';
import 'package:gemini_landscaping_app/providers/admin_provider.dart';
import 'package:gemini_landscaping_app/screens/photos/photo_annotator.dart';
import 'package:gemini_landscaping_app/services/photo_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class PhotoViewer extends ConsumerStatefulWidget {
  final SitePhoto photo;
  const PhotoViewer({super.key, required this.photo});

  @override
  ConsumerState<PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends ConsumerState<PhotoViewer> {
  late SitePhoto _photo;

  @override
  void initState() {
    super.initState();
    _photo = widget.photo;
  }

  Future<void> _togglePin() async {
    final newPinned = !_photo.pinned;
    await PhotoService().togglePin(_photo.id, newPinned);
    setState(() => _photo = _photo.copyWith(pinned: newPinned));
  }

  Future<void> _setBeforeAfter(String? value) async {
    await PhotoService().setBeforeAfter(_photo.id, value);
    setState(() => _photo = _photo.copyWith(beforeAfter: value));
  }

  Future<void> _annotate() async {
    final path = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => PhotoAnnotator(imageUrl: _photo.url),
      ),
    );
    if (path == null || !mounted) return;

    final user = FirebaseAuth.instance.currentUser;
    final annotated = await PhotoService().uploadPhoto(
      file: File(path),
      category: _photo.category,
      uploadedBy: user?.displayName ?? 'Unknown',
      uploadedByUid: user?.uid ?? '',
      siteId: _photo.siteId,
      siteName: _photo.siteName,
      equipmentId: _photo.equipmentId,
      equipmentName: _photo.equipmentName,
      reportId: _photo.reportId,
      projectId: _photo.projectId,
      caption: _photo.caption != null
          ? '${_photo.caption} (annotated)'
          : 'Annotated',
      tags: [..._photo.tags, 'annotated'],
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Annotated photo saved')),
      );
      Navigator.pop(context, annotated);
    }
  }

  Future<void> _deletePhoto() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Photo', style: GoogleFonts.montserrat()),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await PhotoService().deletePhoto(_photo);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = ref.watch(isAdminProvider);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // Annotate
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.white, size: 20),
            tooltip: 'Annotate',
            onPressed: _annotate,
          ),
          // Pin toggle
          IconButton(
            icon: Icon(
              _photo.pinned ? Icons.push_pin : Icons.push_pin_outlined,
              color: _photo.pinned ? Colors.amber : Colors.white,
              size: 20,
            ),
            tooltip: _photo.pinned ? 'Unpin' : 'Pin',
            onPressed: _togglePin,
          ),
          // Before/After menu
          PopupMenuButton<String?>(
            icon: const Icon(Icons.label_outline, color: Colors.white, size: 20),
            tooltip: 'Before/After',
            onSelected: _setBeforeAfter,
            itemBuilder: (_) => [
              PopupMenuItem(
                value: null,
                child: Text('No Label',
                    style: TextStyle(
                        fontWeight: _photo.beforeAfter == null
                            ? FontWeight.bold
                            : FontWeight.normal)),
              ),
              PopupMenuItem(
                value: 'before',
                child: Text('Before',
                    style: TextStyle(
                        fontWeight: _photo.beforeAfter == 'before'
                            ? FontWeight.bold
                            : FontWeight.normal)),
              ),
              PopupMenuItem(
                value: 'after',
                child: Text('After',
                    style: TextStyle(
                        fontWeight: _photo.beforeAfter == 'after'
                            ? FontWeight.bold
                            : FontWeight.normal)),
              ),
            ],
          ),
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  color: Colors.white, size: 20),
              tooltip: 'Delete',
              onPressed: _deletePhoto,
            ),
        ],
      ),
      body: Column(
        children: [
          // Image
          Expanded(
            child: InteractiveViewer(
              child: Center(
                child: CachedNetworkImage(
                  imageUrl: _photo.url,
                  fit: BoxFit.contain,
                  placeholder: (_, __) =>
                      const CircularProgressIndicator(color: Colors.white),
                  errorWidget: (_, __, ___) =>
                      const Icon(Icons.broken_image, color: Colors.white),
                ),
              ),
            ),
          ),
          // Metadata bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            color: Colors.black87,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_photo.siteName != null)
                  Text(
                    _photo.siteName!,
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.person_outline,
                        size: 13, color: Colors.grey[400]),
                    const SizedBox(width: 4),
                    Text(
                      _photo.uploadedBy,
                      style: GoogleFonts.montserrat(
                        fontSize: 11,
                        color: Colors.grey[400],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.access_time,
                        size: 13, color: Colors.grey[400]),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('MMM d, yyyy  h:mm a')
                          .format(_photo.uploadedAt),
                      style: GoogleFonts.montserrat(
                        fontSize: 11,
                        color: Colors.grey[400],
                      ),
                    ),
                  ],
                ),
                if (_photo.caption != null &&
                    _photo.caption!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    _photo.caption!,
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      color: Colors.grey[300],
                    ),
                  ),
                ],
                if (_photo.beforeAfter != null) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _photo.beforeAfter == 'before'
                          ? Colors.orange
                          : Colors.green,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _photo.beforeAfter == 'before' ? 'Before' : 'After',
                      style: GoogleFonts.montserrat(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
