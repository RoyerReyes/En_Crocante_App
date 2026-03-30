import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:encrocante_app/providers/config_provider.dart';
import 'package:encrocante_app/providers/pedido_provider.dart';
import 'package:encrocante_app/services/auth_service.dart';
import 'package:encrocante_app/screens/login_screen.dart';
import 'package:encrocante_app/widgets/user_management_tab.dart';
import 'package:encrocante_app/models/pedido_model.dart';
import 'package:encrocante_app/constants/pedido_estados.dart';
import 'package:encrocante_app/screens/reports_screen.dart';
import 'package:encrocante_app/providers/theme_provider.dart';
import 'package:encrocante_app/services/notification_service.dart'; // Import Added
import 'package:encrocante_app/screens/admin_platillo_management_screen.dart'; // Import Added
import 'package:encrocante_app/widgets/admin_insumos_tab.dart'; // ADDED
import 'package:image_picker/image_picker.dart'; // Import Added
import 'dart:io'; // Import Added
import 'package:encrocante_app/constants/api_constants.dart'; // Import Added for Image URL construction
import 'package:cached_network_image/cached_network_image.dart'; // Import Added

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late TextEditingController _nameController;
  late TextEditingController _tablesController;
  late TextEditingController _currencyController;
  final TextEditingController _broadcastMessageController = TextEditingController();
  final TextEditingController _broadcastTitleController = TextEditingController(text: 'Anuncio');
  
  // Local state for notifications removed in favor of ConfigProvider


  @override
  void initState() {
    super.initState();
    // Creamos 6 pestañas
    _tabController = TabController(length: 6, vsync: this);
    
    // Initialize controllers with current values
    final config = Provider.of<ConfigProvider>(context, listen: false);
    _nameController = TextEditingController(text: config.nombreRestaurante);
    _tablesController = TextEditingController(text: config.numeroMesas.toString());
    _currencyController = TextEditingController(text: config.moneda);

    // Setup Notification Listener
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pedidoProvider = Provider.of<PedidoProvider>(context, listen: false);
      // Ensure socket is initialized for Admin to receive updates
      pedidoProvider.initSocket();
      
      pedidoProvider.notificationStream.listen((message) {
        if (!mounted) return;
        final currentConfig = Provider.of<ConfigProvider>(context, listen: false);

        // Filter based on message content & config
        // Simple heuristic: if message contains "LISTO", check notifPedidoListo
        bool shouldShow = true;
        if (message.contains("LISTO") && !currentConfig.notifPedidoListo) {
           shouldShow = false;
        }
        if (message.contains("Tiempo de espera") && !currentConfig.notifTiempoEspera) {
           shouldShow = false;
        }
        if (message.contains("Stock") && !currentConfig.notifStockBajo) {
           shouldShow = false;
        }

        if (shouldShow) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
              action: SnackBarAction(label: 'Ver', onPressed: () {
                // Navigate to Reports or relevant tab if needed
              }),
            ),
          );
        }
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _tablesController.dispose();
    _currencyController.dispose();
    _broadcastMessageController.dispose();
    _broadcastTitleController.dispose();
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Administrador'),
        automaticallyImplyLeading: false, // Oculta el botón de regreso
        actions: [
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return IconButton(
                icon: Icon(themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode),
                onPressed: () {
                  themeProvider.toggleTheme(!themeProvider.isDarkMode);
                },
                tooltip: 'Cambiar Tema',
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout), // Icono de logout
            onPressed: () => _logout(context), // Llama al método de logout
            tooltip: 'Cerrar Sesión',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true, // Permite scroll si las pestañas no caben
          tabs: const [
            Tab(icon: Icon(Icons.settings), text: 'General'),
            Tab(icon: Icon(Icons.notifications), text: 'Notificaciones'),
            Tab(icon: Icon(Icons.bar_chart), text: 'Reportes'),
            Tab(icon: Icon(Icons.people), text: 'Personal'),
            Tab(icon: Icon(Icons.restaurant_menu), text: 'Menú'), // New Tab
            Tab(icon: Icon(Icons.fastfood), text: 'Insumos'), // ADDED
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Vista para la pestaña General
          _buildGeneralTab(context),
          
          // Vista para la pestaña Notificaciones
          _buildNotificationsTab(context),
          
          // Vista para la pestaña Reportes
          _buildReportsTab(context),
          
          // Vista para la pestaña Personal (reutilizada)
          const UserManagementTab(),
          
          // Vista para CRUD Platillos
          const AdminPlatilloManagementScreen(),
          
          // Vista para CRUD Insumos
          const AdminInsumosTab(),
        ],
      ),
    );
  }

  // Widget para la pestaña Notificaciones
  Widget _buildNotificationsTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 80.0), // Padding inferior para evitar superposición
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Configuración de Notificaciones',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Personaliza qué notificaciones quieres recibir.',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 24),

                  Consumer<ConfigProvider>(
                    builder: (context, config, child) {
                      return Column(
                        children: [
                          _buildNotificationToggle(
                            'Pedido listo',
                            'Notificar cuando un pedido esté listo para servir',
                            config.notifPedidoListo,
                            (bool value) => config.setNotifPedidoListo(value),
                          ),
                          const Divider(),
                          _buildNotificationToggle(
                            'Tiempo de espera prolongado',
                            'Alerta cuando un pedido exceda el tiempo estimado',
                            config.notifTiempoEspera,
                            (bool value) => config.setNotifTiempoEspera(value),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const SizedBox(height: 24),
          _buildBroadcastCard(), // New Broadcast Card
          const SizedBox(height: 24),
          _buildSoundConfigCard(), // New Sound Config Card
          // Configuración se guarda automáticamente
        ],

      ),
    );
  }

  // Helper para construir los toggles de notificación
  Widget _buildNotificationToggle(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Theme.of(context).primaryColor,
          ),
        ],
      ),
    );
  }

  // Widget para la vista de la pestaña General
  Widget _buildGeneralTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 80.0), // Padding inferior para evitar superposición
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildConfigCard(context),
          const SizedBox(height: 24),
          _buildQrConfigCard(context), // New QR Config Card
          const SizedBox(height: 24),
          _buildSystemStatsCard(),
        ],
      ),
    );
  }

  Widget _buildConfigCard(BuildContext context) {
    final config = Provider.of<ConfigProvider>(context, listen: false);
    
    // Controllers initialized in initState

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Información del Restaurante',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () {
                     // Guardar cambios manualmente
                     config.setNombreRestaurante(_nameController.text);
                     config.setNumeroMesas(int.tryParse(_tablesController.text) ?? 25);
                     config.setMoneda(_currencyController.text);
                     
                     ScaffoldMessenger.of(context).showSnackBar(
                       const SnackBar(content: Text('Configuración guardada correctamente.'), backgroundColor: Colors.green)
                     );
                  },
                  icon: const Icon(Icons.save),
                  label: const Text("Guardar"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                )
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Edita y guarda los datos de tu negocio.',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            
            _buildConfigField(
              'Nombre del Restaurante:',
              _nameController,
            ),
            const SizedBox(height: 16),
            
            _buildConfigField(
              'Número de Mesas:',
              _tablesController,
            ),
            const SizedBox(height: 16),
            
            _buildConfigField(
              'Moneda:',
              _currencyController,
            ),
            const SizedBox(height: 16),
            
            // Campo de solo lectura (sin controller)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Zona Horaria:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: 'America/Peru/Lima',
                  readOnly: true,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    filled: true,
                    fillColor: Colors.black12
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemStatsCard() {
    final ReportService _reportService = ReportService();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Estadísticas del Sistema',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            FutureBuilder<Map<String, dynamic>>(
              future: _reportService.getSystemStats(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                final stats = snapshot.data ?? {};
                
                return Column(
                  children: [
                    _buildStatRow(
                      'Tiempo de actividad',
                      stats['tiempo_actividad'] ?? 'Online',
                      'Estado del servidor',
                    ),
                    const SizedBox(height: 16),
                    _buildStatRow(
                      'Órdenes Totales',
                      (stats['total_ordenes'] ?? 0).toString(),
                      'Desde el inicio',
                    ),
                    const SizedBox(height: 16),
                    _buildStatRow(
                      'Eficiencia',
                      stats['rendimiento'] ?? '100%',
                      'Pedidos completados vs Totales',
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Widget auxiliar para campos de texto de configuración
  Widget _buildConfigField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          style: const TextStyle(fontSize: 16),
        ),
      ],
    );
  }

  // Widget para la pestaña Reportes
  Widget _buildReportsTab(BuildContext context) {
    return const ReportsTab();
  }
  // Widget auxiliar para las filas de estadísticas
  Widget _buildStatRow(String label, String value, String subtitle) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
            Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600))
          ],
        ),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }

  // Widget para Configuración de QR
  Widget _buildQrConfigCard(BuildContext context) {
    final config = Provider.of<ConfigProvider>(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'QR de Pagos (Yape/Plin)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Sube la imagen del QR de tu establecimiento.',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            
            Center(
              child: Column(
                children: [
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: config.qrImagenUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: CachedNetworkImage(
                              imageUrl: ApiConstants.getImageUrl(config.qrImagenUrl), // Helper needed? Or full URL?
                              // Config handles relative path in upload middleware, so we need base URL.
                              // Assuming ConfigProvider stores relative path like /uploads/config/qr.png
                              fit: BoxFit.cover,
                              placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                              errorWidget: (context, url, error) => const Icon(Icons.error),
                            ),
                          )
                        : const Icon(Icons.qr_code_2, size: 80, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final ImagePicker picker = ImagePicker();
                      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                      
                      if (image != null) {
                         try {
                           ScaffoldMessenger.of(context).showSnackBar(
                             const SnackBar(content: Text('Subiendo imagen...')),
                           );
                           
                           await config.uploadQrImage(File(image.path));
                           
                           ScaffoldMessenger.of(context).showSnackBar(
                             const SnackBar(content: Text('QR actualizado correctamente'), backgroundColor: Colors.green),
                           );
                         } catch (e) {
                           ScaffoldMessenger.of(context).showSnackBar(
                             SnackBar(content: Text('Error al subir imagen: $e'), backgroundColor: Colors.red),
                           );
                         }
                      }
                    },
                    icon: const Icon(Icons.upload),
                    label: const Text('Cambiar Imagen QR'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white
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

  // Widget para Configuración de Sonido
  Widget _buildSoundConfigCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Configuración de Alertas Sonoras',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Prueba si el sonido de alerta está funcionando correctamente.',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: const Row(
                children: [
                   Icon(Icons.info_outline, color: Colors.blue),
                   SizedBox(width: 10),
                   Expanded(
                     child: Text(
                       'Esta prueba usará el sonido de notificación predeterminado de tu dispositivo.',
                       style: TextStyle(fontSize: 12),
                     ),
                   )
                ]
              )
            ),
            const SizedBox(height: 16),

            Center(
              child: ElevatedButton.icon(
                onPressed: () async {
                   ScaffoldMessenger.of(context).showSnackBar(
                     const SnackBar(content: Text('Enviando notificación de prueba...'), duration: Duration(seconds: 1)),
                   );
                   await NotificationService().testSound(); // This now calls showNotification too inside service
                },
                icon: const Icon(Icons.volume_up),
                label: const Text('Probar Notificación y Sonido'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  // Widget para enviar Broadcasts
  Widget _buildBroadcastCard() {
     return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enviar Anuncio Global',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Envía un mensaje a todos los dispositivos conectados (Mozos/Cocina).',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            
            TextField(
              controller: _broadcastTitleController,
              decoration: const InputDecoration(
                labelText: 'Título',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _broadcastMessageController,
              decoration: const InputDecoration(
                labelText: 'Mensaje',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.message),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            
            Center(
              child: ElevatedButton.icon(
                onPressed: () async {
                   final message = _broadcastMessageController.text.trim();
                   final title = _broadcastTitleController.text.trim();
                   
                   if (message.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Por favor escribe un mensaje.'))
                      );
                      return;
                   }
                   
                   ScaffoldMessenger.of(context).showSnackBar(
                     const SnackBar(content: Text('Enviando anuncio...')),
                   );
                   
                   final success = await NotificationService().sendBroadcast(title, message);
                   
                   if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Anuncio enviado correctamente.'), backgroundColor: Colors.green),
                      );
                      _broadcastMessageController.clear();
                   } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Error al enviar anuncio.'), backgroundColor: Colors.red),
                      );
                   }
                },
                icon: const Icon(Icons.send),
                label: const Text('Enviar Anuncio'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}




