import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gemini_landscaping_app/models/equipment_model.dart';
import 'package:gemini_landscaping_app/models/schedule_model.dart';
import 'package:gemini_landscaping_app/services/schedule_service.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

/// Embeddable week-view body widget. The parent provides the Scaffold/AppBar.
class WeekViewBody extends StatefulWidget {
  final DateTime monday;
  final String? userRole;
  final void Function(DateTime date)? onSwitchToDailyView;
  final void Function(int weekOffset)? onWeekChanged;

  const WeekViewBody({
    super.key,
    required this.monday,
    this.userRole,
    this.onSwitchToDailyView,
    this.onWeekChanged,
  });

  @override
  WeekViewBodyState createState() => WeekViewBodyState();
}

class WeekViewBodyState extends State<WeekViewBody> {
  static const _darkGreen = Color.fromARGB(255, 59, 82, 73);

  final ScheduleService _service = ScheduleService();
  late List<DateTime> _weekDays;
  Map<DateTime, List<ScheduleEntry>> _weekSchedules = {};
  List<Equipment> _activeTrucks = [];
  DateTime? _selectedDay;
  bool _loading = true;
  int? _hoveredDayIndex;
  String? _userRole;
  String? _gridTruckId;   // truck shown in the week grid (always one)
  String? _agendaTruckId; // null = "All" in agenda, otherwise a truck ID

  bool get _isAdmin => _userRole == 'admin';

  /// Public accessor for parent AppBar actions.
  DateTime? get selectedDay => _selectedDay;

  @override
  void initState() {
    super.initState();
    _userRole = widget.userRole;
    if (_userRole == null) _loadUserRole();
    _weekDays = _computeWeekDays(widget.monday);
    _selectedDay = _findTodayInWeek() ?? _weekDays.first;
    _loadWeekData();
  }

