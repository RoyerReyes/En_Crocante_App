import 'package:flutter/material.dart';
import '../models/platillo_model.dart';
import '../services/auth_service.dart';
import '../services/platillo_service.dart';
import 'login_screen.dart';

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

  final TextEditingController _searchController = TextEditingController();
  String _filtroSeleccionado = 'Todos';
  List<Platillo> _platillosOriginales = [];
  List<Platillo> _platillosFiltrados = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
    _searchController.addListener(_onSearchChanged);
  }

  Future<void> _loadData() {
    _platillosFuture = _platilloService.getPlatillos();
    return _platillosFuture.then((platillos) {
      if (mounted) {
        setState(() {
          _platillosOriginales = platillos;
          _filterPlatillos(); // Aplicar filtros iniciales
        });
      }
    });
  }

  void _onSearchChanged() {
    _filterPlatillos();
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

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshPlatillos() async {
    _searchController.clear();
    setState(() {
      _filtroSeleccionado = 'Todos';
    });
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Mesa"),
            Text(widget.userName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal)),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.receipt_long), tooltip: 'Ver Pedidos', onPressed: () {}),
          IconButton(icon: const Icon(Icons.shopping_cart), tooltip: 'Ver Carrito', onPressed: () {}),
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
                      leading: CircleAvatar(
                        radius: 30,
                        backgroundImage: (platillo.imagenUrl != null && platillo.imagenUrl!.isNotEmpty)
                            ? NetworkImage(platillo.imagenUrl!)
                            : null,
                        child: (platillo.imagenUrl == null || platillo.imagenUrl!.isEmpty)
                            ? const Icon(Icons.restaurant, color: Colors.white)
                            : null,
                      ),
                      title: Text(platillo.nombre),
                      // CORRECCIÓN: Usar ?? '' para mostrar un texto vacío si la descripción es nula.
                      subtitle: Text(platillo.descripcion ?? ''),
                      trailing: Text('\$${platillo.precio.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
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
    if (_platillosOriginales.isEmpty) {
      return const SizedBox.shrink(); 
    }
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
              onSelected: (bool selected) {
                if (selected) {
                  _onFilterSelected(filtro);
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildClienteTab() {
    return const Center(
      child: Text('Información del Cliente', style: TextStyle(fontSize: 18)),
    );
  }
}
