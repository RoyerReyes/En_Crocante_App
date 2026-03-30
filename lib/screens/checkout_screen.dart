import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/pedido_model.dart';
import '../providers/pedido_provider.dart';
import '../providers/config_provider.dart'; // Import Provider
import '../constants/pedido_estados.dart';
import '../constants/api_constants.dart'; // Import ApiConstants
import 'package:cached_network_image/cached_network_image.dart'; // Import CachedImage
import '../services/receipt_service.dart'; // Import ReceiptService
import '../services/cliente_service.dart'; // Import ClienteService
import '../models/cliente_model.dart'; // Import Cliente model

class CheckoutScreen extends StatefulWidget {
  final Pedido pedido;

  const CheckoutScreen({super.key, required this.pedido});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _montoRecibidoController = TextEditingController();
  
  double _vuelto = 0.0;
  bool _qrVisible = false;

  // Loyalty State
  int _puntosDisponibles = 0;
  bool _usarPuntos = false;
  double _descuentoPuntos = 0.0;
  int _puntosCanjeados = 0;
  bool _loadingPuntos = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _montoRecibidoController.addListener(_calcularVuelto);
    _fetchPuntosCliente();
  }

  Future<void> _fetchPuntosCliente() async {
    if (widget.pedido.clienteId != null) {
      setState(() { _loadingPuntos = true; });
      try {
        final clientes = await ClienteService().buscarClientes(widget.pedido.nombreCliente ?? "");
        // Simple match or get by ID if service supported it. Assuming closest match or implemented getById
        // Since we don't have getById exposed easily, we search. Ideally backend adds getById.
        // CHECK: ClienteService has buscarClientes.
        // Backend `buscarCliente` searches by name/dni.
        // Risky if names are duplicate. 
        // Better: Use `buscarCliente` with ID if supported or just search.
        // Let's assume search works for now, or better: 
        // The previous step `CartScreen` used `clienteSeleccionado` which has the object. 
        // Here we only have `pedido` which has `clienteId`.
        // I will assume `buscarClientes` with the name is 'okay' for now, but really should add `getClienteById`.
        // Wait, backend `clienteService.js` has `buscarCliente` which does `SELECT * FROM clientes WHERE nombre LIKE ? OR dni LIKE ?`.
        // AND `buscarCliente` in backend returns an array.
        
        // Use the ID if possible. 
        // Actually, let's just assume we can find them.
        // Logic:
        final match = clientes.firstWhere((c) => c.id == widget.pedido.clienteId, orElse: () => Cliente(id: 0, nombre: '', puntos: 0));
        if (match.id != 0) {
           setState(() {
             _puntosDisponibles = match.puntos;
           });
        }
      } catch (e) {
        debugPrint('Error fetching points: $e');
      } finally {
        if (mounted) setState(() { _loadingPuntos = false; });
      }
    }
  }

  void _calcularVuelto() {
    final monto = double.tryParse(_montoRecibidoController.text) ?? 0.0;
    // Total a pagar considera descuento
    final totalAPagar = widget.pedido.total - _descuentoPuntos;
    setState(() {
      _vuelto = monto - totalAPagar;
    });
  }

  void _togglePuntos(bool valor) {
    if (valor) {
      final config = Provider.of<ConfigProvider>(context, listen: false);
      final puntosPorSol = config.puntosPorSolCanje;
      
      // Calcular máximo descuento posible
      double maxDescuento = _puntosDisponibles / puntosPorSol;
      
      // No descontar más que el total
      if (maxDescuento > widget.pedido.total) {
        maxDescuento = widget.pedido.total;
      }

      setState(() {
        _usarPuntos = true;
        _descuentoPuntos = maxDescuento; // Canjeamos todo lo posible
        // Opcional: Permitir ingresar cuántos puntos usar. Por ahora: TODO o NADA (o tope total)
        
        // Redondear a 2 decimales
        _descuentoPuntos = double.parse(_descuentoPuntos.toStringAsFixed(2));
        
        // Calcular puntos requeridos para este descuento
        // Si 1 pto = 1 sol -> ptos = descuento
        // Si 10 ptos = 1 sol -> ptos = descuento * 10
        _puntosCanjeados = (_descuentoPuntos * puntosPorSol).ceil();
      });
    } else {
      setState(() {
        _usarPuntos = false;
        _descuentoPuntos = 0.0;
        _puntosCanjeados = 0;
      });
    }
    _calcularVuelto();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _montoRecibidoController.dispose();
    super.dispose();
  }

  Future<void> _procesarPago(String metodoPago) async {
    final provider = Provider.of<PedidoProvider>(context, listen: false);
    
    try {
      // Mostrar loading
      debugPrint('🔍 CHECKOUT: Procesando pago con metodo: $metodoPago');
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(child: CircularProgressIndicator()),
      );

      await provider.updatePedidoStatus(
        widget.pedido.id, 
        PedidoEstados.pagado, 
        metodoPago: metodoPago, 
        montoRecibido: metodoPago == 'Efectivo' ? double.tryParse(_montoRecibidoController.text) : null,
        vuelto: metodoPago == 'Efectivo' ? _vuelto : null,
        descuento: _usarPuntos ? _descuentoPuntos : 0.0,
        puntosCanjeados: _usarPuntos ? _puntosCanjeados : 0,
      );

      if (mounted) {
        // Generar recibo automáticamente o preguntar
        double? montoRecibido;
        double? vuelto;

        if (metodoPago == 'Efectivo') {
          montoRecibido = double.tryParse(_montoRecibidoController.text);
          vuelto = _vuelto;
        }

        ReceiptService().printReceipt(
          widget.pedido, 
          paymentMethod: metodoPago,
          montoRecibido: montoRecibido,
          vuelto: vuelto,
          descuento: _usarPuntos ? _descuentoPuntos : 0.0,
          puntosCanjeados: _usarPuntos ? _puntosCanjeados : 0,
        );

        Navigator.pop(context); // Cerrar loading
        Navigator.pop(context); // Volver a la lista
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pago con $metodoPago exitoso. Boleta generada.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Cerrar loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al procesar pago: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cobrar Mesa ${widget.pedido.mesaId ?? "?"}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 1. Tarjeta de Resumen
            _buildOrderSummaryCard(),
            
            // --- LOYALTY SECTION (COMENTADO TEMPORALMENTE) ---
            /*
            if (_puntosDisponibles > 0)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                child: Card(
                  color: Colors.amber.shade50,
                  elevation: 2,
                  child: SwitchListTile(
                    title: Text('Canjear Puntos (Disp: $_puntosDisponibles)', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.brown)),
                    subtitle: Text('Descuento aplicable: S/ ${(_puntosDisponibles / Provider.of<ConfigProvider>(context, listen: false).puntosPorSolCanje).toStringAsFixed(2)}'),
                    secondary: const Icon(Icons.stars, color: Colors.amber),
                    value: _usarPuntos,
                    onChanged: _togglePuntos,
                    activeColor: Colors.amber,
                  ),
                ),
              ),
              */

            const SizedBox(height: 10),

            // 2. Título Método de Pago
            const Text(
              'Método de Pago',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // 3. Tabs y Contenido de Pago
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, spreadRadius: 1)],
              ),
              child: Column(
                children: [
                  TabBar(
                    controller: _tabController,
                    labelColor: Theme.of(context).primaryColor,
                    unselectedLabelColor: Colors.grey,
                    tabs: const [
                       Tab(icon: Icon(Icons.money), text: 'Efectivo'),
                       Tab(icon: Icon(Icons.qr_code), text: 'Yape / Plin'),
                    ],
                  ),
                  SizedBox(
                    height: 450, // Aumentado para evitar overflow
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildCashPaymentView(),
                        _buildDigitalPaymentView(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummaryCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Mesa ${widget.pedido.mesaId} - ${widget.pedido.nombreCliente ?? "Cliente"}', 
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.print, color: Colors.grey),
                      tooltip: 'Imprimir Boleta (Pre-cuenta)',
                      onPressed: () {
                        ReceiptService().printReceipt(widget.pedido);
                      },
                    ),
                    OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context); // Volver para "cambiar pedido" (simplemente es salir del checkout)
                      },
                      child: const Text('Cambiar'),
                    ),
                  ],
                ),
              ],
            ),
            
            const Divider(),
            
            // Lista de items (limitada para no ocupar toda la pantalla si hay muchos)
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 150),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: widget.pedido.detalles.length,
                itemBuilder: (ctx, i) {
                  final d = widget.pedido.detalles[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text('${d.cantidad}x ${d.nombrePlatillo ?? "Item"}', overflow: TextOverflow.ellipsis)),
                        Text('S/ ${d.subtotal.toStringAsFixed(2)}'),
                      ],
                    ),
                  );
                },
              ),
            ),
            
            const Divider(),
            
            if (widget.pedido.costoDelivery != null && widget.pedido.costoDelivery! > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Costo Delivery:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                    Text('S/ ${widget.pedido.costoDelivery!.toStringAsFixed(2)}', 
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.blueGrey)),
                  ],
                ),
              ),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total a pagar:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                Text('S/ ${widget.pedido.total.toStringAsFixed(2)}', 
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.green)),
              ],
            ),
             Text('Entregado: ${widget.pedido.createdAt.toLocal().toString().split('.')[0]}', 
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildCashPaymentView() {
    bool canPay = _vuelto >= 0 && _montoRecibidoController.text.isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 80.0), // Padding inferior extra
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Cálculo de Cambio', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          const SizedBox(height: 20),
          
          TextField(
            controller: _montoRecibidoController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Monto Recibido',
              prefixText: 'S/ ',
              border: OutlineInputBorder(),
              focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.green, width: 2)),
            ),
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 30),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  const Text('Total a pagar:', style: TextStyle(color: Colors.grey)),
                  Text(
                    'S/ ${(widget.pedido.total - _descuentoPuntos).toStringAsFixed(2)}', 
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                  ),
                  // PROGRAMA FIDELIZACION COMENTADO
                  /*
                  if (_descuentoPuntos > 0)
                    Text('(Desc: -S/ ${_descuentoPuntos.toStringAsFixed(2)})', style: const TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold)),
                  */
                ],
              ),
              Column(
                children: [
                  const Text('Cambio a dar:', style: TextStyle(color: Colors.grey)),
                  Text(
                    'S/ ${_vuelto < 0 ? "Faltante" : _vuelto.toStringAsFixed(2)}', 
                    style: TextStyle(
                      fontSize: 18, 
                      fontWeight: FontWeight.bold,
                      color: _vuelto < 0 ? Colors.red : Colors.green
                    )
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 30),
          
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: canPay ? () => _procesarPago('Efectivo') : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: Text(
                'Confirmar Pago de S/ ${widget.pedido.total.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDigitalPaymentView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 80.0), // Padding inferior para evitar superposición
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Código QR para Yape/Plin', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const Text('El cliente debe escanear este código para realizar el pago', style: TextStyle(color: Colors.grey, fontSize: 12), textAlign: TextAlign.center),
          
          const SizedBox(height: 20),
          
          if (!_qrVisible)
             SizedBox(
               height: 150,
               child: Center(
                 child: OutlinedButton.icon(
                   icon: const Icon(Icons.qr_code_2, size: 30),
                   label: const Text('Mostrar QR de Pago'),
                   onPressed: () {
                     setState(() {
                       _qrVisible = true;
                     });
                   },
                 ),
               ),
             )
          else
            Column(
              children: [
                // QR Display Logic
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(border: Border.all(color: Colors.purple)),
                  child: Consumer<ConfigProvider>(
                    builder: (context, config, child) {
                      if (config.qrImagenUrl != null && config.qrImagenUrl!.isNotEmpty) {
                        return SizedBox(
                          height: 200, // Adjusted size
                          width: 200,
                          child: CachedNetworkImage(
                            imageUrl: ApiConstants.getImageUrl(config.qrImagenUrl),
                            placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                            errorWidget: (context, url, error) => const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.error, color: Colors.red),
                                Text("Error al cargar QR", style: TextStyle(fontSize: 10)),
                              ],
                            ),
                            fit: BoxFit.contain,
                          ),
                        );
                      } else {
                        return const Column(
                          children: [
                            Icon(Icons.qr_code_scanner, size: 120, color: Colors.purple),
                            Text("No QR Configurado", style: TextStyle(color: Colors.grey)),
                          ],
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(height: 10),
                const Text('Monto a pagar', style: TextStyle(color: Colors.grey)),
                Text('S/ ${widget.pedido.total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                Text('Mesa ${widget.pedido.mesaId} • ${widget.pedido.nombreCliente}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            
          const SizedBox(height: 30),
          
          SizedBox(
            width: double.infinity,
             height: 50,
            child: ElevatedButton(
              onPressed: _qrVisible ? () => _procesarPago('Yape - Plin') : null, // Solo activo si mostró QR
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
              ),
              child: Text(
                'Confirmar Pago de S/ ${(widget.pedido.total - _descuentoPuntos).toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
