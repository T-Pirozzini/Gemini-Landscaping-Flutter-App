import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum ReportMode { regular, additional }

class PhaseToggle extends StatelessWidget {
  final ReportMode mode;
  final ValueChanged<ReportMode> onChanged;

  static const _green = Color.fromARGB(255, 31, 182, 77);
  static const _blueGrey = Color.fromARGB(255, 97, 125, 140);

  const PhaseToggle({
    super.key,
    required this.mode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          _chip('REGULAR', ReportMode.regular, _green),
          SizedBox(width: 6),
          _chip('ADDITIONAL', ReportMode.additional, _blueGrey),
        ],
      ),
    );
  }

  Widget _chip(String label, ReportMode value, Color activeColor) {
    final isSelected = mode == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(value),
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? activeColor : Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? activeColor : Colors.grey[400]!,
              width: isSelected ? 2 : 1,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.montserrat(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isSelected ? Colors.white : Colors.grey[600],
            ),
          ),
        ),
      ),
    );
  }
}

/// Legacy adapter: wraps PhaseToggle for screens still using the old API.
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
  late ReportMode _mode;

  @override
  void initState() {
    super.initState();
    _mode = widget.isInitialRegularMaintenance
        ? ReportMode.regular
        : ReportMode.additional;
  }

  @override
  Widget build(BuildContext context) {
    return PhaseToggle(
      mode: _mode,
      onChanged: (newMode) {
        setState(() => _mode = newMode);
        // Map to bool for legacy callers
        widget.onServiceTypeChanged(newMode == ReportMode.regular);
      },
    );
  }
}
