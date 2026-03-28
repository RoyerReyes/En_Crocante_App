import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/pedido_provider.dart';
import '../providers/config_provider.dart';
import '../services/secure_storage_service.dart'; // Import
import '../screens/pedidos_list_screen.dart' as import_screens;
import '../main.dart'; // Import for rootScaffoldMessengerKey and navigatorKey
import '../services/notification_service.dart'; // Import

class NotificationWrapper extends StatefulWidget {
  final Widget child;
  const NotificationWrapper({super.key, required this.child});

  @override
  State<NotificationWrapper> createState() => _NotificationWrapperState();
}

class _NotificationWrapperState extends State<NotificationWrapper> {
  
  @override
  void initState() {
    super.initState();
    // Escuchar stream de notificaciones
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pedidoProvider = Provider.of<PedidoProvider>(context, listen: false);
      pedidoProvider.notificationStream.listen((message) async {
        if (!mounted) return;

        // Check Config
        final config = Provider.of<ConfigProvider>(context, listen: false);
        
        // Check Role
        // We use a pragmatic approach: The message content determines the target audience.
        // "Cocina:" -> Means "From Kitchen" -> Target: Waiter
        // "Nuevo pedido" -> Target: Kitchen
        
        // To be safe, we get the role from storage
        final storage = SecureStorageService();
        final role = await storage.getUserRole(); // 'admin', 'mesero', 'cocina'
        
        bool shouldNotify = false;

        // --- FILTERING LOGIC ---
        
        // 1. Item Ready / Order Ready (Target: Waiter/Admin)
        if (message.contains("LISTO") || message.contains("listo")) {
           // Mesero or Admin should see this
           if (role == 'mesero' || role == 'admin') {
              if (config.notifPedidoListo) shouldNotify = true;
           }
        } 
        // 2. New Order (Target: Kitchen/Admin)
        else if (message.contains("Nuevo pedido")) {
           // Cocina or Admin should see this
           if (role == 'cocina' || role == 'cocinero' || role == 'admin') {
              // We could add a config for this too like 'notifNuevoPedido'
              shouldNotify = true; 
           }
        }
        // 3. Wait Time Warning (Target: Admin/Waiter)
        else if (message.contains("Tiempo de espera")) {
           if (role == 'admin' || role == 'mesero') {
              if (config.notifTiempoEspera) shouldNotify = true;
           }
        }

        
        // 5. Broadcast Message (Target: All Staff)
        else if (message.contains("anuncio")) { // We will use a flag or check title in a better implementation, but for now simple string check
           shouldNotify = true;
        }
        else {
           shouldNotify = true;
        }

        if (shouldNotify) {
           // Show System Notification (Status Bar)
           NotificationService().showNotification('En Crocante', message);

           rootScaffoldMessengerKey.currentState?.showSnackBar(
            SnackBar(
              content: Text(message, style: const TextStyle(fontWeight: FontWeight.bold)),
              behavior: SnackBarBehavior.floating,
              backgroundColor: message.contains("LISTO") || message.contains("listo") 
                  ? Colors.green 
                  : (message.contains("Tiempo de espera") ? Colors.redAccent : Colors.deepOrange),
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: 'Ver',
                textColor: Colors.white,
                onPressed: () { 
                   // Navigate using global key
                   navigatorKey.currentState?.push(
                     MaterialPageRoute(builder: (context) => const import_screens.PedidosListScreen())
                   );
                }, 
              ),
            ),
          );
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
