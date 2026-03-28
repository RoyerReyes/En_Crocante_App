import 'package:dio/dio.dart';
import 'package:encrocante_app/services/dio_client.dart';
import '../models/cart_item_model.dart';
import '../models/pedido_model.dart';
import 'local_storage_service.dart'; // Import
import 'package:flutter/foundation.dart'; // Import debugPrint

class PedidoService {
  final Dio _dio;

  PedidoService({Dio? dioClient}) : _dio = dioClient ?? dio;

  /// Envía un nuevo pedido al backend.
  /// 
  /// Recibe el nombre de la mesa y la lista de items del carrito.
  /// Devuelve `true` si el pedido fue exitoso, `false` si no.
  /// En caso de error, lanza una excepción con el mensaje.
  Future<bool> crearPedido(List<CartItem> items, String nombreCliente, int numeroMesa, {String? notaGeneralPedido, String tipoPedido = 'mesa', int? clienteId, double costoDelivery = 0.0}) async {
    // 1. Formatear
    final List<Map<String, dynamic>> itemsData = items.map((item) {
      return {
        'platillo_id': item.platillo.id,
        'cantidad': item.cantidad,
        if (item.notas != null && item.notas!.isNotEmpty) 'nota': item.notas,
      };
    }).toList();

    final Map<String, dynamic> pedidoData = {
      'tipo': tipoPedido,
      'nombre_cliente': nombreCliente,
      'numero_mesa': numeroMesa,
      'costo_delivery': costoDelivery,
      'detalles': itemsData,
    };
    if (clienteId != null) {
      pedidoData['cliente_id'] = clienteId; 
    }
    if (notaGeneralPedido != null && notaGeneralPedido.isNotEmpty) {
      pedidoData['observaciones'] = notaGeneralPedido; 
    }

    // 2. Intentar enviar
    try {
      await sendOrderToBackend(pedidoData);
      return true;
    } catch (e) {
       // --- OFFLINE LOGIC ---
       bool isNetworkError = false;
       if (e is DioException) {
          if (e.type == DioExceptionType.connectionTimeout || 
              e.type == DioExceptionType.receiveTimeout || 
              e.type == DioExceptionType.unknown ||
              e.error.toString().contains('SocketException')) {
            isNetworkError = true;
          }
       }
       
       if (isNetworkError) {
          print("⚠️ Conexión fallida. Guardando pedido Offline.");
          await LocalStorageService.queueOfflineOrder(pedidoData);
          return true; // Éxito aparente
       }
       
      rethrow;
    }
  }

  /// Actualiza un pedido existente en el backend.
  Future<bool> actualizarPedido(int pedidoId, List<CartItem> items, String nombreCliente, int numeroMesa, {String? notaGeneralPedido, String tipoPedido = 'mesa', int? clienteId, double costoDelivery = 0.0}) async {
    final List<Map<String, dynamic>> itemsData = items.map((item) {
      return {
        'platillo_id': item.platillo.id,
        'cantidad': item.cantidad,
        if (item.notas != null && item.notas!.isNotEmpty) 'nota': item.notas,
      };
    }).toList();

    final Map<String, dynamic> pedidoData = {
      'tipo': tipoPedido,
      'nombre_cliente': nombreCliente,
      'numero_mesa': numeroMesa,
      'costo_delivery': costoDelivery,
      'detalles': itemsData,
    };
    if (clienteId != null) {
      pedidoData['cliente_id'] = clienteId; 
    }
    if (notaGeneralPedido != null && notaGeneralPedido.isNotEmpty) {
      pedidoData['observaciones'] = notaGeneralPedido; 
    }

    try {
      final response = await _dio.put('/pedidos/$pedidoId', data: pedidoData);
      if (response.statusCode != 200 && response.statusCode != 201) {
         throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          error: 'El servidor respondió con el código ${response.statusCode}',
        );
      }
      return true;
    } catch (e) {
      rethrow;
    }
  }


  // Método expuesto para el SyncManager (o privado si se mueve la lógica aquí)
  Future<void> sendOrderToBackend(Map<String, dynamic> pedidoData) async {
    try {
      final response = await _dio.post('/pedidos', data: pedidoData);
      if (response.statusCode != 201) {
         throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          error: 'El servidor respondió con el código ${response.statusCode}',
        );
      }
    } catch (e) {
      rethrow; // Propagar error para que quien llame decida qué hacer
    }
  }

  /// Obtiene una lista de pedidos desde el backend.
  ///
  /// Opcionalmente, puede filtrar los pedidos por estado.
  /// Devuelve un `Future` que se resuelve en una lista de objetos `Pedido`.
  /// Lanza una excepción en caso de error.
  Future<List<Pedido>> getPedidos({String? estadoFiltro}) async {
    try {
      final response = await _dio.get('/pedidos', queryParameters: estadoFiltro != null ? {'estado': estadoFiltro} : null);

      if (response.statusCode == 200) {
        final List<dynamic>? pedidosJson = response.data; // Allow null
        if (pedidosJson == null) {
          return []; // Return an empty list if no data
        }
        return pedidosJson.map((json) => Pedido.fromJson(json)).toList();
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          error: 'El servidor respondió con el código ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      print('Error al obtener pedidos: ${e.response?.data ?? e.message}');
      rethrow;
    } catch (e) {
      print('Error inesperado al obtener pedidos: $e');
      throw Exception('Ocurrió un error inesperado al obtener pedidos.');
    }
  }

  /// Actualizar el estado de un pedido y opcionalmente el método de pago
  Future<void> updatePedidoStatus(int pedidoId, String newStatus, {String? metodoPago, double? montoRecibido, double? vuelto, double? descuento, int? puntosCanjeados}) async {
    try {
      debugPrint('🔍 SERVICE: updatePedidoStatus id=$pedidoId status=$newStatus pago=$metodoPago');
      final data = {
        'estado': newStatus,
        if (metodoPago != null) 'metodo_pago': metodoPago,
        if (montoRecibido != null) 'monto_recibido': montoRecibido,
        if (vuelto != null) 'vuelto': vuelto,
        if (descuento != null) 'descuento': descuento,
        if (puntosCanjeados != null) 'puntos_canjeados': puntosCanjeados,
      };
      
      debugPrint('🔍 SERVICE: Body a enviar: $data');

      final response = await _dio.patch(
        '/pedidos/$pedidoId/estado',
        data: data,
      );

      if (response.statusCode != 200) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          error: 'El servidor respondió con el código ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      print('Error al actualizar estado del pedido: ${e.response?.data ?? e.message}');
      rethrow;
    } catch (e) {
      print('Error inesperado al actualizar estado: $e');
      throw Exception('Ocurrió un error inesperado al actualizar el estado.');
    }
  }

  /// Toggle el estado 'listo' de un item individual
  Future<Map<String, dynamic>> toggleItemStatus(int detalleId) async {
    try {
      final response = await _dio.patch('/pedidos/detalle/$detalleId/toggle');
      return response.data;
    } catch (e) {
      debugPrint('Error toggle item: $e');
      rethrow;
    }
  }
}
