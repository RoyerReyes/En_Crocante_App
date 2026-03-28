import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:encrocante_app/widgets/kitchen_order_ticket.dart';
import 'package:encrocante_app/models/pedido_model.dart';
import 'package:encrocante_app/models/platillo_model.dart';
import 'package:encrocante_app/providers/pedido_provider.dart';
import 'package:encrocante_app/providers/platillo_provider.dart';
import 'package:encrocante_app/constants/pedido_estados.dart';

// Mocks needed for providers if they make network calls
// But KitchenOrderTicket mostly uses properties. 
// It calls methods on PedidoProvider for buttons.

// We can use a real PedidoProvider with a Fake Service for the test 
// or simpler, just check if buttons are present. Button logic is inside onPressed.

// Fake Provider to avoid network calls
class TestPlatilloProvider extends PlatilloProvider {
  @override
  Future<void> fetchPlatillos() async {
    // No-op to avoid network usage
  }

  @override
  List<Platillo> get platillos => [
    Platillo(id: 1, nombre: 'Platillo Test', precio: 10.0, activo: true, categoria: Categoria(id: 1, nombre: 'Test')),
  ];
}

void main() {
  testWidgets('KitchenOrderTicket displays correct info and buttons', (WidgetTester tester) async {
    final pedido = Pedido(
      id: 1,
      mesaId: 5,
      nombreCliente: 'Cliente Test',
      nombreMesero: 'Mesero Test',
      estado: PedidoEstados.pendiente,
      tipo: 'mesa',
      total: 50.0,
      createdAt: DateTime.now(),
      detalles: [
        PedidoDetalle(id: 1, platilloId: 1, cantidad: 2, precioUnitario: 10.0),
      ],
    );

    // Ensure Dio is not accessed by using Fake PedidoProvider or just standard one (lazy dio is safe if not called)
    // But KitchenOrderTicket interacts with PedidoProvider methods on button press?
    // The test only verifying 'findsOneWidget' for buttons doesnt press them.
    // So real PedidoProvider is safe.

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => PedidoProvider()),
          ChangeNotifierProvider<PlatilloProvider>(create: (_) => TestPlatilloProvider()), 
        ],
        child: MaterialApp(
          home: Scaffold(
            body: KitchenOrderTicket(
              pedido: pedido,
              userRole: 'cocinero',
            ),
          ),
        ),
      ),
    );

    // Verify Info
    expect(find.text('Mesa 5'), findsOneWidget);
    expect(find.text('Cliente Test'), findsOneWidget);
    expect(find.text('Mesero Test'), findsOneWidget);
    
    // Verify Buttons for 'Pendiente' state
    expect(find.text('Iniciar Preparación'), findsOneWidget);
    expect(find.text('Cancelar Pedido'), findsOneWidget);
  });
}
