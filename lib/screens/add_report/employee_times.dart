import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gemini_landscaping_app/models/app_user.dart';
import 'package:gemini_landscaping_app/providers/user_provider.dart';

class EmployeeTimesComponent extends ConsumerStatefulWidget {
  final String? selectedName;
  final TimeOfDay initialTimeOn;
  final TimeOfDay initialTimeOff;
  final ValueChanged<String?> onNameChanged;
  final ValueChanged<TimeOfDay> onTimeOnChanged;
  final ValueChanged<TimeOfDay> onTimeOffChanged;
  final VoidCallback onDelete;

  const EmployeeTimesComponent({
    super.key,
    required this.selectedName,
    required this.initialTimeOn,
    required this.initialTimeOff,
    required this.onNameChanged,
    required this.onTimeOnChanged,
    required this.onTimeOffChanged,
    required this.onDelete,
  });

  @override
  ConsumerState<EmployeeTimesComponent> createState() =>
      _EmployeeTimesComponentState();
}

class _EmployeeTimesComponentState
    extends ConsumerState<EmployeeTimesComponent> {
  late TimeOfDay timeOn;
  late TimeOfDay timeOff;

  @override
  void initState() {
    super.initState();
    timeOn = widget.initialTimeOn;
    timeOff = widget.initialTimeOff;
  }

  String _formatTime(TimeOfDay t) =>
      '${t.hour}:${t.minute.toString().padLeft(2, '0')}';

  void _showEmployeePicker(List<AppUser> users) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Text('Select Employee',
                      style: GoogleFonts.montserrat(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                  Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(sheetContext),
                    child: Icon(Icons.close, size: 20, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
            Divider(height: 1),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: users.length + 1,
                itemBuilder: (_, i) {
                  if (i == users.length) {
                    return ListTile(
                      dense: true,
                      leading: Icon(Icons.edit, size: 18, color: Colors.grey[500]),
                      title: Text('Enter manually',
                          style: GoogleFonts.montserrat(
                              fontSize: 13, color: Colors.grey[600])),
                      onTap: () {
                        Navigator.pop(sheetContext);
                        _showManualNameEntry();
                      },
                    );
                  }
                  final isSelected = users[i].username == widget.selectedName;
                  return ListTile(
                    dense: true,
                    title: Text(
                      users[i].username,
                      style: GoogleFonts.montserrat(
                        fontSize: 13,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                    trailing: isSelected
                        ? Icon(Icons.check, color: Colors.green, size: 18)
                        : null,
                    onTap: () {
                      widget.onNameChanged(users[i].username);
                      Navigator.pop(sheetContext);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showManualNameEntry() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Enter Employee Name',
            style: GoogleFonts.montserrat(
                fontSize: 14, fontWeight: FontWeight.w600)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: GoogleFonts.montserrat(fontSize: 13),
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            hintText: 'Full name',
            hintStyle: GoogleFonts.montserrat(fontSize: 13),
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.green, width: 2),
            ),
          ),
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              widget.onNameChanged(value.trim());
              Navigator.pop(dialogContext);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Cancel', style: GoogleFonts.montserrat(fontSize: 12)),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                widget.onNameChanged(controller.text.trim());
                Navigator.pop(dialogContext);
              }
            },
            child: Text('Add',
                style: GoogleFonts.montserrat(
                    fontSize: 12, color: Colors.green[700])),
          ),
        ],
      ),
    );
  }

  void _pickTime(bool isTimeOn) {
    final current = isTimeOn ? timeOn : timeOff;

    // Generate 30-min slots from 6:00 to 19:30
    final slots = <TimeOfDay>[];
    for (var h = 6; h <= 19; h++) {
      slots.add(TimeOfDay(hour: h, minute: 0));
      slots.add(TimeOfDay(hour: h, minute: 30));
    }

    var pickerTime = DateTime(2000, 1, 1, current.hour, current.minute);

    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (sheetContext) {
        var showExact = false;
        return StatefulBuilder(
          builder: (_, setSheetState) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    children: [
                      Text(
                        isTimeOn ? 'Start Time' : 'End Time',
                        style: GoogleFonts.montserrat(
                            fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      Spacer(),
                      if (showExact)
                        GestureDetector(
                          onTap: () {
                            final picked = TimeOfDay(
                                hour: pickerTime.hour,
                                minute: pickerTime.minute);
                            setState(() {
                              if (isTimeOn) {
                                timeOn = picked;
                                widget.onTimeOnChanged(picked);
                              } else {
                                timeOff = picked;
                                widget.onTimeOffChanged(picked);
                              }
                            });
                            Navigator.pop(sheetContext);
                          },
                          child: Text('Done',
                              style: GoogleFonts.montserrat(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      Color.fromARGB(255, 31, 182, 77))),
                        )
                      else
                        GestureDetector(
                          onTap: () =>
                              setSheetState(() => showExact = true),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.tune,
                                  size: 14, color: Colors.grey[500]),
                              SizedBox(width: 4),
                              Text('Exact',
                                  style: GoogleFonts.montserrat(
                                      fontSize: 12,
                                      color: Colors.grey[500])),
                            ],
                          ),
                        ),
                      SizedBox(width: 12),
                      GestureDetector(
                        onTap: () => Navigator.pop(sheetContext),
                        child: Icon(Icons.close,
                            size: 20, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1),
                if (showExact)
                  SizedBox(
                    height: 200,
                    child: CupertinoDatePicker(
                      mode: CupertinoDatePickerMode.time,
                      use24hFormat: true,
                      initialDateTime: pickerTime,
                      onDateTimeChanged: (dt) => pickerTime = dt,
                    ),
                  )
                else
                  Padding(
                    padding: EdgeInsets.all(12),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      gridDelegate:
                          SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        childAspectRatio: 2.5,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: slots.length,
                      itemBuilder: (_, i) {
                        final slot = slots[i];
                        final isSelected = slot.hour == current.hour &&
                            slot.minute == current.minute;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              if (isTimeOn) {
                                timeOn = slot;
                                widget.onTimeOnChanged(slot);
                              } else {
                                timeOff = slot;
                                widget.onTimeOffChanged(slot);
                              }
                            });
                            Navigator.pop(sheetContext);
                          },
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Color.fromARGB(255, 31, 182, 77)
                                  : Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected
                                    ? Color.fromARGB(255, 31, 182, 77)
                                    : Colors.grey[300]!,
                              ),
                            ),
                            child: Text(
                              _formatTime(slot),
                              style: GoogleFonts.montserrat(
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isSelected
                                    ? Colors.white
                                    : Colors.black87,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(activeUsersProvider);
    final hasName = widget.selectedName != null && widget.selectedName!.isNotEmpty;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          // Name — tappable
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                usersAsync.whenData((users) => _showEmployeePicker(users));
              },
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(Icons.person_outline,
                        size: 18,
                        color: hasName ? Colors.green[700] : Colors.grey[400]),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        hasName ? widget.selectedName! : 'Select employee',
                        style: GoogleFonts.montserrat(
                          fontSize: 13,
                          fontWeight:
                              hasName ? FontWeight.w500 : FontWeight.w400,
                          color: hasName ? Colors.black87 : Colors.grey[500],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Times — tappable chips with generous targets
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _pickTime(true),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blueGrey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blueGrey[200]!),
              ),
              child: Text(
                _formatTime(timeOn),
                style: GoogleFonts.montserrat(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.blueGrey[800]),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child:
                Icon(Icons.arrow_forward, size: 12, color: Colors.grey[400]),
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _pickTime(false),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blueGrey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blueGrey[200]!),
              ),
              child: Text(
                _formatTime(timeOff),
                style: GoogleFonts.montserrat(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.blueGrey[800]),
              ),
            ),
          ),
          // Delete
          SizedBox(width: 6),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onDelete,
            child: Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.close, size: 18, color: Colors.grey[400]),
            ),
          ),
        ],
      ),
    );
  }
}
