import 'package:encrocante_app/screens/login_screen.dart';
import 'package:encrocante_app/services/auth_service.dart';
import 'package:encrocante_app/widgets/kitchen_order_ticket.dart';
import 'package:encrocante_app/widgets/kitchen_stat_card.dart'; // Import Added
import 'package:encrocante_app/widgets/kitchen_state_row.dart'; // Import Added
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/pedido_model.dart'; // Import Added
import '../providers/pedido_provider.dart';
import '../constants/pedido_estados.dart'; // Importar constantes
import '../services/secure_storage_service.dart'; // Importar SecureStorageService
import '../providers/salsa_provider.dart'; // Import Added
import '../providers/presa_provider.dart'; // Import Added

class KitchenScreen extends StatefulWidget {
  const KitchenScreen({super.key});

  @override
  State<KitchenScreen> createState() => _KitchenScreenState();
}

class _KitchenScreenState extends State<KitchenScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedFilter = 'Todos los pedidos'; // Estado para el filtro
  String? _userRole; // Almacenar el rol del usuario

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _checkUserRole(); // Verificar rol al inicio

    // Usamos addPostFrameCallback para asegurarnos de que el context está disponible.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pedidoProvider =
          Provider.of<PedidoProvider>(context, listen: false);

      // 1. Cargar los datos iniciales
      pedidoProvider.cargarPedidosIniciales();

      // 2. Configurar y conectar el socket centralizado
      pedidoProvider.initSocket();

      // 3. Cargar salsas
      Provider.of<SalsaProvider>(context, listen: false).fetchSalsas();
    });
  }

  Future<void> _checkUserRole() async {
    final SecureStorageService storage = SecureStorageService();
    final role = await storage.getUserRole();
    setState(() {
      _userRole = role;
    });
    
    if (role != 'admin' && role != 'cocinero' && role != 'cocina') {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ Modo solo lectura: No tienes permisos de cocina.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    // Desconectar el socket y el controller
    // _socketService.disconnect(); // Ya gestionado por PedidoProvider
    _tabController.dispose();
    super.dispose();
  }

  // Método para manejar el cierre de sesión
  Future<void> _logout(BuildContext context) async {
    final AuthService authService = AuthService();
    await authService.logout();
    // Navega a la pantalla de login y remueve todas las rutas anteriores
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (Route<dynamic> route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Envuelve el Scaffold con el Consumer para que toda la UI pueda reaccionar a los cambios.
    return Consumer<PedidoProvider>(
      builder: (context, pedidoProvider, child) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 1,
            leading: IconButton(
              icon: const Icon(Icons.logout, color: Colors.black87),
              onPressed: () => _logout(context),
              tooltip: 'Cerrar Sesión',
            ),
            title: null,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.black87),
                onPressed: () {
                  pedidoProvider.cargarPedidosIniciales();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Actualizando pedidos...')),
                  );
                },
                tooltip: 'Actualizar',
              ),
              _buildCounterColumn('Pendientes', pedidoProvider.pedidos.where((p) => p.estado == PedidoEstados.recibido || p.estado == PedidoEstados.pendiente).length, Colors.orange.shade700),
              _buildCounterColumn('En curso', pedidoProvider.pedidos.where((p) => p.estado == PedidoEstados.enPreparacion).length, Colors.blue.shade700),
              _buildCounterColumn('Listos', pedidoProvider.pedidos.where((p) => p.estado == PedidoEstados.listo).length, Colors.green.shade700),
              const SizedBox(width: 16),
            ],
            bottom: TabBar(
              controller: _tabController,
              labelColor: Colors.black87,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.orange.shade700,
              tabs: const [
                Tab(text: 'Pedidos'),
                Tab(text: 'Stats'),
                Tab(text: 'Insumos'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              // Pestaña de Pedidos
              _buildPedidosView(pedidoProvider),
              // Pestaña de Stats
              _buildStatsView(pedidoProvider),
              // Pestaña de Insumos
              _buildInsumosView(),
            ],
          ),
        );
      },
    );
  }

  // Widget para la vista de la pestaña 'Stats'
  Widget _buildStatsView(PedidoProvider pedidoProvider) {
    // Definir "Hoy" estrictamente (inicio y fin del día)
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    // Filtrar pedidos de HOY
    final pedidosHoy = pedidoProvider.pedidos.where((p) {
      return p.createdAt.isAfter(startOfDay) && p.createdAt.isBefore(endOfDay);
    }).toList();

    // Stats Básicos
    final int pendientes = pedidoProvider.pedidos.where((p) => p.estado == PedidoEstados.recibido || p.estado == PedidoEstados.pendiente).length;
    final int enPreparacion = pedidoProvider.pedidos.where((p) => p.estado == PedidoEstados.enPreparacion).length;
    // Completados Hoy = Listos + Entregados + Pagados
    final int completadosHoy = pedidosHoy.where((p) => 
        p.estado == PedidoEstados.listo || 
        p.estado == PedidoEstados.entregado || 
        p.estado == PedidoEstados.pagado
    ).length;
    
    // Calculamos Pedidos Cancelados Hoy
    final int canceladosHoy = pedidosHoy.where((p) => p.estado == PedidoEstados.cancelado).length;

    // Calculamos Mesas en Atención (Mesas únicas con pedidos activos)
    final int mesasEnAtencion = pedidoProvider.pedidosActivos.map((p) => p.mesaId).toSet().length;

    // Cálculos para "Eficiencia del día"
    final int totalPedidosHoy = pedidosHoy.length;
    final int totalPedidosCompletadosHoy = completadosHoy; // Usamos variable ya calculada
    
    // Promedio de platos por pedido (para medir carga de trabajo)
    double promedioPlatosPorPedido = 0.0;
    if (totalPedidosHoy > 0) {
      int totalPlatosHoy = pedidosHoy.fold(0, (sum, p) => sum + p.detalles.fold(0, (s, d) => s + d.cantidad));
      promedioPlatosPorPedido = totalPlatosHoy / totalPedidosHoy;
    }

    // Demorados (> 30 mins) - Solo de los activos
    final int demorados = pedidoProvider.pedidosActivos.where((p) => 
        DateTime.now().difference(p.createdAt).inMinutes > 30
    ).length;


    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 80.0), // Extra bottom padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                KitchenStatCard(title: 'Pendientes', counter: '$pendientes', subtitle: 'por iniciar', color: Colors.orange.shade700),
                KitchenStatCard(title: 'En Preparación', counter: '$enPreparacion', subtitle: 'pedidos en curso', color: Colors.blue.shade700),
                KitchenStatCard(title: 'Completados Hoy', counter: '$completadosHoy', subtitle: 'listos/entregados', color: Colors.green.shade700),
                KitchenStatCard(title: 'Mesas en Atención', counter: '$mesasEnAtencion', subtitle: 'mesas esperando', color: Colors.purple.shade700),
              ],
            ),
            const SizedBox(height: 24),
            
            // Tarjeta de Eficiencia del Día (Rediseñada)
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Resumen del Día',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    KitchenStateRow(title: 'Pedidos Totales (Hoy)', value: '$totalPedidosHoy', color: Colors.black87),
                    KitchenStateRow(title: 'Pedidos Cancelados', value: '$canceladosHoy', color: Colors.red.shade700),
                    KitchenStateRow(title: 'Promedio Platos/Pedido', value: promedioPlatosPorPedido.toStringAsFixed(1), color: Colors.orange.shade700),
                    if (totalPedidosHoy > 0) ...[
                      const Divider(height: 24),
                       KitchenStateRow(
                        title: '% Completado', 
                        value: '${((totalPedidosCompletadosHoy / totalPedidosHoy) * 100).toStringAsFixed(0)}%', 
                        color: Colors.blue.shade700, 
                        isTotal: true
                      ),
                    ]
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }



  // Widget para la vista de la pestaña 'Pedidos'
  Widget _buildPedidosView(PedidoProvider pedidoProvider) {
    // 1. Filtrar pedidos según la selección
    List<Pedido> filteredPedidos;
    
    // Contadores para los chips
    final int countPendientes = pedidoProvider.pedidos.where((p) => p.estado == PedidoEstados.recibido || p.estado == PedidoEstados.pendiente).length;
    final int countPreparando = pedidoProvider.pedidos.where((p) => p.estado == PedidoEstados.enPreparacion).length;
    final int countListos = pedidoProvider.pedidos.where((p) => p.estado == PedidoEstados.listo).length;

    switch (_selectedFilter) {
      case 'Pendientes':
        // Usamos pedidosCocina para mantener el orden FIFO
        filteredPedidos = pedidoProvider.pedidosCocina.where((p) => p.estado == PedidoEstados.recibido || p.estado == PedidoEstados.pendiente).toList();
        break;
      case 'Preparando':
        filteredPedidos = pedidoProvider.pedidosCocina.where((p) => p.estado == PedidoEstados.enPreparacion).toList();
        break;
      case 'Listos':
        filteredPedidos = pedidoProvider.pedidos.where((p) => p.estado == PedidoEstados.listo).toList(); // Listos quizás no importa tanto el FIFO
        break;
      default: // 'Todos los pedidos'
        filteredPedidos = pedidoProvider.pedidosCocina;
        break;
    }

    // Definición de los filtros y sus etiquetas dinámicas
    final Map<String, String> filters = {
      'Todos los pedidos': 'Todos',
      'Pendientes': 'Pendientes ($countPendientes)',
      'Preparando': 'Preparando ($countPreparando)',
      'Listos': 'Listos ($countListos)',
    };

    return Column(
      children: [
        // Barra de filtro con ChoiceChips
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: filters.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: ChoiceChip(
                    label: Text(entry.value),
                    selected: _selectedFilter == entry.key,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedFilter = entry.key;
                        });
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        // Contenido principal
        Expanded(
          child: filteredPedidos.isEmpty
              ? _buildNoOrdersPlaceholder()
              : LayoutBuilder(
                  builder: (context, constraints) {
                    // Responsive: 1 columna si es estrecho (celular), 2 si es ancho (tablet/landscape)
                    final int crossAxisCount = constraints.maxWidth > 600 ? 2 : 1;
                    return GridView.builder(
                      padding: const EdgeInsets.only(
                        left: 8.0, 
                        top: 8.0, 
                        right: 8.0, 
                        bottom: 80.0 // Extra padding for system bars
                      ),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        childAspectRatio: 0.85,
                        crossAxisSpacing: 8.0,
                        mainAxisSpacing: 8.0,
                      ),
                      itemCount: filteredPedidos.length,
                      itemBuilder: (context, index) {
                        return KitchenOrderTicket(
                          pedido: filteredPedidos[index],
                          userRole: _userRole, // Pasar rol
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  // Widget para mostrar cuando no hay pedidos
  Widget _buildNoOrdersPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.soup_kitchen_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          const Text(
            'No hay pedidos',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Los pedidos aparecerán aquí',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  // Widget para contadores verticales en la AppBar
  Widget _buildCounterColumn(String label, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            count.toString(),
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsumosView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 80.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Sección Salsas
          Container(
            color: Colors.grey.shade200,
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: const Text('Disponibilidad de Salsas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          Consumer<SalsaProvider>(
            builder: (context, salsaProvider, child) {
              if (salsaProvider.isLoading) return const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()));
              if (salsaProvider.salsas.isEmpty) return const Padding(padding: EdgeInsets.all(16.0), child: Text("No se encontraron salsas."));
              
              return ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: salsaProvider.salsas.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = salsaProvider.salsas[index];
                  return SwitchListTile(
                    title: Text(item.nombre, style: const TextStyle(fontWeight: FontWeight.w500)),
                    value: item.activo,
                    activeColor: Colors.green,
                    onChanged: (val) async {
                       await salsaProvider.toggleSalsa(item.id, val);
                    },
                  );
                },
              );
            },
          ),
          
          // Sección Presas
          Container(
            color: Colors.grey.shade200,
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: const Text('Disponibilidad de Presas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          Consumer<PresaProvider>(
            builder: (context, presaProvider, child) {
              if (presaProvider.isLoading) return const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()));
              if (presaProvider.presas.isEmpty) return const Padding(padding: EdgeInsets.all(16.0), child: Text("No se encontraron presas."));
              
              return ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: presaProvider.presas.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = presaProvider.presas[index];
                  return SwitchListTile(
                    title: Text(item.nombre, style: const TextStyle(fontWeight: FontWeight.w500)),
                    value: item.activo,
                    activeColor: Colors.green,
                    onChanged: (val) async {
                       await presaProvider.togglePresa(item.id, val);
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
