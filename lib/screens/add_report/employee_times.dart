import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EmployeeTimesComponent extends StatefulWidget {
  final TextEditingController nameController;
  final TimeOfDay initialTimeOn;
  final TimeOfDay initialTimeOff;
  final ValueChanged<TimeOfDay> onTimeOnChanged;
  final ValueChanged<TimeOfDay> onTimeOffChanged;
  final VoidCallback onDelete;

  const EmployeeTimesComponent({
    super.key,
    required this.nameController,
    required this.initialTimeOn,
    required this.initialTimeOff,
    required this.onTimeOnChanged,
    required this.onTimeOffChanged,
    required this.onDelete,
  });

  @override
  State<EmployeeTimesComponent> createState() => _EmployeeTimesComponentState();
}

class _EmployeeTimesComponentState extends State<EmployeeTimesComponent> {
  late TimeOfDay timeOn;
  late TimeOfDay timeOff;

  @override
  void initState() {
    super.initState();
    timeOn = widget.initialTimeOn;
    timeOff = widget.initialTimeOff;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: TextField(
            controller: widget.nameController,
            style: GoogleFonts.montserrat(fontSize: 14),
            maxLines: null,
            keyboardType: TextInputType.text,
            decoration: const InputDecoration(
              hintText: 'Name',
              border: OutlineInputBorder(),
              contentPadding:
                  EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
            ),
          ),
        ),
        const SizedBox(width: 10),
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
