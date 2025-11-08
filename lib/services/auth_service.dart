import 'package:dio/dio.dart';
import '../models/usuario_model.dart';
import 'secure_storage_service.dart';
import 'dio_client.dart';

class AuthService {
  final Dio _dio = dio;
  final SecureStorageService _storageService = SecureStorageService();

  Future<Usuario> login(String usuario, String password) async {
    try {
      // CORRECCIÓN FINAL: Se revierte el campo a 'usuario' para que coincida con lo que el backend
      // está pidiendo en el log de error, ignorando la documentación auth_api.md.
      final response = await _dio.post("/api/auth/login", data: {
        'usuario': usuario,
        'password': password,
      });

      if (response.data is! Map<String, dynamic>) {
        throw Exception('Respuesta inesperada del servidor.');
      }

      final responseData = response.data as Map<String, dynamic>;

      if (responseData['token'] != null) {
        final token = responseData['token'] as String;
        await _storageService.saveToken(token);
        print("✅ Login exitoso y token guardado.");
      } else {
        throw Exception('El servidor no devolvió un token.');
      }

      if (responseData.containsKey('usuario') && responseData['usuario'] is Map<String, dynamic>) {
        return Usuario.fromJson(responseData['usuario']);
      } else {
        throw Exception('La respuesta no contiene los datos del usuario.');
      }

    } on DioException catch (e) {
      if (e.response != null) {
        var errorMessage = 'Usuario o contraseña incorrectos.';
        if (e.response?.data is Map<String, dynamic>) {
          errorMessage = e.response?.data['message'] ?? errorMessage;
        }
        throw Exception(errorMessage);
      } else {
        throw Exception('No se pudo conectar al servidor.');
      }
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> logout() async {
    await _storageService.deleteToken();
  }

  Future<void> register(Map<String, dynamic> userData) async {
    try {
      await _dio.post("/api/auth/register", data: userData);
      print("✅ Usuario registrado con éxito.");

    } on DioException catch (e) {
      if (e.response != null) {
        var errorMessage = 'No se pudo registrar el usuario.';
        if (e.response?.data is Map<String, dynamic>) {
          errorMessage = e.response?.data['message'] ?? errorMessage;
        }
        throw Exception(errorMessage);
      } else {
        throw Exception('No se pudo conectar al servidor.');
      }
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }
}
