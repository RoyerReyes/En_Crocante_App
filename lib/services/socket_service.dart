import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'dio_client.dart';
import 'secure_storage_service.dart';

class SocketService {
  IO.Socket? _socket;
  final SecureStorageService _storageService = SecureStorageService();
  final Function(Map<String, dynamic>) onEstadoActualizado;
  final Function(Map<String, dynamic>)? onNuevoPedido;
  final Function(Map<String, dynamic>)? onItemActualizado;
  final Function(Map<String, dynamic>)? onBroadcastMessage; // Added

  SocketService({
    required this.onEstadoActualizado, 
    this.onNuevoPedido, 
    this.onItemActualizado,
    this.onBroadcastMessage,
  });

  Future<void> connectToServer() async {
    if (_socket != null && _socket!.connected) return;

    try {
      final baseUrl = dio.options.baseUrl;
      final token = await _storageService.getToken();

      if (token == null || token.isEmpty) {
        if (kDebugMode) debugPrint('❌ SocketService: Token inválido');
        return;
      }

      // Configuración optimizada para Socket.IO v4
      _socket = IO.io(baseUrl, IO.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(5)
          .setReconnectionDelay(1000)
          .setAuth({'token': token})
          .build());

      _socket!.onConnect((_) {
        // Conectado
      });

      _socket!.on('estadoPedidoActualizado', (data) {
        if (data is Map<String, dynamic>) {
          onEstadoActualizado(data);
        }
      });

      _socket!.on('pedido_actualizado', (data) {
        if (data is Map<String, dynamic>) {
          onEstadoActualizado(data);
        }
      });

      _socket!.on('estado_actualizado', (data) {
        if (data is Map<String, dynamic>) {
          onEstadoActualizado(data);
        }
      });

      _socket!.on('pedido_creado', (data) {
        if (data is Map<String, dynamic> && onNuevoPedido != null) {
          onNuevoPedido!(data);
        }
      });

      _socket!.on('pedido_item_actualizado', (data) {
        if (data is Map && onItemActualizado != null) {
          onItemActualizado!(Map<String, dynamic>.from(data));
        }
      });

      _socket!.on('broadcast_message', (data) {
        if (data is Map && onBroadcastMessage != null) {
          onBroadcastMessage!(Map<String, dynamic>.from(data));
        }
      });

      _socket!.onDisconnect((_) {});
      _socket!.onConnectError((err) { 
        if (kDebugMode) debugPrint('❌ SocketService: Error conexión: $err');
      });
      _socket!.onError((err) {
        if (kDebugMode) debugPrint('❌ SocketService: Error: $err');
      });

    } catch (e) {
      if (kDebugMode) debugPrint('❌ SocketService: Excepción: $e');
    }
  }

  void disconnect() {
    if (_socket != null) {
      _socket!.disconnect();
      // No seteamos _socket a null inmediatamente por si queremos reconectar, 
      // pero en este caso dispose() probablemente sea el final del ciclo de vida.
    }
  }

  void dispose() {
    disconnect();
    _socket?.dispose();
    _socket = null;
  }
}
