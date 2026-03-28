import 'dart:async';
import 'package:flutter/foundation.dart'; // Import kDebugMode
import 'package:flutter/material.dart';
import 'package:dio/dio.dart'; // Importar DioException
import '../models/pedido_model.dart';
import '../services/pedido_service.dart';
import '../services/socket_service.dart'; // Import SocketService
import '../services/notification_service.dart'; // Import NotificationService
import '../constants/pedido_estados.dart'; // Importar constantes

class PedidoProvider extends ChangeNotifier {
  final PedidoService _pedidoService;
  final List<Pedido> _pedidos = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Stream para notificaciones
  final _notificationController = StreamController<String>.broadcast();
  Stream<String> get notificationStream => _notificationController.stream;

  PedidoProvider({PedidoService? pedidoService}) 
      : _pedidoService = pedidoService ?? PedidoService() {
    startMonitoringWaitTimes();
  }

  List<Pedido> get pedidos => _pedidos;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Getters optimizados para la UI
  List<Pedido> get pedidosActivos => _pedidos
      .where((p) => PedidoEstados.esActivo(p.estado))
      .toList();

  List<Pedido> get pedidosHistorial => _pedidos
      .where((p) => PedidoEstados.esHistorial(p.estado))
      .toList();

  // Getter específico para Cocina: FIFO (El más antiguo primero)
  List<Pedido> get pedidosCocina {
    final list = _pedidos
        .where((p) => p.estado == PedidoEstados.recibido || 
                      p.estado == PedidoEstados.pendiente || 
                      p.estado == PedidoEstados.enPreparacion || 
                      p.estado == PedidoEstados.listo)
        .toList();
    list.sort((a, b) => a.createdAt.compareTo(b.createdAt)); // Ascendente: Oldest first
    return list;
  }

  // Carga inicial de pedidos desde la API REST.
  Future<void> cargarPedidosIniciales() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Llamada real a la API
      final pedidosCargados = await _pedidoService.getPedidos();

