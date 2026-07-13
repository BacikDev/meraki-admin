class AdminPatternModel {
  final int id;
  final String titulo;
  final String descripcion;
  final String imagen;
  final String nivel;
  final String fuente;
  final String url;

  final int categoriaId;
  final String categoriaNombre;

  final bool publicado;
  final bool destacado;
  final int orden;

  final DateTime? createdAt;

  const AdminPatternModel({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.imagen,
    required this.nivel,
    required this.fuente,
    required this.url,
    required this.categoriaId,
    required this.categoriaNombre,
    required this.publicado,
    required this.destacado,
    required this.orden,
    this.createdAt,
  });

  factory AdminPatternModel.fromJson(
    Map<String, dynamic> json,
  ) {
    final category = json['categories'];

    String categoryName = 'Sin categoría';

    if (category is Map<String, dynamic>) {
      categoryName =
          category['nombre']?.toString() ?? 'Sin categoría';
    } else if (category is Map) {
      categoryName =
          category['nombre']?.toString() ?? 'Sin categoría';
    } else if (category is List && category.isNotEmpty) {
      final firstCategory = category.first;

      if (firstCategory is Map) {
        categoryName =
            firstCategory['nombre']?.toString() ??
                'Sin categoría';
      }
    }

    return AdminPatternModel(
      id: _toInt(json['id']),
      titulo: json['titulo']?.toString() ?? '',
      descripcion: json['descripcion']?.toString() ?? '',
      imagen: json['imagen']?.toString() ?? '',
      nivel: json['nivel']?.toString() ?? '',
      fuente: json['fuente']?.toString() ?? '',
      url: json['url']?.toString() ?? '',
      categoriaId: _toInt(json['categoria_id']),
      categoriaNombre: categoryName,
      publicado: json['publicado'] as bool? ?? true,
      destacado: json['destacado'] as bool? ?? false,
      orden: _toInt(json['orden']),
      createdAt: DateTime.tryParse(
        json['created_at']?.toString() ?? '',
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'titulo': titulo,
      'descripcion': descripcion,
      'imagen': imagen,
      'nivel': nivel,
      'fuente': fuente,
      'url': url,
      'categoria_id': categoriaId,
      'publicado': publicado,
      'destacado': destacado,
      'orden': orden,
    };
  }

  AdminPatternModel copyWith({
    int? id,
    String? titulo,
    String? descripcion,
    String? imagen,
    String? nivel,
    String? fuente,
    String? url,
    int? categoriaId,
    String? categoriaNombre,
    bool? publicado,
    bool? destacado,
    int? orden,
    DateTime? createdAt,
  }) {
    return AdminPatternModel(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      descripcion: descripcion ?? this.descripcion,
      imagen: imagen ?? this.imagen,
      nivel: nivel ?? this.nivel,
      fuente: fuente ?? this.fuente,
      url: url ?? this.url,
      categoriaId: categoriaId ?? this.categoriaId,
      categoriaNombre:
          categoriaNombre ?? this.categoriaNombre,
      publicado: publicado ?? this.publicado,
      destacado: destacado ?? this.destacado,
      orden: orden ?? this.orden,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}