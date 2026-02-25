import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DisposalSection extends StatelessWidget {
  final bool hasDisposal;
  final ValueChanged<bool> onDisposalChanged;
  final TextEditingController locationController;
  final TextEditingController costController;

  const DisposalSection({
    super.key,
    required this.hasDisposal,
    required this.onDisposalChanged,
    required this.locationController,
    required this.costController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SwitchListTile(
          title: Text(
            'Disposal Run',
            style: GoogleFonts.montserrat(
                fontSize: 14, fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            'Did you do a dump run?',
            style: GoogleFonts.montserrat(fontSize: 12),
          ),
          value: hasDisposal,
          activeTrackColor: Color.fromARGB(150, 31, 182, 77),
          contentPadding: EdgeInsets.zero,
          onChanged: onDisposalChanged,
        ),
        if (hasDisposal) ...[
          SizedBox(height: 8),
          TextField(
            controller: locationController,
            style: GoogleFonts.montserrat(fontSize: 14),
            decoration: InputDecoration(
              labelText: 'Dump Location',
              border: OutlineInputBorder(),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
          SizedBox(height: 8),
          TextField(
            controller: costController,
            style: GoogleFonts.montserrat(fontSize: 14),
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Disposal Cost (\$)',
              border: OutlineInputBorder(),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
        ],
      ],
    );
  }
}
