import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/pedido_model.dart';
import '../providers/pedido_provider.dart';
import '../constants/pedido_estados.dart';
import '../utils/date_formatter.dart'; // Importar DateFormatter
import '../services/receipt_service.dart'; // Importar ReceiptService
import 'checkout_screen.dart'; // Importar pantalla de cobro
import '../providers/cart_provider.dart';
import '../providers/order_details_provider.dart';

class PedidosListScreen extends StatefulWidget {
  const PedidosListScreen({super.key});

  @override
  State<PedidosListScreen> createState() => _PedidosListScreenState();
}

class _PedidosListScreenState extends State<PedidosListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Trigger initial data load and Socket connection
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pedidoProvider = Provider.of<PedidoProvider>(context, listen: false);
      pedidoProvider.cargarPedidosIniciales();
      
      // Inicializar socket centralizado en el provider
      pedidoProvider.initSocket();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Pedidos'),
          bottom: TabBar(
            controller: _tabController,
            tabs: [
              Tab(
                icon: Consumer<PedidoProvider>(
                  builder: (context, pedidoProvider, child) {
                    // Contar pedidos que están 'listo' O tienen al menos un ítem 'listo'
                    final readyCount = pedidoProvider.pedidos.where((p) {
                      if (p.estado == 'listo') return true;
                      if (p.estado == 'en_preparacion') {
                        return p.detalles.any((d) => d.listo);
                      }
                      return false;
                    }).length;
                    
                    return Badge(
                      label: Text(readyCount.toString()),
                      isLabelVisible: readyCount > 0,
                      child: const Icon(Icons.timelapse),
                    );
                  },
                ),
                text: 'Activos',
              ),
              const Tab(icon: Icon(Icons.history), text: 'Historial'),
            ],
          ),
      ),
      body: Consumer<PedidoProvider>(
        builder: (context, pedidoProvider, child) {
          if (pedidoProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (pedidoProvider.errorMessage != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 60),
                    const SizedBox(height: 16),
                    Text(
                      'Ocurrió un problema',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      pedidoProvider.errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => pedidoProvider.cargarPedidosIniciales(),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reintentar'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildPedidosList(pedidoProvider.pedidosActivos, isHistorial: false),
              _buildPedidosList(pedidoProvider.pedidosHistorial, isHistorial: true),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPedidosList(List<Pedido> pedidos, {required bool isHistorial}) {
    if (pedidos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isHistorial ? Icons.history_toggle_off : Icons.fastfood_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              isHistorial ? 'No tienes pedidos recientes' : 'No hay pedidos activos',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: pedidos.length,
      // Increased bottom padding to prevent overlap with system buttons/navigation
      padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 100.0),
      itemBuilder: (context, index) {
        final pedido = pedidos[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: PedidoEstados.getColor(pedido.estado).withOpacity(0.3), width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      pedido.tipo.toLowerCase() == 'delivery' 
                          ? 'Delivery' 
                          : pedido.tipo.toLowerCase() == 'recojo' || pedido.tipo.toLowerCase() == 'llevar'
                              ? 'Para Llevar' 
                              : 'Mesa ${pedido.mesaId ?? "?"}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    _buildStateChip(pedido.estado),
                      IconButton(
                        icon: const Icon(Icons.print, color: Colors.grey),
                        onPressed: () => ReceiptService().printReceipt(
                          pedido, 
                          paymentMethod: pedido.metodoPago,
                          montoRecibido: pedido.montoRecibido,
                          vuelto: pedido.vuelto
                        ),
                        tooltip: 'Imprimir Ticket de Venta',
                      ),
                      if (!isHistorial && pedido.estado != PedidoEstados.entregado)
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () {
                            Provider.of<CartProvider>(context, listen: false).loadPedido(pedido);
                            final orderProvider = Provider.of<OrderDetailsProvider>(context, listen: false);
                            orderProvider.setNombreCliente(pedido.nombreCliente ?? '');
                            orderProvider.setNumeroMesa(pedido.mesaId ?? 1);
                            
                            Navigator.of(context).pop();
                          },
                          tooltip: 'Editar Pedido',
                        ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Cliente: ${pedido.nombreCliente ?? "Sin nombre"}'),
                if (pedido.metodoPago != null) // Mostrar método de pago si existe
                  Text('Método de Pago: ${pedido.metodoPago}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                const SizedBox(height: 4),
                Text(
                  'Total: S/${pedido.total.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
                ),
                const Divider(height: 24),
                const Text('Detalles:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                
                // Lista de detalles del pedido
                ...pedido.detalles.map((detalle) => Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${detalle.cantidad}x',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              detalle.nombrePlatillo ?? 'Platillo #${detalle.platilloId}', 
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (detalle.notas != null && detalle.notas!.trim().isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2.0),
                                child: Text(
                                  'Nota: ${detalle.notas}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.red[700],
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (detalle.listo)
                         // Visual Checkbox (Read-only) to match Kitchen UI
                         IgnorePointer(
                           child: Checkbox(
                             value: true, 
                             onChanged: (_) {}, // Kept enabled visually
                             activeColor: Colors.green,
                             visualDensity: VisualDensity.compact,
                           ),
                         )
                      else 
                         // Checkbox vacío para indicar pendiente (Read-only)
                         IgnorePointer(
                           child: Checkbox(
                             value: false, 
                             onChanged: (_) {}, 
                             visualDensity: VisualDensity.compact,
                           ),
                         ),
                    ],
                  ),
                )),

                // Botón Servir (Solo visible si está Listo)
                if (pedido.estado == PedidoEstados.listo) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.room_service),
                      label: const Text('Servir a Mesa'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: PedidoEstados.getColor(PedidoEstados.listo), // Green
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () async {
                        final provider = Provider.of<PedidoProvider>(context, listen: false);
                        await provider.updatePedidoStatus(pedido.id, PedidoEstados.entregado);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Pedido marcado como entregado (En mesa)')),
                          );
                        }
                      },
                    ),
                  ),
                ] else if (pedido.estado == PedidoEstados.entregado) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Text('S/', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      label: const Text('Cobrar y Finalizar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueGrey,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                         // Navegar a la pantalla de cobro
                         Navigator.of(context).push(
                           MaterialPageRoute(builder: (context) => CheckoutScreen(pedido: pedido)),
                         );
                      },
                    ),
                  ),
                ],

                const SizedBox(height: 8),
                Text(
                  'Hora: ${DateFormatter.formatFriendly(pedido.createdAt)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  textAlign: TextAlign.end,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStateChip(String estado) {
    return Chip(
      label: Text(
        PedidoEstados.getLabel(estado),
        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
      ),
      backgroundColor: PedidoEstados.getColor(estado),
      padding: const EdgeInsets.symmetric(horizontal: 0),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}