import 'package:flutter/foundation.dart';

// Modelo para el objeto anidado 'categoria'
class Categoria {
  final int id;
  final String nombre;

  Categoria({required this.id, required this.nombre});

  factory Categoria.fromJson(Map<String, dynamic> json) {
    return Categoria(
      id: json['id'] as int,
      nombre: json['nombre'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
    };
  }
}

class Platillo {
  final int id;
  final String nombre;
  final String? descripcion;
  final double precio;
  final String? imagenUrl;
  final bool activo;
  final Categoria categoria;

  Platillo({
    required this.id,
    required this.nombre,
    this.descripcion,
    required this.precio,
    this.imagenUrl,
    required this.activo,
    required this.categoria,
  });

  factory Platillo.fromJson(Map<String, dynamic> json) {
    final dynamic rawPrecio = json['precio'];
    double parsedPrecio;

    if (rawPrecio is String) {
      parsedPrecio = double.parse(rawPrecio);
    } else if (rawPrecio is num) {
      parsedPrecio = rawPrecio.toDouble();
    } else {
      throw FormatException('Precio con formato inesperado: $rawPrecio');
    }

    final dynamic rawActivo = json['activo'];
    bool parsedActivo;
    if (rawActivo is int) {
      parsedActivo = rawActivo == 1;
    } else if (rawActivo is bool) {
      parsedActivo = rawActivo;
    } else if (rawActivo is String) {
      parsedActivo = rawActivo == '1' || rawActivo.toLowerCase() == 'true';
    } else {
      parsedActivo = false;
    }

    // Debug raw json
    debugPrint('Platillo.fromJson: id=${json['id']}, imagen_url=${json['imagen_url']}, imagenUrl=${json['imagenUrl']}');
    
    return Platillo(
      id: json['id'] as int,
      nombre: json['nombre'] as String,
      descripcion: json['descripcion'] as String?,
      precio: parsedPrecio,
      imagenUrl: json['imagen_url'] as String?,
      activo: parsedActivo,
      categoria: Categoria.fromJson(json['categoria'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'precio': precio,
      'imagenUrl': imagenUrl,
      'activo': activo,
      'categoria': categoria.toJson(),
    };
  }
}
