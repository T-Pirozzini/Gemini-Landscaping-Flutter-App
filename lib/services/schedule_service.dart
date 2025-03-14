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

  Future<List<Equipment>> fetchActiveTrucks() async {
    final snapshot = await _firestore
        .collection('equipment')
        .where('equipmentType', isEqualTo: 'Truck')
        .where('active', isEqualTo: true)
        .get();
    return snapshot.docs
        .map((doc) => Equipment.fromMap(doc.id, doc.data()))
        .toList();
  }

  Future<List<Equipment>> fetchAllTrucks() async {
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
      final site = sites.firstWhere(
        (s) => s.id == data['siteId'],
        orElse: () =>
            throw Exception('Site not found for siteId: ${data['siteId']}'),
      );
      return ScheduleEntry.fromMap(doc.id, data, site);
    }).toList();
  }

  Future<void> addTruck(String name, int year, String serialNumber, Color color,
      {bool isActive = true}) async {
    await _firestore.collection('equipment').add({
      'name': name,
      'year': year,
      'equipmentType': 'Truck',
      'serialNumber': serialNumber,
      'color': color.value,
      'active': isActive,
    });
  }

  Future<void> updateTruck(String truckId, bool active, Color color) async {
    try {
      print(
          'Updating truck $truckId with active: $active, color: ${color.value} (hex: ${color.value.toRadixString(16).padLeft(8, '0')})');
      await _firestore
          .collection('equipment')
          .doc(truckId)
          .update({'active': active, 'color': color.value});
      print('Truck $truckId updated successfully');
      // Fetch and print the updated document to verify
      final updatedDoc =
          await _firestore.collection('equipment').doc(truckId).get();
      print('Verified updated data: ${updatedDoc.data()}');
    } catch (e) {
      print('Error updating truck $truckId: $e');
      throw Exception('Failed to update truck: $e');
    }
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

  Future<void> updateScheduleEntryNotes(
      String scheduleEntryId, String notes) async {
    try {
      await _firestore.collection('Schedules').doc(scheduleEntryId).update({
        'notes': notes,
      });
      print('Updated notes for schedule entry $scheduleEntryId');
    } catch (e) {
      print('Error updating notes for schedule entry $scheduleEntryId: $e');
      throw Exception('Failed to update notes: $e');
    }
  }

  Future<void> deleteScheduleEntry(String scheduleEntryId) async {
    try {
      await _firestore.collection('Schedules').doc(scheduleEntryId).delete();
      print('Deleted schedule entry $scheduleEntryId');
    } catch (e) {
      print('Error deleting schedule entry $scheduleEntryId: $e');
      throw Exception('Failed to delete schedule entry: $e');
    }
  }
}
