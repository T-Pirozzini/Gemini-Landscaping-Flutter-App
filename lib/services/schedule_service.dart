import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gemini_landscaping_app/models/equipment_model.dart';
import 'package:gemini_landscaping_app/models/schedule_model.dart';
import 'package:gemini_landscaping_app/models/site_info.dart';

class ScheduleService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<SiteInfo>> fetchActiveSites() async {
    final snapshot = await _firestore
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
        target: (data['target'] as num).toDouble(),
        id: doc.id,
      );
    }).toList();
  }

  Future<List<Equipment>> fetchTrucks() async {
    final snapshot = await _firestore
        .collection('equipment')
        .where('equipmentType', isEqualTo: 'Truck')
        .get();
    return snapshot.docs
        .map((doc) => Equipment.fromMap(doc.id, doc.data()))
        .toList();
  }

  Future<List<ScheduleEntry>> fetchSchedules(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(Duration(days: 1));
    final snapshot = await _firestore
        .collection('Schedules')
        .where('date', isGreaterThanOrEqualTo: startOfDay.toIso8601String())
        .where('date', isLessThan: endOfDay.toIso8601String())
        .get();

    final sites = await fetchActiveSites();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      final site = sites.firstWhere((s) => s.id == data['siteId']);
      return ScheduleEntry.fromMap(doc.id, data, site);
    }).toList();
  }

  Future<void> addTruck(
      String name, int year, String serialNumber, Color color) async {
    await _firestore.collection('equipment').add({
      'name': name,
      'year': year,
      'equipmentType': 'Truck',
      'serialNumber': serialNumber,
      'color': color.value,
    });
  }

  Future<void> addScheduleEntry(ScheduleEntry entry) async {
    await _firestore.collection('Schedules').add(entry.toMap());
  }

  Future<void> updateScheduleEntry(ScheduleEntry entry) async {
    if (entry.id != null) {
      await _firestore
          .collection('Schedules')
          .doc(entry.id)
          .update(entry.toMap());
    }
  }
}
