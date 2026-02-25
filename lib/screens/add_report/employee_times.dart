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

  void _showEmployeePicker(List<AppUser> users) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: users.length,
          itemBuilder: (_, i) => ListTile(
            contentPadding:
                EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            title: Text(
              users[i].username,
              style: GoogleFonts.montserrat(fontSize: 16),
            ),
            trailing: users[i].username == widget.selectedName
                ? Icon(Icons.check, color: Colors.green)
                : null,
            onTap: () {
              widget.onNameChanged(users[i].username);
              Navigator.pop(context);
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(activeUsersProvider);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Employee name selector
        Expanded(
          child: GestureDetector(
            onTap: () {
              usersAsync.whenData((users) => _showEmployeePicker(users));
            },
            child: InputDecorator(
              decoration: InputDecoration(
                hintText: 'Select Employee',
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
                suffixIcon: Icon(Icons.arrow_drop_down, size: 20),
              ),
              child: Text(
                widget.selectedName ?? '',
                style: GoogleFonts.montserrat(fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Time ON
        Column(
          children: [
            const Text("ON", style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(
              width: 100,
              height: 30,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.access_time_outlined, size: 16),
                label: Text(
                  '${timeOn.hour}:${timeOn.minute.toString().padLeft(2, '0')}',
                  style: GoogleFonts.montserrat(fontSize: 14),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 31, 182, 77),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  textStyle: GoogleFonts.montserrat(fontSize: 14),
                ),
                onPressed: () async {
                  TimeOfDay? newTimeOn = await showTimePicker(
                    context: context,
                    initialTime: timeOn,
                  );
                  if (newTimeOn != null) {
                    setState(() {
                      timeOn = newTimeOn;
                      widget.onTimeOnChanged(newTimeOn);
                    });
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(width: 10),
        // Time OFF
        Column(
          children: [
            const Text("OFF", style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(
              width: 100,
              height: 30,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.access_time_outlined, size: 16),
                label: Text(
                  '${timeOff.hour}:${timeOff.minute.toString().padLeft(2, '0')}',
                  style: GoogleFonts.montserrat(fontSize: 14),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 31, 182, 77),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  textStyle: GoogleFonts.montserrat(fontSize: 14),
                ),
                onPressed: () async {
                  TimeOfDay? newTimeOff = await showTimePicker(
                    context: context,
                    initialTime: timeOff,
                  );
                  if (newTimeOff != null) {
                    setState(() {
                      timeOff = newTimeOff;
                      widget.onTimeOffChanged(newTimeOff);
                    });
                  }
                },
              ),
            ),
          ],
        ),
        SizedBox(
          width: 20,
          child: IconButton(
            padding: EdgeInsets.zero,
            icon: const Icon(
              Icons.delete,
              color: Colors.grey,
              size: 24,
            ),
            onPressed: widget.onDelete,
          ),
        ),
      ],
    );
  }
}
