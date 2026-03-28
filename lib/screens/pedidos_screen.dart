import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/pedido_provider.dart';

class PedidosScreen extends StatefulWidget {
  const PedidosScreen({super.key});

  @override
  State<PedidosScreen> createState() => _PedidosScreenState();
}

class _PedidosScreenState extends State<PedidosScreen> {
  @override
  void initState() {
    super.initState();
    // Usamos addPostFrameCallback para asegurarnos de que el context está disponible
    // y llamamos al provider para que cargue los datos.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PedidoProvider>(context, listen: false).cargarPedidosIniciales();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Pedidos'),
      ),
      body: Consumer<PedidoProvider>(
        builder: (context, pedidoProvider, child) {
          // Estado de Carga
          if (pedidoProvider.isLoading && pedidoProvider.pedidos.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          // Estado de Error
          if (pedidoProvider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${pedidoProvider.errorMessage}', textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => pedidoProvider.cargarPedidosIniciales(),
                    child: const Text('Reintentar'),
                  )
                ],
              ),
            );
          }

          // Estado Vacío
          if (pedidoProvider.pedidos.isEmpty) {
            return const Center(child: Text('No tienes pedidos activos.'));
          }

          // Estado con Datos
          return RefreshIndicator(
            onRefresh: () => pedidoProvider.cargarPedidosIniciales(),
            child: ListView.builder(
              itemCount: pedidoProvider.pedidos.length,
              itemBuilder: (context, index) {
                final pedido = pedidoProvider.pedidos[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  elevation: 4,
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      child: Text(pedido.id.toString()),
                    ),
                    title: Text('Pedido #${pedido.id}'),
                    trailing: Chip(
                      label: Text(
                        pedido.estado.replaceAll('_', ' ').toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      backgroundColor: _getColorForEstado(pedido.estado),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Color _getColorForEstado(String estado) {
    switch (estado) {
      case 'recibido':
        return Colors.blue;
      case 'en_preparacion':
        return Colors.orange;
      case 'listo':
        return Colors.green;
      case 'entregado':
        return Colors.grey;
      default:
        return Colors.black;
    }
  }
}
