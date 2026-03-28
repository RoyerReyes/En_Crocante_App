import 'package:encrocante_app/models/platillo_model.dart';
import 'package:flutter/foundation.dart'; // Para UniqueKey

class CartItem {
  final String uniqueId; // NEW
  final Platillo platillo;
  final int cantidad; // mantenemos para compatibilidad estricta
  final String? notas;

  CartItem({
    String? uniqueId,
    required this.platillo,
    this.cantidad = 1,
    this.notas,
  }) : uniqueId = uniqueId ?? UniqueKey().toString();

  CartItem copyWith({
    Platillo? platillo,
    int? cantidad,
    String? notas,
    bool clearNotas = false,
  }) {
    return CartItem(
      uniqueId: this.uniqueId,
      platillo: platillo ?? this.platillo,
      cantidad: cantidad ?? this.cantidad,
      notas: clearNotas ? null : (notas ?? this.notas),
    );
  }

  double get subtotal => platillo.precio * cantidad;

  Map<String, dynamic> toJson() {
    return {
      'platillo': platillo.toJson(),
      'cantidad': cantidad,
      'notas': notas,
    };
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      platillo: Platillo.fromJson(json['platillo']),
      cantidad: json['cantidad'] as int,
      notas: json['notas'] as String?,
    );
  }
}
