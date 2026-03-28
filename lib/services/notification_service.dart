import 'package:flutter/foundation.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:encrocante_app/services/dio_client.dart'; // Added


class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  Future<void> init() async {
    // Android Init Settings
    // Use 'launcher_icon' if that's what flutter_launcher_icons generated
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    // iOS Init Settings (Minimal)
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
         // Handle notification tap
         debugPrint('🔔 Tapped notification: ${response.payload}');
      },
    );

    await _createNotificationChannel();
  }

  Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel', // id
      'Notificaciones Importantes', // title
      description: 'Canal para alertas de pedidos y cocina', // description
      importance: Importance.max,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<void> requestPermissions() async {
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  /// Muestra una notificación en la barra de estado
  Future<void> showNotification(String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'high_importance_channel',
      'Notificaciones Importantes',
      channelDescription: 'Alertas de pedidos',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      styleInformation: BigTextStyleInformation(''), // Allows long text
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    // Use millisecondsSinceEpoch to ensure unique IDs, allowing notifications to stack
    final int notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    await flutterLocalNotificationsPlugin.show(
      notificationId, // Unique ID
      title,
      body,
      platformChannelSpecifics,
    );
  }

  /// Reproduce el sonido de notificación predeterminado del sistema.
  Future<void> playReadySound() async {
    try {
      final player = FlutterRingtonePlayer();
      await player.playNotification();
      debugPrint('🔔 NotificationService: Reproduciendo sonido de sistema.');
    } catch (e) {
      debugPrint('❌ NotificationService: Error al reproducir sonido: $e');
    }
  }

  // Método para enviar broadcast (Admin)
  Future<bool> sendBroadcast(String title, String message) async {
    try {
      final response = await dio.post('/notifications/broadcast', data: {
        'title': title,
        'message': message,
      });
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('❌ Error sending broadcast: $e');
      return false;
    }
  }

  // Método para probar el sonido desde la UI de Admin
  Future<void> testSound() async {
    await playReadySound();
    await showNotification("Prueba de Sonido", "El sistema de audio está funcionando correctamente.");
  }
}
