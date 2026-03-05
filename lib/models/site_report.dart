import 'package:cloud_firestore/cloud_firestore.dart';

/// Holds per-phase data for v2 dual-phase reports.
/// A report can have a regularPhase, an additionalPhase, or both.
class ReportPhase {
  final bool isRegularMaintenance;
  final List<EmployeeTime> employees;
  final int totalDuration; // minutes
  final Map<String, List<String>> services;
  final Map<String, List<EmployeeTime>>? serviceEmployees; // per-service time tracking
  final Map<String, String>? serviceNotes; // per-service notes
  final Map<String, List<MaterialList>>? serviceMaterials; // per-service materials
  final Map<String, Disposal>? serviceDisposal; // per-service disposal

  ReportPhase({
    required this.isRegularMaintenance,
    required this.employees,
    required this.totalDuration,
    required this.services,
    this.serviceEmployees,
    this.serviceNotes,
    this.serviceMaterials,
    this.serviceDisposal,
  });

  factory ReportPhase.fromMap(Map<String, dynamic> map) {
    final employeeTimesData =
        map['employeeTimes'] as Map<String, dynamic>? ?? {};
    final employees = employeeTimesData.entries.map((entry) {
      final data = entry.value as Map<String, dynamic>;
      return EmployeeTime(
        name: entry.key,
        timeOn: (data['timeOn'] as Timestamp).toDate(),
        timeOff: (data['timeOff'] as Timestamp).toDate(),
        duration: data['duration'] as int,
      );
    }).toList();

    final servicesData = map['services'] as Map<String, dynamic>? ?? {};
    final services =
        servicesData.map((k, v) => MapEntry(k, List<String>.from(v)));

    // Parse per-service employee times if present
    Map<String, List<EmployeeTime>>? serviceEmployees;
    if (map['serviceEmployees'] != null) {
      final seData = map['serviceEmployees'] as Map<String, dynamic>;
      serviceEmployees = seData.map((serviceName, empMap) {
        final emps = (empMap as Map<String, dynamic>).entries.map((entry) {
          final data = entry.value as Map<String, dynamic>;
          return EmployeeTime(
            name: entry.key,
            timeOn: (data['timeOn'] as Timestamp).toDate(),
            timeOff: (data['timeOff'] as Timestamp).toDate(),
            duration: data['duration'] as int,
          );
        }).toList();
        return MapEntry(serviceName, emps);
      });
    }

    // Parse per-service notes
    Map<String, String>? serviceNotes;
    if (map['serviceNotes'] != null) {
      serviceNotes = Map<String, String>.from(
        map['serviceNotes'] as Map<String, dynamic>,
      );
    }

    // Parse per-service materials
    Map<String, List<MaterialList>>? serviceMaterials;
    if (map['serviceMaterials'] != null) {
      final smData = map['serviceMaterials'] as Map<String, dynamic>;
      serviceMaterials = smData.map((key, value) {
        final matList = (value as List<dynamic>)
            .map((m) => MaterialList.fromMap(m as Map<String, dynamic>))
            .toList();
        return MapEntry(key, matList);
      });
    }

    // Parse per-service disposal
    Map<String, Disposal>? serviceDisposal;
    if (map['serviceDisposal'] != null) {
      final sdData = map['serviceDisposal'] as Map<String, dynamic>;
      serviceDisposal = sdData.map((key, value) =>
          MapEntry(key, Disposal.fromMap(value as Map<String, dynamic>)));
    }

    return ReportPhase(
      isRegularMaintenance: map['isRegularMaintenance'] ?? true,
      employees: employees,
      totalDuration: map['totalCombinedDuration'] ?? 0,
      services: services,
      serviceEmployees: serviceEmployees,
      serviceNotes: serviceNotes,
      serviceMaterials: serviceMaterials,
      serviceDisposal: serviceDisposal,
    );
  }

