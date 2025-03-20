import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:gemini_landscaping_app/models/equipment_model.dart';
import 'package:gemini_landscaping_app/models/schedule_model.dart';
import 'package:gemini_landscaping_app/screens/add_report/add_site_report.dart';
import 'package:gemini_landscaping_app/services/schedule_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/mdi.dart';

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
    initialHeight = widget.durationSlots * 40.0; // 40.0 is timeSlotHeight
    currentHeight = initialHeight;
    print(
        'initState: initialHeight=$initialHeight, durationSlots=${widget.durationSlots}');
  }

  @override
  void didUpdateWidget(DraggableScheduleEntry oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.durationSlots != widget.durationSlots) {
      initialHeight = widget.durationSlots * 40.0;
      currentHeight = initialHeight;
      print(
          'didUpdateWidget: Updated initialHeight=$initialHeight, durationSlots=${widget.durationSlots}');
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
    print('Drag started, initialHeight=$initialHeight');
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    if (widget.userRole != 'admin') return;
    dragOffset += details.delta.dy;
    print('Dragging: delta.dy=${details.delta.dy}, dragOffset=$dragOffset');

    setState(() {
      double newHeight = initialHeight + dragOffset;
      final slotsSpanned = (newHeight / 40.0).ceil();
      final adjustedSlots = slotsSpanned < 1 ? 1 : slotsSpanned;
      newHeight = adjustedSlots * 40.0;
      currentHeight = newHeight;

      final newDurationSlots = adjustedSlots;
      final endSlotIndex = (widget.startOffset + newDurationSlots - 1).round();
      print('Updating highlight: endSlotIndex=$endSlotIndex');
      widget.onResizeHover(endSlotIndex);
    });
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    if (widget.userRole != 'admin') return;
    print('Drag ended, new height: $currentHeight');
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
      print('Resize completed: new initialHeight=$initialHeight');
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
    print('Dragging the entry started');
  }

  void _onDragEnd(DraggableDetails details) {
    if (widget.userRole != 'admin') return;
    setState(() {
      isMoving = false;
    });
    print('Dragging the entry ended');
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
                  print('Error: ScheduleEntry ID is null');
                }
              },
              child: Text('Save', style: GoogleFonts.roboto()),
            ),
          ],
        );
      },
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
                  print('Error: ScheduleEntry ID is null');
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
        ? baseColor.withOpacity(0.2) // Lighter color for completed
        : baseColor.withOpacity(0.6); // Default opacity for pending

    return Stack(
      fit: StackFit.expand,
      children: [
        Draggable<ScheduleEntry>(
          data: widget.userRole == 'admin' ? widget.entry : null,
          feedback: Material(
            elevation: 4,
            child: Container(
              width: 150,
              height: initialHeight,
              decoration: BoxDecoration(
                color: widget.truck.color.withOpacity(0.8),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AutoSizeText(
                      widget.entry.site.name,
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                    ),
                    AutoSizeText(
                      _formatDuration(
                          widget.entry.startTime, widget.entry.endTime),
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
            ),
          ),
          childWhenDragging: const SizedBox.shrink(),
          onDragStarted: _onDragStarted,
          onDragEnd: _onDragEnd,
          child: Container(
            height: currentHeight,
            decoration: BoxDecoration(
              color: displayColor,
              border: Border.all(color: Colors.white, width: 1),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AutoSizeText(
                    widget.entry.site.name,
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                    ),
                    maxLines: 1,
                  ),
                  AutoSizeText(
                    _formatDuration(
                        widget.entry.startTime, widget.entry.endTime),
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (!isMoving)
          Positioned(
            top: 2,
            left: 2, // Move to top-right corner for better balance
            child: MenuAnchor(
              builder: (context, controller, child) {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.more_vert,
                      color: Colors.black54,
                      size: 18,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                    onPressed: () {
                      if (controller.isOpen) {
                        controller.close();
                      } else {
                        controller.open();
                      }
                    },
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
                    leadingIcon: Icon(Icons.delete, color: Colors.red.shade400),
                    child: Text('Delete Schedule Entry'),
                    onPressed: () => _showDeleteConfirmationDialog(context),
                  ),
              ],
            ),
          ),
        Positioned(
          top: 4,
          right: 4,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final availableWidth = constraints.maxWidth;
              final baseIconSize = (availableWidth / 5) / 2.5;
              final iconSize = baseIconSize.clamp(10.0, 16.0);
              final splashRadius = iconSize * 1.2;
              final padding = (iconSize / 14.0) * 1.0;

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Tooltip(
                    message: 'Add/Edit Notes',
                    child: Material(
                      color: Colors.white70,
                      elevation: 1,
                      shape: CircleBorder(),
                      child: Padding(
                        padding: EdgeInsets.all(padding),
                        child: IconButton(
                          icon: widget.entry.notes != null &&
                                  widget.entry.notes != ""
                              ? Iconify(
                                  Mdi.note_alert,
                                  size: iconSize,
                                  color: Colors.pinkAccent,
                                )
                              : Iconify(
                                  Mdi.note_outline,
                                  size: iconSize,
                                  color: Colors.black54,
                                ),
                          splashRadius: splashRadius,
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints(),
                          onPressed: () => _showNotesDialog(context),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
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
                height: 15,
                color: Colors.black.withOpacity(0.3),
                child: Center(
                  child: Icon(
                    Icons.drag_handle,
                    size: 15,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
