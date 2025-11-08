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
}

class Platillo {
  final int id;
  final String nombre;
  final String? descripcion;
  final double precio;
  final String? imagenUrl;
  final bool activo; // El tipo de dato sigue siendo bool
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

    // CORRECCIÓN: Manejo flexible para el campo 'activo'.
    // Si viene como int (1 o 0), lo convertimos a bool.
    // Si ya viene como bool, lo usamos directamente.
    final dynamic rawActivo = json['activo'];
    bool parsedActivo;
    if (rawActivo is int) {
      parsedActivo = rawActivo == 1;
    } else if (rawActivo is bool) {
      parsedActivo = rawActivo;
    } else {
      // Valor por defecto o error si el tipo es inesperado.
      parsedActivo = false; 
    }

    return Platillo(
      id: json['id'] as int,
      nombre: json['nombre'] as String,
      descripcion: json['descripcion'] as String?,
      precio: parsedPrecio,
      imagenUrl: json['imagenUrl'] as String?,
      activo: parsedActivo, // Usamos el valor parseado
      categoria: Categoria.fromJson(json['categoria'] as Map<String, dynamic>),
    );
  }
}
