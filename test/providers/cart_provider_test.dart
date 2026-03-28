import 'package:flutter_test/flutter_test.dart';
import 'package:encrocante_app/providers/cart_provider.dart';
import 'package:encrocante_app/models/platillo_model.dart';

void main() {
  group('CartProvider Tests', () {
    late CartProvider cartProvider;
    late Platillo platillo1;
    late Platillo platillo2;

    setUp(() {
      cartProvider = CartProvider();
      
      final categoria = Categoria(id: 1, nombre: 'Entradas');
      
      platillo1 = Platillo(
        id: 1,
        nombre: 'Ceviche',
        precio: 25.0,
        activo: true,
        categoria: categoria,
      );
      
      platillo2 = Platillo(
        id: 2,
        nombre: 'Jalea',
        precio: 40.0,
        activo: true,
        categoria: categoria,
      );
    });

    test('Initial state should be empty', () {
      expect(cartProvider.items, isEmpty);
      expect(cartProvider.itemCount, 0);
      expect(cartProvider.totalAmount, 0.0);
    });

    test('Add item should add to cart', () {
      cartProvider.addItem(platillo1);

      expect(cartProvider.items, hasLength(1));
      expect(cartProvider.items.containsKey(platillo1.id), true);
      expect(cartProvider.itemCount, 1);
      expect(cartProvider.totalAmount, 25.0);
    });

    test('Add existing item should increment quantity', () {
      cartProvider.addItem(platillo1);
      cartProvider.addItem(platillo1);

      expect(cartProvider.items, hasLength(1));
      expect(cartProvider.items[platillo1.id]!.cantidad, 2);
      expect(cartProvider.itemCount, 2);
      expect(cartProvider.totalAmount, 50.0);
    });

    test('Add different items should handle multiple entries', () {
      cartProvider.addItem(platillo1);
      cartProvider.addItem(platillo2);

      expect(cartProvider.items, hasLength(2));
      expect(cartProvider.itemCount, 2);
      expect(cartProvider.totalAmount, 65.0); // 25 + 40
    });

    test('Remove single item should decrement quantity', () {
      cartProvider.addItem(platillo1);
      cartProvider.addItem(platillo1);
      
      cartProvider.removeSingleItem(platillo1.id);

      expect(cartProvider.items[platillo1.id]!.cantidad, 1);
      expect(cartProvider.itemCount, 1);
      expect(cartProvider.totalAmount, 25.0);
    });

    test('Remove single item with quantity 1 should remove from cart', () {
      cartProvider.addItem(platillo1);
      
      cartProvider.removeSingleItem(platillo1.id);

      expect(cartProvider.items, isEmpty);
      expect(cartProvider.totalAmount, 0.0);
    });

    test('Clear cart should remove all items', () {
      cartProvider.addItem(platillo1);
      cartProvider.addItem(platillo2);
      
      cartProvider.clearCart();

      expect(cartProvider.items, isEmpty);
      expect(cartProvider.itemCount, 0);
      expect(cartProvider.totalAmount, 0.0);
    });
  });
}
