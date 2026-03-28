import 'package:encrocante_app/models/cart_item_model.dart';
import 'package:encrocante_app/models/platillo_model.dart';
import 'package:encrocante_app/providers/cart_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late CartProvider cartProvider;
  late Platillo platillo1;
  late Platillo platillo2;

  setUp(() {
    cartProvider = CartProvider();
    
    final categoria = Categoria(id: 1, nombre: 'Entradas');
    
    platillo1 = Platillo(
      id: 1,
      nombre: 'Tequeños',
      precio: 15.0,
      activo: true,
      categoria: categoria,
    );
    
    platillo2 = Platillo(
      id: 2,
      nombre: 'Ceviche',
      precio: 25.0,
      activo: true,
      categoria: categoria,
    );
  });

  group('CartProvider Advanced Tests', () {
    test('addItem increments quantity if item exists', () {
      cartProvider.addItem(platillo1);
      expect(cartProvider.itemCount, 1);
      
      cartProvider.addItem(platillo1);
      expect(cartProvider.itemCount, 2);
      expect(cartProvider.items[1]!.cantidad, 2);
      expect(cartProvider.totalAmount, 30.0);
    });

    test('addItem adds distinct items separately', () {
      cartProvider.addItem(platillo1);
      cartProvider.addItem(platillo2);
      
      expect(cartProvider.itemCount, 2); // 1 of each
      expect(cartProvider.items.length, 2);
      expect(cartProvider.totalAmount, 40.0);
    });

    test('removeSingleItem decrements quantity or removes item', () {
      cartProvider.addItem(platillo1);
      cartProvider.addItem(platillo1); // Qty = 2
      
      cartProvider.removeSingleItem(1);
      expect(cartProvider.items[1]!.cantidad, 1);
      expect(cartProvider.items.containsKey(1), true);
      
      cartProvider.removeSingleItem(1);
      expect(cartProvider.items.containsKey(1), false);
      expect(cartProvider.itemCount, 0);
    });

    test('updateItemNotes modifies item notes correctly', () {
      cartProvider.addItem(platillo1);
      
      cartProvider.updateItemNotes(1, 'Sin queso');
      expect(cartProvider.items[1]!.notas, 'Sin queso');
      
      cartProvider.updateItemNotes(1, null);
      expect(cartProvider.items[1]!.notas, null);
    });

    test('clearCart removes all items', () {
      cartProvider.addItem(platillo1);
      cartProvider.addItem(platillo2);
      
      cartProvider.clearCart();
      
      expect(cartProvider.items.isEmpty, true);
      expect(cartProvider.itemCount, 0);
      expect(cartProvider.totalAmount, 0.0);
    });

    test('Total calculation with mixed items and quantities', () {
      // 3 Tequeños (15 * 3 = 45) + 1 Ceviche (25) = 70
      cartProvider.addItem(platillo1);
      cartProvider.addItem(platillo1);
      cartProvider.addItem(platillo1);
      cartProvider.addItem(platillo2);

      expect(cartProvider.totalAmount, 70.0);
    });
  });
}