  @override
  void didUpdateWidget(covariant WeekViewBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.monday != widget.monday) {
      _weekDays = _computeWeekDays(widget.monday);
      _selectedDay = _findTodayInWeek() ?? _weekDays.first;
      _loadWeekData();
    }
  }

  List<DateTime> _computeWeekDays(DateTime monday) {
    return List.generate(
        5, (i) => DateTime(monday.year, monday.month, monday.day + i));
  }

  DateTime? _findTodayInWeek() {
    final now = DateTime.now();
    for (var d in _weekDays) {
      if (d.year == now.year && d.month == now.month && d.day == now.day) {
        return d;
      }
    }
    return null;
  }

  Future<void> _loadUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final snapshot = await FirebaseFirestore.instance
          .collection('Users')
          .doc(user.uid)
          .get();
      if (snapshot.exists) {
        setState(() {
          _userRole = snapshot.data()?['role'] as String? ?? 'user';
        });
      }
    }
  }

  Future<void> _loadWeekData() async {
    setState(() => _loading = true);
    _activeTrucks = await _service.fetchActiveTrucks();
    _weekSchedules = await _service.fetchSchedulesForWeek(_weekDays.first);
    // Default grid truck to first active truck if not set or no longer valid
    if (_gridTruckId == null ||
        !_activeTrucks.any((t) => t.id == _gridTruckId)) {
      _gridTruckId = _activeTrucks.isNotEmpty ? _activeTrucks.first.id : null;
    }
    setState(() => _loading = false);
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  bool _isSelectedDay(DateTime date) {
    return _selectedDay != null &&
        date.year == _selectedDay!.year &&
        date.month == _selectedDay!.month &&
        date.day == _selectedDay!.day;
  }

  // --- Public methods for parent AppBar actions ---

  void copySelectedDay() {
    if (_selectedDay != null) _showCopyDaySheet(_selectedDay!);
  }

  void copyWeekToNext() {
    _showCopyWeekDialog();
  }

  // --- Cross-day move ---
  Future<void> _moveEntryToDay(
      ScheduleEntry entry, DateTime targetDay) async {
    final entryDay = DateTime(
        entry.startTime.year, entry.startTime.month, entry.startTime.day);
    if (entryDay == targetDay) return;

    await _service.moveEntryToDate(entry, targetDay);
    await _loadWeekData();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Moved ${entry.site.name} to ${DateFormat('EEEE').format(targetDay)}'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // --- Copy day → day ---
  void _showCopyDaySheet(DateTime sourceDay) {
    if (!_isAdmin) return;
    final sourceEntries = _weekSchedules[sourceDay] ?? [];
    if (sourceEntries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                '${DateFormat('EEEE').format(sourceDay)} has no entries to copy')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Copy ${DateFormat('EEEE').format(sourceDay)}'s schedule to...",
                style: GoogleFonts.montserrat(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              ..._weekDays.where((d) => d != sourceDay).map((targetDay) {
                final targetEntries = _weekSchedules[targetDay] ?? [];
                return ListTile(
                  leading: Icon(Icons.calendar_today, color: _darkGreen),
                  title: Text(DateFormat('EEEE, MMM d').format(targetDay)),
                  subtitle: targetEntries.isNotEmpty
                      ? Text('${targetEntries.length} existing entries',
                          style: TextStyle(color: Colors.orange[700]))
                      : null,
                  onTap: () {
                    Navigator.pop(context);
                    _confirmCopyDay(sourceDay, targetDay, sourceEntries,
                        targetEntries.length);
                  },
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmCopyDay(DateTime sourceDay, DateTime targetDay,
      List<ScheduleEntry> entries, int existingCount) async {
    if (existingCount > 0) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Confirm Copy', style: GoogleFonts.montserrat()),
          content: Text(
            '${DateFormat('EEEE').format(targetDay)} already has $existingCount entries. '
            'Copy ${entries.length} entries from ${DateFormat('EEEE').format(sourceDay)} anyway? '
            'New entries will be added alongside existing ones.',
            style: GoogleFonts.roboto(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Copy', style: TextStyle(color: _darkGreen)),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    final dayOffset = targetDay.difference(sourceDay).inDays;
    await _service.batchCopyEntries(entries, dayOffset);
    await _loadWeekData();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Copied ${entries.length} entries to ${DateFormat('EEEE').format(targetDay)}'),
        ),
      );
    }
  }

  // --- Copy week → next week ---
  void _showCopyWeekDialog() async {
    final allEntries =
        _weekSchedules.values.expand((list) => list).toList();
    if (allEntries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No entries this week to copy')),
      );
      return;
    }

    // Check if next week has entries
    final nextMonday = _weekDays.first.add(const Duration(days: 7));
    final nextWeekSchedules =
        await _service.fetchSchedulesForWeek(nextMonday);
    final nextWeekCount =
        nextWeekSchedules.values.expand((list) => list).length;

    if (!mounted) return;

    final weekLabel =
        '${DateFormat('MMM d').format(nextMonday)} – ${DateFormat('MMM d').format(nextMonday.add(const Duration(days: 4)))}';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Copy to Next Week', style: GoogleFonts.montserrat()),
        content: Text(
          'Copy ${allEntries.length} entries to next week ($weekLabel)?'
          '${nextWeekCount > 0 ? '\n\nNext week already has $nextWeekCount entries. New entries will be added alongside existing ones.' : ''}',
          style: GoogleFonts.roboto(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Copy', style: TextStyle(color: _darkGreen)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await _service.batchCopyEntries(allEntries, 7);
    // Ask parent to navigate forward one week
    widget.onWeekChanged?.call(1);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Copied ${allEntries.length} entries to next week'),
        ),
      );
    }
  }

  // --- Move to any date (cross-week) ---
  void _showMoveToDatePicker(ScheduleEntry entry) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: entry.startTime,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      helpText: 'Move "${entry.site.name}" to...',
    );
    if (picked == null || !mounted) return;

    final entryDay = DateTime(
        entry.startTime.year, entry.startTime.month, entry.startTime.day);
    final targetDay = DateTime(picked.year, picked.month, picked.day);
    if (entryDay == targetDay) return;

    await _service.moveEntryToDate(entry, targetDay);
    await _loadWeekData();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Moved ${entry.site.name} to ${DateFormat('EEE, MMM d').format(targetDay)}'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // --- Entry action sheet (admin) ---
  void _showEntryActions(ScheduleEntry entry) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    entry.site.name,
                    style: GoogleFonts.montserrat(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ListTile(
                  leading:
                      Icon(Icons.calendar_view_day, color: _darkGreen),
                  title: const Text('View in daily schedule'),
                  onTap: () {
                    Navigator.pop(context);
                    widget.onSwitchToDailyView?.call(entry.startTime);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.date_range, color: Colors.blue[700]),
                  title: const Text('Move to another date...'),
                  subtitle: const Text('Move to any day, including next week'),
                  onTap: () {
                    Navigator.pop(context);
                    _showMoveToDatePicker(entry);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    return Column(
      children: [
        _buildGridTruckSelector(),
        _buildWeekGrid(),
        _buildAgendaFilter(),
        Divider(height: 1, color: Colors.grey[300]),
        Expanded(child: _buildDayAgenda()),
      ],
    );
  }

  // === GRID TRUCK SELECTOR (always one truck) ===
  Widget _buildGridTruckSelector() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _activeTrucks.map((truck) {
            final isSelected = _gridTruckId == truck.id;
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: GestureDetector(
                onTap: () => setState(() => _gridTruckId = truck.id),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? truck.color.withValues(alpha: 0.15)
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? truck.color.withValues(alpha: 0.6)
                          : Colors.grey[300]!,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: truck.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        truck.name,
                        style: GoogleFonts.montserrat(
                          fontSize: 11,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected ? truck.color : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // === AGENDA FILTER (All + per-truck) ===
  Widget _buildAgendaFilter() {
    final dayEntries = _selectedDay != null
        ? (_weekSchedules[_selectedDay] ?? [])
        : <ScheduleEntry>[];
    final allCount = dayEntries.length;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _agendaChip(
              label: 'All',
              count: allCount,
              isSelected: _agendaTruckId == null,
              onTap: () => setState(() => _agendaTruckId = null),
            ),
            const SizedBox(width: 6),
            ..._activeTrucks.map((truck) {
              final truckCount =
                  dayEntries.where((e) => e.truckId == truck.id).length;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: _agendaChip(
                  label: truck.name,
                  count: truckCount,
                  color: truck.color,
                  isSelected: _agendaTruckId == truck.id,
                  onTap: () => setState(() => _agendaTruckId = truck.id),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _agendaChip({
    required String label,
    required int count,
    required bool isSelected,
    required VoidCallback onTap,
    Color? color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? (color ?? _darkGreen).withValues(alpha: 0.15)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? (color ?? _darkGreen).withValues(alpha: 0.5)
                : Colors.grey[300]!,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (color != null) ...[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: GoogleFonts.montserrat(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? (color ?? _darkGreen) : Colors.grey[600],
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (color ?? _darkGreen).withValues(alpha: 0.2)
                      : Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$count',
                  style: GoogleFonts.montserrat(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? (color ?? _darkGreen)
                        : Colors.grey[500],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // === WEEK GRID (top half) ===
  Widget _buildWeekGrid() {
    final screenWidth = MediaQuery.of(context).size.width;
    final dayColumnWidth = screenWidth / 5;

    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Day headers
          Row(
            children: _weekDays.map((day) {
              final isToday = _isToday(day);
              final isSelected = _isSelectedDay(day);
              return GestureDetector(
                onTap: () => setState(() => _selectedDay = day),
                onLongPress: _isAdmin ? () => _showCopyDaySheet(day) : null,
                child: Container(
                  width: dayColumnWidth,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? _darkGreen.withValues(alpha: 0.1)
                        : Colors.transparent,
                    border: Border(
                      bottom: BorderSide(
                        color: isSelected ? _darkGreen : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        DateFormat('E').format(day),
                        style: GoogleFonts.montserrat(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isToday
                              ? const Color.fromARGB(255, 31, 182, 77)
                              : Colors.grey[600],
                        ),
                      ),
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: isToday
                              ? const Color.fromARGB(255, 31, 182, 77)
                              : Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${day.day}',
                          style: GoogleFonts.montserrat(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isToday ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                      if (_isAdmin)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            'hold to copy',
                            style: GoogleFonts.montserrat(
                              fontSize: 7,
                              color: Colors.grey[400],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          // Entry blocks per day — each column is a DragTarget
          SizedBox(
            height: 200,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _weekDays.asMap().entries.map((mapEntry) {
                final idx = mapEntry.key;
                final day = mapEntry.value;
                final allEntries = _weekSchedules[day] ?? [];
                final entries = _gridTruckId == null
                    ? allEntries
                    : allEntries.where((e) => e.truckId == _gridTruckId).toList();
                final isSelected = _isSelectedDay(day);
                final isHovered = _hoveredDayIndex == idx;

                return DragTarget<ScheduleEntry>(
                  onWillAcceptWithDetails: (details) {
                    setState(() => _hoveredDayIndex = idx);
                    return true;
                  },
                  onLeave: (_) {
                    setState(() => _hoveredDayIndex = null);
                  },
                  onAcceptWithDetails: (details) {
                    setState(() => _hoveredDayIndex = null);
                    _moveEntryToDay(details.data, day);
                  },
                  builder: (context, candidateData, rejectedData) {
                    return Container(
                      width: dayColumnWidth,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 2, vertical: 4),
                      decoration: BoxDecoration(
                        color: isHovered
                            ? Colors.green.withValues(alpha: 0.1)
                            : isSelected
                                ? _darkGreen.withValues(alpha: 0.05)
                                : Colors.transparent,
                        border: Border(
                          right: BorderSide(
                              color: Colors.grey[200]!, width: 0.5),
                        ),
                      ),
                      child: entries.isEmpty
                          ? Center(
                              child: isHovered
                                  ? Icon(Icons.add_circle_outline,
                                      size: 20,
                                      color: Colors.green.withValues(
                                          alpha: 0.4))
                                  : Text(
                                      '–',
                                      style: GoogleFonts.montserrat(
                                          fontSize: 14,
                                          color: Colors.grey[300]),
                                    ),
                            )
                          : SingleChildScrollView(
                              child: Column(
                                children: entries.map((entry) {
                                  final truck = _activeTrucks
                                      .where((t) => t.id == entry.truckId)
                                      .toList();
                                  final truckColor = truck.isNotEmpty
                                      ? truck.first.color
                                      : Colors.grey;
                                  final durationMin = entry.endTime
                                      .difference(entry.startTime)
                                      .inMinutes;
                                  final blockHeight =
                                      (durationMin / 30 * 12)
                                          .clamp(16.0, 40.0);

                                  return Container(
                                    width: double.infinity,
                                    height: blockHeight,
                                    margin:
                                        const EdgeInsets.only(bottom: 2),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 3, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: truckColor.withValues(
                                          alpha: 0.6),
                                      borderRadius:
                                          BorderRadius.circular(3),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      entry.site.name,
                                      style: GoogleFonts.montserrat(
                                        fontSize: 8,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                    );
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // === DAY AGENDA (bottom half) ===
  Widget _buildDayAgenda() {
    if (_selectedDay == null) {
      return Center(
        child: Text('Select a day above',
            style: GoogleFonts.montserrat(color: Colors.grey[400])),
      );
    }

    final allDayEntries = _weekSchedules[_selectedDay] ?? [];
    final entries = _agendaTruckId == null
        ? allDayEntries
        : allDayEntries.where((e) => e.truckId == _agendaTruckId).toList();
    final dayLabel = DateFormat('EEEE, MMM d').format(_selectedDay!);

    if (entries.isEmpty) {
      return Column(
        children: [
          _dayAgendaHeader(dayLabel),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.event_available,
                      size: 36, color: Colors.grey[300]),
                  const SizedBox(height: 8),
                  Text('No entries scheduled',
                      style: GoogleFonts.montserrat(
                          fontSize: 13, color: Colors.grey[400])),
                ],
              ),
            ),
          ),
        ],
      );
    }

    // Group entries by truck
    final byTruck = <String, List<ScheduleEntry>>{};
    for (var entry in entries) {
      final truckId = entry.truckId ?? 'unassigned';
      byTruck.putIfAbsent(truckId, () => []);
      byTruck[truckId]!.add(entry);
    }
    for (var list in byTruck.values) {
      list.sort((a, b) => a.startTime.compareTo(b.startTime));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _dayAgendaHeader(dayLabel),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            children: byTruck.entries.map((truckGroup) {
              final truck = _activeTrucks
                  .where((t) => t.id == truckGroup.key)
                  .toList();
              final truckName =
                  truck.isNotEmpty ? truck.first.name : 'Unassigned';
              final truckColor =
                  truck.isNotEmpty ? truck.first.color : Colors.grey;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Truck header (skip when filtered to a single truck)
                  if (_agendaTruckId == null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: truckColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            truckName,
                            style: GoogleFonts.montserrat(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                          ),
                        ],
                      ),
                    ),
                  // Entries for this truck
                  ...truckGroup.value.map((entry) =>
                      _buildAgendaEntryCard(entry, truckColor)),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildAgendaEntryCard(ScheduleEntry entry, Color truckColor) {
    final timeOn = DateFormat('h:mm a').format(entry.startTime);
    final timeOff = DateFormat('h:mm a').format(entry.endTime);
    final durationMin =
        entry.endTime.difference(entry.startTime).inMinutes;
    final hours = durationMin ~/ 60;
    final mins = durationMin % 60;
    final durationStr = hours > 0
        ? '${hours}h ${mins > 0 ? '${mins}m' : ''}'
        : '${mins}m';
    final isCompleted = entry.status == 'completed';

    final cardContent = Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          // Left color bar
          Container(
            width: 3,
            height: 36,
            decoration: BoxDecoration(
              color: truckColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.site.name,
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '$timeOn – $timeOff  ($durationStr)',
                  style: GoogleFonts.montserrat(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          // Status icons
          if (isCompleted)
            const Icon(Icons.check_circle, size: 18, color: Colors.green),
          if (entry.notes != null && entry.notes!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child:
                  Icon(Icons.sticky_note_2, size: 16, color: Colors.pink[300]),
            ),
          // Drag handle for admin
          if (_isAdmin)
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Icon(Icons.drag_indicator,
                  size: 18, color: Colors.grey[400]),
            ),
        ],
      ),
    );

    // Wrap in LongPressDraggable for admins, tappable for everyone
    if (_isAdmin) {
      return GestureDetector(
        onTap: () => _showEntryActions(entry),
        child: LongPressDraggable<ScheduleEntry>(
          data: entry,
          delay: const Duration(milliseconds: 300),
          feedback: Material(
            elevation: 6,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 180,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: truckColor.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                entry.site.name,
                style: GoogleFonts.montserrat(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          childWhenDragging: Opacity(
            opacity: 0.3,
            child: cardContent,
          ),
          child: cardContent,
        ),
      );
    }

    // Non-admin: just tappable
    return GestureDetector(
      onTap: () => widget.onSwitchToDailyView?.call(entry.startTime),
      child: cardContent,
    );
  }

  Widget _dayAgendaHeader(String label) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.montserrat(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _darkGreen,
              ),
            ),
          ),
          // Tap to switch to daily view
          GestureDetector(
            onTap: () {
              if (_selectedDay != null) {
                widget.onSwitchToDailyView?.call(_selectedDay!);
              }
            },
            child: Row(
              children: [
                Text(
                  'Daily view',
                  style: GoogleFonts.montserrat(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
                Icon(Icons.chevron_right, size: 16, color: Colors.grey[500]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
