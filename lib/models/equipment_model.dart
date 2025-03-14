import 'package:flutter/material.dart';

class Equipment {
  final String id;
  final String name;
  final int year;
  final String equipmentType;
  final String serialNumber;
  final Color color;
  final bool active;

  Equipment({
    required this.id,
    required this.name,
    required this.year,
    required this.equipmentType,
    required this.serialNumber,
    required this.color,
    this.active = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'year': year,
      'equipment': equipmentType,
      'serialNumber': serialNumber,
      'color': color.value,
      'active': active,
    };
  }

  factory Equipment.fromMap(String id, Map<String, dynamic> data) {
    return Equipment(
      id: id,
      name: data['name'] as String,
      year: data['year'] as int,
      equipmentType: data['equipmentType'] as String,
      serialNumber: data['serialNumber'] as String,
      color: Color(data['color'] as int? ??
          Colors.blue.value), // Default to blue if missing
      active: data['active'] as bool? ?? true,
    );
  }

  // Add copyWith method to create a new instance with updated values
  Equipment copyWith({String? id, String? name, int? year, String? equipmentType, String? serialNumber, Color? color, bool? active}) {
    return Equipment(
      id: id ?? this.id,
      name: name ?? this.name,
      year: year ?? this.year,
      equipmentType: equipmentType ?? this.equipmentType,
      serialNumber: serialNumber ?? this.serialNumber,
      color: color ?? this.color,
      active: active ?? this.active,
    );
  }
}
