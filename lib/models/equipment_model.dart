import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Equipment {
  final String id;
  final String name;
  final int year;
  final String equipmentType;
  final String serialNumber;
  final Color color;
  final bool active;
  final String? imageUrl;
  final int? mileage;
  final DateTime? lastServiceDate;
  final String? lastServiceNotes;
  final String currentStatus; // 'operational', 'needs-attention', 'out-of-service'

  Equipment({
    required this.id,
    required this.name,
    required this.year,
    required this.equipmentType,
    required this.serialNumber,
    required this.color,
    this.active = true,
    this.imageUrl,
    this.mileage,
    this.lastServiceDate,
    this.lastServiceNotes,
    this.currentStatus = 'operational',
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'name': name,
      'year': year,
      'equipmentType': equipmentType,
      'serialNumber': serialNumber,
      'color': color.toARGB32(),
      'active': active,
      'currentStatus': currentStatus,
    };
    if (imageUrl != null) map['imageUrl'] = imageUrl;
    if (mileage != null) map['mileage'] = mileage;
    if (lastServiceDate != null) {
      map['lastServiceDate'] = Timestamp.fromDate(lastServiceDate!);
    }
    if (lastServiceNotes != null) map['lastServiceNotes'] = lastServiceNotes;
    return map;
  }

  factory Equipment.fromMap(String id, Map<String, dynamic> data) {
    return Equipment(
      id: id,
      name: data['name'] as String? ?? '',
      year: data['year'] as int? ?? 0,
      // Handle both old key ('equipment') and new key ('equipmentType')
      equipmentType:
          (data['equipmentType'] ?? data['equipment']) as String? ?? '',
      serialNumber: data['serialNumber'] as String? ?? '',
      color: Color(data['color'] as int? ?? 0xFF2196F3),
      active: data['active'] as bool? ?? true,
      imageUrl: data['imageUrl'] as String?,
      mileage: data['mileage'] as int?,
      lastServiceDate: data['lastServiceDate'] != null
          ? (data['lastServiceDate'] as Timestamp).toDate()
          : null,
      lastServiceNotes: data['lastServiceNotes'] as String?,
      currentStatus: data['currentStatus'] as String? ?? 'operational',
    );
  }

  Equipment copyWith({
    String? id,
    String? name,
    int? year,
    String? equipmentType,
    String? serialNumber,
    Color? color,
    bool? active,
    String? imageUrl,
    int? mileage,
    DateTime? lastServiceDate,
    String? lastServiceNotes,
    String? currentStatus,
  }) {
    return Equipment(
      id: id ?? this.id,
      name: name ?? this.name,
      year: year ?? this.year,
      equipmentType: equipmentType ?? this.equipmentType,
      serialNumber: serialNumber ?? this.serialNumber,
      color: color ?? this.color,
      active: active ?? this.active,
      imageUrl: imageUrl ?? this.imageUrl,
      mileage: mileage ?? this.mileage,
      lastServiceDate: lastServiceDate ?? this.lastServiceDate,
      lastServiceNotes: lastServiceNotes ?? this.lastServiceNotes,
      currentStatus: currentStatus ?? this.currentStatus,
    );
  }
}
