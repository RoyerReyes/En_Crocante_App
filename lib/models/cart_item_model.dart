import 'package:encrocante_app/models/platillo_model.dart';

// Este modelo nos ayuda a agrupar un Platillo con su cantidad.
class CartItem {
  final Platillo platillo;
  int cantidad;

  CartItem({required this.platillo, this.cantidad = 1});

  void incrementar() {
    cantidad++;
  }

  void decrementar() {
    if (cantidad > 0) {
      cantidad--;
    }
  }

  double get subtotal => platillo.precio * cantidad;
}
