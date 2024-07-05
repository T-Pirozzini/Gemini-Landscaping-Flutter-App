import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ServiceTypeComponent extends StatefulWidget {
  final bool isInitialRegularMaintenance;
  final ValueChanged<bool> onServiceTypeChanged;

  const ServiceTypeComponent({
    super.key,
    required this.isInitialRegularMaintenance,
    required this.onServiceTypeChanged,
  });

  @override
  State<ServiceTypeComponent> createState() => _ServiceTypeComponentState();
}

class _ServiceTypeComponentState extends State<ServiceTypeComponent> {
  late bool isRegularMaintenance;

  @override
  void initState() {
    super.initState();
    isRegularMaintenance = widget.isInitialRegularMaintenance;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ChoiceChip(
          selectedColor: const Color.fromARGB(255, 59, 82, 73),
          labelStyle: TextStyle(color: Colors.white),
          label: Text(
            'REGULAR MAINTENANCE',
            style: GoogleFonts.montserrat(fontSize: 12),
          ),
          selected: isRegularMaintenance,
          onSelected: (selected) {
            if (!isRegularMaintenance) {
              setState(() {
                isRegularMaintenance = true;
              });
              widget.onServiceTypeChanged(true);
            }
          },
        ),
        const SizedBox(width: 8),
        ChoiceChip(
          selectedColor: const Color.fromARGB(255, 59, 82, 73),
          labelStyle: TextStyle(color: Colors.white),
          label: Text(
            'ADDITIONAL SERVICE',
            style: GoogleFonts.montserrat(fontSize: 12),
          ),
          selected: !isRegularMaintenance,
          onSelected: (selected) {
            if (isRegularMaintenance) {
              setState(() {
                isRegularMaintenance = false;
              });
              widget.onServiceTypeChanged(false);
            }
          },
        ),
      ],
    );
  }
}
