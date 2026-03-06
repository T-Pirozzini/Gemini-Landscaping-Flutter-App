import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:gemini_landscaping_app/models/equipment_model.dart';
import 'package:gemini_landscaping_app/models/schedule_model.dart';
import 'package:gemini_landscaping_app/screens/add_report/add_site_report.dart';
import 'package:gemini_landscaping_app/screens/photos/upload_photo_sheet.dart';
import 'package:gemini_landscaping_app/services/schedule_service.dart';
import 'package:google_fonts/google_fonts.dart';

class DraggableScheduleEntry extends StatefulWidget {
  final ScheduleEntry entry;
  final Equipment truck;
  final double startOffset;
  final double durationSlots;
  final Function(ScheduleEntry, DateTime) onResize;
  final Function(int?) onResizeHover;
  final DateTime selectedDate;
  final VoidCallback onRefresh;
  final String? userRole;

  const DraggableScheduleEntry({
    required this.entry,
    required this.truck,
    required this.startOffset,
    required this.durationSlots,
    required this.onResize,
    required this.onResizeHover,
    required this.selectedDate,
    required this.onRefresh,
    this.userRole,
  });

  @override
  _DraggableScheduleEntryState createState() => _DraggableScheduleEntryState();
}

class _DraggableScheduleEntryState extends State<DraggableScheduleEntry> {
  double currentHeight;
  late double initialHeight;
  double dragOffset = 0.0;
  bool isMoving = false;

  _DraggableScheduleEntryState()
      : currentHeight = 0,
        initialHeight = 0;

  @override
  void initState() {
    super.initState();
    initialHeight = widget.durationSlots * 40.0;
    currentHeight = initialHeight;
  }

