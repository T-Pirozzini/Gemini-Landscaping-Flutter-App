import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gemini_landscaping_app/models/schedule_model.dart';
import 'package:gemini_landscaping_app/models/site_info.dart';
import 'package:intl/intl.dart'; // For formatting time

class ScheduleScreen extends StatefulWidget {
  @override
  _ScheduleScreenState createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final List<ScheduleEntry> schedule = []; // Populate this later
  final List<SiteInfo> activeSites = []; // Fetch from Firebase
  final DateTime today = DateTime.now();
  int? _hoveredSlotIndex;

  @override
  void initState() {
    super.initState();
    _loadActiveSites();
  }

  Future<List<SiteInfo>> fetchActiveSites() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('SiteList')
        .where('status', isEqualTo: true)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return SiteInfo(
        address: data['address'] as String,
        imageUrl: data['imageUrl'] as String,
        management: data['management'] as String,
        name: data['name'] as String,
        status: data['status'] as bool,
        target: (data['target'] as num).toDouble(), // Convert to double
        id: doc.id,
      );
    }).toList();
  }

  Future<void> _loadActiveSites() async {
    final sites = await fetchActiveSites();
    setState(() {
      activeSites.addAll(sites);
    });
  }

  void _addScheduleEntry(SiteInfo site, DateTime start, DateTime end) {
    setState(() {
      schedule.add(ScheduleEntry(site: site, startTime: start, endTime: end));
    });
  }

  void _updateScheduleEntry(ScheduleEntry entry, DateTime newStart) {
    final duration = entry.endTime.difference(entry.startTime);
    final newEnd = newStart.add(duration);
    setState(() {
      schedule[schedule.indexOf(entry)] = ScheduleEntry(
        site: entry.site,
        startTime: newStart,
        endTime: newEnd,
      );
      _hoveredSlotIndex = null; // Clear highlight
    });
  }

  @override
  Widget build(BuildContext context) {
    const double timeSlotHeight = 40.0;
    const int slotsPerDay = 20; // 7:00 AM - 5:00 PM

    return Scaffold(
      appBar: AppBar(
        title: Text('Schedule - ${DateFormat('MMM d, yyyy').format(today)}'),
      ),
      body: SingleChildScrollView(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Time Slots Column with Highlighting
            Column(
              children: List.generate(slotsPerDay, (index) {
                final hour = 7 + (index ~/ 2);
                final minute = (index % 2) * 30;
                final time =
                    DateTime(today.year, today.month, today.day, hour, minute);
                return Container(
                  height: timeSlotHeight,
                  width: 80,
                  color: _hoveredSlotIndex == index
                      ? Colors.green.withOpacity(0.3)
                      : Colors.transparent,
                  child: Center(
                    child: Text(
                      DateFormat('h:mm a').format(time),
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                );
              }),
            ),
            // Schedule Area
            Expanded(
              child: Container(
                height: timeSlotHeight * slotsPerDay,
                child: Stack(
                  children: [
                    // Drop Targets
                    ...List.generate(slotsPerDay, (index) {
                      final hour = 7 + (index ~/ 2);
                      final minute = (index % 2) * 30;
                      final slotTime = DateTime(
                          today.year, today.month, today.day, hour, minute);
                      return Positioned(
                        top: index * timeSlotHeight,
                        left: 0,
                        right: 0,
                        height: timeSlotHeight,
                        child: DragTarget<ScheduleEntry>(
                          onWillAcceptWithDetails: (details) {
                            setState(() => _hoveredSlotIndex =
                                index); // Highlight this slot
                            return true;
                          },
                          onLeave: (data) {
                            setState(() =>
                                _hoveredSlotIndex = null); // Clear when leaving
                          },
                          onAcceptWithDetails: (details) {
                            _updateScheduleEntry(details.data, slotTime);
                          },
                          builder: (context, candidateData, rejectedData) {
                            return Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.grey.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    }),
                    // Draggable Schedule Entries
                    ...schedule.map((entry) {
                      final startMinutes =
                          entry.startTime.hour * 60 + entry.startTime.minute;
                      final endMinutes =
                          entry.endTime.hour * 60 + entry.endTime.minute;
                      final startOffset = (startMinutes - 7 * 60) / 30;
                      final durationSlots = (endMinutes - startMinutes) / 30;

                      return Positioned(
                        top: startOffset * timeSlotHeight,
                        left: 0,
                        right: 0,
                        height: durationSlots * timeSlotHeight,
                        child: Draggable<ScheduleEntry>(
                          data: entry,
                          feedback: Material(
                            elevation: 4,
                            child: Container(
                              width: MediaQuery.of(context).size.width - 100,
                              height: durationSlots * timeSlotHeight,
                              color: Colors.blue.withOpacity(0.8),
                              child: Center(child: Text(entry.site.name)),
                            ),
                          ),
                          childWhenDragging:
                              SizedBox.shrink(), // No grey placeholder
                          child: Container(
                            color: Colors.blue.withOpacity(0.5),
                            child: Center(child: Text(entry.site.name)),
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showSitePicker(context),
        child: Icon(Icons.add),
      ),
    );
  }

  void _showSitePicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        SiteInfo? selectedSite;
        TimeOfDay? startTime = TimeOfDay(hour: 7, minute: 0);
        TimeOfDay? endTime = TimeOfDay(hour: 9, minute: 30);

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Add Site to Schedule'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButton<SiteInfo>(
                      hint: Text('Select a Site'),
                      value: selectedSite,
                      onChanged: (SiteInfo? value) {
                        setDialogState(() => selectedSite = value);
                      },
                      items: activeSites.map((site) {
                        return DropdownMenuItem(
                          value: site,
                          child: Text(site.name),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                            'Start: ${startTime?.format(context) ?? 'Not set'}'),
                        ElevatedButton(
                          onPressed: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: startTime ?? TimeOfDay.now(),
                            );
                            if (picked != null) {
                              setDialogState(() => startTime = picked);
                            }
                          },
                          child: Text('Pick Start'),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('End: ${endTime?.format(context) ?? 'Not set'}'),
                        ElevatedButton(
                          onPressed: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: endTime ?? TimeOfDay.now(),
                            );
                            if (picked != null) {
                              setDialogState(() => endTime = picked);
                            }
                          },
                          child: Text('Pick End'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    if (selectedSite != null &&
                        startTime != null &&
                        endTime != null) {
                      final start = DateTime(today.year, today.month, today.day,
                          startTime!.hour, startTime!.minute);
                      final end = DateTime(today.year, today.month, today.day,
                          endTime!.hour, endTime!.minute);
                      if (end.isAfter(start)) {
                        _addScheduleEntry(selectedSite!, start, end);
                        Navigator.pop(context);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content:
                                  Text('End time must be after start time')),
                        );
                      }
                    }
                  },
                  child: Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
