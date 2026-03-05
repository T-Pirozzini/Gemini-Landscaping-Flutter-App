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
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: TextField(
            controller: widget.vendorController,
            style: GoogleFonts.montserrat(fontSize: 12),
            decoration: InputDecoration(
              hintText: 'Vendor',
              hintStyle:
                  GoogleFonts.montserrat(fontSize: 12, color: Colors.grey[400]),
              isDense: true,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          flex: 3,
          child: TextField(
            controller: widget.materialController,
            style: GoogleFonts.montserrat(fontSize: 12),
            decoration: InputDecoration(
              hintText: 'Material / Qty',
              hintStyle:
                  GoogleFonts.montserrat(fontSize: 12, color: Colors.grey[400]),
              isDense: true,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          flex: 1,
          child: TextField(
            controller: widget.costController,
            style: GoogleFonts.montserrat(fontSize: 12),
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: '\$ Cost',
              hintStyle:
                  GoogleFonts.montserrat(fontSize: 12, color: Colors.grey[400]),
              isDense: true,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
      ],
    );
  }
}