  @override
  void didUpdateWidget(DraggableScheduleEntry oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.durationSlots != widget.durationSlots) {
      initialHeight = widget.durationSlots * 40.0;
      currentHeight = initialHeight;
    }
  }

  void _onVerticalDragStart(DragStartDetails details) {
    if (widget.userRole != 'admin') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Only admins can adjust schedule entries.')),
      );
      return;
    }
    dragOffset = 0.0;
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    if (widget.userRole != 'admin') return;
    dragOffset += details.delta.dy;
    setState(() {
      double newHeight = initialHeight + dragOffset;
      final slotsSpanned = (newHeight / 40.0).ceil();
      final adjustedSlots = slotsSpanned < 1 ? 1 : slotsSpanned;
      newHeight = adjustedSlots * 40.0;
      currentHeight = newHeight;

      final newDurationSlots = adjustedSlots;
      final endSlotIndex = (widget.startOffset + newDurationSlots - 1).round();
      widget.onResizeHover(endSlotIndex);
    });
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    if (widget.userRole != 'admin') return;
    final newDurationSlots = (currentHeight / 40.0).round();
    final newEndMinutes = (widget.startOffset + newDurationSlots) * 30 + 7 * 60;
    final newHour = newEndMinutes ~/ 60;
    final newMinute = (newEndMinutes % 60).toInt();
    final newEndTime = DateTime(
      widget.selectedDate.year,
      widget.selectedDate.month,
      widget.selectedDate.day,
      newHour,
      newMinute,
    );
    if (newEndTime.isAfter(widget.entry.startTime)) {
      widget.onResize(widget.entry, newEndTime);
      // Reset dragOffset and update initialHeight for the next resize
      dragOffset = 0.0;
      initialHeight = currentHeight;
    }
    widget.onResizeHover(null);
  }

  void _onDragStarted() {
    if (widget.userRole != 'admin') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Only admins can move schedule entries.')),
      );
      return;
    }
    setState(() {
      isMoving = true;
    });
  }

  void _onDragEnd(DraggableDetails details) {
    if (widget.userRole != 'admin') return;
    setState(() {
      isMoving = false;
    });
  }

  void _repeatNextWeek() async {
    if (widget.userRole != 'admin') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Only admins can repeat entries.')),
      );
      return;
    }
    final scheduleService = ScheduleService();
    final nextWeekDate = widget.entry.startTime.add(Duration(days: 7));
    final newStartTime = DateTime(
      nextWeekDate.year,
      nextWeekDate.month,
      nextWeekDate.day,
      widget.entry.startTime.hour,
      widget.entry.startTime.minute,
    );
    final newEndTime = DateTime(
      nextWeekDate.year,
      nextWeekDate.month,
      nextWeekDate.day,
      widget.entry.endTime.hour,
      widget.entry.endTime.minute,
    );

    final newEntry = ScheduleEntry(
      site: widget.entry.site,
      startTime: newStartTime,
      endTime: newEndTime,
      truckId: widget.entry.truckId,
      notes: widget.entry.notes,
      status: widget.entry.status,
    );

    await scheduleService.addScheduleEntry(newEntry);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Entry repeated for next week!')),
    );
    widget.onRefresh();
  }

  void _showNotesDialog(BuildContext context) {
    final TextEditingController _noteController = TextEditingController(
      text: widget.entry.notes ?? '', // Pre-fill with existing notes
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Notes for ${widget.entry.site.name}',
              style: GoogleFonts.montserrat()),
          content: Container(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _noteController,
                  decoration: InputDecoration(
                    labelText: 'Notes',
                    border: OutlineInputBorder(),
                    hintText: 'Enter notes here...',
                  ),
                  maxLines: 5,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: GoogleFonts.roboto()),
            ),
            TextButton(
              onPressed: () async {
                if (widget.entry.id != null) {
                  await ScheduleService().updateScheduleEntryNotes(
                    widget.entry.id!,
                    _noteController.text.trim(),
                  );
                  widget.onRefresh(); // Refresh the schedule
                  Navigator.pop(context);
                } else {
                  debugPrint('Error: ScheduleEntry ID is null');
                }
              },
              child: Text('Save', style: GoogleFonts.roboto()),
            ),
          ],
        );
      },
    );
  }

  void _showAttachPhotosSheet(BuildContext context) {
    if (widget.entry.id == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => UploadPhotoSheet(
        preselectedSiteId: widget.entry.site.id,
        preselectedSiteName: widget.entry.site.name,
        preselectedCategory: 'instruction',
      ),
    );
  }

  void _showSiteAddressDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Address for ${widget.entry.site.name}',
              textAlign: TextAlign.center, style: GoogleFonts.montserrat()),
          content: Container(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.entry.site.address,
                  style: GoogleFonts.roboto(),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close', style: GoogleFonts.roboto()),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context) {
    if (widget.userRole != 'admin') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Only admins can delete schedule entries.')),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Confirm Deletion', style: GoogleFonts.montserrat()),
          content: Text(
            'Are you sure you want to delete the schedule entry for ${widget.entry.site.name}? This action cannot be undone.',
            style: GoogleFonts.roboto(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), // Cancel
              child: Text('Cancel', style: GoogleFonts.roboto()),
            ),
            TextButton(
              onPressed: () async {
                if (widget.entry.id != null) {
                  await ScheduleService().deleteScheduleEntry(widget.entry.id!);
                  widget.onRefresh(); // Refresh the schedule
                  Navigator.pop(context); // Close confirmation dialog
                } else {
                  debugPrint('Error: ScheduleEntry ID is null');
                }
              },
              child:
                  Text('Delete', style: GoogleFonts.roboto(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _navigateToAddReport(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddSiteReport(
          prefilledSite: widget.entry.site,
          prefilledDate: widget.entry.startTime,
          prefilledEndTime: widget.entry.endTime,
        ),
      ),
    ).then((_) async {
      // After returning from AddSiteReport, check and update status
      if (widget.entry.id != null) {
        await ScheduleService()
            .updateScheduleEntryStatus(widget.entry.id!, 'completed');
        widget.onRefresh(); // Refresh to reflect the updated status
      }
    });
  }

  // Helper method to calculate and format the duration
  String _formatDuration(DateTime startTime, DateTime endTime) {
    final duration = widget.entry.endTime.difference(widget.entry.startTime);
    final int hours = duration.inHours;
    final int minutes = duration.inMinutes % 60;
    String formattedDuration = '';
    if (hours > 0) {
      formattedDuration += '$hours hour${hours != 1 ? 's' : ''}';
    }
    if (minutes > 0) {
      if (formattedDuration.isNotEmpty) formattedDuration += ' ';
      formattedDuration += '$minutes min${minutes != 1 ? 's' : ''}';
    }
    return formattedDuration.isEmpty ? '0 mins' : formattedDuration;
  }

  @override
  Widget build(BuildContext context) {
    Color baseColor = widget.truck.color;
    Color displayColor = widget.entry.status == 'completed'
        ? baseColor.withValues(alpha: 0.4) // Lighter color for completed
        : baseColor.withValues(alpha: 0.8); // Default opacity for pending

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Draggable<ScheduleEntry>(
            data: widget.userRole == 'admin' ? widget.entry : null,
            feedback: Material(
              color: Colors.transparent,
              elevation: 6,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 150,
                height: initialHeight,
                decoration: BoxDecoration(
                  color: widget.truck.color.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: SizedBox(
                    width: 140,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AutoSizeText(
                          widget.entry.site.name,
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          textAlign: TextAlign.center,
                          minFontSize: 8,
                        ),
                        AutoSizeText(
                          _formatDuration(
                              widget.entry.startTime, widget.entry.endTime),
                          style: GoogleFonts.montserrat(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white70,
                          ),
                          maxLines: 1,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            childWhenDragging: const SizedBox.shrink(),
            onDragStarted: _onDragStarted,
            onDragEnd: _onDragEnd,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                height: currentHeight,
                decoration: BoxDecoration(
                  color: displayColor,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      offset: const Offset(0, 1),
                      blurRadius: 3,
                    ),
                  ],
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AutoSizeText(
                          widget.entry.site.name,
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          textAlign: TextAlign.center,
                          minFontSize: 8,
                        ),
                        AutoSizeText(
                          _formatDuration(
                              widget.entry.startTime, widget.entry.endTime),
                          style: GoogleFonts.montserrat(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white70,
                          ),
                          maxLines: 1,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        if (!isMoving)
          Positioned(
            top: 2,
            right: 2,
            child: MenuAnchor(
              builder: (context, controller, child) {
                final hasNotes = widget.entry.notes != null &&
                    widget.entry.notes!.isNotEmpty;
                return GestureDetector(
                  onTap: () => controller.isOpen
                      ? controller.close()
                      : controller.open(),
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Stack(
                      children: [
                        const Center(
                          child: Icon(Icons.more_vert,
                              color: Colors.white, size: 14),
                        ),
                        // Pink dot when notes or photos exist
                        if (hasNotes)
                          Positioned(
                            top: 1,
                            right: 1,
                            child: Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Colors.pinkAccent,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
              menuChildren: [
                MenuItemButton(
                  leadingIcon: Icon(Icons.note_add, color: Colors.green),
                  child: Text('Add Site Report'),
                  onPressed: () => _navigateToAddReport(context),
                ),
                if (widget.userRole == 'admin')
                  MenuItemButton(
                    leadingIcon: Icon(Icons.repeat, color: Colors.black54),
                    child: Text('Repeat Next Week'),
                    onPressed: _repeatNextWeek,
                  ),
                MenuItemButton(
                  leadingIcon:
                      widget.entry.notes != null && widget.entry.notes != ""
                          ? Icon(Icons.note, color: Colors.pinkAccent)
                          : Icon(Icons.note_outlined, color: Colors.black54),
                  child: Text('Add/Edit Notes'),
                  onPressed: () => _showNotesDialog(context),
                ),
                MenuItemButton(
                  leadingIcon: Icon(Icons.location_on, color: Colors.black54),
                  child: Text('View Site Address'),
                  onPressed: () => _showSiteAddressDialog(context),
                ),
                if (widget.userRole == 'admin')
                  MenuItemButton(
                    leadingIcon:
                        Icon(Icons.add_a_photo, color: Colors.blue[600]),
                    child: Text('Attach Work Photos'),
                    onPressed: () => _showAttachPhotosSheet(context),
                  ),
                if (widget.userRole == 'admin')
                  MenuItemButton(
                    leadingIcon: Icon(Icons.delete, color: Colors.red.shade400),
                    child: Text('Delete Schedule Entry'),
                    onPressed: () => _showDeleteConfirmationDialog(context),
                  ),
              ],
            ),
          ),
        // Completed checkmark overlay
        if (widget.entry.status == 'completed' && !isMoving)
          Positioned(
            bottom: widget.userRole == 'admin' ? 18 : 2,
            right: 2,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                Icons.check_circle,
                size: 16,
                color: Colors.green.shade700,
              ),
            ),
          ),
        if (!isMoving && widget.userRole == 'admin')
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onVerticalDragStart: _onVerticalDragStart,
              onVerticalDragUpdate: _onVerticalDragUpdate,
              onVerticalDragEnd: _onVerticalDragEnd,
              child: Container(
                height: 20,
                color: Colors.black.withValues(alpha: 0.3),
                child: Center(
                  child: Icon(
                    Icons.drag_handle,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
