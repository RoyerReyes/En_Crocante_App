import 'dart:io';
import 'package:dio/dio.dart';
import 'package:encrocante_app/models/cart_item_model.dart';
import 'package:encrocante_app/models/platillo_model.dart';
import 'package:encrocante_app/services/connectivity_service.dart';
import 'package:encrocante_app/services/local_storage_service.dart';
import 'package:encrocante_app/services/pedido_service.dart';
import 'package:encrocante_app/services/sync_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mocktail/mocktail.dart';

// Mocks
class MockDio extends Mock implements Dio {}
class MockConnectivityService extends Mock implements ConnectivityService {}

void main() {
  late MockDio mockDio;
  late MockConnectivityService mockConnectivityService;
  late PedidoService pedidoService;
  late SyncService syncService;

  setUpAll(() async {
    registerFallbackValue(<String, dynamic>{'dummy': 'value'}); 
    // Setup Hive...
    final tempDir = await Directory.systemTemp.createTemp();
    Hive.init(tempDir.path);
    await Hive.openBox(LocalStorageService.boxOfflineOrders);
    await Hive.openBox(LocalStorageService.boxPlatillos);
  });

  setUp(() async {
    await Hive.box(LocalStorageService.boxOfflineOrders).clear();
    mockDio = MockDio();
    mockConnectivityService = MockConnectivityService();
    // Inject mock Dio
    pedidoService = PedidoService(dioClient: mockDio);
    syncService = SyncService(mockConnectivityService);
  });

  group('Offline Logic Tests', () {
    final testItem = CartItem(
      platillo: Platillo(
        id: 1,
        nombre: 'Test Dish',
        precio: 10.0,
        descripcion: 'Desc',
        categoria: Categoria(id: 1, nombre: 'Cat'),
        activo: true,
      ),
      cantidad: 1,
    );

    test('PedidoService queues order when Dio throws connection error', () async {
      // Arrange
      when(() => mockDio.post(any(), data: any(named: 'data')))
          .thenThrow(DioException(
            requestOptions: RequestOptions(path: '/pedidos'),
            type: DioExceptionType.connectionTimeout,
            error: 'SocketException',
          ));

      // Act
      final result = await pedidoService.crearPedido(
        [testItem],
        'Cliente Offline',
        1,
      );

      // Assert
      expect(result, true, reason: "Should return true (optimistic success)");
      
      final box = Hive.box(LocalStorageService.boxOfflineOrders);
      expect(box.length, 1, reason: "Order should be in Hive box");
      
      final storedOrder = box.getAt(0) as Map;
      expect(storedOrder['nombre_cliente'], 'Cliente Offline');
    });

    test('SyncService sends queued orders when connectivity returns', () async {
      // Arrange
      // 1. Queue an order
      final orderData = {'nombre_cliente': 'Synced Client', 'detalles': [], 'tipo': 'mesa'};
      await LocalStorageService.queueOfflineOrder(orderData);
      
      // 2. Setup Mock
      final mockPedidoService = MockPedidoService();
      // Important: Use successful return or the loop might retry/fail depending on implementation. 
      // sendOrderToBackend returns Future<void> or throws. We want success.
      when(() => mockPedidoService.sendOrderToBackend(any())).thenAnswer((_) async {});
      
      final testSyncService = SyncService(mockConnectivityService, pedidoService: mockPedidoService);
      
      // Act
      // Manually trigger the processing logic
      await testSyncService.processQueue();
      
      // Assert
      // Verify that sendOrderToBackend was called with the correct data
      verify(() => mockPedidoService.sendOrderToBackend(any())).called(1);
      
      // Verify queue is empty
      final box = Hive.box(LocalStorageService.boxOfflineOrders);
      expect(box.length, 0, reason: "Queue should be empty after sync");
    });
  }); // End group

  tearDownAll(() async {
    await Hive.deleteFromDisk();
  });
}

class MockPedidoService extends Mock implements PedidoService {}
