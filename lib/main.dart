import 'package:encrocante_app/providers/cart_provider.dart';
import 'package:encrocante_app/providers/pedido_provider.dart';
import 'package:encrocante_app/providers/order_details_provider.dart';
import 'package:encrocante_app/providers/platillo_provider.dart';
import 'package:encrocante_app/providers/config_provider.dart';
import 'package:encrocante_app/providers/theme_provider.dart'; // Import
import 'package:encrocante_app/screens/login_screen.dart';
import 'package:encrocante_app/widgets/notification_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:encrocante_app/services/local_storage_service.dart'; // Import
import 'package:encrocante_app/services/connectivity_service.dart'; // Import
import 'package:encrocante_app/services/sync_service.dart'; // Import

import 'package:encrocante_app/services/notification_service.dart'; // Import
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalStorageService.init(); // Initialize Hive
  
  // Initialize Notifications
  final notificationService = NotificationService();
  await notificationService.init();
  await notificationService.requestPermissions(); // Request on app start (or better in a specific screen, but ok for now)

  await initializeDateFormatting('es', null);

  runApp(const MyApp());
}

final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => CartProvider()),
        ChangeNotifierProvider(create: (context) => PedidoProvider()),
        ChangeNotifierProvider(create: (context) => OrderDetailsProvider()),
        ChangeNotifierProvider(create: (context) => PlatilloProvider()),
        ChangeNotifierProvider(create: (context) => ConfigProvider()),
        ChangeNotifierProvider(create: (context) => ThemeProvider()), // Nuevo
        ChangeNotifierProvider(create: (context) => ConnectivityService()), // Nuevo Offline Service
        ChangeNotifierProxyProvider<ConnectivityService, SyncService>(
          create: (context) => SyncService(Provider.of<ConnectivityService>(context, listen: false)),
          update: (context, connectivity, previous) => previous ?? SyncService(connectivity),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'En Crocante',
            navigatorKey: navigatorKey, // Add global navigator key
            themeMode: themeProvider.themeMode,
            theme: ThemeData(
              primarySwatch: Colors.deepOrange,
              brightness: Brightness.light,
              visualDensity: VisualDensity.adaptivePlatformDensity,
            ),
            darkTheme: ThemeData(
              primarySwatch: Colors.deepOrange,
              brightness: Brightness.dark,
              visualDensity: VisualDensity.adaptivePlatformDensity,
              // Ajustes para Dark Mode
              scaffoldBackgroundColor: const Color(0xFF121212),
              cardColor: const Color(0xFF1E1E1E),
              appBarTheme: const AppBarTheme(
                backgroundColor: Color(0xFF1F1F1F),
              ),
            ),
            home: const LoginScreen(), 
            scaffoldMessengerKey: rootScaffoldMessengerKey, // Global Key for Notifications
            debugShowCheckedModeBanner: false,
            builder: (context, child) {
              return NotificationWrapper(child: child!);
            },
          );
        },
      ),
    );
  }
}
