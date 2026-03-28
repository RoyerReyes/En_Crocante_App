class Cliente {
  final int id;
  final String nombre;
  final String? dni;
  final String? telefono;
  final String? email;
  final int puntos;

  Cliente({
    required this.id,
    required this.nombre,
    this.dni,
    this.telefono,
    this.email,
    this.puntos = 0,
  });

  factory Cliente.fromJson(Map<String, dynamic> json) {
    return Cliente(
      id: json['id'],
      nombre: json['nombre'],
      dni: json['dni'],
      telefono: json['telefono'],
      email: json['email'],
      puntos: json['puntos'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'dni': dni,
      'telefono': telefono,
      'email': email,
      'puntos': puntos,
    };
  }
}
