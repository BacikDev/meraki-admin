class AdminCategoryModel {
  final int id;
  final String nombre;
  final String imagen;
  final String? descripcion;
  final DateTime? createdAt;

  const AdminCategoryModel({
    required this.id,
    required this.nombre,
    required this.imagen,
    this.descripcion,
    this.createdAt,
  });

  factory AdminCategoryModel.fromJson(Map<String, dynamic> json) {
    return AdminCategoryModel(
      id: json['id'] ?? 0,
      nombre: json['nombre'] ?? '',
      imagen: json['imagen'] ?? '',
      descripcion: json['descripcion'],
      createdAt: json['created_at'] == null
          ? null
          : DateTime.tryParse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'imagen': imagen,
      'descripcion': descripcion,
    };
  }

  AdminCategoryModel copyWith({
    int? id,
    String? nombre,
    String? imagen,
    String? descripcion,
    DateTime? createdAt,
  }) {
    return AdminCategoryModel(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      imagen: imagen ?? this.imagen,
      descripcion: descripcion ?? this.descripcion,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}