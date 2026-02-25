import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ServiceChipGroup extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<String> services;
  final List<String> selectedServices;
  final ValueChanged<List<String>> onSelectionChanged;

  const ServiceChipGroup({
    super.key,
    required this.title,
    required this.icon,
    required this.services,
    required this.selectedServices,
    required this.onSelectionChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: 6, bottom: 2),
          child: Row(
            children: [
              Icon(icon, size: 16, color: Colors.green[700]),
              SizedBox(width: 4),
              Text(
                title,
                style: GoogleFonts.montserrat(
                    fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: services.map((service) {
            final isSelected = selectedServices.contains(service);
            return FilterChip(
              label: Text(
                service,
                style: GoogleFonts.montserrat(fontSize: 12),
              ),
              selected: isSelected,
              selectedColor: Colors.green[200],
              checkmarkColor: Colors.green[800],
              backgroundColor: Colors.grey[100],
              onSelected: (selected) {
                final updated = List<String>.from(selectedServices);
                selected ? updated.add(service) : updated.remove(service);
                onSelectionChanged(updated);
              },
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            );
          }).toList(),
        ),
      ],
    );
  }
}