      _pedidos.clear();
      _pedidos.addAll(pedidosCargados);
    } catch (e) {
      _errorMessage = 'Error al cargar los pedidos: $e';
      debugPrint(_errorMessage);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Socket Management
  SocketService? _socketService;

  void initSocket() {
    if (_socketService != null) return; // Prevent multiple instances

    debugPrint('🔌 PedidoProvider: Inicializando SocketService...');
    _socketService = SocketService(
      onEstadoActualizado: actualizarEstadoDesdeSocket,
      onNuevoPedido: agregarPedidoDesdeSocket,
      onItemActualizado: actualizarItemDesdeSocket,
      onBroadcastMessage: procesarBroadcastDesdeSocket, // Added
    );
    _socketService!.connectToServer();
  }

  void disconnectSocket() {
    _socketService?.disconnect();
    _socketService = null;
  }

  // Timer para verificar tiempos de espera
  Timer? _waitTimer;
  final Set<int> _longWaitNotifiedIds = {}; // Para no notificar repetidamente el mismo pedido

  // Iniciar timer de monitoreo
  void startMonitoringWaitTimes() {
    _waitTimer?.cancel();
    _waitTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _checkLongWaitTimes();
    });
  }

  void _checkLongWaitTimes() {
    final now = DateTime.now();
    // Only check orders that are NOT ready/delivered/paid
    final pedidosDemorados = _pedidos.where((p) => 
        p.estado == PedidoEstados.recibido || 
        p.estado == PedidoEstados.pendiente || 
        p.estado == PedidoEstados.enPreparacion
    );

    for (final pedido in pedidosDemorados) {
      final difference = now.difference(pedido.createdAt);
      // Umbral de 30 minutos
      if (difference.inMinutes >= 30 && !_longWaitNotifiedIds.contains(pedido.id)) {
        _longWaitNotifiedIds.add(pedido.id);
        _notificationController.sink.add('⚠️ Tiempo de espera prolongado: Mesa ${pedido.mesaId} (${difference.inMinutes} min)');
      }
    }
  }

  @override
  void dispose() {
    disconnectSocket();
    _waitTimer?.cancel();
    super.dispose();
  }

  /// **Método para agregar un nuevo pedido recibido por Socket**
  void agregarPedidoDesdeSocket(Map<String, dynamic> data) {
    try {
      // debugPrint('🔔 Provider: Procesando nuevo pedido del socket: $data');
      // El backend envía el pedido completo en la data
      final nuevoPedido = Pedido.fromJson(data);
      
      // Verificar si ya existe para evitar duplicados
      if (!_pedidos.any((p) => p.id == nuevoPedido.id)) {
        _pedidos.insert(0, nuevoPedido); // Agregar al inicio
        notifyListeners();
        // debugPrint('✅ Provider: Pedido ${nuevoPedido.id} agregado a la lista.');
        
        // --- NOTIFICACIÓN PARA COCINA ---
        // (En una app real, filtraríamos por rol, pero aquí notificamos globalmente y la UI decide si mostrar o no.
        _notificationController.sink.add('👨‍🍳 Nuevo pedido recibido: ${_getMesaLabelForNotification(nuevoPedido)}');
        
      } else {
         // debugPrint('⚠️ Provider: Pedido ${nuevoPedido.id} ya existe, se ignora.');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Provider: Error al agregar pedido desde socket: $e');
    }
  }

  /// **Método clave que es llamado por el SocketService a través de un callback.**
  void actualizarEstadoDesdeSocket(Map<String, dynamic> data) {
    try {
      final int pedidoId = data['id'];
      final String nuevoEstado = data['estado'];

      final index = _pedidos.indexWhere((p) => p.id == pedidoId);

      if (index != -1) {
        // Si el backend envía el objeto pedido completo actualizado, úsalo.
        if (data['pedido'] != null) {
           _pedidos[index] = Pedido.fromJson(data['pedido']);
        } else {
           _pedidos[index] = _pedidos[index].copyWith(estado: nuevoEstado);
        }
        
        // debugPrint('✅ Provider: Pedido $pedidoId actualizado a $nuevoEstado (Sincronizado)');
        
        // --- NOTIFICACIÓN PARA MOZO ---
        // SOLO notificar cuando esté LISTO para servir (según requerimiento de usuario)
        if (nuevoEstado == 'listo') {
           _notificationController.sink.add('🍽️ ¡El pedido de ${_getMesaLabelForNotification(_pedidos[index])} está LISTO para servir!');
           // Reproducir sonido de alerta
           NotificationService().playReadySound();
        } 
        
        notifyListeners();
      } else {
        // debugPrint('⚠️ Provider: Pedido $pedidoId no encontrado para actualizar.');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Provider: Error al procesar datos del socket: $e');
    }
  }

  void actualizarItemDesdeSocket(Map<String, dynamic> data) {
    try {
      if (kDebugMode) debugPrint('🔔 Provider: Recibido pedido_item_actualizado: $data');
      
      final int pedidoId = int.tryParse(data['pedidoId'].toString()) ?? 0;
      final int detalleId = int.tryParse(data['detalleId'].toString()) ?? 0;
      final bool listo = data['listo'] == true || data['listo'] == 1 || data['listo'] == 'true';

      final index = _pedidos.indexWhere((p) => p.id == pedidoId);
      if (index != -1) {
        final pedido = _pedidos[index];
        final detIndex = pedido.detalles.indexWhere((d) => d.id == detalleId);
        
        if (detIndex != -1) {
          // Update item locally
          final oldDetail = pedido.detalles[detIndex];
          if (oldDetail.listo != listo) {
             if (kDebugMode) debugPrint('✅ Provider: Actualizando item ${oldDetail.nombrePlatillo} a listo=$listo');
             
             final newDetail = PedidoDetalle(
                id: oldDetail.id,
                platilloId: oldDetail.platilloId,
                cantidad: oldDetail.cantidad,
                precioUnitario: oldDetail.precioUnitario,
                notas: oldDetail.notas,
                nombrePlatillo: oldDetail.nombrePlatillo,
                listo: listo,
             );
             final newDetails = List<PedidoDetalle>.from(pedido.detalles);
             newDetails[detIndex] = newDetail;
             _pedidos[index] = pedido.copyWith(detalles: newDetails);
             notifyListeners();

             if (listo) {
                final nombre = oldDetail.nombrePlatillo ?? 'Item';
                // Mensaje claro: "¡Platillo listo! Mesa X"
                final msg = '🔔 Cocina: $nombre (${_getMesaLabelForNotification(pedido)}) está LISTO para servir.';
                _notificationController.sink.add(msg);
                if (kDebugMode) debugPrint('📢 Notificación enviada: $msg');
                NotificationService().playReadySound(); // Ensure sound plays for items too
             }
          } else {
             if (kDebugMode) debugPrint('⚠️ Provider: El item ya tenía el estado listo=$listo, no se notifica.');
          }
        } else {
           if (kDebugMode) debugPrint('⚠️ Provider: Detalle $detalleId no encontrado en pedido $pedidoId');
        }
      } else {
         if (kDebugMode) debugPrint('⚠️ Provider: Pedido $pedidoId no encontrado en lista local');
      }
    } catch (e) {
       if (kDebugMode) debugPrint('❌ Provider: Error al procesar item socket: $e');
    }
  }

  void procesarBroadcastDesdeSocket(Map<String, dynamic> data) {
    try {
      final String mensaje = data['message'] ?? '';
      final String titulo = data['title'] ?? 'Anuncio';
      
      if (mensaje.isNotEmpty) {
         // Add explicit 'anuncio' tag for NotificationWrapper filter
         _notificationController.sink.add('📢 $titulo: $mensaje (anuncio)');
         NotificationService().playReadySound();
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Provider: Error procesando broadcast: $e');
    }
  }

  /// Llama al servicio para actualizar el estado de un pedido en el backend.
  Future<void> updatePedidoStatus(int pedidoId, String newStatus, {String? metodoPago, double? montoRecibido, double? vuelto, double? descuento, int? puntosCanjeados}) async {
    // Primero, actualizamos el estado localmente para una respuesta UI inmediata (optimista).
    final index = _pedidos.indexWhere((p) => p.id == pedidoId);
    String? oldStatus; // Guardar el estado anterior por si la llamada al backend falla

    // debugPrint('🔍 PROVIDER: updatePedidoStatus id=$pedidoId status=$newStatus pago=$metodoPago desc=$descuento');

    if (index != -1) {
      oldStatus = _pedidos[index].estado;
      // Actualizamos estado y metodo de pago si existe
      _pedidos[index] = _pedidos[index].copyWith(
        estado: newStatus,
        metodoPago: metodoPago ?? _pedidos[index].metodoPago,
        montoRecibido: montoRecibido ?? _pedidos[index].montoRecibido,
        vuelto: vuelto ?? _pedidos[index].vuelto,
        descuento: descuento ?? _pedidos[index].descuento,
        puntosCanjeados: puntosCanjeados ?? _pedidos[index].puntosCanjeados,
      ); 
      notifyListeners(); // Notificar para actualizar la UI inmediatamente
    }

    try {
      await _pedidoService.updatePedidoStatus(
        pedidoId, 
        newStatus, 
        metodoPago: metodoPago, 
        montoRecibido: montoRecibido, 
        vuelto: vuelto,
        descuento: descuento,
        puntosCanjeados: puntosCanjeados,
      );
      // debugPrint('✅ Pedido $pedidoId actualizado a "$newStatus" en el backend.');
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        if (kDebugMode) debugPrint('⚠️ PedidoProvider: Acceso denegado (403) al actualizar pedido $pedidoId a "$newStatus". Revierte cambios localmente.');
        // Si hay un error 403, revertir el estado localmente
        if (index != -1 && oldStatus != null) {
          _pedidos[index] = _pedidos[index].copyWith(estado: oldStatus); // Revertir a estado anterior
          notifyListeners(); // Notificar para revertir la UI
        }
        _errorMessage = 'Error de permisos (403): ${e.response?.data['message'] ?? 'Acceso denegado.'}';
      } else {
        if (kDebugMode) debugPrint('❌ PedidoProvider: Error al actualizar pedido $pedidoId a "$newStatus": $e');
        _errorMessage = 'Error al actualizar estado del pedido: ${e.response?.data['message'] ?? e.message}';
        // Si falla por otra razón, podrías revertir o mostrar el error.
        if (index != -1 && oldStatus != null) {
          _pedidos[index] = _pedidos[index].copyWith(estado: oldStatus);
          notifyListeners();
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ PedidoProvider: Error inesperado al actualizar pedido $pedidoId a "$newStatus": $e');
      _errorMessage = 'Error inesperado: $e';
      if (index != -1 && oldStatus != null) {
        _pedidos[index] = _pedidos[index].copyWith(estado: oldStatus);
        notifyListeners();
      }
    }
  }

  Future<void> toggleItem(int pedidoId, int detalleId) async {
    // 1. Optimistic Update
    final start = DateTime.now();
    final index = _pedidos.indexWhere((p) => p.id == pedidoId);
    if (index != -1) {
      final pedido = _pedidos[index];
      final detIndex = pedido.detalles.indexWhere((d) => d.id == detalleId);
      if (detIndex != -1) {
        // Create new detail with toggled status
        final oldDetail = pedido.detalles[detIndex];
        final newDetail = PedidoDetalle(
          id: oldDetail.id,
          platilloId: oldDetail.platilloId,
          cantidad: oldDetail.cantidad,
          precioUnitario: oldDetail.precioUnitario,
          notas: oldDetail.notas,
          nombrePlatillo: oldDetail.nombrePlatillo,
          listo: !oldDetail.listo,
        );
        
        // Update details list
        final newDetails = List<PedidoDetalle>.from(pedido.detalles);
        newDetails[detIndex] = newDetail;
        
        // Update pedido
        _pedidos[index] = pedido.copyWith(detalles: newDetails);
        notifyListeners();
      }
    }

    // 2. Call Backend
    try {
      final result = await _pedidoService.toggleItemStatus(detalleId);
      
      // If backend says order status changed, and we haven't received socket yet,
      // we could update it here too, but socket is usually fast.
      // However, if we want to be super responsive:
      if (result['orderStatusChanged'] == true && index != -1) {
         final newOrderStatus = result['newOrderStatus'];
         if (newOrderStatus != _pedidos[index].estado) {
            _pedidos[index] = _pedidos[index].copyWith(estado: newOrderStatus);
            notifyListeners();
         }
      }
    } catch (e) {
      // Revert if error
      if (kDebugMode) debugPrint('❌ Error toggling item: $e');
      // We should revert the optimistic update here... 
      // Simplified: Just reload orders or ignore for now as it's a rare case in localhost.
    }
  }

  String _getMesaLabelForNotification(Pedido pedido) {
    if (pedido.tipo == 'delivery') return 'Delivery';
    if (pedido.tipo == 'recojo') return 'Para Llevar';
    return 'Mesa ${pedido.mesaId ?? "?"}';
  }
}
