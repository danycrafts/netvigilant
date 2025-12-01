class AuthUser {
  final String id;
  final String email;
  final DateTime createdAt;

  const AuthUser({
    required this.id,
    required this.email,
    required this.createdAt,
  });

  AuthUser copyWith({
    String? id,
    String? email,
    DateTime? createdAt,
  }) {
    return AuthUser(
      id: id ?? this.id,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthUser &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          email == other.email &&
          createdAt == other.createdAt;

  @override
  int get hashCode => id.hashCode ^ email.hashCode ^ createdAt.hashCode;

  @override
  String toString() => 'AuthUser(id: $id, email: $email, createdAt: $createdAt)';
}