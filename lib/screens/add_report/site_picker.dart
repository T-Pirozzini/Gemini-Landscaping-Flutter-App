import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gemini_landscaping_app/models/site_info.dart';
import 'package:gemini_landscaping_app/providers/site_list_provider.dart';
import 'package:gemini_landscaping_app/providers/management_company_provider.dart';

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
        return GestureDetector(
          onTap: () => _showSitePickerDialog(context, siteList),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.location_on,
                    size: 16,
                    color: widget.dropdownValue != null
                        ? Colors.green[700]
                        : Colors.grey[400]),
                SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.dropdownValue ?? 'Select a site',
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          fontWeight: widget.dropdownValue != null
                              ? FontWeight.w500
                              : FontWeight.w400,
                          color: widget.dropdownValue != null
                              ? Colors.black87
                              : Colors.grey[500],
                        ),
                      ),
                      if (widget.selectedSite != null)
                        Text(
                          widget.selectedSite!.address,
                          style: GoogleFonts.montserrat(
                            fontSize: 10,
                            color: Colors.grey[500],
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_drop_down,
                    size: 18, color: Colors.grey[500]),
              ],
            ),
          ),
        );
      },
      loading: () => Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }

  void _showSitePickerDialog(BuildContext context, List<SiteInfo> siteList) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return _SitePickerDialog(
          siteList: siteList,
          onSiteSelected: (site) {
            widget.onSiteChanged(site);
          },
          onSiteAdded: (newSite) {
            widget.onSiteChanged(newSite);
            // ignore: unused_result
            ref.refresh(siteListProvider);
          },
        );
      },
    );
  }
}

class _SitePickerDialog extends ConsumerStatefulWidget {
  final List<SiteInfo> siteList;
  final ValueChanged<SiteInfo> onSiteSelected;
  final ValueChanged<SiteInfo> onSiteAdded;

  const _SitePickerDialog({
    required this.siteList,
    required this.onSiteSelected,
    required this.onSiteAdded,
  });

  @override
  ConsumerState<_SitePickerDialog> createState() => _SitePickerDialogState();
}

class _SitePickerDialogState extends ConsumerState<_SitePickerDialog> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<SiteInfo> get _filteredSites {
    if (_searchQuery.isEmpty) return widget.siteList;
    final query = _searchQuery.toLowerCase();
    return widget.siteList
        .where((site) =>
            site.name.toLowerCase().contains(query) ||
            site.address.toLowerCase().contains(query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredSites;

    return AlertDialog(
      titlePadding: EdgeInsets.fromLTRB(16, 16, 16, 0),
      contentPadding: EdgeInsets.fromLTRB(0, 8, 0, 0),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Select a Site',
                  style: GoogleFonts.montserrat(
                      fontSize: 16, fontWeight: FontWeight.w600)),
              Spacer(),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).pop();
                  _showAddSiteSheet();
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Color.fromARGB(255, 59, 82, 73),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, size: 14, color: Colors.white),
                      SizedBox(width: 4),
                      Text('New Site',
                          style: GoogleFonts.montserrat(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _searchQuery = value),
            style: GoogleFonts.montserrat(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Search sites...',
              hintStyle: GoogleFonts.montserrat(fontSize: 14),
              prefixIcon: Icon(Icons.search, size: 20),
              isDense: true,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.green, width: 2),
              ),
            ),
          ),
        ],
      ),
      content: Container(
        width: double.maxFinite,
        height: 400,
        child: RawScrollbar(
          thumbColor: const Color.fromARGB(255, 59, 82, 73),
          radius: Radius.circular(10),
          thickness: 6,
          child: ListView.builder(
            itemCount: filtered.length + 1, // +1 for "Add New Site"
            itemBuilder: (context, index) {
              if (index == filtered.length) {
                return _addNewSiteTile();
              }
              final site = filtered[index];
              return ListTile(
                dense: true,
                title: Text(
                  site.name,
                  style: GoogleFonts.montserrat(
                      fontSize: 14, fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  site.address,
                  style: GoogleFonts.montserrat(
                      fontSize: 12, color: Colors.grey[600]),
                ),
                onTap: () {
                  widget.onSiteSelected(site);
                  Navigator.of(context).pop();
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _addNewSiteTile() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Color.fromARGB(255, 59, 82, 73),
          radius: 16,
          child: Icon(Icons.add, color: Colors.white, size: 18),
        ),
        title: Text(
          'Add New Site',
          style: GoogleFonts.montserrat(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color.fromARGB(255, 59, 82, 73),
          ),
        ),
        onTap: () {
          Navigator.of(context).pop();
          _showAddSiteSheet();
        },
      ),
    );
  }

  void _showAddSiteSheet() {
    final nameController = TextEditingController();
    final addressController = TextEditingController();
    String selectedManagement = '';

    // Read management companies from provider
    final companiesAsync = ref.read(managementCompaniesStreamProvider);
    final companyNames = <String>[''];
    companiesAsync.whenData((companies) {
      companyNames.addAll(companies.map((c) => c.name));
    });

    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Add a New Site',
                    style: GoogleFonts.montserrat(
                        fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    style: GoogleFonts.montserrat(fontSize: 14),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      labelText: 'Site Name',
                      labelStyle: GoogleFonts.montserrat(fontSize: 14),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                            BorderSide(color: Colors.green, width: 2),
                      ),
                    ),
                  ),
                  SizedBox(height: 12),
                  TextField(
                    controller: addressController,
                    style: GoogleFonts.montserrat(fontSize: 14),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      labelText: 'Address',
                      labelStyle: GoogleFonts.montserrat(fontSize: 14),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                            BorderSide(color: Colors.green, width: 2),
                      ),
                    ),
                  ),
                  SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedManagement,
                    decoration: InputDecoration(
                      labelText: 'Management Company',
                      labelStyle: GoogleFonts.montserrat(fontSize: 14),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                            BorderSide(color: Colors.green, width: 2),
                      ),
                    ),
                    items: companyNames.map((name) {
                      return DropdownMenuItem(
                        value: name,
                        child: Text(
                          name.isEmpty ? 'None' : name,
                          style: GoogleFonts.montserrat(fontSize: 14),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setSheetState(
                          () => selectedManagement = value ?? '');
                    },
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color.fromARGB(255, 59, 82, 73),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 14),
                      textStyle: GoogleFonts.montserrat(
                          fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    onPressed: () async {
                      if (nameController.text.trim().isEmpty) return;

                      final docRef = await FirebaseFirestore.instance
                          .collection('SiteList')
                          .add({
                        'name': nameController.text.trim(),
                        'address': addressController.text.trim(),
                        'management': selectedManagement,
                        'imageUrl': '',
                        'status': true,
                        'target': 1000,
                        'program': true,
                      });
                      await docRef.update({'id': docRef.id});

                      final newSite = SiteInfo(
                        id: docRef.id,
                        name: nameController.text.trim(),
                        address: addressController.text.trim(),
                        management: selectedManagement,
                        imageUrl: '',
                        status: true,
                        target: 1000,
                        program: true,
                      );

                      Navigator.of(sheetContext).pop();
                      widget.onSiteAdded(newSite);
                    },
                    child: Text('Add Site'),
                  ),
                  SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
