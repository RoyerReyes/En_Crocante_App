import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  // Creamos una instancia del almacenamiento
  final _storage = const FlutterSecureStorage();

  // Usamos una clave constante para guardar y leer el token.
  // Esto evita errores de tipeo en el futuro.
  static const _tokenKey = 'auth_token';

  // Guarda el token de forma segura
  Future<void> saveToken(String token) async {
    try {
      await _storage.write(key: _tokenKey, value: token);
      print("✅ Token guardado de forma segura.");
    } catch (e) {
      print("❌ Error al guardar el token: $e");
    }
  }

  // Lee el token desde el almacenamiento seguro
  Future<String?> getToken() async {
    try {
      final token = await _storage.read(key: _tokenKey);
      if (token != null) {
        print("🔑 Token recuperado.");
      } else {
        print("No se encontró ningún token.");
      }
      return token;
    } catch (e) {
      print("❌ Error al leer el token: $e");
      return null;
    }
  }

  // Elimina el token del almacenamiento (para el logout)
  Future<void> deleteToken() async {
    try {
      await _storage.delete(key: _tokenKey);
      print("✅ Token eliminado (logout).");
    } catch (e) {
      print("❌ Error al eliminar el token: $e");
    }
  }
}
