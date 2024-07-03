import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EmployeeTimesComponent extends StatefulWidget {
  final TextEditingController nameController;
  final TimeOfDay initialTimeOn;
  final TimeOfDay initialTimeOff;
  final ValueChanged<TimeOfDay> onTimeOnChanged;
  final ValueChanged<TimeOfDay> onTimeOffChanged;
  const EmployeeTimesComponent(
      {super.key,
      required this.nameController,
      required this.initialTimeOn,
      required this.initialTimeOff,
      required this.onTimeOnChanged,
      required this.onTimeOffChanged});

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
      children: [
        Expanded(
          child: Container(
            width: 100,
            height: 40,
            child: TextField(
              controller: widget.nameController,
              style: GoogleFonts.montserrat(fontSize: 14),
              maxLines: null,
              keyboardType: TextInputType.text,
              decoration: const InputDecoration(
                hintText: 'Name',
              ),
            ),
          ),
        ),
        Column(
          children: [
            const Text("ON", style: TextStyle(fontWeight: FontWeight.bold)),
            Container(
              width: 100,
              height: 30,
              child: FloatingActionButton.extended(
                heroTag: null,
                icon: const Icon(Icons.access_time_outlined),
                label: Text('${timeOn.hour}:${timeOn.minute.toString().padLeft(2, '0')}'),
                backgroundColor: const Color.fromARGB(255, 31, 182, 77),
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
            Container(
              width: 100,
              height: 30,
              child: FloatingActionButton.extended(
                heroTag: null,
                icon: const Icon(Icons.access_time_outlined),
                label: Text('${timeOff.hour}:${timeOff.minute.toString().padLeft(2, '0')}'),
                backgroundColor: const Color.fromARGB(255, 31, 182, 77),
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
      ],
    );
  }
}
