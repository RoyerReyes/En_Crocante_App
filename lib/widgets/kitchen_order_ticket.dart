import 'package:encrocante_app/models/platillo_model.dart';
import 'package:encrocante_app/providers/platillo_provider.dart';
import 'package:encrocante_app/providers/pedido_provider.dart'; // Añadir esta importación
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/pedido_model.dart';
import '../constants/pedido_estados.dart';

class KitchenOrderTicket extends StatelessWidget {
  final Pedido pedido;
  final String? userRole; // Nuevo parámetro opcional

  const KitchenOrderTicket({super.key, required this.pedido, this.userRole});

  @override
  Widget build(BuildContext context) {
    // Datos reales del modelo
    final mozoName = pedido.nombreMesero ?? 'Sin asignar';
    final clientName = pedido.nombreCliente ?? 'Cliente General';

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 4.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      margin: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Encabezado ---
          _buildHeader(context, mozoName),
          const Divider(height: 1),

          // --- Cuerpo del Pedido ---
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Sub-encabezado con cliente y hora ---
                  _buildSubHeader(clientName),
                  const SizedBox(height: 16),
                  
                  // --- Lista de platillos ---
                  ..._buildPlatillosList(context),
                  
                  // --- Notas Generales del Pedido ---
                if (pedido.observaciones != null && pedido.observaciones!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: Colors.yellow[50],
                        border: Border.all(color: Colors.amber[200]!),
                        borderRadius: BorderRadius.circular(4)
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Notas Generales:', 
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber[900])
                          ),
                          Text(
                            pedido.observaciones!,
                            style: const TextStyle(fontStyle: FontStyle.italic),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          
          // --- Pie de página con acciones ---
          _buildFooter(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String mozoName) {
    return Container(
      color: _getStatusColor(pedido.estado).withOpacity(0.1),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Text(
            _getTipoPedidoLabel(),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              mozoName,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Chip(
            label: Text(
              pedido.estado.toUpperCase(),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
            ),
            backgroundColor: _getStatusColor(pedido.estado),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          )
        ],
      ),
    );
  }

