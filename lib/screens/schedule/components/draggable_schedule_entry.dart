import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:gemini_landscaping_app/models/equipment_model.dart';
import 'package:gemini_landscaping_app/models/schedule_model.dart';
import 'package:google_fonts/google_fonts.dart';

class DraggableScheduleEntry extends StatefulWidget {
  final ScheduleEntry entry;
  final Equipment truck;
  final double startOffset;
  final double durationSlots;
  final Function(ScheduleEntry, DateTime) onResize;
  final Function(int?) onResizeHover;
  final DateTime selectedDate;

  const DraggableScheduleEntry({
    required this.entry,
    required this.truck,
    required this.startOffset,
    required this.durationSlots,
    required this.onResize,
    required this.onResizeHover,
    required this.selectedDate,
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
                child: AutoSizeText(
                  widget.entry.site.name,
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    color: Colors.white,
                  ),
                  maxLines: 1,
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
              child: AutoSizeText(
                widget.entry.site.name,
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                ),
                maxLines: 1,
              ),
            ),
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
