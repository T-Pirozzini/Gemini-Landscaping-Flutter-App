class SiteReport {
  final String id;
  final String siteName;
  final int totalCombinedDuration;
  final String date;
  final bool filed;
  final List<EmployeeTime> employees;
  final String address;
  final Map<String, List<String>> services;
  final List<MaterialList> materials;
  final String description;
  final List<String> noteTags;
  final String submittedBy;
  final DateTime timestamp;
  final bool isRegularMaintenance;
  final Disposal? disposal;

  SiteReport({
    required this.id,
    required this.siteName,
    required this.totalCombinedDuration,
    required this.date,
    this.filed = false,
    required this.employees,
    required this.address,
    required this.services,
    required this.materials,
    required this.description,
    this.noteTags = const [],
    required this.submittedBy,
    required this.timestamp,
    required this.isRegularMaintenance,
    this.disposal,
  });
}

class EmployeeTime {
  final String name;
  final DateTime timeOn;
  final DateTime timeOff;
  final int duration;

  EmployeeTime({
    required this.name,
    required this.timeOn,
    required this.timeOff,
    required this.duration,
  });
}

class MaterialList {
  final String cost;
  final String description;
  final String vendor;

  MaterialList({
    required this.cost,
    required this.description,
    required this.vendor,
  });
}

class Disposal {
  final bool hasDisposal;
  final String location;
  final String cost;

  Disposal({
    required this.hasDisposal,
    this.location = '',
    this.cost = '',
  });

  factory Disposal.fromMap(Map<String, dynamic> map) {
    return Disposal(
      hasDisposal: map['hasDisposal'] ?? false,
      location: map['location'] ?? '',
      cost: map['cost'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'hasDisposal': hasDisposal,
      'location': location,
      'cost': cost,
    };
  }
}
