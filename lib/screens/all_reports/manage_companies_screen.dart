import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:gemini_landscaping_app/models/management_company.dart';
import 'package:gemini_landscaping_app/providers/management_company_provider.dart';
import 'package:gemini_landscaping_app/services/firestore_service.dart';

class ManageCompaniesScreen extends ConsumerStatefulWidget {
  const ManageCompaniesScreen({super.key});

  @override
  ConsumerState<ManageCompaniesScreen> createState() =>
      _ManageCompaniesScreenState();
}

class _ManageCompaniesScreenState
    extends ConsumerState<ManageCompaniesScreen> {
  static const _darkGreen = Color.fromARGB(255, 59, 82, 73);
  static const _greenAccent = Color.fromARGB(255, 31, 182, 77);

  @override
  Widget build(BuildContext context) {
    final companiesAsync = ref.watch(managementCompaniesStreamProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: _darkGreen,
        title: Text(
          'Management Companies',
          style: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _darkGreen,
        onPressed: () => _showAddCompanyDialog(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: companiesAsync.when(
        data: (companies) {
          if (companies.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.business_outlined,
                      size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 8),
                  Text(
                    'No management companies yet',
                    style: GoogleFonts.montserrat(
                        fontSize: 14, color: Colors.grey.shade500),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap + to add one',
                    style: GoogleFonts.montserrat(
                        fontSize: 12, color: Colors.grey.shade400),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: companies.length,
            itemBuilder: (context, index) =>
                _buildCompanyCard(companies[index]),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildCompanyCard(ManagementCompany company) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: company.imageUrl.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: company.imageUrl,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    width: 48,
                    height: 48,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.image, color: Colors.grey),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    width: 48,
                    height: 48,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.broken_image, color: Colors.grey),
                  ),
                )
              : Container(
                  width: 48,
                  height: 48,
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.business, color: Colors.grey),
                ),
        ),
        title: Text(
          company.name,
          style: GoogleFonts.montserrat(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: IconButton(
          icon: Icon(Icons.delete_outline,
              color: Colors.red.shade400, size: 22),
          onPressed: () => _confirmDelete(company),
        ),
      ),
    );
  }

  void _showAddCompanyDialog() {
    final nameController = TextEditingController();
    File? pickedImage;
    bool isUploading = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: Text(
                'Add Management Company',
                style: GoogleFonts.montserrat(
                    fontSize: 16, fontWeight: FontWeight.w600),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Image picker
                  GestureDetector(
                    onTap: () async {
                      final picker = ImagePicker();
                      final picked = await picker.pickImage(
                        source: ImageSource.gallery,
                        maxWidth: 512,
                        maxHeight: 512,
                        imageQuality: 80,
                      );
                      if (picked != null) {
                        setDialogState(
                            () => pickedImage = File(picked.path));
                      }
                    },
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: Colors.grey.shade300),
                      ),
                      child: pickedImage != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(pickedImage!,
                                  fit: BoxFit.cover),
                            )
                          : Column(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_photo_alternate,
                                    size: 32,
                                    color: Colors.grey.shade400),
                                const SizedBox(height: 4),
                                Text(
                                  'Add Logo',
                                  style: GoogleFonts.montserrat(
                                      fontSize: 11,
                                      color: Colors.grey.shade500),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Name field
                  TextField(
                    controller: nameController,
                    style: GoogleFonts.montserrat(fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Company Name',
                      labelStyle: GoogleFonts.montserrat(fontSize: 13),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                            color: _greenAccent, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.montserrat(color: Colors.grey),
                  ),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: _darkGreen,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: isUploading
                      ? null
                      : () async {
                          final name = nameController.text.trim();
                          if (name.isEmpty) return;

                          setDialogState(() => isUploading = true);

                          try {
                            String imageUrl = '';

                            // Upload image if picked
                            if (pickedImage != null) {
                              final timestamp = DateTime.now()
                                  .millisecondsSinceEpoch;
                              final storageRef = FirebaseStorage
                                  .instance
                                  .ref()
                                  .child(
                                      'management_logos/$timestamp.jpg');
                              await storageRef.putFile(pickedImage!);
                              imageUrl =
                                  await storageRef.getDownloadURL();
                            }

                            final company = ManagementCompany(
                              id: '',
                              name: name,
                              imageUrl: imageUrl,
                            );

                            await FirestoreService()
                                .addManagementCompany(company);

                            Navigator.pop(dialogContext);
                          } catch (e) {
                            setDialogState(() => isUploading = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text('Error: $e')),
                            );
                          }
                        },
                  child: isUploading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text('Add',
                          style: GoogleFonts.montserrat(
                              fontWeight: FontWeight.w600)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDelete(ManagementCompany company) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Delete Company',
              style: GoogleFonts.montserrat(
                  fontSize: 16, fontWeight: FontWeight.w600)),
          content: Text(
            'Delete "${company.name}"? Sites using this company will no longer show a logo.',
            style: GoogleFonts.montserrat(fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child:
                  Text('Cancel', style: GoogleFonts.montserrat(color: Colors.grey)),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                Navigator.pop(dialogContext);

                // Delete image from storage if exists
                if (company.imageUrl.isNotEmpty) {
                  try {
                    final storageRef = FirebaseStorage.instance
                        .refFromURL(company.imageUrl);
                    await storageRef.delete();
                  } catch (_) {
                    // Image may already be deleted
                  }
                }

                await FirestoreService()
                    .deleteManagementCompany(company.id);
              },
              child: Text('Delete',
                  style: GoogleFonts.montserrat(fontWeight: FontWeight.w600)),
            ),
          ],
        );
      },
    );
  }
}
