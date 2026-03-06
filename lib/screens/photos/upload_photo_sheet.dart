import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gemini_landscaping_app/providers/site_list_provider.dart';
import 'package:gemini_landscaping_app/services/photo_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

class UploadPhotoSheet extends ConsumerStatefulWidget {
  final String? preselectedSiteId;
  final String? preselectedSiteName;
  final String? preselectedCategory;
  final String? preselectedEquipmentId;
  final String? preselectedEquipmentName;
  final String? preselectedProjectId;

  const UploadPhotoSheet({
    super.key,
    this.preselectedSiteId,
    this.preselectedSiteName,
    this.preselectedCategory,
    this.preselectedEquipmentId,
    this.preselectedEquipmentName,
    this.preselectedProjectId,
  });

  @override
  ConsumerState<UploadPhotoSheet> createState() => _UploadPhotoSheetState();
}

class _UploadPhotoSheetState extends ConsumerState<UploadPhotoSheet> {
  static const _darkGreen = Color.fromARGB(255, 59, 82, 73);
  static const _greenAccent = Color.fromARGB(255, 31, 182, 77);

  final _picker = ImagePicker();
  final _captionController = TextEditingController();
  final List<File> _files = [];

  late String _category;
  String? _siteId;
  String? _siteName;
  String? _beforeAfter;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _category = widget.preselectedCategory ?? 'site';
    _siteId = widget.preselectedSiteId;
    _siteName = widget.preselectedSiteName;
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 1200,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() => _files.add(File(picked.path)));
    }
  }

  Future<void> _upload() async {
    if (_files.isEmpty) return;
    setState(() => _uploading = true);

    final user = FirebaseAuth.instance.currentUser!;
    final uploadedBy = user.displayName ?? user.email ?? '';
    final caption = _captionController.text.trim().isEmpty
        ? null
        : _captionController.text.trim();

    try {
      for (final file in _files) {
        await PhotoService().uploadPhoto(
          file: file,
          category: _category,
          uploadedBy: uploadedBy,
          uploadedByUid: user.uid,
          siteId: _siteId,
          siteName: _siteName,
          equipmentId: widget.preselectedEquipmentId,
          equipmentName: widget.preselectedEquipmentName,
          projectId: widget.preselectedProjectId,
          caption: caption,
          beforeAfter: _beforeAfter,
          tags: [_category],
        );
      }
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Uploaded ${_files.length} photo${_files.length == 1 ? '' : 's'}'),
          ),
        );
      }
    } catch (e) {
      setState(() => _uploading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sitesAsync = ref.watch(siteListProvider);

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Text(
                  'Upload Photo',
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Category selector
            Text('Category',
                style: GoogleFonts.montserrat(
                    fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              children: [
                _categoryChip('site', 'Site'),
                _categoryChip('equipment', 'Equipment'),
                _categoryChip('project', 'Project'),
              ],
            ),
            const SizedBox(height: 12),

            // Site picker
            if (_category == 'site' || _category == 'project')
              sitesAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (sites) {
                  return DropdownButtonFormField<String>(
                    value: _siteId,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Site',
                      labelStyle: GoogleFonts.montserrat(fontSize: 12),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 10),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    items: sites.map((site) {
                      return DropdownMenuItem(
                        value: site.id,
                        child: Text(site.name,
                            style: GoogleFonts.montserrat(fontSize: 12)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      final site = sites.firstWhere((s) => s.id == val);
                      setState(() {
                        _siteId = val;
                        _siteName = site.name;
                      });
                    },
                  );
                },
              ),

            const SizedBox(height: 12),

            // Before/After toggle
            Text('Label (optional)',
                style: GoogleFonts.montserrat(
                    fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              children: [
                _labelChip(null, 'None'),
                _labelChip('before', 'Before'),
                _labelChip('after', 'After'),
              ],
            ),
            const SizedBox(height: 12),

            // Caption
            TextField(
              controller: _captionController,
              style: GoogleFonts.montserrat(fontSize: 12),
              decoration: InputDecoration(
                labelText: 'Caption (optional)',
                labelStyle: GoogleFonts.montserrat(fontSize: 12),
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 12),

            // Photo picker row
            Row(
              children: [
                _sourceButton(Icons.camera_alt, 'Camera', ImageSource.camera),
                const SizedBox(width: 10),
                _sourceButton(
                    Icons.photo_library, 'Gallery', ImageSource.gallery),
              ],
            ),

            // Preview thumbnails
            if (_files.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 80,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _files.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            _files[index],
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 2,
                          right: 2,
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _files.removeAt(index)),
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              padding: const EdgeInsets.all(3),
                              child: const Icon(Icons.close,
                                  size: 12, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 16),

            // Upload button
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                icon: _uploading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.cloud_upload, size: 18),
                label: Text(
                  _uploading
                      ? 'Uploading...'
                      : 'Upload ${_files.length} Photo${_files.length == 1 ? '' : 's'}',
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _darkGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed:
                    _files.isEmpty || _uploading ? null : _upload,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _categoryChip(String value, String label) {
    final selected = _category == value;
    return ChoiceChip(
      label: Text(label,
          style: GoogleFonts.montserrat(
            fontSize: 11,
            color: selected ? Colors.white : Colors.grey[700],
          )),
      selected: selected,
      selectedColor: _darkGreen,
      backgroundColor: Colors.grey[200],
      showCheckmark: false,
      onSelected: (_) => setState(() => _category = value),
    );
  }

  Widget _labelChip(String? value, String label) {
    final selected = _beforeAfter == value;
    final chipColor = value == 'before'
        ? Colors.orange
        : value == 'after'
            ? _greenAccent
            : Colors.grey[600]!;
    return ChoiceChip(
      label: Text(label,
          style: GoogleFonts.montserrat(
            fontSize: 11,
            color: selected ? Colors.white : Colors.grey[700],
          )),
      selected: selected,
      selectedColor: chipColor,
      backgroundColor: Colors.grey[200],
      showCheckmark: false,
      onSelected: (_) => setState(() => _beforeAfter = value),
    );
  }

  Widget _sourceButton(
      IconData icon, String label, ImageSource source) {
    return Expanded(
      child: OutlinedButton.icon(
        icon: Icon(icon, size: 16, color: _darkGreen),
        label: Text(label,
            style: GoogleFonts.montserrat(
                fontSize: 11, color: _darkGreen)),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.grey[300]!),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(vertical: 10),
        ),
        onPressed: () => _pickImage(source),
      ),
    );
  }
}
