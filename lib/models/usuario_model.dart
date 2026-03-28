class Usuario {
  final int id;
  final String nombre;
  final String usuario; // Campo principal, no puede ser nulo.
  final String rol;
  final bool activo;

  Usuario({
    required this.id,
    required this.nombre,
    required this.usuario,
    required this.rol,
    required this.activo,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    // Lógica robusta: Prioriza 'usuario', pero si falta, usa 'email' como fallback
    // para evitar la excepción de parsing que reporta el usuario.
    final String usuarioPrincipal = json['usuario'] ?? json['email'] ?? 'desconocido';

    if (usuarioPrincipal == 'desconocido' && json['id'] != null) {
      // Si no podemos obtener un identificador, es un problema.
      print("ALERTA: No se pudo determinar el usuario para el id: ${json['id']}");
    }

    return Usuario(
      id: json['id'] as int,
      nombre: json['nombre'] as String,
      usuario: usuarioPrincipal,
      rol: (json['rol'] as String).toLowerCase(),
      // Aseguramos compatibilidad: si 'activo' no viene, asumimos que es true.
      // La API puede devolver 1/0 o true/false, manejamos ambos.
      activo: json['activo'] == null ? true : (json['activo'] is bool ? json['activo'] : json['activo'] == 1),
    );
  }
}
