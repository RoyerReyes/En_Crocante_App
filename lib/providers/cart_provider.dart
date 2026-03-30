import 'package:flutter/foundation.dart';
import '../models/cart_item_model.dart';
import '../models/platillo_model.dart';
import '../models/pedido_model.dart';
import 'package:flutter/material.dart'; // Para UniqueKey si fuera necesario directamente

class CartProvider with ChangeNotifier {
  final List<CartItem> _items = [];
  int? _editPedidoId;
  double _costoDelivery = 0.0;

  List<CartItem> get itemsList => List.unmodifiable(_items);
  int? get editPedidoId => _editPedidoId;
  int get itemCount => _items.fold(0, (sum, item) => sum + item.cantidad);
  double get costoDelivery => _costoDelivery;
  double get totalItemsAmount => _items.fold(0.0, (sum, item) => sum + item.subtotal);
  double get totalAmount => totalItemsAmount + _costoDelivery;

  // Añade un CADA nuevo producto como un renglón independiente SIEMPRE.
  void addItem(Platillo platillo, {String? notas}) {
    _items.add(CartItem(platillo: platillo, notas: notas));
    notifyListeners();
  }

  // Elimina un ítem de la lista basado en su Unique ID
  void removeItemByUniqueId(String uniqueId) {
    _items.removeWhere((item) => item.uniqueId == uniqueId);
    notifyListeners();
  }

  // Para compatibilidad histórica en otras pantallas (vaciado total del item si existe, aunque no es recomendado ahora)
  void removeSingleItem(int platilloId) {
    // Si la pantalla vieja llama esto, removemos el último agregado de ese platillo
    final index = _items.lastIndexWhere((item) => item.platillo.id == platilloId);
    if (index != -1) {
       _items.removeAt(index);
    }
    notifyListeners();
  }

  void removeItem(int platilloId) {
    _items.removeWhere((item) => item.platillo.id == platilloId);
    notifyListeners();
  }

  void setCostoDelivery(double value) {
    _costoDelivery = value;
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    _editPedidoId = null;
    _costoDelivery = 0.0;
    notifyListeners();
  }

  void loadPedido(Pedido pedido) {
    _items.clear();
    _editPedidoId = pedido.id;
    for (var detalle in pedido.detalles) {
      final platilloDummy = Platillo(
        id: detalle.platilloId,
        nombre: detalle.nombrePlatillo ?? 'Producto',
        descripcion: '',
        precio: detalle.precioUnitario,
        categoria: Categoria(id: 1, nombre: 'Actualizando...'), // Dummy
        activo: true,
      );
      
      // En modo edición mantenemos temporalmente la cantidad agrupada por si viene del backend agrupado
      // Pero si queremos desagrupar el historial también (opcional):
      for (int i = 0; i < detalle.cantidad; i++) {
         _items.add(CartItem(
            platillo: platilloDummy,
            cantidad: 1, // Desglosamos en UI
            notas: detalle.notas,
         ));
      }
    }
    notifyListeners();
  }

  void updateItemNotes(String uniqueId, String? newNotes) {
    final index = _items.indexWhere((item) => item.uniqueId == uniqueId);
    if (index != -1) {
      _items[index] = _items[index].copyWith(
        notas: newNotes,
        clearNotas: newNotes == null,
      );
      notifyListeners();
    }
  }
}

