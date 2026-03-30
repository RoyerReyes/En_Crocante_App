import 'dart:async';

import 'package:encrocante_app/providers/cart_provider.dart';
import 'package:encrocante_app/providers/pedido_provider.dart';
import 'package:encrocante_app/providers/config_provider.dart'; // Added
import 'package:encrocante_app/screens/cart_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/platillo_model.dart';
import '../services/auth_service.dart';
import '../services/platillo_service.dart';
import '../widgets/order_details_widget.dart'; // Add this
import '../providers/order_details_provider.dart'; // ADDED: Missing import
import '../providers/salsa_provider.dart'; // Import Added
import '../providers/presa_provider.dart'; // ADDED
import 'login_screen.dart';
import 'pedidos_list_screen.dart';
import '../widgets/dish_avatar.dart'; // Added

class PlatillosPage extends StatefulWidget {
  final String userRole;
  final String userName;

  const PlatillosPage({super.key, required this.userRole, required this.userName});

  @override
  State<PlatillosPage> createState() => _PlatillosPageState();
}

class _PlatillosPageState extends State<PlatillosPage> with SingleTickerProviderStateMixin {
  final PlatilloService _platilloService = PlatilloService();
  final AuthService _authService = AuthService();
  late Future<List<Platillo>> _platillosFuture;
  late TabController _tabController;
  Timer? _debounceTimer;

  String? _mozoResponsable; // New field

  final TextEditingController _searchController = TextEditingController();
  String _filtroSeleccionado = 'Todos';
  List<Platillo> _platillosOriginales = [];
  List<Platillo> _platillosFiltrados = [];

