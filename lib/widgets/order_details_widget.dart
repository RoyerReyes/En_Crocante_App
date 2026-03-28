import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../providers/order_details_provider.dart';
import '../providers/config_provider.dart'; // Import ConfigProvider
import '../services/cliente_service.dart';
import '../models/cliente_model.dart';
import '../constants/app_constants.dart';

class OrderDetailsWidget extends StatefulWidget {
  final String? mozoResponsable;

  const OrderDetailsWidget({super.key, this.mozoResponsable});

  @override
  State<OrderDetailsWidget> createState() => _OrderDetailsWidgetState();
}

class _OrderDetailsWidgetState extends State<OrderDetailsWidget> {
  late TextEditingController _nombreClienteController;

  @override
  void initState() {
    super.initState();
    _nombreClienteController = TextEditingController();
    // Initialize controller with value from provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final orderDetails = Provider.of<OrderDetailsProvider>(context, listen: false);
      _nombreClienteController.text = orderDetails.nombreCliente;
    });
  }

  @override
  void dispose() {
    _nombreClienteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<OrderDetailsProvider, CartProvider, ConfigProvider>(
      builder: (context, orderDetails, cart, config, child) {
        // PROGRAMA DE FIDELIZACION (COMENTADO TEMPORALMENTE)
        // final int puntosGanados = (cart.totalAmount / config.solesPorPunto).floor();

        return SingleChildScrollView( // Para que el contenido sea scrollable si es demasiado largo
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Información del Cliente',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Completa los datos antes de enviar el pedido',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Expanded(
                    child: Autocomplete<Cliente>(
                      optionsBuilder: (TextEditingValue textEditingValue) {
                         if (textEditingValue.text.isEmpty) { return const Iterable<Cliente>.empty(); }
                         return ClienteService().buscarClientes(textEditingValue.text);
                      },
                      displayStringForOption: (Cliente option) => option.nombre,
                      onSelected: (Cliente selection) {
                        orderDetails.setCliente(selection);
                      },
                      fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                         // Sincronizar controller si hay cliente seleccionado
                         if (orderDetails.clienteSeleccionado != null && textEditingController.text != orderDetails.clienteSeleccionado!.nombre) {
                            textEditingController.text = orderDetails.clienteSeleccionado!.nombre;
                         }
                         return TextField(
                          controller: textEditingController,
                          focusNode: focusNode,
                          onChanged: (value) {
                             // Si borra o edita, limpiamos el cliente seleccionado para permitir nombre libre
                             if (orderDetails.clienteSeleccionado != null && value != orderDetails.clienteSeleccionado!.nombre) {
                                orderDetails.setCliente(null);
                             }
                             orderDetails.setNombreCliente(value);
                          },
                          decoration: InputDecoration(
                            labelText: 'Cliente (Buscar por nombre/DNI)',
                            border: const OutlineInputBorder(),
                            isDense: true,
                            suffixIcon: orderDetails.clienteSeleccionado != null 
                              ? const Icon(Icons.check_circle, color: Colors.green)
                              : const Icon(Icons.search),
                            errorText: orderDetails.nombreCliente.trim().isEmpty ? 'El nombre es obligatorio' : null,
                          ),
                         );
                      },
                      optionsViewBuilder: (context, onSelected, options) {
                        return Align(
                          alignment: Alignment.topLeft,
                          child: Material(
                            elevation: 4.0,
                            child: SizedBox(
                              width: 300, // Ajustar ancho
                              height: 200,
                              child: ListView.builder(
                                padding: const EdgeInsets.all(8.0),
                                shrinkWrap: true,
                                itemCount: options.length,
                                itemBuilder: (BuildContext context, int index) {
                                  final Cliente option = options.elementAt(index);
                                  return ListTile(
                                    title: Text(option.nombre),
                                    // PROGRAMA DE FIDELIZACION (COMENTADO)
                                    subtitle: Text('DNI: ${option.dni ?? "Sin DNI"}'),
                                    onTap: () => onSelected(option),
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.person_add),
                    tooltip: 'Nuevo Cliente',
                    onPressed: () => _showCreateClienteDialog(context, orderDetails),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Modalidad de Atención',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                   Expanded(
                     child: ElevatedButton(
                       onPressed: () => orderDetails.setTipoAtencion('mesa'),
                       style: ElevatedButton.styleFrom(
                         backgroundColor: orderDetails.tipoAtencion == 'mesa' ? AppConstants.primaryColor : Colors.grey.shade200,
                         foregroundColor: orderDetails.tipoAtencion == 'mesa' ? Colors.white : Colors.black87,
                         elevation: orderDetails.tipoAtencion == 'mesa' ? 2 : 0,
                       ),
                       child: const Text('Atención en Mesa'),
                     )
                   ),
                   const SizedBox(width: 8),
                   Expanded(
                     child: ElevatedButton(
                       onPressed: () => orderDetails.setTipoAtencion('llevar'),
                       style: ElevatedButton.styleFrom(
                         backgroundColor: orderDetails.tipoAtencion != 'mesa' ? AppConstants.primaryColor : Colors.grey.shade200,
                         foregroundColor: orderDetails.tipoAtencion != 'mesa' ? Colors.white : Colors.black87,
                         elevation: orderDetails.tipoAtencion != 'mesa' ? 2 : 0,
                       ),
                       child: const Text('Para Llevar'),
                     )
                   ),
                ]
              ),
              const SizedBox(height: 16),

              if (orderDetails.tipoAtencion == 'mesa')
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Número de Mesa:', style: TextStyle(fontSize: 16)),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove),
                            onPressed: orderDetails.numeroMesa > 1 
                                ? () => orderDetails.setNumeroMesa(orderDetails.numeroMesa - 1)
                                : null,
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              orderDetails.numeroMesa.toString(), 
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: orderDetails.numeroMesa < 50
                                ? () => orderDetails.setNumeroMesa(orderDetails.numeroMesa + 1)
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: CheckboxListTile(
                        title: const Text('Enviar por Delivery', style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: const Text('Se agregará un recargo por delivery en el carrito'),
                        value: orderDetails.esDelivery,
                        onChanged: (val) {
                          if (val != null) {
                             orderDetails.setEsDelivery(val);
                          }
                        },
                        activeColor: AppConstants.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.deepOrange),
                          SizedBox(width: 8),
                          Expanded(child: Text('No olvides agregar recipiente descartable al carrito.', style: TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.w500))),
                        ],
                      ),
                    )
                  ],
                ),

              const SizedBox(height: 24),
              if (widget.mozoResponsable != null)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.person, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text(
                        'Mozo: ${widget.mozoResponsable}',
                        style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.blue),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
  void _showCreateClienteDialog(BuildContext context, OrderDetailsProvider orderDetails) {
    final nombreCtrl = TextEditingController();
    final dniCtrl = TextEditingController();
    final telefonoCtrl = TextEditingController();
    final emailCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Registrar Nuevo Cliente'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nombreCtrl, decoration: const InputDecoration(labelText: 'Nombre Completo *')),
            TextField(controller: dniCtrl, decoration: const InputDecoration(labelText: 'DNI *'), keyboardType: TextInputType.number),
            TextField(controller: telefonoCtrl, decoration: const InputDecoration(labelText: 'Teléfono (Opcional)'), keyboardType: TextInputType.phone),
            TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email (Opcional)'), keyboardType: TextInputType.emailAddress),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (nombreCtrl.text.isEmpty || dniCtrl.text.isEmpty) {
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nombre y DNI son obligatorios')));
                 return;
              }
              try {
                final nuevoCliente = await ClienteService().crearCliente({
                  'nombre': nombreCtrl.text, 
                  'dni': dniCtrl.text,
                  'telefono': telefonoCtrl.text.isEmpty ? null : telefonoCtrl.text,
                  'email': emailCtrl.text.isEmpty ? null : emailCtrl.text,
                });
                orderDetails.setCliente(nuevoCliente);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cliente registrado ✅')));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}
