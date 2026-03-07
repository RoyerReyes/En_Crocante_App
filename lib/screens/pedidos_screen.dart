import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/pedido_provider.dart';
import '../services/socket_service.dart';

class PedidosScreen extends StatefulWidget {
  const PedidosScreen({super.key});

  @override
  State<PedidosScreen> createState() => _PedidosScreenState();
}

class _PedidosScreenState extends State<PedidosScreen> {
  late SocketService _socketService;

  @override
  void initState() {
    super.initState();
    
    // 1. Obtenemos la instancia del provider SIN escuchar cambios.
    // Usamos listen: false porque estamos fuera del método build.
    final pedidoProvider = Provider.of<PedidoProvider>(context, listen: false);

    // 2. Cargamos los datos iniciales (simulados por ahora).
    pedidoProvider.cargarPedidosIniciales();

    // 3. Creamos el SocketService y le pasamos el método del provider como callback.
    // Así, el servicio notificará al provider directamente.
    _socketService = SocketService(
      onEstadoActualizado: pedidoProvider.actualizarEstadoDesdeSocket,
    );

    // 4. Nos conectamos al servidor de sockets.
    _socketService.connectToServer();
  }

  @override
  void dispose() {
    // Es una buena práctica desconectarse al salir de la pantalla para liberar recursos.
    _socketService.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seguimiento de Pedidos en Tiempo Real'),
      ),
      // 5. Usamos un Consumer para que solo esta parte de la UI se reconstruya
      // cuando el PedidoProvider llame a notifyListeners().
      body: Consumer<PedidoProvider>(
        builder: (context, pedidoProvider, child) {
          if (pedidoProvider.pedidos.isEmpty) {
            return const Center(child: Text('No hay pedidos para mostrar.'));
          }
          // Usamos un RefreshIndicator para poder recargar los pedidos manualmente.
          return RefreshIndicator(
            onRefresh: () async {
              // En el futuro, aquí podrías volver a llamar a la API REST.
              pedidoProvider.cargarPedidosIniciales();
            },
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

  // Función auxiliar para dar color a los estados del pedido.
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
