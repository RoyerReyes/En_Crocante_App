import 'package:encrocante_app/screens/pedidos_list_screen.dart'; // Importar PedidosListScreen
import 'package:encrocante_app/services/auth_service.dart';
import 'package:encrocante_app/services/pedido_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../widgets/cart_item_tile.dart';
import '../constants/app_constants.dart';
import '../providers/order_details_provider.dart';
import '../providers/config_provider.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final PedidoService _pedidoService = PedidoService();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  @override
  void dispose() {
    super.dispose();
  }

  void _submitOrder() async {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final orderDetailsProvider = Provider.of<OrderDetailsProvider>(context, listen: false);

    if (cartProvider.itemsList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El carrito está vacío. Agrega productos antes de realizar un pedido.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (orderDetailsProvider.nombreCliente.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, completa el nombre del cliente en la pestaña Cliente.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() { _isLoading = true; });

    try {
      bool success = false;
      if (cartProvider.editPedidoId != null) {
        success = await _pedidoService.actualizarPedido(
          cartProvider.editPedidoId!,
          cartProvider.itemsList,
          orderDetailsProvider.nombreCliente.trim(),
          orderDetailsProvider.numeroMesa,
          tipoPedido: orderDetailsProvider.tipoAtencion,
          clienteId: orderDetailsProvider.clienteSeleccionado?.id,
          costoDelivery: cartProvider.costoDelivery,
        );
      } else {
        success = await _pedidoService.crearPedido(
          cartProvider.itemsList,
          orderDetailsProvider.nombreCliente.trim(),
          orderDetailsProvider.numeroMesa,
          tipoPedido: orderDetailsProvider.tipoAtencion,
          clienteId: orderDetailsProvider.clienteSeleccionado?.id,
          costoDelivery: cartProvider.costoDelivery,
        );
      }

      if (success && mounted) {
        cartProvider.clearCart();
        orderDetailsProvider.resetClientDetails();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Pedido realizado con éxito!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Redirigir al dashboard de pedidos para seguimiento inmediato
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const PedidosListScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al realizar el pedido: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Carrito de Compras'),
      ),
      body: Column(
        children: [
          Expanded(
            child: Consumer<CartProvider>(
              builder: (context, cart, child) {
                final cartItems = cart.itemsList;
                if (cartItems.isEmpty) {
                  return const Center(
                    child: Text('Tu carrito está vacío.', style: TextStyle(fontSize: 18, color: Colors.grey)),
                  );
                }
                return ListView.builder(
                  itemCount: cartItems.length,
                  itemBuilder: (context, index) {
                    final item = cartItems[index];


                    return CartItemTile(item: item);
                  },
                );
              },
            ),
          ),
          _buildCheckoutBarContent(context),
        ],
      ),
    );
  }

  Widget _buildCheckoutBarContent(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cart, child) {
        // Obtenemos el provider de detalles del pedido sin escuchar cambios constantes si solo validamos al final,
        // PERO queremos validación en tiempo real para el botón, así que usamos Consumer2 o Provider.of<OrderDetailsProvider>(context)
        return Consumer<OrderDetailsProvider>(
          builder: (context, orderDetails, child) {
            
            final bool canSubmit = cart.itemsList.isNotEmpty && orderDetails.nombreCliente.trim().isNotEmpty;

            // PROGRAMA DE FIDELIZACION (COMENTADO TEMPORALMENTE)
            // final int puntosGanados = (cart.totalItemsAmount / config.solesPorPunto).floor();

            return SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), spreadRadius: 1, blurRadius: 5, offset: const Offset(0, -2))],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (orderDetails.esDelivery)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: TextField(
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Costo de Delivery (S/)',
                            border: OutlineInputBorder(),
                            isDense: true,
                            prefixIcon: Icon(Icons.delivery_dining),
                          ),
                          onChanged: (value) {
                             final cost = double.tryParse(value) ?? 0.0;
                             cart.setCostoDelivery(cost);
                          },
                        ),
                      ),
                    
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Subtotal Productos:'),
                            Text('S/ ${cart.totalItemsAmount.toStringAsFixed(2)}'),
                          ],
                        ),
                        if (orderDetails.esDelivery)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Delivery:'),
                              Text('S/ ${cart.costoDelivery.toStringAsFixed(2)}'),
                            ],
                          ),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total a pagar:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            Text('S/ ${cart.totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppConstants.primaryColor)),
                          ],
                        ),
                      ],
                    ),
                    
                    // PROGRAMA DE FIDELIZACION (COMENTADO TEMPORALMENTE)
                    /*
                    if (puntosGanados > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.stars, color: Colors.amber, size: 20),
                            const SizedBox(width: 8),
                            Text('Ganas $puntosGanados pts', style: const TextStyle(color: Colors.brown, fontWeight: FontWeight.bold)),
                          ],
                        )
                      ),
                    */

                    const SizedBox(height: 16.0),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.delete_outline, size: 20),
                            label: const FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'Limpiar Carrito', 
                                style: TextStyle(fontSize: 12),
                                maxLines: 1,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                            ),
                            onPressed: cart.itemCount == 0
                                ? null
                                : () {
                                    // Confirm dialog logic...
                                    _showClearCartDialog(context, cart);
                                  },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: _isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : ElevatedButton.icon(
                                  icon: Icon(canSubmit ? Icons.check_circle : Icons.warning_amber_rounded),
                                  label: Text(canSubmit 
                                    ? (cart.editPedidoId != null ? 'Actualizar Pedido' : 'Realizar Pedido') 
                                    : 'Faltan datos del cliente'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: canSubmit ? Colors.green.shade600 : Colors.grey.shade400,
                                    minimumSize: const Size.fromHeight(50),
                                  ),
                                  onPressed: canSubmit ? _submitOrder : null,
                                ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showClearCartDialog(BuildContext context, CartProvider cart) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Limpiar Carrito?'),
        content: const Text('¿Estás seguro de eliminar todos los productos del carrito?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            // ignore: use_build_context_synchronously
            onPressed: () {
              cart.clearCart();
              Navigator.of(ctx).pop();
            },
            child: const Text('Limpiar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}