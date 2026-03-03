import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gemini_landscaping_app/models/equipment_model.dart';
import 'package:gemini_landscaping_app/providers/admin_provider.dart';
import 'package:gemini_landscaping_app/screens/utility_screens/equipment_detail_page.dart';
import 'package:gemini_landscaping_app/screens/utility_screens/equipment_form.dart';
import 'package:google_fonts/google_fonts.dart';

class EquipmentPage extends ConsumerWidget {
  const EquipmentPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = ref.watch(isAdminProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Equipment',
          style: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: Color.fromARGB(255, 59, 82, 73),
        centerTitle: true,
        toolbarHeight: 36,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('equipment').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading equipment',
                  style: GoogleFonts.montserrat(color: Colors.red)),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.build_outlined, size: 48, color: Colors.grey[300]),
                  SizedBox(height: 12),
                  Text('No equipment added yet',
                      style: GoogleFonts.montserrat(
                          fontSize: 14, color: Colors.grey[500])),
                ],
              ),
            );
          }

          final equipmentList = docs
              .map((doc) =>
                  Equipment.fromMap(doc.id, doc.data() as Map<String, dynamic>))
              .toList();

          return ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            itemCount: equipmentList.length,
            itemBuilder: (context, index) {
              final eq = equipmentList[index];
              return _EquipmentCard(equipment: eq);
            },
          );
        },
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              backgroundColor: Color.fromARGB(255, 59, 82, 73),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => EquipmentFormPage()),
              ),
              child: Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }
}

class _EquipmentCard extends StatelessWidget {
  final Equipment equipment;

  const _EquipmentCard({required this.equipment});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('equipment')
          .doc(equipment.id)
          .collection('repair_entries')
          .snapshots(),
      builder: (context, repairSnapshot) {
        // Determine highest priority from active (non-resolved) entries
        String topPriority = 'none';
        int activeCount = 0;
        if (repairSnapshot.hasData) {
          for (var doc in repairSnapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final p = data['priority'] as String? ?? 'resolved';
            if (p != 'resolved') {
              activeCount++;
              if (p == 'high') {
                topPriority = 'high';
              } else if (p == 'medium' && topPriority != 'high') {
                topPriority = 'medium';
              } else if (p == 'low' &&
                  topPriority != 'high' &&
                  topPriority != 'medium') {
                topPriority = 'low';
              }
            }
          }
        }

        final statusColor = _statusDotColor(equipment.currentStatus);
        final priorityColor = _priorityBorderColor(topPriority);

        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EquipmentDetailPage(equipmentId: equipment.id),
            ),
          ),
          child: Container(
            margin: EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: topPriority != 'none' ? priorityColor : Colors.grey[200]!,
                width: topPriority != 'none' ? 1.5 : 1,
              ),
            ),
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Row(
                children: [
                  // Equipment image or placeholder
                  _buildImage(),
                  SizedBox(width: 12),
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                equipment.name,
                                style: GoogleFonts.montserrat(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // Status dot
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: statusColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            _typeBadge(equipment.equipmentType),
                            SizedBox(width: 6),
                            if (equipment.year > 0)
                              Text(
                                '${equipment.year}',
                                style: GoogleFonts.montserrat(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            if (equipment.mileage != null) ...[
                              Icon(Icons.speed,
                                  size: 12, color: Colors.grey[400]),
                              SizedBox(width: 3),
                              Text(
                                '${equipment.mileage} km',
                                style: GoogleFonts.montserrat(
                                  fontSize: 11,
                                  color: Colors.grey[500],
                                ),
                              ),
                              SizedBox(width: 10),
                            ],
                            if (activeCount > 0) ...[
                              Icon(Icons.warning_amber,
                                  size: 12, color: priorityColor),
                              SizedBox(width: 3),
                              Text(
                                '$activeCount active issue${activeCount != 1 ? 's' : ''}',
                                style: GoogleFonts.montserrat(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: priorityColor,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Arrow
                  Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildImage() {
    if (equipment.imageUrl != null && equipment.imageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: equipment.imageUrl!,
          width: 56,
          height: 56,
          fit: BoxFit.cover,
          placeholder: (_, __) =>
              Container(width: 56, height: 56, color: Colors.grey[200]),
          errorWidget: (_, __, ___) => _placeholderIcon(),
        ),
      );
    }
    return _placeholderIcon();
  }

  Widget _placeholderIcon() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        _iconForType(equipment.equipmentType),
        size: 28,
        color: Colors.grey[400],
      ),
    );
  }

  Widget _typeBadge(String type) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.blueGrey[50],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        type,
        style: GoogleFonts.montserrat(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: Colors.blueGrey[700],
        ),
      ),
    );
  }

  static IconData _iconForType(String type) {
    switch (type) {
      case 'Truck':
      case 'Vehicle (other)':
        return Icons.local_shipping;
      case 'Trailer':
        return Icons.rv_hookup;
      case 'Mower (push)':
      case 'Mower (ride-on)':
        return Icons.grass;
      case 'Blower':
        return Icons.air;
      case 'Trimmer':
      case 'Hedger':
      case 'Edger':
        return Icons.content_cut;
      case 'Tool (other)':
        return Icons.build;
      case 'Machine (other)':
        return Icons.precision_manufacturing;
      default:
        return Icons.handyman;
    }
  }

  static Color _statusDotColor(String status) {
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

  static Color _priorityBorderColor(String priority) {
    switch (priority) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.amber;
      default:
        return Colors.grey[300]!;
    }
  }
}
