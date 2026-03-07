import 'package:flutter/foundation.dart';
import '../models/platillo_model.dart';

class CartProvider with ChangeNotifier {
  final List<Platillo> _items = [];

  List<Platillo> get items => _items;

  int get itemCount => _items.length;

  void addItem(Platillo platillo) {
    _items.add(platillo);
    notifyListeners(); // Notifica a los widgets que escuchan para que se reconstruyan.
  }

  void removeItem(Platillo platillo) {
    _items.remove(platillo);
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}
