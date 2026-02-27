import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ServiceCategory extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color accentColor;
  final List<String> mainServices;
  final List<String> extraServices;
  final List<String> selectedMain;
  final List<String> selectedExtras;
  final ValueChanged<List<String>> onMainChanged;
  final ValueChanged<List<String>> onExtrasChanged;
  final bool showOther;

  const ServiceCategory({
    super.key,
    required this.title,
    required this.icon,
    required this.accentColor,
    required this.mainServices,
    required this.extraServices,
    required this.selectedMain,
    required this.selectedExtras,
    required this.onMainChanged,
    required this.onExtrasChanged,
    this.showOther = true,
  });

  @override
  Widget build(BuildContext context) {
    // Collect "other" items = selected extras that aren't in the predefined list
    final otherItems =
        selectedExtras.where((s) => !extraServices.contains(s)).toList();

    return Padding(
      padding: EdgeInsets.only(top: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Category header (colored & bold) ---
          Padding(
            padding: EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Icon(icon, size: 16, color: accentColor),
                SizedBox(width: 5),
                Text(
                  title,
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: accentColor,
                  ),
                ),
              ],
            ),
          ),
          // --- Main service chips ---
          Wrap(
            spacing: 4,
            runSpacing: 0,
            children: mainServices.map((service) {
              final isSelected = selectedMain.contains(service);
              return _ServiceChip(
                label: service,
                isSelected: isSelected,
                selectedColor: Colors.green[100]!,
                selectedBorder: Colors.green[400]!,
                selectedText: Colors.green[900]!,
                onTap: () {
                  final updated = List<String>.from(selectedMain);
                  isSelected ? updated.remove(service) : updated.add(service);
                  onMainChanged(updated);
                },
              );
            }).toList(),
          ),
          // --- Extras sub-label ---
          if (extraServices.isNotEmpty || showOther)
            Padding(
              padding: EdgeInsets.only(top: 3, bottom: 2),
              child: Text(
                'EXTRAS',
                style: GoogleFonts.montserrat(
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  color: Colors.amber[700],
                  letterSpacing: 0.6,
                ),
              ),
            ),
          // --- Extras chips ---
          if (extraServices.isNotEmpty || showOther)
            Wrap(
              spacing: 4,
              runSpacing: 0,
              children: [
                ...extraServices.map((service) {
                  final isSelected = selectedExtras.contains(service);
                  return _ServiceChip(
                    label: service,
                    isSelected: isSelected,
                    selectedColor: Colors.amber[100]!,
                    selectedBorder: Colors.amber[400]!,
                    selectedText: Colors.amber[900]!,
                    onTap: () {
                      final updated = List<String>.from(selectedExtras);
                      isSelected
                          ? updated.remove(service)
                          : updated.add(service);
                      onExtrasChanged(updated);
                    },
                  );
                }),
                // "Other" custom entries already added
                ...otherItems.map((item) {
                  return _ServiceChip(
                    label: item,
                    isSelected: true,
                    selectedColor: Colors.amber[100]!,
                    selectedBorder: Colors.amber[400]!,
                    selectedText: Colors.amber[900]!,
                    onTap: () {
                      final updated = List<String>.from(selectedExtras);
                      updated.remove(item);
                      onExtrasChanged(updated);
                    },
                  );
                }),
                // "Other" button
                if (showOther)
                  _OtherChip(
                    onAdd: (value) {
                      final updated = List<String>.from(selectedExtras);
                      if (!updated.contains(value)) {
                        updated.add(value);
                        onExtrasChanged(updated);
                      }
                    },
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

// --- Compact service chip ---
class _ServiceChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color selectedColor;
  final Color selectedBorder;
  final Color selectedText;
  final VoidCallback onTap;

  const _ServiceChip({
    required this.label,
    required this.isSelected,
    required this.selectedColor,
    required this.selectedBorder,
    required this.selectedText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 4),
        padding: EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? selectedColor : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? selectedBorder : Colors.grey[300]!,
            width: 0.5,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? selectedText : Colors.grey[700],
          ),
        ),
      ),
    );
  }
}

// --- "Other" chip with dialog ---
class _OtherChip extends StatelessWidget {
  final ValueChanged<String> onAdd;

  const _OtherChip({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showOtherDialog(context),
      child: Container(
        margin: EdgeInsets.only(bottom: 4),
        padding: EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.amber[300]!,
            width: 1,
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, size: 10, color: Colors.amber[700]),
            SizedBox(width: 2),
            Text(
              'other',
              style: GoogleFonts.montserrat(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: Colors.amber[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showOtherDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Add Custom Service',
            style: GoogleFonts.montserrat(
                fontSize: 14, fontWeight: FontWeight.w600)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: GoogleFonts.montserrat(fontSize: 13),
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            hintText: 'Service name',
            hintStyle: GoogleFonts.montserrat(fontSize: 13),
            isDense: true,
            contentPadding:
                EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.amber, width: 2),
            ),
          ),
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              onAdd(value.trim().toLowerCase());
              Navigator.pop(dialogContext);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Cancel', style: GoogleFonts.montserrat(fontSize: 12)),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                onAdd(controller.text.trim().toLowerCase());
                Navigator.pop(dialogContext);
              }
            },
            child: Text('Add',
                style: GoogleFonts.montserrat(
                    fontSize: 12, color: Colors.amber[800])),
          ),
        ],
      ),
    );
  }
}
