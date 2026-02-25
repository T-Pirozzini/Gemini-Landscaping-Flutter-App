class AppUser {
  final String uid;
  final String email;
  final String username;
  final String role;
  final bool active;

  const AppUser({
    required this.uid,
    required this.email,
    required this.username,
    required this.role,
    required this.active,
  });

  factory AppUser.fromMap(Map<String, dynamic> map, String uid) {
    return AppUser(
      uid: uid,
      email: map['email'] ?? '',
      username: map['username'] ?? (map['email'] ?? '').split('@')[0],
      role: map['role'] ?? 'employee',
      active: map['active'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'username': username,
      'role': role,
      'active': active,
    };
  }
}
