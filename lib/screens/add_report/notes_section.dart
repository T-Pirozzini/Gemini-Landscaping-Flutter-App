import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NotesSection extends StatelessWidget {
  final List<String> selectedTags;
  final ValueChanged<List<String>> onTagsChanged;
  final TextEditingController notesController;

  static const defaultTags = [
    'Focused on specific area',
    'Ran out of time',
    'Resident feedback',
    'Equipment issue',
    'Extra work needed next visit',
    'Weather delay',
    'Irrigation issue',
  ];

  const NotesSection({
    super.key,
    required this.selectedTags,
    required this.onTagsChanged,
    required this.notesController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Tags:',
          style: GoogleFonts.montserrat(
              fontSize: 13, fontWeight: FontWeight.w500),
        ),
        SizedBox(height: 4),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: defaultTags.map((tag) {
            final isSelected = selectedTags.contains(tag);
            return FilterChip(
              label: Text(
                tag,
                style: GoogleFonts.montserrat(fontSize: 11),
              ),
              selected: isSelected,
              selectedColor: Colors.green[200],
              checkmarkColor: Colors.green[800],
              backgroundColor: Colors.grey[100],
              onSelected: (selected) {
                final updated = List<String>.from(selectedTags);
                selected ? updated.add(tag) : updated.remove(tag);
                onTagsChanged(updated);
              },
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            );
          }).toList(),
        ),
        SizedBox(height: 8),
        Text(
          'Additional Notes (optional):',
          style: GoogleFonts.montserrat(
              fontSize: 13, fontWeight: FontWeight.w500),
        ),
        SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(10),
          ),
          height: 80,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: TextField(
              controller: notesController,
              maxLines: null,
              keyboardType: TextInputType.multiline,
              decoration: InputDecoration(
                hintText: 'Any additional details...',
                border: InputBorder.none,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
