import 'package:encrocante_app/constants/pedido_estados.dart';
import 'package:encrocante_app/models/pedido_model.dart';
import 'package:encrocante_app/models/platillo_model.dart';
import 'package:encrocante_app/providers/pedido_provider.dart';
import 'package:encrocante_app/providers/platillo_provider.dart';
import 'package:encrocante_app/widgets/kitchen_order_ticket.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

// Fake Providers for Testing (No Mockito required)
class FakePedidoProvider extends ChangeNotifier implements PedidoProvider {
  @override
  List<Pedido> get pedidos => [];

  @override
  Future<void> updatePedidoStatus(int pedidoId, String newStatus) async {
    // Mock logic: just print for verification if needed, or do nothing.
    debugPrint("Update status called: $pedidoId -> $newStatus");
  }
  
  // Implement required members with dummies/defaults
  @override
  bool get isLoading => false;
  @override
  String? get errorMessage => null;
  @override
  List<Pedido> get pedidosActivos => [];
  @override
  List<Pedido> get pedidosHistorial => [];

  @override
  void actualizarEstadoDesdeSocket(Map<String, dynamic> data) {}
  @override
  void agregarPedidoDesdeSocket(Map<String, dynamic> data) {}
  @override
  Future<void> cargarPedidosIniciales() async {}
}

class FakePlatilloProvider extends ChangeNotifier implements PlatilloProvider {
  @override
  List<Platillo> get platillos => [];
  
  // Implement required members
  @override
  bool get isLoading => false;
  @override
  String? get errorMessage => null;
  @override
  List<String> get categorias => [];
  @override
  List<Platillo> get filteredPlatillos => [];
  @override
  String get selectedFilter => '';
  
  @override
  Future<void> fetchPlatillos() async {}
  @override
  void setFilter(String filter) {}
  @override
  void setSearchQuery(String query) {}
}

void main() {
  late FakePedidoProvider fakePedidoProvider;
  late FakePlatilloProvider fakePlatilloProvider;

  setUp(() {
    fakePedidoProvider = FakePedidoProvider();
    fakePlatilloProvider = FakePlatilloProvider();
  });

  Widget createWidgetUnderTest(Pedido pedido, String role) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<PedidoProvider>.value(value: fakePedidoProvider),
        ChangeNotifierProvider<PlatilloProvider>.value(value: fakePlatilloProvider),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 400, // Simula ancho de pantalla
              height: 600,
              child: KitchenOrderTicket(pedido: pedido, userRole: role),
            ),
          ),
        ),
      ),
    );
  }

  group('KitchenOrderTicket Logic & UI', () {
    final basePedido = Pedido(
      id: 1,
      mesaId: 1,
      usuarioId: 1,
      nombreCliente: 'Cliente Test',
      estado: PedidoEstados.recibido,
      tipo: 'mesa',
      total: 50.0,
      createdAt: DateTime.now(),
      detalles: [],
    );

    testWidgets('Estado Recibido: Botones Iniciar y Cancelar', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest(basePedido, 'cocinero'));
      await tester.pumpAndSettle();

      expect(find.text('Iniciar Preparación'), findsOneWidget);
      expect(find.text('Cancelar Pedido'), findsOneWidget);
    });

    testWidgets('Estado En Preparación: Botón Listo para Servir', (WidgetTester tester) async {
      final pedido = basePedido.copyWith(estado: PedidoEstados.enPreparacion);
      await tester.pumpWidget(createWidgetUnderTest(pedido, 'cocinero'));
      await tester.pumpAndSettle();

      expect(find.text('Listo para Servir'), findsOneWidget);
    });

    testWidgets('Estado Listo: Botón Entregar Pedido', (WidgetTester tester) async {
      final pedido = basePedido.copyWith(estado: PedidoEstados.listo);
      await tester.pumpWidget(createWidgetUnderTest(pedido, 'cocinero'));
      await tester.pumpAndSettle();

      expect(find.text('Entregar Pedido'), findsOneWidget);
    });

    testWidgets('Rol No Autorizado: Texto Solo lectura', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest(basePedido, 'mozo'));
      await tester.pumpAndSettle();

      expect(find.text('Solo lectura'), findsOneWidget);
      expect(find.text('Iniciar Preparación'), findsNothing);
    });
  });
}