  Map<String, dynamic> toMap() {
    final employeeTimesMap = <String, dynamic>{};
    for (var emp in employees) {
      employeeTimesMap[emp.name] = {
        'timeOn': Timestamp.fromDate(emp.timeOn),
        'timeOff': Timestamp.fromDate(emp.timeOff),
        'duration': emp.duration,
      };
    }
    final map = <String, dynamic>{
      'isRegularMaintenance': isRegularMaintenance,
      'employeeTimes': employeeTimesMap,
      'totalCombinedDuration': totalDuration,
      'services': services,
    };
    if (serviceEmployees != null) {
      map['serviceEmployees'] = serviceEmployees!.map((service, emps) {
        final empMap = <String, dynamic>{};
        for (var emp in emps) {
          empMap[emp.name] = {
            'timeOn': Timestamp.fromDate(emp.timeOn),
            'timeOff': Timestamp.fromDate(emp.timeOff),
            'duration': emp.duration,
          };
        }
        return MapEntry(service, empMap);
      });
    }
    if (serviceNotes != null && serviceNotes!.isNotEmpty) {
      map['serviceNotes'] = serviceNotes;
    }
    if (serviceMaterials != null && serviceMaterials!.isNotEmpty) {
      map['serviceMaterials'] = serviceMaterials!.map((key, matList) =>
          MapEntry(key, matList.map((m) => m.toMap()).toList()));
    }
    if (serviceDisposal != null && serviceDisposal!.isNotEmpty) {
      map['serviceDisposal'] = serviceDisposal!
          .map((key, d) => MapEntry(key, d.toMap()));
    }
    return map;
  }

  ReportPhase copyWith({
    bool? isRegularMaintenance,
    List<EmployeeTime>? employees,
    int? totalDuration,
    Map<String, List<String>>? services,
    Map<String, List<EmployeeTime>>? serviceEmployees,
    Map<String, String>? serviceNotes,
    Map<String, List<MaterialList>>? serviceMaterials,
    Map<String, Disposal>? serviceDisposal,
  }) {
    return ReportPhase(
      isRegularMaintenance: isRegularMaintenance ?? this.isRegularMaintenance,
      employees: employees ?? this.employees,
      totalDuration: totalDuration ?? this.totalDuration,
      services: services ?? this.services,
      serviceEmployees: serviceEmployees ?? this.serviceEmployees,
      serviceNotes: serviceNotes ?? this.serviceNotes,
      serviceMaterials: serviceMaterials ?? this.serviceMaterials,
      serviceDisposal: serviceDisposal ?? this.serviceDisposal,
    );
  }
}

class SiteReport {
  final String id;
  final int version; // 1 for legacy, 2 for new dual-phase
  final String status; // 'submitted' or 'draft'
  final String? draftOwnerId;
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
  final ReportPhase? regularPhase;
  final ReportPhase? additionalPhase;

  SiteReport({
    required this.id,
    this.version = 1,
    this.status = 'submitted',
    this.draftOwnerId,
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
    this.regularPhase,
    this.additionalPhase,
  });

  bool get isDraft => status == 'draft';
  bool get hasBothPhases => regularPhase != null && additionalPhase != null;

  /// Create a v2 SiteReport from phases.
  /// Flat fields (employees, services, totalCombinedDuration) are computed
  /// by merging both phases for backward compat with existing views.
  factory SiteReport.fromPhases({
    String id = '',
    required String siteName,
    required String date,
    required String address,
    required String submittedBy,
    required DateTime timestamp,
    required List<MaterialList> materials,
    Disposal? disposal,
    List<String> noteTags = const [],
    String description = '',
    String status = 'submitted',
    String? draftOwnerId,
    bool filed = false,
    ReportPhase? regularPhase,
    ReportPhase? additionalPhase,
  }) {
    // Merge employees from both phases
    final allEmployees = <EmployeeTime>[
      ...?regularPhase?.employees,
      ...?additionalPhase?.employees,
    ];

    // Sum durations
    final totalDuration =
        (regularPhase?.totalDuration ?? 0) +
        (additionalPhase?.totalDuration ?? 0);

    // Merge services (union of both phases)
    final mergedServices = <String, List<String>>{};
    void addServices(Map<String, List<String>> s) {
      for (var entry in s.entries) {
        mergedServices.putIfAbsent(entry.key, () => []);
        for (var item in entry.value) {
          if (!mergedServices[entry.key]!.contains(item)) {
            mergedServices[entry.key]!.add(item);
          }
        }
      }
    }

    if (regularPhase != null) addServices(regularPhase.services);
    if (additionalPhase != null) addServices(additionalPhase.services);

    return SiteReport(
      id: id,
      version: 2,
      status: status,
      draftOwnerId: draftOwnerId,
      siteName: siteName,
      totalCombinedDuration: totalDuration,
      date: date,
      filed: filed,
      employees: allEmployees,
      address: address,
      services: mergedServices,
      materials: materials,
      description: description,
      noteTags: noteTags,
      submittedBy: submittedBy,
      timestamp: timestamp,
      isRegularMaintenance: regularPhase != null,
      disposal: disposal,
      regularPhase: regularPhase,
      additionalPhase: additionalPhase,
    );
  }

