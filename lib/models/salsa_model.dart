class Salsa {
  final int id;
  final String nombre;
  bool activo;

  Salsa({
    required this.id,
    required this.nombre,
    required this.activo,
  });

  factory Salsa.fromJson(Map<String, dynamic> json) {
    return Salsa(
      id: json['id'],
      nombre: json['nombre'],
      activo: json['activo'] == 1 || json['activo'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'activo': activo ? 1 : 0,
    };
  }
}
