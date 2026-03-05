class ManagementCompany {
  final String id;
  final String name;
  final String imageUrl;

  const ManagementCompany({
    required this.id,
    required this.name,
    required this.imageUrl,
  });

  factory ManagementCompany.fromMap(Map<String, dynamic> map, String id) {
    return ManagementCompany(
      id: id,
      name: map['name'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'imageUrl': imageUrl,
    };
  }
}
