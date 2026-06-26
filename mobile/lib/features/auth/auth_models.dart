class AuthUser {
  AuthUser({required this.id, this.fullName, required this.email, required this.role, this.permissions = const []});

  final String id;
  final String? fullName;
  final String email;
  final String role;
  final List<String> permissions;

  factory AuthUser.fromJson(Map<String, dynamic> j) => AuthUser(
        id: j['id'] as String,
        fullName: j['fullName'] as String?,
        email: j['email'] as String,
        role: j['role'] as String? ?? 'VIEWER',
        permissions: (j['permissions'] as List?)?.cast<String>() ?? const [],
      );
}
