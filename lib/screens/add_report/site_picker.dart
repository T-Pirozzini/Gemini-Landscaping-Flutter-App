import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gemini_landscaping_app/models/site_info.dart';
import 'package:gemini_landscaping_app/providers/site_list_provider.dart';

class SitePickerComponent extends ConsumerStatefulWidget {
  final String? dropdownValue;
  final SiteInfo? selectedSite;
  final ValueChanged<SiteInfo> onSiteChanged;

  const SitePickerComponent({
    Key? key,
    required this.dropdownValue,
    required this.selectedSite,
    required this.onSiteChanged,
  }) : super(key: key);

  @override
  _SitePickerComponentState createState() => _SitePickerComponentState();
}

class _SitePickerComponentState extends ConsumerState<SitePickerComponent> {
  @override
  Widget build(BuildContext context) {
    final sitesAsyncValue = ref.watch(siteListProvider);

    return sitesAsyncValue.when(
      data: (siteList) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 300,
              child: DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.all(8),
                  border: OutlineInputBorder(),
                  labelText: 'Select a Site',
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.green, width: 2.0),
                  ),
                ),
                value: widget.dropdownValue,
                items: siteList.map((site) {
                  return DropdownMenuItem<String>(
                    value: site.name,
                    child: Text(
                      site.name,
                      style: GoogleFonts.montserrat(fontSize: 14),
                    ),
                  );
                }).toList(),
                onChanged: (String? value) {
                  final selectedSite = siteList.firstWhere(
                    (site) => site.name == value,
                    orElse: () => SiteInfo(
                      address: '',
                      imageUrl: '',
                      management: '',
                      name: '',
                      status: false,
                    ),
                  );
                  widget.onSiteChanged(selectedSite);
                },
              ),
            ),
            if (widget.selectedSite != null)
              Text(
                'Address: ${widget.selectedSite!.address}',
                style: GoogleFonts.montserrat(fontSize: 14),
              ),
          ],
        );
      },
      loading: () => Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }
}
