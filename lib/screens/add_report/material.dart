import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MaterialComponent extends StatefulWidget {
  final TextEditingController vendorController;
  final TextEditingController materialController;
  final TextEditingController costController;
  const MaterialComponent(
      {super.key,
      required this.vendorController,
      required this.materialController,
      required this.costController});

  @override
  State<MaterialComponent> createState() => _MaterialComponentState();
}

class _MaterialComponentState extends State<MaterialComponent> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextField(
                controller: widget.vendorController,
                style: GoogleFonts.montserrat(fontSize: 14),
                decoration: const InputDecoration(
                  labelText: 'Vendor',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 3,
              child: TextField(
                controller: widget.materialController,
                style: GoogleFonts.montserrat(fontSize: 14),
                decoration: const InputDecoration(
                  labelText: 'Material/Quantity',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 1,
              child: TextField(
                controller: widget.costController,
                style: GoogleFonts.montserrat(fontSize: 14),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Cost',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
