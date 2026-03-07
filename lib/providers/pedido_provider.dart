import 'package:flutter/material.dart';
import '../models/pedido_model.dart';

class PedidoProvider extends ChangeNotifier {
  final List<Pedido> _pedidos = [];

  List<Pedido> get pedidos => _pedidos;

  // Simula la carga inicial de pedidos desde una API REST.
  // En el futuro, aquí harías una llamada http.get a tu endpoint de pedidos.
  void cargarPedidosIniciales() {
    // Datos de ejemplo para simular la carga inicial.
    _pedidos.clear(); // Limpiamos para evitar duplicados si se llama varias veces
    _pedidos.addAll([
      Pedido(id: 1, estado: 'recibido'),
      Pedido(id: 2, estado: 'recibido'),
      Pedido(id: 3, estado: 'en_preparacion'),
    ]);
    // No es necesario notificar listeners aquí, la UI se construirá con estos datos.
  }

  /// **Método clave que será llamado por el SocketService a través de un callback.**
  void actualizarEstadoDesdeSocket(Map<String, dynamic> data) {
    try {
      final int pedidoId = data['id'];
      final String nuevoEstado = data['estado'];

      // Buscamos el pedido en nuestra lista local.
      final index = _pedidos.indexWhere((p) => p.id == pedidoId);

      if (index != -1) {
        // Si lo encontramos, actualizamos su estado.
        _pedidos[index].estado = nuevoEstado;
        debugPrint('✅ Provider: Pedido $pedidoId actualizado a $nuevoEstado');

        // ¡La magia de Provider! Notifica a todos los widgets que escuchan para que se redibujen.
        notifyListeners();
      } else {
        debugPrint('⚠️ Provider: Pedido $pedidoId no encontrado en la lista local.');
      }
    } catch (e) {
      debugPrint('❌ Provider: Error al procesar datos del socket: $e');
    }
  }
}
