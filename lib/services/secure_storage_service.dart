import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  // Creamos una instancia del almacenamiento
  final _storage = const FlutterSecureStorage();

  // Usamos una clave constante para guardar y leer el token.
  // Esto evita errores de tipeo en el futuro.
  static const _tokenKey = 'auth_token';
  static const _userNameKey = 'user_name'; // Nueva clave para el nombre de usuario
  static const _userRoleKey = 'user_role'; // Clave para el rol

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

  // Guarda el nombre de usuario de forma segura
  Future<void> saveUserName(String userName) async {
    try {
      await _storage.write(key: _userNameKey, value: userName);
      print("✅ Nombre de usuario guardado de forma segura.");
    } catch (e) {
      print("❌ Error al guardar el nombre de usuario: $e");
    }
  }

  // Lee el nombre de usuario desde el almacenamiento seguro
  Future<String?> getUserName() async {
    try {
      final userName = await _storage.read(key: _userNameKey);
      if (userName != null) {
        print("👤 Nombre de usuario recuperado.");
      } else {
        print("No se encontró ningún nombre de usuario.");
      }
      return userName;
    } catch (e) {
      print("❌ Error al leer el nombre de usuario: $e");
      return null;
    }
  }

  // Guarda el rol del usuario
  Future<void> saveUserRole(String role) async {
    try {
      await _storage.write(key: _userRoleKey, value: role);
      print("✅ Rol de usuario guardado: $role");
    } catch (e) {
      print("❌ Error al guardar el rol: $e");
    }
  }

  // Lee el rol del usuario
  Future<String?> getUserRole() async {
    try {
      return await _storage.read(key: _userRoleKey);
    } catch (e) {
      print("❌ Error al leer el rol: $e");
      return null;
    }
  }

  // Elimina el token y el nombre de usuario del almacenamiento (para el logout)
  Future<void> deleteToken() async {
    try {
      await _storage.delete(key: _tokenKey);
      await _storage.delete(key: _userNameKey); // Eliminar también el nombre de usuario
      await _storage.delete(key: _userRoleKey); // Eliminar rol
      print("✅ Token y nombre de usuario eliminados (logout).");
    } catch (e) {
      print("❌ Error al eliminar el token y el nombre de usuario: $e");
    }
  }
}
