import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ServiceCategory extends StatefulWidget {
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
  final bool collapsibleExtras;

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
    this.collapsibleExtras = false,
  });

  @override
  State<ServiceCategory> createState() => _ServiceCategoryState();
}

class _ServiceCategoryState extends State<ServiceCategory> {
  bool _extrasExpanded = false;

  @override
  void didUpdateWidget(ServiceCategory oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Auto-expand when an extra gets selected
    if (!_extrasExpanded && widget.selectedExtras.isNotEmpty) {
      _extrasExpanded = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final otherItems = widget.selectedExtras
        .where((s) => !widget.extraServices.contains(s))
        .toList();
    final hasExtras = widget.extraServices.isNotEmpty || widget.showOther;
    final extrasCount = widget.selectedExtras.length;
    final showExtrasContent =
        !widget.collapsibleExtras || _extrasExpanded;

    return Container(
      margin: EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Colored left accent bar
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: widget.accentColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(10),
                  bottomLeft: Radius.circular(10),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
          // --- Category header (colored & bold) ---
          Row(
            children: [
              Icon(widget.icon, size: 18, color: widget.accentColor),
              SizedBox(width: 6),
              Text(
                widget.title,
                style: GoogleFonts.montserrat(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: widget.accentColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 6),
          // --- Main service chips ---
          Wrap(
            spacing: 6,
            runSpacing: 2,
            children: widget.mainServices.map((service) {
              final isSelected = widget.selectedMain.contains(service);
              return _ServiceChip(
                label: service,
                isSelected: isSelected,
                selectedColor: Colors.green[100]!,
                selectedBorder: Colors.green[400]!,
                selectedText: Colors.green[900]!,
                onTap: () {
                  final updated = List<String>.from(widget.selectedMain);
                  isSelected
                      ? updated.remove(service)
                      : updated.add(service);
                  widget.onMainChanged(updated);
                },
              );
            }).toList(),
          ),
          // --- Extras label (tappable if collapsible) ---
          if (hasExtras)
            GestureDetector(
              onTap: widget.collapsibleExtras
                  ? () => setState(() => _extrasExpanded = !_extrasExpanded)
                  : null,
              child: Padding(
                padding: EdgeInsets.only(top: 6, bottom: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      extrasCount > 0 && !showExtrasContent
                          ? 'EXTRAS ($extrasCount)'
                          : 'EXTRAS',
                      style: GoogleFonts.montserrat(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: Colors.amber[700],
                        letterSpacing: 0.6,
                      ),
                    ),
                    if (widget.collapsibleExtras) ...[
                      SizedBox(width: 3),
                      Icon(
                        _extrasExpanded
                            ? Icons.expand_less
                            : Icons.expand_more,
                        size: 14,
                        color: Colors.amber[700],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          // --- Extras chips (collapsible) ---
          if (hasExtras && showExtrasContent)
            Wrap(
              spacing: 6,
              runSpacing: 2,
              children: [
                ...widget.extraServices.map((service) {
                  final isSelected =
                      widget.selectedExtras.contains(service);
                  return _ServiceChip(
                    label: service,
                    isSelected: isSelected,
                    selectedColor: Colors.amber[100]!,
                    selectedBorder: Colors.amber[400]!,
                    selectedText: Colors.amber[900]!,
                    onTap: () {
                      final updated =
                          List<String>.from(widget.selectedExtras);
                      isSelected
                          ? updated.remove(service)
                          : updated.add(service);
                      widget.onExtrasChanged(updated);
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
                      final updated =
                          List<String>.from(widget.selectedExtras);
                      updated.remove(item);
                      widget.onExtrasChanged(updated);
                    },
                  );
                }),
                // "Other" button
                if (widget.showOther)
                  _OtherChip(
                    onAdd: (value) {
                      final updated =
                          List<String>.from(widget.selectedExtras);
                      if (!updated.contains(value)) {
                        updated.add(value);
                        widget.onExtrasChanged(updated);
                      }
                    },
                  ),
              ],
            ),
                  ],
                ),
              ),
            ),
          ],
        ),
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
        margin: EdgeInsets.only(bottom: 6),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? selectedColor : Colors.grey[50],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? selectedBorder : Colors.grey[300]!,
            width: isSelected ? 1.0 : 0.5,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 12,
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
        margin: EdgeInsets.only(bottom: 6),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.amber[300]!,
            width: 1,
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, size: 12, color: Colors.amber[700]),
            SizedBox(width: 3),
            Text(
              'other',
              style: GoogleFonts.montserrat(
                fontSize: 12,
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
            child:
                Text('Cancel', style: GoogleFonts.montserrat(fontSize: 12)),
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
