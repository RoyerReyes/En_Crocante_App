import 'package:encrocante_app/constants/pedido_estados.dart';
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
    pedidoProvider = PedidoProvider(pedidoService: mockPedidoService);
  });

  test('FULL ORDER CYCLE: Recibido -> Listo -> Entregado -> Pagado', () async {
    // 1. Initial State: Order Created (Recibido/Pendiente)
    final initialOrder = {
      'id': 101,
      'estado': PedidoEstados.pendiente,
      'fecha': '2023-10-27T10:00:00Z',
      'detalles': [],
      'total': 100.0,
      'mesa_id': 1
    };
    
    // Simulate Socket Arrival
    pedidoProvider.agregarPedidoDesdeSocket(initialOrder);
    
    expect(pedidoProvider.pedidos.first.estado, PedidoEstados.pendiente);
    expect(pedidoProvider.pedidosActivos.length, 1);
    expect(pedidoProvider.pedidosHistorial.length, 0);

    // 2. Kitchen: Mark as Ready (Listo)
    // Simulate Socket Update from Kitchen
    pedidoProvider.actualizarEstadoDesdeSocket({
      'id': 101,
      'estado': PedidoEstados.listo
    });

    expect(pedidoProvider.pedidos.first.estado, PedidoEstados.listo);
    // It should STILL be in active list for the waiter to serve
    expect(pedidoProvider.pedidosActivos.isEmpty, false); 
    expect(pedidoProvider.pedidosActivos.first.estado, PedidoEstados.listo);

    // 3. Waiter: Serves Order (Entregado)
    // Here we usually call Keypad/Button, but we test Provider logic
    when(() => mockPedidoService.updatePedidoStatus(101, PedidoEstados.entregado))
        .thenAnswer((_) async {}); // Mock successful service call

    await pedidoProvider.updatePedidoStatus(101, PedidoEstados.entregado);

    expect(pedidoProvider.pedidos.first.estado, PedidoEstados.entregado);
    // Should STILL be active (Por Cobrar)
    expect(pedidoProvider.pedidosActivos.isEmpty, false);

    // 4. Waiter/Cashier: Payment (Pagado)
    when(() => mockPedidoService.updatePedidoStatus(101, PedidoEstados.pagado))
        .thenAnswer((_) async {});

    await pedidoProvider.updatePedidoStatus(101, PedidoEstados.pagado);

    expect(pedidoProvider.pedidos.first.estado, PedidoEstados.pagado);
    
    // NOW it should move to History
    expect(pedidoProvider.pedidosActivos.isEmpty, true);
    expect(pedidoProvider.pedidosHistorial.length, 1);
    expect(pedidoProvider.pedidosHistorial.first.estado, PedidoEstados.pagado);
  });
}
