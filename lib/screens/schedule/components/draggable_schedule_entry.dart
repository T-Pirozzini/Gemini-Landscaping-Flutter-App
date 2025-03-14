import 'package:auto_size_text/auto_size_text.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  const DraggableScheduleEntry({
    required this.entry,
    required this.truck,
    required this.startOffset,
    required this.durationSlots,
    required this.onResize,
    required this.onResizeHover,
    required this.selectedDate,
    required this.onRefresh,
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
    dragOffset = 0.0;
    print('Drag started, initialHeight=$initialHeight');
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
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
    setState(() {
      isMoving = true;
    });
    print('Dragging the entry started');
  }

  void _onDragEnd(DraggableDetails details) {
    setState(() {
      isMoving = false;
    });
    print('Dragging the entry ended');
  }

  void _repeatNextWeek() async {
    final scheduleService = ScheduleService();

    // Calculate the date for the same day next week
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

    // Create a new independent entry
    final newEntry = ScheduleEntry(
      site: widget.entry.site,
      startTime: newStartTime,
      endTime: newEndTime,
      truckId: widget.entry.truckId,
      notes: widget.entry.notes,
    );

    // Add the new entry to Firestore
    await scheduleService.addScheduleEntry(newEntry);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Entry repeated for next week!')),
    );

    // Refresh the schedule (though it only updates the current day)
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
    );
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
    return Stack(
      fit: StackFit.expand,
      children: [
        Draggable<ScheduleEntry>(
          data: widget.entry,
          feedback: Material(
            elevation: 4,
            child: Container(
              width: 150,
              height: initialHeight,
              color: widget.truck.color.withOpacity(0.8),
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
            color: widget.truck.color.withOpacity(0.5),
            height: currentHeight,
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
            top: 4,
            left: 4,
            right: 4,
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Calculate icon size based on available width
                final availableWidth = constraints.maxWidth;
                // Assume 5 buttons; allocate space evenly with some padding
                final baseIconSize =
                    (availableWidth / 5) / 2.5; // Adjust divider for padding
                // Clamp icon size between 10 and 16 pixels for usability
                final iconSize = baseIconSize.clamp(10.0, 16.0);
                // Scale splash radius and padding proportionally
                final splashRadius =
                    iconSize * 1.2; // Slightly larger than icon
                final padding =
                    (iconSize / 14.0) * 1.0; // Scale padding based on default

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Tooltip(
                      message: 'Add Site Report',
                      child: Material(
                        color: Colors.white,
                        elevation: 1,
                        shape: CircleBorder(),
                        child: Padding(
                          padding: EdgeInsets.all(padding),
                          child: IconButton(
                            icon: Icon(
                              Icons.note_add,
                              size: iconSize,
                              color: Colors.green,
                            ),
                            splashRadius: splashRadius,
                            padding: EdgeInsets.zero,
                            constraints: BoxConstraints(),
                            onPressed: () => _navigateToAddReport(context),
                          ),
                        ),
                      ),
                    ),
                    Tooltip(
                      message: 'Repeat Next Week',
                      child: Material(
                        color: Colors.white,
                        elevation: 1,
                        shape: CircleBorder(),
                        child: Padding(
                          padding: EdgeInsets.all(padding),
                          child: IconButton(
                            icon: Stack(
                              alignment: Alignment.center,
                              children: [
                                Icon(
                                  Icons.repeat,
                                  size: iconSize,
                                  color: Colors.black54,
                                ),
                                Positioned(
                                  top: 1,
                                  right: 1,
                                  child: Text(
                                    '1',
                                    style: TextStyle(
                                      fontSize: iconSize / 2,
                                      color: Colors.black54,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            splashRadius: splashRadius,
                            padding: EdgeInsets.zero,
                            constraints: BoxConstraints(),
                            onPressed: _repeatNextWeek,
                          ),
                        ),
                      ),
                    ),
                    Tooltip(
                      message: 'Add/Edit Notes',
                      child: Material(
                        color: Colors.white,
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
                                    color: widget.entry.notes != null &&
                                            widget.entry.notes != ""
                                        ? Colors.blue
                                        : Colors.black54,
                                  )
                                : Iconify(
                                    Mdi.note_outline,
                                    size: iconSize,
                                    color: widget.entry.notes != null &&
                                            widget.entry.notes != ""
                                        ? Colors.blue
                                        : Colors.black54,
                                  ),
                            splashRadius: splashRadius,
                            padding: EdgeInsets.zero,
                            constraints: BoxConstraints(),
                            onPressed: () => _showNotesDialog(context),
                          ),
                        ),
                      ),
                    ),
                    Tooltip(
                      message: 'View Site Address',
                      child: Material(
                        color: Colors.white,
                        elevation: 1,
                        shape: CircleBorder(),
                        child: Padding(
                          padding: EdgeInsets.all(padding),
                          child: IconButton(
                            icon: Icon(
                              Icons.location_on,
                              size: iconSize,
                              color: Colors.black54,
                            ),
                            splashRadius: splashRadius,
                            padding: EdgeInsets.zero,
                            constraints: BoxConstraints(),
                            onPressed: () => _showSiteAddressDialog(context),
                          ),
                        ),
                      ),
                    ),
                    Tooltip(
                      message: 'Delete Schedule Entry',
                      child: Material(
                        color: Colors.white,
                        elevation: 1,
                        shape: CircleBorder(),
                        child: Padding(
                          padding: EdgeInsets.all(padding),
                          child: IconButton(
                            icon: Icon(
                              Icons.delete,
                              size: iconSize,
                              color: Colors.red.shade400,
                            ),
                            splashRadius: splashRadius,
                            padding: EdgeInsets.zero,
                            constraints: BoxConstraints(),
                            onPressed: () =>
                                _showDeleteConfirmationDialog(context),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        if (!isMoving)
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
                color: Colors.black.withOpacity(0.3),
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
    );
  }
}
