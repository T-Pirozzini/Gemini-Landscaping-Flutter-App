import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ServiceToggleComponent extends StatefulWidget {
  final String title;
  final List<String> services;
  final List<String> selectedServices;
  final ValueChanged<List<String>> onSelectionChanged;

  const ServiceToggleComponent(
      {super.key,
      required this.title,
      required this.services,
      required this.selectedServices,
      required this.onSelectionChanged});

  @override
  State<ServiceToggleComponent> createState() => _ServiceToggleComponentState();
}

class _ServiceToggleComponentState extends State<ServiceToggleComponent> {
  late List<String> selectedServices;

  @override
  void initState() {
    super.initState();
    selectedServices = widget.selectedServices;
  }

  void _toggleSelection(int index) {
    setState(() {
      if (selectedServices.contains(widget.services[index])) {
        selectedServices.remove(widget.services[index]);
      } else {
        selectedServices.add(widget.services[index]);
      }
    });
    widget.onSelectionChanged(selectedServices);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Material(
        elevation: 1,
        borderRadius: BorderRadius.circular(4),
        child: ExpansionTile(
          tilePadding: EdgeInsets.zero,
          childrenPadding: EdgeInsets.zero,
          title: Text(
            widget.title,
            style: GoogleFonts.montserrat(
                fontSize: 14, fontWeight: FontWeight.bold),
          ),
          children: [
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, // Adjust the number of columns as needed
                childAspectRatio: 3, // Adjust the aspect ratio as needed
              ),
              itemCount: widget.services.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: ToggleButtons(
                    onPressed: (int) => _toggleSelection(index),
                    borderRadius: const BorderRadius.all(Radius.circular(8)),
                    selectedBorderColor: Colors.green[700],
                    selectedColor: Colors.white,
                    fillColor: Colors.green[200],
                    color: Colors.green[700],
                    constraints: const BoxConstraints(
                      minHeight: 25.0,
                      minWidth: 110.0,
                    ),
                    isSelected: [
                      selectedServices.contains(widget.services[index])
                    ],
                    children: [
                      Text(
                        widget.services[index],
                        style: GoogleFonts.montserrat(fontSize: 12),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
