class PedidoDetalle {
  final int id;
  final int platilloId;
  final int cantidad;
  final double precioUnitario;
  final String? notas;
  final String? nombrePlatillo;
  final bool listo; // Nuevo campo

  PedidoDetalle({
    required this.id,
    required this.platilloId,
    required this.cantidad,
    required this.precioUnitario,
    this.notas,
    this.nombrePlatillo,
    this.listo = false, // Default false
  });

  double get subtotal => cantidad * precioUnitario;

  factory PedidoDetalle.fromJson(Map<String, dynamic> json) {
    return PedidoDetalle(
      id: json['id'] as int,
      platilloId: json['platillo_id'] as int,
      cantidad: json['cantidad'] as int,
      precioUnitario: double.parse(json['precio_unitario'].toString()),
      notas: json['nota'] as String?,
      nombrePlatillo: json['platillo_nombre'] as String?,
      listo: json['listo'] == 1 || json['listo'] == true, // Handle MySQL pseudo-boolean
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'id': id,
      'platillo_id': platilloId,
      'cantidad': cantidad,
      'precio_unitario': precioUnitario,
      'listo': listo,
    };
    if (notas != null) {
      data['notas'] = notas;
    }
    return data;
  }
}


class Pedido {
  final int id;
  final int? mesaId;
  final int? usuarioId;
  final int? clienteId; // Nuevo campo
  final String? nombreCliente;
  final String? nombreMesero;
  final String? observaciones;
  final String? metodoPago; 
  final double? montoRecibido;
  final double? vuelto;
  final double? descuento;
  final int? puntosCanjeados;
  final String estado;
  final String tipo; // 'mesa', 'delivery', 'recojo'
  final double total;
  final double? costoDelivery;
  final DateTime createdAt;
  final List<PedidoDetalle> detalles;

  Pedido({
    required this.id,
    this.mesaId,
    this.usuarioId,
    this.clienteId,
    this.nombreCliente,
    this.nombreMesero,
    this.observaciones,
    this.metodoPago,
    this.montoRecibido,
    this.vuelto,
    this.descuento,
    this.puntosCanjeados,
    required this.estado,
    required this.tipo,
    required this.total,
    this.costoDelivery,
    required this.createdAt,
    required this.detalles,
  });

  factory Pedido.fromJson(Map<String, dynamic> json) {
    var detallesList = json['detalles'] as List?;
    List<PedidoDetalle> _detalles = [];
    if (detallesList != null) {
      _detalles = detallesList.map((i) => PedidoDetalle.fromJson(i as Map<String, dynamic>)).toList();
    }

    return Pedido(
      id: json['id'] as int,
      mesaId: json['mesa_id'] as int?,
      usuarioId: json['usuario_id'] as int?,
      clienteId: json['cliente_id'] as int?,
      nombreCliente: json['nombre_cliente'] as String?,
      nombreMesero: json['mesero'] as String?,
      observaciones: json['observaciones'] as String?,
      metodoPago: json['metodo_pago'] as String?,
      montoRecibido: json['monto_recibido'] != null ? double.tryParse(json['monto_recibido'].toString()) : null,
      vuelto: json['vuelto'] != null ? double.tryParse(json['vuelto'].toString()) : null,
      descuento: json['descuento'] != null ? double.tryParse(json['descuento'].toString()) : null,
      puntosCanjeados: json['puntos_canjeados'] as int?,
      estado: json['estado'] as String,
      tipo: json['tipo'] as String? ?? 'mesa', // Default fallback
      total: double.parse(json['total'].toString()),
      costoDelivery: json['costo_delivery'] != null ? double.tryParse(json['costo_delivery'].toString()) : null,
      createdAt: DateTime.parse(json['fecha'] as String),
      detalles: _detalles,
    );
  }

  Pedido copyWith({
    int? id,
    int? mesaId,
    int? usuarioId,
    int? clienteId,
    String? nombreCliente,
    String? nombreMesero,
    String? observaciones,
    String? metodoPago,
    double? montoRecibido,
    double? vuelto,
    double? descuento,
    int? puntosCanjeados,
    String? estado,
    String? tipo,
    double? total,
    double? costoDelivery,
    DateTime? createdAt,
    List<PedidoDetalle>? detalles,
  }) {
    return Pedido(
      id: id ?? this.id,
      mesaId: mesaId ?? this.mesaId,
      usuarioId: usuarioId ?? this.usuarioId,
      clienteId: clienteId ?? this.clienteId,
      nombreCliente: nombreCliente ?? this.nombreCliente,
      nombreMesero: nombreMesero ?? this.nombreMesero,
      observaciones: observaciones ?? this.observaciones,
      metodoPago: metodoPago ?? this.metodoPago,
      montoRecibido: montoRecibido ?? this.montoRecibido,
      vuelto: vuelto ?? this.vuelto,
      descuento: descuento ?? this.descuento,
      puntosCanjeados: puntosCanjeados ?? this.puntosCanjeados,
      estado: estado ?? this.estado,
      tipo: tipo ?? this.tipo,
      total: total ?? this.total,
      costoDelivery: costoDelivery ?? this.costoDelivery,
      createdAt: createdAt ?? this.createdAt,
      detalles: detalles ?? this.detalles,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mesa_id': mesaId,
      'usuario_id': usuarioId,
      'cliente_id': clienteId,
      'nombre_cliente': nombreCliente,
      'mesero': nombreMesero,
      'metodo_pago': metodoPago,
      'monto_recibido': montoRecibido,
      'vuelto': vuelto,
      'descuento': descuento,
      'puntos_canjeados': puntosCanjeados,
      'estado': estado,
      'tipo': tipo,
      'total': total,
      'costo_delivery': costoDelivery,
      'fecha': createdAt.toIso8601String(),
      'detalles': detalles.map((d) => d.toJson()).toList(),
    };
  }
}
