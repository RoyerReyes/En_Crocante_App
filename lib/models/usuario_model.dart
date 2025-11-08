class Usuario {
  final int id;
  final String nombre;
  final String usuario;
  final String rol;

  Usuario({
    required this.id,
    required this.nombre,
    required this.usuario,
    required this.rol,
  });

  // Un "factory constructor" para crear una instancia de Usuario desde un mapa.
  // Esto es muy común al trabajar con datos JSON.
  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id'] as int,
      nombre: json['nombre'] as String,
      usuario: json['usuario'] as String,
      rol: json['rol'] as String,
    );
  }
}
