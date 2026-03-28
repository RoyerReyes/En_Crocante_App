import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:encrocante_app/widgets/order_details_widget.dart';
import 'package:encrocante_app/providers/cart_provider.dart';
import 'package:encrocante_app/providers/order_details_provider.dart';

void main() {
  testWidgets('OrderDetailsWidget shows validation error initially if name is empty', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => CartProvider()),
          ChangeNotifierProvider(create: (_) => OrderDetailsProvider()),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: OrderDetailsWidget(mozoResponsable: 'Juan'),
          ),
        ),
      ),
    );

    // Initial state: Name is empty, so error should be visible
    expect(find.text('El nombre es obligatorio'), findsOneWidget);
    expect(find.text('Mozo: Juan'), findsOneWidget);
  });

  testWidgets('OrderDetailsWidget validation error disappears when name is entered', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => CartProvider()),
          ChangeNotifierProvider(create: (_) => OrderDetailsProvider()),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: OrderDetailsWidget(mozoResponsable: 'Juan'),
          ),
        ),
      ),
    );

    // Enter name
    await tester.enterText(find.byType(TextField), 'Cliente Test');
    await tester.pump();

    // Error should be gone
    expect(find.text('El nombre es obligatorio'), findsNothing);
  });

  testWidgets('Table number selector logic', (WidgetTester tester) async {
    final orderDetailsProvider = OrderDetailsProvider();
    
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => CartProvider()),
          ChangeNotifierProvider.value(value: orderDetailsProvider),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: OrderDetailsWidget(),
          ),
        ),
      ),
    );

    // Initial table is 1
    expect(find.text('1'), findsOneWidget);

    // Try to decrease below 1 (should not work)
    await tester.tap(find.byIcon(Icons.remove));
    await tester.pump();
    expect(find.text('1'), findsOneWidget); // Still 1

    // Increase
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    expect(find.text('2'), findsOneWidget);
  });
}
