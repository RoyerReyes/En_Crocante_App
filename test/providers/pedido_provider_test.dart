
import 'package:flutter_test/flutter_test.dart';
import 'package:encrocante_app/providers/pedido_provider.dart';
import 'package:encrocante_app/models/pedido_model.dart';
import 'package:mockito/mockito.dart';

void main() {
  group('PedidoProvider Item Update', () {
    late PedidoProvider pedidoProvider;

    setUp(() {
      pedidoProvider = PedidoProvider();
    });

    test('should update item status and emit notification when socket event is received', () async {
      // 1. Arrange: Add a dummy order
      final dummyOrder = Pedido(
        id: 100,
        mesaId: 5,
        estado: 'en_preparacion',
        tipo: 'mesa',
        createdAt: DateTime.now(),
        detalles: [
          PedidoDetalle(
            id: 200, 
            platilloId: 1, 
            cantidad: 1, 
            precioUnitario: 10.0, 
            nombrePlatillo: 'Ceviche',
            listo: false
          )
        ],
        total: 10.0
      );
      
      // Inject dummy order (accessing private list strictly for testing might require visibleForTesting or reflection, 
      // but here we can simulate "charging from API" or just use the socket add method if available,
      // or we can mock the initial load. 
      // Since _pedidos is private, we'll use `agregarPedidoDesdeSocket` to inject it first.)
      
      final orderJson = dummyOrder.toJson(); 
      // Need to ensure json structure matches what `Pedido.fromJson` expects.
      // We'll trust `fromJson` is working or mock it.
      // Actually `agregarPedidoDesdeSocket` uses `Pedido.fromJson`.
      
      pedidoProvider.agregarPedidoDesdeSocket(orderJson);
      
      expect(pedidoProvider.pedidos.length, 1);
      expect(pedidoProvider.pedidos.first.detalles.first.listo, false);

      // 2. Act: Simulate Socket Event for Item Toggle
      // We expect the Stream to emit a notification
      bool notificationReceived = false;
      pedidoProvider.notificationStream.listen((msg) {
        if (msg.contains('Ceviche') && msg.contains('LISTO')) {
          notificationReceived = true;
        }
      });

      final socketPayload = {
        'pedidoId': 100,
        'detalleId': 200,
        'listo': true
      };

      pedidoProvider.actualizarItemDesdeSocket(socketPayload);

      // 3. Assert: Check State Update
      expect(pedidoProvider.pedidos.first.detalles.first.listo, true);
      
      // Check Notification (async, wait a bit)
      await Future.delayed(Duration.zero);
      expect(notificationReceived, true);
    });
  });
}