  Widget _buildSubHeader(String clientName) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TICKET: P-${pedido.id.toString().padLeft(2, '0')}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.blueGrey),
              ),
              Text(
                clientName,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        Text(
          DateFormat('hh:mm a').format(pedido.createdAt.toLocal()), // Fix Timezone
          style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  List<Widget> _buildPlatillosList(BuildContext context) {
    final platilloProvider = Provider.of<PlatilloProvider>(context, listen: false);
    
    return pedido.detalles.map((detalle) {
      // Preferimos el nombre snapshot del detalle, si no, buscamos en provider
      String nombrePlatillo = detalle.nombrePlatillo ?? 'Platillo #${detalle.platilloId}';
      
      if (detalle.nombrePlatillo == null) {
          final Platillo platillo = platilloProvider.platillos.firstWhere(
            (p) => p.id == detalle.platilloId,
            orElse: () => Platillo(id: 0, nombre: 'Platillo Desconocido', precio: 0.0, activo: false, categoria: Categoria(id: 0, nombre: 'Desconocida')),
          );
          if (platillo.id != 0) {
             nombrePlatillo = platillo.nombre;
          }
      }

      final bool isEnPreparacion = pedido.estado == PedidoEstados.enPreparacion;
      final bool isListo = pedido.estado == PedidoEstados.listo;

      return Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    '${detalle.cantidad}x $nombrePlatillo',
                    style: TextStyle(
                      fontSize: 16,
                      decoration: detalle.listo ? TextDecoration.lineThrough : null,
                      color: detalle.listo ? Colors.green : Colors.black,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                
                // Lógica de visualización de Checkbox
                if (isEnPreparacion) 
                  Checkbox(
                    value: detalle.listo,
                    onChanged: (bool? value) {
                      // Call provider toggle
                      Provider.of<PedidoProvider>(context, listen: false).toggleItem(pedido.id, detalle.id);
                    },
                    activeColor: Colors.green,
                  )
                else if (isListo || detalle.listo)
                  const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Icon(Icons.check_circle, color: Colors.green, size: 24),
                  )
                else 
                  // En estado 'recibido' o 'pendiente', mostramos un placeholder o nada
                  const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Icon(Icons.check_box_outline_blank, color: Colors.grey, size: 24),
                  ),
              ],
            ),
            if (detalle.notas != null && detalle.notas!.trim().isNotEmpty) // Ensure not empty
              Padding(
                padding: const EdgeInsets.only(top: 4.0, left: 8.0),
                child: Text(
                  'Nota Item: "${detalle.notas!}"',
                  style: TextStyle(
                      fontSize: 14,
                      color: Colors.red.shade700, // Rojo para resaltar
                      fontWeight: FontWeight.bold, // Negrita para resaltar
                      fontStyle: FontStyle.italic),
                ),
              ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildFooter(BuildContext context) {
    final pedidoProvider = Provider.of<PedidoProvider>(context, listen: false);

    // Verificación de permisos
    final bool canEdit = userRole == 'admin' || userRole == 'cocinero' || userRole == 'cocina';
    
    if (!canEdit) {
       // Si no tiene permisos y el pedido no está listo (donde no hay acciones críticas), no mostrar nada o mensaje
       return const Padding(
         padding: EdgeInsets.all(8.0),
         child: Center(child: Text('Solo lectura', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic))),
       );
    }

    switch (pedido.estado) {
      // Estado 1: Pedido Recibido / Pendiente
      case PedidoEstados.recibido:
      case PedidoEstados.pendiente:
        return _buildActionButtons(
          context,
          primaryText: 'Iniciar Preparación',
          onPrimary: () =>
              pedidoProvider.updatePedidoStatus(pedido.id, PedidoEstados.enPreparacion),
          secondaryText: 'Cancelar Pedido',
          onSecondary: () =>
              pedidoProvider.updatePedidoStatus(pedido.id, PedidoEstados.cancelado),
          primaryColor: Colors.green,
          secondaryColor: Colors.red,
        );

      // Estado 2: En Preparación
      case PedidoEstados.enPreparacion:
        return _buildActionButtons(
          context,
          primaryText: 'Listo para Servir',
          onPrimary: () => pedidoProvider.updatePedidoStatus(pedido.id, PedidoEstados.listo),
          secondaryText: 'Pausar',
          onSecondary: () =>
              pedidoProvider.updatePedidoStatus(pedido.id, PedidoEstados.recibido),
        );

      // Estado 3: Listo para entregar
      case PedidoEstados.listo:
        return Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(20), // Rounded pill shape-ish
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, color: Colors.green.shade700),
                  const SizedBox(width: 8),
                  Text(
                    'Esperando entrega del mozo',
                    style: TextStyle(
                      color: Colors.green.shade800,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.undo, size: 18),
                label: const Text('Volver a Preparación'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey.shade700,
                  side: BorderSide(color: Colors.grey.shade300),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), // Match style
                ),
                onPressed: () =>
                    pedidoProvider.updatePedidoStatus(pedido.id, PedidoEstados.enPreparacion),
              ),
            ),
          ],
        );

      // Otros estados (cancelado, entregado, etc.)
      default:
        return const SizedBox.shrink(); // No mostrar acciones
    }
  }

  // Helper para construir la fila de botones de acción
  Widget _buildActionButtons(
    BuildContext context, {
    required String primaryText,
    required VoidCallback onPrimary,
    required String secondaryText,
    required VoidCallback onSecondary,
    Color primaryColor = Colors.blue,
    Color secondaryColor = Colors.grey,
  }) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
              onPressed: onPrimary,
              child: Text(primaryText),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(foregroundColor: secondaryColor),
              onPressed: onSecondary,
              child: Text(secondaryText),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String estado) {
    return PedidoEstados.getColor(estado);
  }

  String _getTipoPedidoLabel() {
    if (pedido.tipo == 'delivery') {
      return 'Delivery';
    } else if (pedido.tipo == 'recojo') {
      return 'Para Llevar';
    } else {
      return 'Mesa ${pedido.mesaId ?? "?"}';
    }
  }
}
