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
              child: GestureDetector(
                onTap: () => _showCustomDropdown(context, siteList),
                child: InputDecorator(
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.all(8),
                    border: OutlineInputBorder(),
                    labelText: 'Select a Site',
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.green, width: 2.0),
                    ),
                  ),
                  child: Text(
                    widget.dropdownValue ?? '',
                    style: GoogleFonts.montserrat(fontSize: 14),
                  ),
                ),
              ),
            ),
            SizedBox(height: 8),
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

  void _showCustomDropdown(BuildContext context, List<SiteInfo> siteList) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Select a Site',
              style: GoogleFonts.montserrat(fontSize: 14)),
          content: Container(
            width: double.maxFinite,
            child: RawScrollbar(
              thumbColor: const Color.fromARGB(255, 59, 82, 73),
              radius: Radius.circular(10),
              thickness: 8,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: siteList.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(
                      siteList[index].name,
                      style: GoogleFonts.montserrat(fontSize: 14),
                    ),
                    onTap: () {
                      widget.onSiteChanged(siteList[index]);
                      Navigator.of(context).pop();
                    },
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
