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

  Future<void> _pickTime(bool isTimeOn) async {
    final initial = isTimeOn ? timeOn : timeOff;
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (picked != null) {
      setState(() {
        if (isTimeOn) {
          timeOn = picked;
          widget.onTimeOnChanged(picked);
        } else {
          timeOff = picked;
          widget.onTimeOffChanged(picked);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(activeUsersProvider);
    final hasName = widget.selectedName != null && widget.selectedName!.isNotEmpty;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Name — tappable
          Expanded(
            child: GestureDetector(
              onTap: () {
                usersAsync.whenData((users) => _showEmployeePicker(users));
              },
              child: Row(
                children: [
                  Icon(Icons.person_outline,
                      size: 16,
                      color: hasName ? Colors.green[700] : Colors.grey[400]),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      hasName ? widget.selectedName! : 'Select employee',
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        fontWeight: hasName ? FontWeight.w500 : FontWeight.w400,
                        color: hasName ? Colors.black87 : Colors.grey[500],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Times — compact tappable chips
          GestureDetector(
            onTap: () => _pickTime(true),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _formatTime(timeOn),
                style: GoogleFonts.montserrat(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.green[800]),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 3),
            child: Icon(Icons.arrow_forward, size: 10, color: Colors.grey[400]),
          ),
          GestureDetector(
            onTap: () => _pickTime(false),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _formatTime(timeOff),
                style: GoogleFonts.montserrat(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.red[800]),
              ),
            ),
          ),
          // Delete
          SizedBox(width: 4),
          GestureDetector(
            onTap: widget.onDelete,
            child: Icon(Icons.close, size: 16, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }
}
