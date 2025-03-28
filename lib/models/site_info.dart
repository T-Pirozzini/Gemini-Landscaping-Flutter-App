class SiteInfo {
  final String address;
  final String imageUrl;
  final String management;
  final String name;
  final bool status;
  final double target;
  final String id;
  final bool program;

  const SiteInfo({
    required this.address,
    required this.imageUrl,
    required this.management,
    required this.name,
    required this.status,
    required this.target,
    required this.id,
    required this.program,
  });

  // Convert SiteInfo to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'address': address,
      'imageUrl': imageUrl,
      'management': management,
      'name': name,
      'status': status,
      'target': target,
      'id': id,
      'program': program,
    };
  }

  // Factory constructor to create SiteInfo from Firestore (optional for now)
  factory SiteInfo.fromMap(Map<String, dynamic> map, String id) {
    return SiteInfo(
      address: map['address'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      management: map['management'] ?? '',
      name: map['name'] ?? '',
      status: map['status'] ?? false,
      target: (map['target'] as num?)?.toDouble() ?? 0.0,
      id: id,
      program: map['program'] ?? true,
    );
  }
}
