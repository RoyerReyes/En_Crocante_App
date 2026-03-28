import 'package:dio/dio.dart';
import 'package:encrocante_app/services/dio_client.dart';
import '../models/usuario_model.dart';
import 'dart:convert'; // ADDED: Import for jsonDecode

class UserService {
  final Dio _dio;

  UserService({Dio? dioClient}) : _dio = dioClient ?? dio; // Use injected or global dio

  // Obtener todos los usuarios
  Future<List<Usuario>> getUsers() async {
    try {
      final response = await _dio.get('/usuarios');
      if (response.statusCode == 200) {
        final List<dynamic> usersJson = response.data;
        return usersJson
            .map((json) => Usuario.fromJson(json))
            .where((usuario) => usuario.activo)
            .toList();
      } else {
        _throwDioException(response);
      }
      throw Exception('Unreachable'); // Should throw in _throwDioException
    } on DioException catch (e) {
      throw _handleDioError(e, 'Error al obtener usuarios');
    } catch (e) {
      throw Exception('Ocurrió un error inesperado al obtener usuarios: $e');
    }
  }

  // Actualizar el rol de un usuario
  Future<Usuario> updateUserRole(int userId, String newRole) async {
    try {
      final response = await _dio.put(
        '/usuarios/$userId',
        data: {'rol': newRole},
      );
      if (response.statusCode == 200) {
        return Usuario.fromJson(response.data);
      } else {
        _throwDioException(response);
      }
      throw Exception('Unreachable');
    } on DioException catch (e) {
      throw _handleDioError(e, 'Error al actualizar rol de usuario');
    } catch (e) {
      throw Exception('Ocurrió un error inesperado al actualizar rol: $e');
    }
  }

  // Eliminar un usuario
  Future<void> deleteUser(int userId) async {
    try {
      final response = await _dio.delete('/usuarios/$userId');
      if (response.statusCode == 204 || response.statusCode == 200) {
        print('Usuario $userId eliminado exitosamente.');
      } else {
        _throwDioException(response);
      }
    } on DioException catch (e) {
      throw _handleDioError(e, 'Error al eliminar usuario');
    } catch (e) {
      throw Exception('Ocurrió un error inesperado al eliminar usuario: $e');
    }
  }

  // Crear un nuevo usuario
  Future<void> createUser(String nombre, String usuario, String password, String rol) async {
    try {
      final response = await _dio.post(
        '/auth/register',
        data: {
          'nombre': nombre,
          'usuario': usuario,
          'password': password,
          'rol': rol,
        },
      );
      if (response.statusCode == 201) {
        return;
      } else {
       _throwDioException(response);
      }
      throw Exception('Unreachable');
    } on DioException catch (e) {
      throw _handleDioError(e, 'Error al crear usuario');
    } catch (e) {
      throw Exception('Ocurrió un error inesperado al crear usuario: $e');
    }
  }

  void _throwDioException(Response response) {
    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      error: 'El servidor respondió con el código ${response.statusCode}',
    );
  }

  Exception _handleDioError(DioException e, String defaultMessage) {
    String errorMessage = '$defaultMessage. Inténtalo más tarde.';
    if (e.response != null) {
      if (e.response?.data is Map<String, dynamic>) {
        final message = e.response?.data['message'];
        if (message is String) {
          errorMessage = message;
        } else if (message != null) {
          errorMessage = message.toString();
        } else {
          errorMessage = 'Respuesta de error inesperada del servidor.';
        }
      } else if (e.response?.data is String) {
        try {
          final decodedBody = jsonDecode(e.response?.data as String);
          errorMessage = decodedBody['message'] ?? 'Error del servidor: ${e.response?.data}';
        } catch (_) {
          errorMessage = 'Error del servidor: ${e.response?.data}';
        }
      }
    } else {
      errorMessage = e.message ?? errorMessage;
    }
    print('$defaultMessage: $errorMessage');
    return Exception(errorMessage);
  }
}
