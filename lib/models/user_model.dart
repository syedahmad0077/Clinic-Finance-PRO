class UserModel {
  final String id;
  final String name;
  final String role;

  UserModel({
    required this.id,
    required this.name,
    required this.role,
  });

  /// Factory constructor to create a UserModel from a local database record map.
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? 'Unknown Staff',
      role: map['role']?.toString() ?? 'General',
    );
  }

  /// Converts UserModel to a Map for database operations.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'role': role,
    };
  }

  /// Display string for role selection dropdowns (e.g. "Muzaffar (Lab)")
  String get displayName => '$name ($role)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