  Map<String, dynamic> toMap() {
    final employeeTimesMap = <String, dynamic>{};
    for (var emp in employees) {
      employeeTimesMap[emp.name] = {
        'timeOn': Timestamp.fromDate(emp.timeOn),
        'timeOff': Timestamp.fromDate(emp.timeOff),
        'duration': emp.duration,
      };
    }

    final map = <String, dynamic>{
      'version': version,
      'status': status,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRegularMaintenance': isRegularMaintenance,
      'employeeTimes': employeeTimesMap,
      'totalCombinedDuration': totalCombinedDuration,
      'siteInfo': {
        'date': date,
        'siteName': siteName,
        'address': address,
      },
      'services': services,
      'materials': materials.map((m) => m.toMap()).toList(),
      'disposal': disposal?.toMap() ?? Disposal(hasDisposal: false).toMap(),
      'noteTags': noteTags,
      'description': description,
      'submittedBy': submittedBy,
      'filed': filed,
    };

    if (draftOwnerId != null) map['draftOwnerId'] = draftOwnerId!;
    if (regularPhase != null) map['regularPhase'] = regularPhase!.toMap();
    if (additionalPhase != null) {
      map['additionalPhase'] = additionalPhase!.toMap();
    }

    return map;
  }

  SiteReport copyWith({
    String? id,
    int? version,
    String? status,
    String? draftOwnerId,
    String? siteName,
    int? totalCombinedDuration,
    String? date,
    bool? filed,
    List<EmployeeTime>? employees,
    String? address,
    Map<String, List<String>>? services,
    List<MaterialList>? materials,
    String? description,
    List<String>? noteTags,
    String? submittedBy,
    DateTime? timestamp,
    bool? isRegularMaintenance,
    Disposal? disposal,
    ReportPhase? regularPhase,
    ReportPhase? additionalPhase,
  }) {
    return SiteReport(
      id: id ?? this.id,
      version: version ?? this.version,
      status: status ?? this.status,
      draftOwnerId: draftOwnerId ?? this.draftOwnerId,
      siteName: siteName ?? this.siteName,
      totalCombinedDuration:
          totalCombinedDuration ?? this.totalCombinedDuration,
      date: date ?? this.date,
      filed: filed ?? this.filed,
      employees: employees ?? this.employees,
      address: address ?? this.address,
      services: services ?? this.services,
      materials: materials ?? this.materials,
      description: description ?? this.description,
      noteTags: noteTags ?? this.noteTags,
      submittedBy: submittedBy ?? this.submittedBy,
      timestamp: timestamp ?? this.timestamp,
      isRegularMaintenance: isRegularMaintenance ?? this.isRegularMaintenance,
      disposal: disposal ?? this.disposal,
      regularPhase: regularPhase ?? this.regularPhase,
      additionalPhase: additionalPhase ?? this.additionalPhase,
    );
  }
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

  factory MaterialList.fromMap(Map<String, dynamic> map) {
    return MaterialList(
      cost: map['cost'] ?? '',
      description: map['description'] ?? '',
      vendor: map['vendor'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'cost': cost,
      'description': description,
      'vendor': vendor,
    };
  }
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
