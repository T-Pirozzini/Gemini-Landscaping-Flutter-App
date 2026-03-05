import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gemini_landscaping_app/models/admin_notification.dart';
import 'package:gemini_landscaping_app/providers/admin_notification_provider.dart';
import 'package:gemini_landscaping_app/services/firestore_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class AdminNotificationsScreen extends ConsumerStatefulWidget {
  const AdminNotificationsScreen({super.key});

  @override
  ConsumerState<AdminNotificationsScreen> createState() =>
      _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState
    extends ConsumerState<AdminNotificationsScreen> {
  static const _darkGreen = Color.fromARGB(255, 59, 82, 73);
  static const _greenAccent = Color.fromARGB(255, 31, 182, 77);

  String _filter = 'pending'; // 'pending', 'approved', 'dismissed', 'all'

  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(adminNotificationsStreamProvider);

    return Column(
      children: [
        // Filter chips
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Row(
            children: ['pending', 'approved', 'dismissed', 'all']
                .map((f) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: ChoiceChip(
                          label: SizedBox(
                            width: double.infinity,
                            child: Text(
                              f[0].toUpperCase() + f.substring(1),
                              textAlign: TextAlign.center,
                              style: GoogleFonts.montserrat(
                                fontSize: 11,
                                fontWeight: _filter == f
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color:
                                    _filter == f ? Colors.white : _darkGreen,
                              ),
                            ),
                          ),
                          selected: _filter == f,
                          selectedColor: _darkGreen,
                          backgroundColor: Colors.white,
                          side: BorderSide(
                            color: _filter == f
                                ? _darkGreen
                                : Colors.grey.shade300,
                          ),
                          onSelected: (_) => setState(() => _filter = f),
                          showCheckmark: false,
                        ),
                      ),
                    ))
                .toList(),
          ),
        ),
        Expanded(
          child: notificationsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (notifications) {
              final filtered = _filter == 'all'
                  ? notifications
                  : notifications
                      .where((n) => n.status == _filter)
                      .toList();

              if (filtered.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_none,
                          size: 48, color: Colors.grey.shade300),
                      const SizedBox(height: 8),
                      Text(
                        'No ${_filter == 'all' ? '' : '$_filter '}notifications',
                        style: GoogleFonts.montserrat(
                            fontSize: 13, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: filtered.length,
                itemBuilder: (context, index) =>
                    _buildNotificationTile(filtered[index]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationTile(AdminNotification notification) {
    final isPending = notification.status == 'pending';
    final isApproved = notification.status == 'approved';

    Color statusColor;
    IconData statusIcon;
    if (isPending) {
      statusColor = Colors.orange;
      statusIcon = Icons.pending_actions;
    } else if (isApproved) {
      statusColor = _greenAccent;
      statusIcon = Icons.check_circle;
    } else {
      statusColor = Colors.grey;
      statusIcon = Icons.cancel_outlined;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isPending
            ? Border.all(color: Colors.orange.withValues(alpha: 0.4))
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(statusIcon, size: 18, color: statusColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Service Program Detected',
                    style: GoogleFonts.montserrat(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _darkGreen,
                    ),
                  ),
                ),
                Text(
                  DateFormat('MMM d').format(notification.createdAt),
                  style: GoogleFonts.montserrat(
                    fontSize: 10,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Details
            _detailRow('Site', notification.siteName),
            _detailRow('Program', notification.programName),
            _detailRow('Detected', '"${notification.detectedService}"'),
            _detailRow('Report Date', notification.reportDate),
            if (notification.resolvedAt != null)
              _detailRow(
                isApproved ? 'Approved' : 'Dismissed',
                DateFormat('MMM d, yyyy').format(notification.resolvedAt!),
              ),
            // Actions for pending
            if (isPending) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => _dismiss(notification),
                    child: Text('Dismiss',
                        style: GoogleFonts.montserrat(
                            fontSize: 12, color: Colors.grey.shade600)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _approve(notification),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _greenAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text('Approve',
                        style: GoogleFonts.montserrat(fontSize: 12)),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: GoogleFonts.montserrat(
                  fontSize: 11, color: Colors.grey.shade600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.montserrat(
                  fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _approve(AdminNotification notification) async {
    await FirestoreService().approveNotificationWithLookup(notification);
  }

  Future<void> _dismiss(AdminNotification notification) async {
    await FirestoreService().dismissNotification(notification.id);
  }
}
