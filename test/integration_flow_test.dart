import 'package:encrocante_app/constants/pedido_estados.dart';
import 'package:encrocante_app/models/cart_item_model.dart';
import 'package:encrocante_app/models/pedido_model.dart';
import 'package:encrocante_app/models/platillo_model.dart';
import 'package:flutter_test/flutter_test.dart';

// Mocks (Simplified for logical flow verification)
class MockBackend {
  int _lastId = 0;
  final List<Map<String, dynamic>> _pedidosDb = [];

  Map<String, dynamic> createPedido(Map<String, dynamic> payload) {
    _lastId++;
    final nuevoPedido = {
      'id': _lastId,
      'mesa_id': payload['numero_mesa'], // Simulate backend mapping
      'usuario_id': 1, // Mock user
      'nombre_cliente': payload['nombre_cliente'],
      'estado': PedidoEstados.recibido,
      'total': 100.00, // Mock total calc
      'fecha': DateTime.now().toIso8601String(),
      'detalles': (payload['detalles'] as List).map((d) {
        return {
          'id': 99,
          'platillo_id': d['platillo_id'],
          'cantidad': d['cantidad'],
          'precio_unitario': 10.0, // Mock price
          'nota': d['nota']
        };
      }).toList(),
    };
    _pedidosDb.add(nuevoPedido);
    return nuevoPedido;
  }

  List<Map<String, dynamic>> getPedidos() => _pedidosDb;
}

void main() {
  group('M1 -> M2 Integration Analysis', () {
    late MockBackend backend;

    setUp(() {
      backend = MockBackend();
    });

    test('Discrepancy Check: M1 Payload vs M2 Model Requirement', () {
      // 1. Create M1 Data (Cart Items)
      final platillo = Platillo(
          id: 5,
          nombre: 'Ají de Gallina',
          precio: 25.0,
          activo: true,
          categoria: Categoria(id: 1, nombre: 'Criollo'));
      final cartItem = CartItem(platillo: platillo, cantidad: 2, notas: 'Sin picante');
      final items = [cartItem];
      final nombreCliente = "Juan Perez";
      final numeroMesa = 5;

      // 2. Simulate M1 Service Logic (Payload Construction)
      // Extracted from PedidoService.crearPedido logic
      final List<Map<String, dynamic>> itemsData = items.map((item) {
        return {
          'platillo_id': item.platillo.id,
          'cantidad': item.cantidad,
          if (item.notas != null && item.notas!.isNotEmpty) 'nota': item.notas,
        };
      }).toList();

      final Map<String, dynamic> m1Payload = {
        'tipo': 'mesa',
        'nombre_cliente': nombreCliente,
        'numero_mesa': numeroMesa,
        'detalles': itemsData,
      };

      // 3. Verify M1 sends what we expect
      expect(m1Payload['numero_mesa'], 5);
      expect(m1Payload['nombre_cliente'], "Juan Perez");
      expect(m1Payload['detalles'][0]['nota'], 'Sin picante'); // Check note mapping

      // 4. Simulate Backend Processing (M1 -> Backend -> M2)
      final backendResponse = backend.createPedido(m1Payload);

      // 5. Verify M2 Model Deserialization (Socket Event payload)
      // M2 receives the JSON from the backend (via Socket 'nuevo_pedido')
      final pedidoM2 = Pedido.fromJson(backendResponse);

      // Analysis Assertions
      expect(pedidoM2.mesaId, 5, reason: "M2 needs mesaId, Backend must map numero_mesa -> mesa_id");
      expect(pedidoM2.nombreCliente, "Juan Perez", reason: "M2 needs client name for Ticket");
      expect(pedidoM2.detalles.length, 1);
      expect(pedidoM2.detalles.first.notas, 'Sin picante', reason: "Notes must persist through flow");
      expect(pedidoM2.estado, PedidoEstados.recibido, reason: "Initial state must be consistent");
    });

    test('State Consistency Check (PedidoEstados)', () {
      // Verify that M1 and M2 agree on what "Listo" means
      expect(PedidoEstados.recibido, 'recibido');
      expect(PedidoEstados.enPreparacion, 'en_preparacion');
      expect(PedidoEstados.listo, 'listo');
      
      // Verify Colors exist for all states (UI crash prevention)
      expect(PedidoEstados.getColor(PedidoEstados.recibido), isNotNull);
      expect(PedidoEstados.getColor(PedidoEstados.enPreparacion), isNotNull);
    });
  });
}
