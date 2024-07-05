import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class DatePickerComponent extends StatefulWidget {
  final TextEditingController dateController;

  const DatePickerComponent({super.key, required this.dateController});

  @override
  State<DatePickerComponent> createState() => _DatePickerComponentState();
}

class _DatePickerComponentState extends State<DatePickerComponent> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        DateTime? pickedDate = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2101),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(
                  primary: Colors.green,
                  onPrimary: Colors.white,
                  onSurface: Colors.black,
                ),
              ),
              child: child!,
            );
          },
        );
        if (pickedDate != null) {
          String formattedDate = DateFormat('MMMM d, yyyy').format(pickedDate);
          setState(() {
            widget.dateController.text =
                formattedDate; // Update the date in the controller
          });
        }
      },
      child: Row(
        children: [
          Icon(
            Icons.edit_calendar,
            color: Colors.green,
          ),
          SizedBox(width: 8), // Add some space between the icon and text
          Text(
            widget.dateController.text,
            style: GoogleFonts.montserrat(fontSize: 14),
          ),
        ],
      ),
    );
  }
}
