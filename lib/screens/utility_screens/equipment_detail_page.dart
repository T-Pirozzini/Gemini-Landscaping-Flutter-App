import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gemini_landscaping_app/models/equipment_model.dart';
import 'package:gemini_landscaping_app/models/repair_entry.dart';
import 'package:gemini_landscaping_app/providers/admin_provider.dart';
import 'package:gemini_landscaping_app/screens/utility_screens/equipment_form.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class EquipmentDetailPage extends ConsumerStatefulWidget {
  final String equipmentId;

  const EquipmentDetailPage({super.key, required this.equipmentId});

  @override
  ConsumerState<EquipmentDetailPage> createState() =>
      _EquipmentDetailPageState();
}

class _EquipmentDetailPageState extends ConsumerState<EquipmentDetailPage> {
  static const _darkGreen = Color.fromARGB(255, 59, 82, 73);

  DocumentReference get _equipmentDoc => FirebaseFirestore.instance
      .collection('equipment')
      .doc(widget.equipmentId);

  CollectionReference get _repairEntries =>
      _equipmentDoc.collection('repair_entries');

  // --- Report issue ---
  void _showReportIssueSheet(Equipment equipment) {
    final descController = TextEditingController();
    final mileageController = TextEditingController(
        text: equipment.mileage != null ? '${equipment.mileage}' : '');
    var selectedPriority = 'medium';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (_, setSheetState) => Padding(
            padding: EdgeInsets.fromLTRB(
                16, 16, 16, MediaQuery.of(sheetContext).viewInsets.bottom + 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Report Issue',
                    style: GoogleFonts.montserrat(
                        fontSize: 16, fontWeight: FontWeight.w700)),
                SizedBox(height: 4),
                Text(equipment.name,
                    style: GoogleFonts.montserrat(
                        fontSize: 13, color: Colors.grey[600])),
                SizedBox(height: 12),
                TextField(
                  controller: descController,
                  maxLines: 3,
                  style: GoogleFonts.montserrat(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Describe the issue...',
                    hintStyle: GoogleFonts.montserrat(
                        fontSize: 13, color: Colors.grey[400]),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                SizedBox(height: 12),
                // Priority chips
                Text('Priority',
                    style: GoogleFonts.montserrat(
                        fontSize: 12, fontWeight: FontWeight.w600)),
                SizedBox(height: 6),
                Row(
                  children: ['low', 'medium', 'high'].map((p) {
                    final isSelected = selectedPriority == p;
                    return Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () =>
                            setSheetState(() => selectedPriority = p),
                        child: Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? _priorityColor(p).withAlpha(30)
                                : Colors.grey[100],
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? _priorityColor(p)
                                  : Colors.grey[300]!,
                            ),
                          ),
                          child: Text(
                            p[0].toUpperCase() + p.substring(1),
                            style: GoogleFonts.montserrat(
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: isSelected
                                  ? _priorityColor(p)
                                  : Colors.grey[600],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                SizedBox(height: 12),
                // Mileage (optional)
                if (_isVehicleType(equipment.equipmentType))
                  TextField(
                    controller: mileageController,
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.montserrat(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Current mileage (km)',
                      hintStyle: GoogleFonts.montserrat(
                          fontSize: 13, color: Colors.grey[400]),
                      isDense: true,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _darkGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () async {
                      if (descController.text.trim().isEmpty) return;
                      final user = FirebaseAuth.instance.currentUser;
                      final mileage = int.tryParse(mileageController.text);

                      final entry = RepairEntry(
                        id: '',
                        dateTime: DateTime.now(),
                        description: descController.text.trim(),
                        priority: selectedPriority,
                        reportedBy: user?.email ?? '',
                        mileageAtReport: mileage,
                      );
                      await _repairEntries.add(entry.toMap());

                      // Update equipment mileage if provided
                      if (mileage != null) {
                        await _equipmentDoc.update({'mileage': mileage});
                      }

                      if (mounted) Navigator.pop(sheetContext);
                    },
                    child: Text('Submit',
                        style: GoogleFonts.montserrat(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- Log service ---
  void _showLogServiceSheet(Equipment equipment) {
    final notesController = TextEditingController();
    final mileageController = TextEditingController(
        text: equipment.mileage != null ? '${equipment.mileage}' : '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(
            16, 16, 16, MediaQuery.of(sheetContext).viewInsets.bottom + 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Log Service',
                style: GoogleFonts.montserrat(
                    fontSize: 16, fontWeight: FontWeight.w700)),
            SizedBox(height: 12),
            TextField(
              controller: notesController,
              maxLines: 2,
              style: GoogleFonts.montserrat(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'What was done? (oil change, tune-up, etc.)',
                hintStyle: GoogleFonts.montserrat(
                    fontSize: 13, color: Colors.grey[400]),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
            SizedBox(height: 12),
            if (_isVehicleType(equipment.equipmentType))
              TextField(
                controller: mileageController,
                keyboardType: TextInputType.number,
                style: GoogleFonts.montserrat(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Current mileage (km)',
                  hintStyle: GoogleFonts.montserrat(
                      fontSize: 13, color: Colors.grey[400]),
                  isDense: true,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _darkGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () async {
                  final updates = <String, dynamic>{
                    'lastServiceDate': Timestamp.fromDate(DateTime.now()),
                    'lastServiceNotes': notesController.text.trim(),
                  };
                  final mileage = int.tryParse(mileageController.text);
                  if (mileage != null) updates['mileage'] = mileage;
                  await _equipmentDoc.update(updates);
                  if (mounted) Navigator.pop(sheetContext);
                },
                child: Text('Save',
                    style: GoogleFonts.montserrat(
                        fontSize: 14, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Resolve entry ---
  Future<void> _resolveEntry(RepairEntry entry) async {
    final user = FirebaseAuth.instance.currentUser;
    await _repairEntries.doc(entry.id).update({
      'priority': 'resolved',
      'resolvedBy': user?.email ?? '',
      'resolvedDate': Timestamp.fromDate(DateTime.now()),
    });
  }

  // --- Delete equipment ---
  Future<void> _deleteEquipment() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Delete Equipment'),
        content: Text('This will permanently delete this equipment and all its repair history.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed == true) {
      await _equipmentDoc.delete();
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = ref.watch(isAdminProvider);

    return StreamBuilder<DocumentSnapshot>(
      stream: _equipmentDoc.snapshots(),
      builder: (context, equipSnap) {
        if (!equipSnap.hasData || !equipSnap.data!.exists) {
          return Scaffold(
            appBar: AppBar(backgroundColor: _darkGreen),
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final equipment = Equipment.fromMap(
            equipSnap.data!.id, equipSnap.data!.data() as Map<String, dynamic>);

        return Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: AppBar(
            backgroundColor: _darkGreen,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              equipment.name,
              style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white),
            ),
            centerTitle: true,
            actions: [
              if (isAdmin)
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: Colors.white),
                  onSelected: (v) {
                    if (v == 'edit') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              EquipmentFormPage(equipment: equipment),
                        ),
                      );
                    } else if (v == 'delete') {
                      _deleteEquipment();
                    }
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(
                        value: 'delete',
                        child:
                            Text('Delete', style: TextStyle(color: Colors.red))),
                  ],
                ),
            ],
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // === HEADER CARD ===
                _buildHeaderCard(equipment),
                SizedBox(height: 12),

                // === STATUS & MILEAGE ===
                _buildStatusCard(equipment),
                SizedBox(height: 12),

                // === SERVICE LOG ===
                _buildServiceCard(equipment),
                SizedBox(height: 12),

                // === REPAIR TIMELINE ===
                _buildRepairTimeline(),

                SizedBox(height: 80),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: _darkGreen,
            foregroundColor: Colors.white,
            icon: Icon(Icons.warning_amber, size: 18),
            label: Text('Report Issue',
                style: GoogleFonts.montserrat(
                    fontSize: 13, fontWeight: FontWeight.w600)),
            onPressed: () => _showReportIssueSheet(equipment),
          ),
        );
      },
    );
  }

  // === HEADER CARD ===
  Widget _buildHeaderCard(Equipment equipment) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          // Image
          GestureDetector(
            onTap: () {
              // TODO: Image upload/change
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: equipment.imageUrl != null &&
                      equipment.imageUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: equipment.imageUrl!,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey[100],
                      child: Icon(Icons.camera_alt,
                          size: 32, color: Colors.grey[400]),
                    ),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(equipment.name,
                    style: GoogleFonts.montserrat(
                        fontSize: 16, fontWeight: FontWeight.w700)),
                SizedBox(height: 4),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.blueGrey[50],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(equipment.equipmentType,
                      style: GoogleFonts.montserrat(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.blueGrey[700])),
                ),
                SizedBox(height: 4),
                if (equipment.year > 0)
                  Text('Year: ${equipment.year}',
                      style: GoogleFonts.montserrat(
                          fontSize: 12, color: Colors.grey[600])),
                if (equipment.serialNumber.isNotEmpty)
                  Text('ID: ${equipment.serialNumber}',
                      style: GoogleFonts.montserrat(
                          fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // === STATUS CARD ===
  Widget _buildStatusCard(Equipment equipment) {
    final statusLabel = _statusLabel(equipment.currentStatus);
    final statusColor = _statusColor(equipment.currentStatus);

    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.circle, size: 10, color: statusColor),
          SizedBox(width: 8),
          Text(statusLabel,
              style: GoogleFonts.montserrat(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: statusColor)),
          Spacer(),
          if (equipment.mileage != null) ...[
            Icon(Icons.speed, size: 14, color: Colors.grey[500]),
            SizedBox(width: 4),
            Text('${equipment.mileage} km',
                style: GoogleFonts.montserrat(
                    fontSize: 13, color: Colors.grey[600])),
          ],
        ],
      ),
    );
  }

  // === SERVICE CARD ===
  Widget _buildServiceCard(Equipment equipment) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.build_outlined, size: 16, color: _darkGreen),
              SizedBox(width: 6),
              Text('LAST SERVICE',
                  style: GoogleFonts.montserrat(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _darkGreen,
                    letterSpacing: 0.6,
                  )),
              Spacer(),
              GestureDetector(
                onTap: () => _showLogServiceSheet(equipment),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _darkGreen,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('Log Service',
                      style: GoogleFonts.montserrat(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white)),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          if (equipment.lastServiceDate != null)
            Text(
              DateFormat('MMMM d, yyyy').format(equipment.lastServiceDate!),
              style: GoogleFonts.montserrat(fontSize: 13),
            )
          else
            Text('No service logged yet',
                style: GoogleFonts.montserrat(
                    fontSize: 12,
                    color: Colors.grey[400],
                    fontStyle: FontStyle.italic)),
          if (equipment.lastServiceNotes != null &&
              equipment.lastServiceNotes!.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text(equipment.lastServiceNotes!,
                  style: GoogleFonts.montserrat(
                      fontSize: 12, color: Colors.grey[600])),
            ),
        ],
      ),
    );
  }

  // === REPAIR TIMELINE ===
  Widget _buildRepairTimeline() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Icon(Icons.history, size: 16, color: _darkGreen),
              SizedBox(width: 6),
              Text('REPAIR HISTORY',
                  style: GoogleFonts.montserrat(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _darkGreen,
                    letterSpacing: 0.6,
                  )),
            ],
          ),
        ),
        StreamBuilder<QuerySnapshot>(
          stream: _repairEntries
              .orderBy('dateTime', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Center(
                  child: Text('No repair entries yet',
                      style: GoogleFonts.montserrat(
                          fontSize: 12,
                          color: Colors.grey[400],
                          fontStyle: FontStyle.italic)),
                ),
              );
            }

            final entries = snapshot.data!.docs
                .map((doc) => RepairEntry.fromMap(
                    doc.id, doc.data() as Map<String, dynamic>))
                .toList();

            return Column(
              children: entries.asMap().entries.map((mapEntry) {
                final index = mapEntry.key;
                final entry = mapEntry.value;
                final isLast = index == entries.length - 1;
                return _buildTimelineEntry(entry, isLast);
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTimelineEntry(RepairEntry entry, bool isLast) {
    final color = _priorityColor(entry.priority);
    final isResolved = entry.priority == 'resolved';
    final dateStr = DateFormat('MMM d, yyyy – h:mm a').format(entry.dateTime);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline column
          SizedBox(
            width: 24,
            child: Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(color: color.withAlpha(60), blurRadius: 4),
                    ],
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: Colors.grey[200],
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(width: 8),
          // Content
          Expanded(
            child: Container(
              margin: EdgeInsets.only(bottom: 8),
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(dateStr,
                          style: GoogleFonts.montserrat(
                              fontSize: 11, color: Colors.grey[500])),
                      Spacer(),
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withAlpha(25),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          entry.priority.toUpperCase(),
                          style: GoogleFonts.montserrat(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: color,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6),
                  Text(entry.description,
                      style: GoogleFonts.montserrat(fontSize: 13)),
                  if (entry.reportedBy.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Text('Reported by: ${entry.reportedBy}',
                          style: GoogleFonts.montserrat(
                              fontSize: 10, color: Colors.grey[400])),
                    ),
                  if (entry.linkedSiteName != null)
                    Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Row(
                        children: [
                          Icon(Icons.link, size: 10, color: Colors.blue[300]),
                          SizedBox(width: 3),
                          Text('From: ${entry.linkedSiteName}',
                              style: GoogleFonts.montserrat(
                                  fontSize: 10, color: Colors.blue[400])),
                        ],
                      ),
                    ),
                  if (isResolved && entry.resolvedBy != null)
                    Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle,
                              size: 12, color: Colors.green),
                          SizedBox(width: 4),
                          Text(
                            'Resolved by ${entry.resolvedBy}',
                            style: GoogleFonts.montserrat(
                                fontSize: 10, color: Colors.green[700]),
                          ),
                        ],
                      ),
                    ),
                  if (!isResolved)
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () => _resolveEntry(entry),
                        child: Container(
                          margin: EdgeInsets.only(top: 6),
                          padding:
                              EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.green[300]!),
                          ),
                          child: Text('Mark Resolved',
                              style: GoogleFonts.montserrat(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green[700])),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Helpers ---
  static Color _priorityColor(String priority) {
    switch (priority) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.amber[700]!;
      case 'resolved':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  static String _statusLabel(String status) {
    switch (status) {
      case 'operational':
        return 'Operational';
      case 'needs-attention':
        return 'Needs Attention';
      case 'out-of-service':
        return 'Out of Service';
      default:
        return 'Operational';
    }
  }

  static Color _statusColor(String status) {
    switch (status) {
      case 'operational':
        return Colors.green;
      case 'needs-attention':
        return Colors.amber;
      case 'out-of-service':
        return Colors.red;
      default:
        return Colors.green;
    }
  }

  static bool _isVehicleType(String type) {
    return type == 'Truck' ||
        type == 'Trailer' ||
        type == 'Vehicle (other)';
  }
}
