import 'package.flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Usamos un Consumer para acceder al estado del carrito y redibujar cuando cambie.
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Carrito de Compras'),
      ),
      body: Consumer<CartProvider>(
        builder: (context, cart, child) {
          if (cart.items.isEmpty) {
            return const Center(
              child: Text(
                'Tu carrito está vacío.',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: cart.items.length,
                  itemBuilder: (context, index) {
                    final platillo = cart.items[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: (platillo.imagenUrl != null && platillo.imagenUrl!.isNotEmpty)
                            ? NetworkImage(platillo.imagenUrl!)
                            : null,
                        child: (platillo.imagenUrl == null || platillo.imagenUrl!.isEmpty)
                            ? const Icon(Icons.restaurant)
                            : null,
                      ),
                      title: Text(platillo.nombre),
                      subtitle: Text('S/${platillo.precio.toStringAsFixed(2)}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                        onPressed: () {
                          // Lógica para eliminar el item del carrito
                          cart.removeItem(platillo);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${platillo.nombre} eliminado del carrito.'),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
              const Divider(height: 1),
              // Aquí podrías agregar un resumen del total en el futuro
            ],
          );
        },
      ),
      bottomNavigationBar: _buildCheckoutBar(context),
    );
  }

  Widget _buildCheckoutBar(BuildContext context) {
    // Envolvemos la barra inferior con un Consumer para que el total se actualice.
    return Consumer<CartProvider>(
      builder: (context, cart, child) {
        // Calculamos el total. NOTA: Esto se recalcula en cada rebuild.
        // Para carritos muy grandes, sería mejor calcularlo dentro del Provider.
        final double total = cart.items.fold(0.0, (sum, item) => sum + item.precio);

        return Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total:', style: TextStyle(fontSize: 16, color: Colors.grey)),
                  Text(
                    'S/${total.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.payment),
                label: const Text('Realizar Pedido'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  textStyle: const TextStyle(fontSize: 16),
                ),
                // El botón se deshabilita si el carrito está vacío.
                onPressed: cart.items.isEmpty
                    ? null
                    : () {
                        // TODO: Lógica para enviar el pedido al backend.
                      },
              ),
            ],
          ),
        );
      },
    );
  }
}