  @override
  void initState() {
    super.initState();
    final pedidoProvider = Provider.of<PedidoProvider>(context, listen: false);
    // Inicializar socket centralizado en el provider
    pedidoProvider.initSocket();
    
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
    _loadMozoResponsable(); // Call this here
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SalsaProvider>(context, listen: false).fetchSalsas();
      Provider.of<PresaProvider>(context, listen: false).fetchPresas();
    });
  }
  
  // Method removed as it is now centralized

  Future<void> _loadData() {
    _platillosFuture = _platilloService.getPlatillos();
    return _platillosFuture.then((platillos) {
      if (mounted) {
        setState(() {
          _platillosOriginales = platillos;
          _filterPlatillos();
        });
      }
    });
  }

  void _onSearchChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        _filterPlatillos();
      }
    });
  }
  
  void _onFilterSelected(String filtro) {
    setState(() {
      _filtroSeleccionado = filtro;
    });
    _filterPlatillos();
  }

  void _filterPlatillos() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _platillosFiltrados = _platillosOriginales.where((platillo) {
        final matchNombre = platillo.nombre.toLowerCase().contains(query);
        final matchCategoria = _filtroSeleccionado == 'Todos' || platillo.categoria.nombre == _filtroSeleccionado;
        return matchNombre && matchCategoria;
      }).toList();
    });
  }

  Future<void> _loadMozoResponsable() async { // New method
    final userName = await _authService.getLoggedInUserName();
    setState(() {
      _mozoResponsable = userName;
    });
  }

  @override
  void dispose() {

    _tabController.dispose();
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshPlatillos() async {
    _searchController.clear();
    setState(() { _filtroSeleccionado = 'Todos'; });
    await _loadData();
  }

  void _logout() async {
    await _authService.logout();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (Route<dynamic> route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 4.0,
        leading: IconButton(
          icon: const Icon(Icons.logout),
          tooltip: 'Cerrar Sesión',
          onPressed: _logout,
        ),
        title: Consumer<OrderDetailsProvider>( // Wrap with Consumer to listen to changes
          builder: (context, orderDetails, child) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Mesa: ${orderDetails.numeroMesa}"), // Display numeroMesa from provider
                Text(widget.userName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal)), // Mozo Responsable
              ],
            );
          },
        ),
        actions: [
          Consumer<PedidoProvider>(
            builder: (context, pedidoProvider, child) {
              // Filter by status 'listo' OR 'en_preparacion' with ready items AND current waiter
              final readyCount = pedidoProvider.pedidosActivos.where((p) {
                 if (p.nombreMesero != widget.userName) return false;
                 if (p.estado == 'listo') return true;
                 if (p.estado == 'en_preparacion') {
                    // Count if ANY item is ready
                    return p.detalles.any((d) => d.listo);
                 }
                 return false;
              }).length;
                  
              return Badge(
                label: Text(readyCount.toString()),
                isLabelVisible: readyCount > 0,
                backgroundColor: Colors.green, // Green for Ready
                child: IconButton(
                  icon: const Icon(Icons.receipt_long), 
                  tooltip: 'Ver Mis Pedidos (Activos: $readyCount)', 
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const PedidosListScreen()),
                    );
                  }
                ),
              );
            },
          ),
          // --- CORRECCIÓN AQUÍ ---
          // El Consumer debe ser de tipo CartProvider para que funcione el carrito.
          Consumer<CartProvider>(
            builder: (context, cart, child) => Badge(
              label: Text(cart.itemCount.toString()),
              isLabelVisible: cart.itemCount > 0,
              child: IconButton(
                icon: const Icon(Icons.shopping_cart),
                tooltip: 'Ver Carrito',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const CartScreen()),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.restaurant_menu), text: 'Menú'),
            Tab(icon: Icon(Icons.person), text: 'Cliente'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMenuTab(),
          _buildClienteTab(),
        ],
      ),
      floatingActionButton: widget.userRole == 'admin'
          ? FloatingActionButton(onPressed: () {}, child: const Icon(Icons.add))
          : null,
    );
  }

  Widget _buildMenuTab() {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    return RefreshIndicator(
      onRefresh: _refreshPlatillos,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar platillos...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(25.0)),
                filled: true,
                fillColor: Colors.grey[200],
              ),
              onChanged: (value) => _onSearchChanged(),
            ),
          ),
          _buildFilterChips(),
          const Divider(height: 1),
          Expanded(
            child: FutureBuilder<List<Platillo>>(
              future: _platillosFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error:\n${snapshot.error}', textAlign: TextAlign.center));
                }
                if (_platillosFiltrados.isEmpty) {
                  return const Center(child: Text("No se encontraron platillos."));
                }
                return ListView.builder(
                  itemCount: _platillosFiltrados.length,
                  itemBuilder: (context, index) {
                    final platillo = _platillosFiltrados[index];
                    return ListTile(
                      leading: Hero(
                        tag: 'platillo_${platillo.id}',
                        child: DishAvatar(
                          imageUrl: platillo.imagenUrl,
                          radius: 30,
                        ),
                      ),
                      title: Text(platillo.nombre),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(platillo.descripcion ?? ''),
                          const SizedBox(height: 4),
                          Text(
                            'S/${platillo.precio.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                        ],
                      ),
                      trailing: Consumer<CartProvider>(
                        builder: (context, cart, child) {
                          if (platillo.categoria.nombre.toLowerCase().contains('descartable')) {
                            int currentQty = cart.itemsList.where((i) => i.platillo.id == platillo.id && (i.notas == null || i.notas!.isEmpty)).length;
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (currentQty > 0)
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline, color: Colors.deepOrange),
                                    onPressed: () => cart.removeSingleItem(platillo.id),
                                  ),
                                if (currentQty > 0)
                                  Text(currentQty.toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                IconButton(
                                  icon: const Icon(Icons.add_circle, color: Colors.deepOrange, size: 30),
                                  onPressed: () => _addToCart(platillo),
                                ),
                              ],
                            );
                          }
                          
                          return IconButton(
                            icon: const Icon(Icons.add_shopping_cart, color: Colors.deepOrange, size: 30),
                            onPressed: () => _addToCart(platillo),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    if (_platillosOriginales.isEmpty) { return const SizedBox.shrink(); }
    final categorias = _platillosOriginales.map((p) => p.categoria.nombre).toSet().toList();
    final filtros = ['Todos', ...categorias]; 

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: Row(
        children: filtros.map((filtro) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: FilterChip(
              label: Text(filtro),
              selected: _filtroSeleccionado == filtro,
              onSelected: (selected) { if (selected) { _onFilterSelected(filtro); } },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildClienteTab() {
    return OrderDetailsWidget(
      mozoResponsable: _mozoResponsable ?? 'Mozo Desconocido',
    );
  }

  void _addToCart(Platillo platillo) {
    String lowerCategory = platillo.categoria.nombre.toLowerCase();
    if (lowerCategory.contains('alitas') || lowerCategory.contains('combo')) {
      _showSalsasDialog(platillo);
    } else if (lowerCategory.contains('broaster') || lowerCategory.contains('mostrito')) {
      _showPresasDialog(platillo);
    } else {
      Provider.of<CartProvider>(context, listen: false).addItem(platillo);
      if (!lowerCategory.contains('descartable')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${platillo.nombre} añadido al carrito.'), duration: const Duration(seconds: 1)),
        );
      }
    }
  }

  void _showSalsasDialog(Platillo platillo) {
    final salsaProvider = Provider.of<SalsaProvider>(context, listen: false);
    final salsasActivas = salsaProvider.salsas.where((s) => s.activo).toList();
    
    if (salsasActivas.isEmpty) {
      // Si no hay salsas configuradas o todas inactivas, agregar directo
      Provider.of<CartProvider>(context, listen: false).addItem(platillo);
      return;
    }

    Set<String> salsasSeleccionadas = {};

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Elige las Salsas para ${platillo.nombre}'),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: salsasActivas.length,
                  itemBuilder: (context, index) {
                    final salsa = salsasActivas[index];
                    final isSelected = salsasSeleccionadas.contains(salsa.nombre);
                    return CheckboxListTile(
                      title: Text(salsa.nombre),
                      activeColor: Colors.orange,
                      value: isSelected,
                      onChanged: (bool? val) {
                        setDialogState(() {
                          if (val == true) {
                            salsasSeleccionadas.add(salsa.nombre);
                          } else {
                            salsasSeleccionadas.remove(salsa.nombre);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () {
                    String notas = salsasSeleccionadas.isNotEmpty 
                      ? 'SALSAS ELEGIDAS: ${salsasSeleccionadas.join(", ")}'
                      : 'SALSAS ELEGIDAS: Ninguna';
                    
                    Provider.of<CartProvider>(context, listen: false).addItem(platillo, notas: notas);
                    Navigator.pop(context);
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${platillo.nombre} añadido al carrito.'), duration: const Duration(seconds: 1)),
                    );
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                  child: const Text('Confirmar', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          }
        );
      }
    );
  }

  void _showPresasDialog(Platillo platillo) {
    final presaProvider = Provider.of<PresaProvider>(context, listen: false);
    final presasActivas = presaProvider.presas.where((p) => p.activo).toList();
    
    if (presasActivas.isEmpty) {
      Provider.of<CartProvider>(context, listen: false).addItem(platillo);
      return;
    }

    final Map<int, bool> seleccionadas = { for (var p in presasActivas) p.id : false };

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Elige tu Presa - ${platillo.nombre}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: presasActivas.map((presa) {
                    return CheckboxListTile(
                      title: Text(presa.nombre),
                      value: seleccionadas[presa.id],
                      activeColor: Colors.deepOrange,
                      onChanged: (bool? val) {
                        setState(() { seleccionadas[presa.id] = val ?? false; });
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context), 
                  child: const Text('Cancelar')
                ),
                ElevatedButton(
                  onPressed: () {
                    final elegidasNombres = presasActivas
                        .where((p) => seleccionadas[p.id] == true)
                        .map((p) => p.nombre)
                        .toList();
                        
                    String notasAnadidas = elegidasNombres.isNotEmpty 
                        ? 'Con: ${elegidasNombres.join(', ')}' 
                        : 'Sin elección de presa';

                    Provider.of<CartProvider>(context, listen: false).addItem(platillo, notas: notasAnadidas);
                    Navigator.pop(context);
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${platillo.nombre} añadido al carrito.'), duration: const Duration(seconds: 1)),
                    );
                  },
                  child: const Text('Añadir al Carrito'),
                )
              ],
            );
          }
        );
      },
    );
  }
}
