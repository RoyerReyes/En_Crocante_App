import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb; 
import 'dart:io' show Platform; 
import 'secure_storage_service.dart';

final SecureStorageService _storageService = SecureStorageService();
final Dio dio = _createDioClient();

Dio _createDioClient() {
  String baseUrl;
  if (kIsWeb) {
    baseUrl = "http://127.0.0.1:3000";
    print("🌐 Dio Base URL (Web): $baseUrl");
  } else if (Platform.isAndroid) {
    // Para dispositivos Android (físicos y emuladores)
    // Aquí usamos la IP real de tu PC: 192.168.18.39
    // Asegúrate de que tu backend esté escuchando en esta IP (0.0.0.0 o la misma IP)
    baseUrl = "http://192.168.18.39:3000"; // <--- ¡Tu IP local real para el dispositivo físico!
    print("📱 Dio Base URL (Android - Dispositivo Físico): $baseUrl");

    // NOTA: Si en algún momento necesitas volver a probar en un EMULADOR,
    // tendrías que cambiar esta línea a: baseUrl = "http://10.0.2.2:3000";
    // o añadir una lógica para detectarlo, pero para tu caso actual de móvil físico, esta es la correcta.

  } else { 
    baseUrl = "http://localhost:3000"; 
    print("💻 Dio Base URL (Otros): $baseUrl");
  }

  final dio = Dio(BaseOptions(
    baseUrl: baseUrl, 
    connectTimeout: const Duration(seconds: 10), 
    receiveTimeout: const Duration(seconds: 5),
  ));

  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      String? token = await _storageService.getToken();

      if (token != null) {
        options.headers["Authorization"] = "Bearer $token";
        print("✅ Token añadido a la cabecera para ${options.path}");
      } else {
        print("⚠️ No se encontró token para la petición a ${options.path}");
      }
      
      return handler.next(options);
    },
    onError: (DioException e, handler) {
      print("❌ Error en petición: ${e.requestOptions.path}");
      print(" Mensaje: ${e.message}");
      if (e.response != null) {
        print(" Status: ${e.response?.statusCode}");
        print(" Data: ${e.response?.data}");
      }
      return handler.next(e);
    },
  ));

  return dio;
}
