class AdminUserModel {
  final String id;
  final String nombre;
  final String email;
  final String avatarUrl;
  final String role;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AdminUserModel({
    required this.id,
    required this.nombre,
    required this.email,
    required this.avatarUrl,
    required this.role,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  factory AdminUserModel.fromJson(Map<String, dynamic> json) {
    return AdminUserModel(
      id: json['id']?.toString() ?? '',
      nombre: json['nombre']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      avatarUrl: json['avatar_url']?.toString() ?? '',
      role: json['role']?.toString() ?? 'user',
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.tryParse(
        json['created_at']?.toString() ?? '',
      ),
      updatedAt: DateTime.tryParse(
        json['updated_at']?.toString() ?? '',
      ),
    );
  }

  String get displayName {
    final cleanName = nombre.trim();

    if (cleanName.isNotEmpty) {
      return cleanName;
    }

    final cleanEmail = email.trim();

    if (cleanEmail.isNotEmpty) {
      return cleanEmail.split('@').first;
    }

    return 'Usuario';
  }

  String get roleLabel {
    switch (role.toLowerCase()) {
      case 'admin':
        return 'Administrador';
      case 'editor':
        return 'Editor';
      default:
        return 'Usuario';
    }
  }

  AdminUserModel copyWith({
    String? id,
    String? nombre,
    String? email,
    String? avatarUrl,
    String? role,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AdminUserModel(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}