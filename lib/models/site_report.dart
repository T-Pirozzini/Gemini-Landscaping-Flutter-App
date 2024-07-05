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
  final String submittedBy;
  final DateTime timestamp;

  SiteReport({
    required this.id,
    required this.siteName,
    required this.totalCombinedDuration,
    required this.date,
    this.filed = false, // Add this field if needed in your provider
    required this.employees,
    required this.address,
    required this.services,
    required this.materials,
    required this.description,
    required this.submittedBy,
    required this.timestamp,
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
