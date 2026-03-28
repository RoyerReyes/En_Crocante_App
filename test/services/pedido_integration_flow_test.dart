import 'package:dio/dio.dart';
import 'package:encrocante_app/models/platillo_model.dart';
import 'package:encrocante_app/providers/cart_provider.dart';
import 'package:encrocante_app/services/pedido_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio mockDio;
  late PedidoService pedidoService;
  late CartProvider cartProvider;

  setUp(() {
    mockDio = MockDio();
    pedidoService = PedidoService(dioClient: mockDio);
    cartProvider = CartProvider();
  });

  test('FULL FLOW: Create Pedido from Cart Items via PedidoService', () async {
    // 1. Setup Cart with Items
    final categoria = Categoria(id: 1, nombre: 'Test Category');
    final platillo = Platillo(id: 10, nombre: 'Pizza', precio: 20.0, activo: true, categoria: categoria);
    
    // Add 2 Pizzas
    cartProvider.addItem(platillo);
    cartProvider.addItem(platillo);
    // Add Note
    cartProvider.updateItemNotes(10, 'Extra cheese');

    // 2. Prepare Data (Mocking CartScreen logic)
    final itemsList = cartProvider.itemsList;
    final nombreCliente = 'John Doe';
    final mesaId = 5;
    final notaGeneral = 'Rápido por favor';

    // 3. Setup Mock Expectation
    when(() => mockDio.post(
      any(),
      data: any(named: 'data'),
    )).thenAnswer(
      (_) async => Response(
        data: {'id': 999, 'message': 'Pedido creado'},
        statusCode: 201,
        requestOptions: RequestOptions(path: '/pedidos'),
      ),
    );

    // 4. Executing the Service Call
    final result = await pedidoService.crearPedido(
      itemsList,
      nombreCliente,
      mesaId,
      notaGeneralPedido: notaGeneral,
    );

    // 5. Assertions
    expect(result, true);

    // Verify Payload structure matches Backend validation requirements
    final expectedPayload = {
      'tipo': 'mesa',
      'nombre_cliente': 'John Doe',
      'numero_mesa': 5,
      'detalles': [
        {
          'platillo_id': 10,
          'cantidad': 2,
          'nota': 'Extra cheese',
        }
      ],
      'observaciones': 'Rápido por favor'
    };

    verify(() => mockDio.post(
      '/pedidos',
      data: expectedPayload,
    )).called(1);
  });

  test('FULL FLOW: Handle Network Error during Order Creation', () async {
      // Setup Cart (Empty or not doesn't matter for Network Error, but let's add one)
      final categoria = Categoria(id: 1, nombre: 'Test');
      final platillo = Platillo(id: 1, nombre: 'Soda', precio: 5.0, activo: true, categoria: categoria);
      cartProvider.addItem(platillo);

      when(() => mockDio.post(any(), data: any(named: 'data')))
          .thenThrow(DioException(
              requestOptions: RequestOptions(path: '/pedidos'),
              error: 'No Internet',
              type: DioExceptionType.connectionError));

      expect(
        () => pedidoService.crearPedido(cartProvider.itemsList, 'Client', 1),
        throwsException,
      );
  });
}
