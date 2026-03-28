import 'dart:async';
import 'package:encrocante_app/services/connectivity_service.dart';
import 'package:encrocante_app/services/local_storage_service.dart';
import 'package:encrocante_app/services/pedido_service.dart';
import 'package:flutter/material.dart';

class SyncService with ChangeNotifier {
  final ConnectivityService _connectivityService;
  final PedidoService _pedidoService;
  bool _isSyncing = false;

  bool get isSyncing => _isSyncing;

  SyncService(this._connectivityService, {PedidoService? pedidoService}) 
      : _pedidoService = pedidoService ?? PedidoService() {
    _connectivityService.addListener(_onConnectionChanged);
  }

  void _onConnectionChanged() {
    if (_connectivityService.isOnline) {
      // Delay ligeramente para asegurar estabilidad de conexión
      Future.delayed(const Duration(seconds: 2), processQueue);
    }
  }

  Future<void> processQueue() async {
    if (_isSyncing) return;
    
    final offlineOrders = LocalStorageService.getOfflineOrders();
    if (offlineOrders.isEmpty) return;

    _isSyncing = true;
    notifyListeners();
    print("🔄 SyncService: Procesando ${offlineOrders.length} pedidos offline...");

    for (var order in offlineOrders) {
      try {
        // Obtenemos la key de Hive para poder borrarlo
        final int hiveKey = order['_hiveKey'];
        
        // Removemos la key interna antes de enviar
        final orderData = Map<String, dynamic>.from(order);
        orderData.remove('_hiveKey');

        print("📤 Enviando pedido offline: $orderData");
        await _pedidoService.sendOrderToBackend(orderData);
        
        // Si éxito, borrar de la cola
        await LocalStorageService.removeOfflineOrder(hiveKey);
        print("✅ Pedido sincronizado y eliminado de cola.");

      } catch (e) {
        print("❌ Error sincronizando pedido: $e");
        // Si falla, se queda en la cola para el próximo intento
        // Podríamos implementar lógica de 'max retries' aquí
      }
    }

    _isSyncing = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _connectivityService.removeListener(_onConnectionChanged);
    super.dispose();
  }
}
