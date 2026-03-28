import 'package:flutter/material.dart';

class PedidoEstados {
  static const String recibido = 'recibido'; // Nuevo estado inicial
  static const String pendiente = 'pendiente';
  static const String enPreparacion = 'en_preparacion';
  static const String listo = 'listo';
  static const String entregado = 'entregado';
  static const String cancelado = 'cancelado';
  static const String pagado = 'pagado'; // Nuevo estado final

  // Activos: Desde que se crea hasta que se entrega en mesa (Esperando pago)
  static const List<String> activos = [recibido, pendiente, enPreparacion, listo, entregado];
  
  // Historial: Ya pagados o cancelados (Cerrados)
  static const List<String> historial = [pagado, cancelado];

  static Color getColor(String estado) {
    switch (estado) {
      case recibido:
      case pendiente:
        return const Color(0xFFFF9800); // Orange
      case enPreparacion:
        return const Color(0xFF2196F3); // Blue
      case listo:
        return const Color(0xFF4CAF50);
      case entregado:
        return const Color(0xFF795548); // Brown/Served
      case pagado:
        return const Color(0xFF9E9E9E); // Grey/Closed
      case cancelado:
        return const Color(0xFFF44336);
      default:
        return Colors.black;
    }
  }

  static String getLabel(String estado) {
    switch (estado) {
      case recibido:
        return 'Recibido';
      case pendiente:
        return 'Pendiente';
      case enPreparacion:
        return 'En Preparación';
      case listo:
        return 'Listo para Servir';
      case entregado:
        return 'En Mesa (Por Cobrar)';
      case pagado:
        return 'Pagado';
      case cancelado:
        return 'Cancelado';
      default:
        return estado.toUpperCase();
    }
  }

  static bool esActivo(String estado) {
    return activos.contains(estado);
  }

  static bool esHistorial(String estado) {
    return historial.contains(estado);
  }
}
