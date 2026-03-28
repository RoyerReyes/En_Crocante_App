import 'package:encrocante_app/models/pedido_model.dart';
import 'package:encrocante_app/providers/pedido_provider.dart';
import 'package:encrocante_app/services/pedido_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockPedidoService extends Mock implements PedidoService {}

void main() {
  late MockPedidoService mockPedidoService;
  late PedidoProvider pedidoProvider;

  setUp(() {
    mockPedidoService = MockPedidoService();
    // We pass the mock service. SocketService serves as internal component but we test handlers directly.
    pedidoProvider = PedidoProvider(pedidoService: mockPedidoService);
  });

  group('PedidoProvider Socket & Logic Tests', () {
    test('agregarPedidoDesdeSocket adds new order to start of list', () {
      final newOrderJson = {
        'id': 100,
        'estado': 'pendiente',
        'mesa_id': 5,
        'nombre_cliente': 'Test Client',
        'total': 50.0,
        'fecha': '2023-10-27T10:00:00Z',
        'detalles': []
      };

      pedidoProvider.agregarPedidoDesdeSocket(newOrderJson);

      expect(pedidoProvider.pedidos.length, 1);
      expect(pedidoProvider.pedidos.first.id, 100);
      expect(pedidoProvider.pedidos.first.estado, 'pendiente');
    });

    test('agregarPedidoDesdeSocket ignores duplicate orders', () {
      final newOrderJson = {
        'id': 100,
        'estado': 'pendiente',
        'mesa_id': 5,
        'nombre_cliente': 'Test Client',
        'total': 50.0,
        'fecha': '2023-10-27T10:00:00Z',
        'detalles': []
      };

      pedidoProvider.agregarPedidoDesdeSocket(newOrderJson);
      pedidoProvider.agregarPedidoDesdeSocket(newOrderJson); // Duplicate

      expect(pedidoProvider.pedidos.length, 1);
    });

    test('pedidosCocina returns active orders sorted by creation time (FIFO)', () {
      final order1 = {
        'id': 1,
        'estado': 'pendiente',
        'fecha': '2023-10-27T10:00:00Z', 'detalles': [], 'total': 10.0
      };
      final order2 = {
        'id': 2,
        'estado': 'recibido',
        'fecha': '2023-10-27T09:00:00Z', 'detalles': [], 'total': 10.0
      };
      final order3 = {
        'id': 3,
        'estado': 'entregado',
        'fecha': '2023-10-27T08:00:00Z', 'detalles': [], 'total': 10.0
      };

      pedidoProvider.agregarPedidoDesdeSocket(order1);
      pedidoProvider.agregarPedidoDesdeSocket(order2);
      pedidoProvider.agregarPedidoDesdeSocket(order3);

      final kitchenOrders = pedidoProvider.pedidosCocina;

      expect(kitchenOrders.length, 2); // Only pending/recibido
      expect(kitchenOrders[0].id, 2); // 09:00 - First
      expect(kitchenOrders[1].id, 1); // 10:00 - Second
    });

    test('actualizarEstadoDesdeSocket updates order status', () {
      final order1 = {
        'id': 50,
        'estado': 'pendiente',
        'fecha': '2023-10-27T10:00:00Z', 'detalles': [], 'total': 20.0
      };
      pedidoProvider.agregarPedidoDesdeSocket(order1);

      pedidoProvider.actualizarEstadoDesdeSocket({
        'id': 50,
        'estado': 'en_preparacion'
      });

      expect(pedidoProvider.pedidos.first.estado, 'en_preparacion');
    });
  });
}
