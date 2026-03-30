class Presa {
  final int id;
  final String nombre;
  bool activo;

  Presa({
    required this.id,
    required this.nombre,
    required this.activo,
  });

  factory Presa.fromJson(Map<String, dynamic> json) {
    return Presa(
      id: json['id'],
      nombre: json['nombre'],
      activo: json['activo'] == 1 || json['activo'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'activo': activo,
    };
  }
}
