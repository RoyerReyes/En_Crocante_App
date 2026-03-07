class Pedido {
  final int id;
  String estado;
  // ... podrías añadir más campos en el futuro, como total, fecha, items, etc.

  Pedido({required this.id, required this.estado});

  // Factory para crear un Pedido desde el JSON que podría enviar el socket
  factory Pedido.fromJson(Map<String, dynamic> json) {
    if (json['id'] == null || json['estado'] == null) {
      throw const FormatException("JSON inválido para crear Pedido.");
    }
    return Pedido(
      id: json['id'] as int,
      estado: json['estado'] as String,
    );
  }
}
