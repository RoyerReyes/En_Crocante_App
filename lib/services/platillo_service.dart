import 'dart:io';
import 'package:dio/dio.dart';
import 'package:encrocante_app/models/platillo_model.dart';
import 'package:encrocante_app/services/local_storage_service.dart';
import 'package:encrocante_app/services/dio_client.dart'; // Add correct import for global dio

class PlatilloService {
  final Dio _dio;

  PlatilloService({Dio? dio}) : _dio = dio ?? getDioInstance();

  static Dio getDioInstance() {
      // Use the global 'dio' instance from dio_client.dart
      return dio; 
  }

  // Create _handleError method
  Exception _handleError(dynamic e) {
    if (e is DioException) {
      if (e.response != null && e.response!.data != null) {
          final data = e.response!.data;
          if (data is Map<String, dynamic> && data.containsKey('message')) {
            return Exception(data['message']);
          }
      }
      return Exception('Error de red al procesar la solicitud.');
    }
    return Exception(e.toString());
  }

  Future<List<Platillo>> getPlatillos({bool includeInactive = false}) async {
    try {
      // 1. Intentar obtener datos del servidor (Network-First)
      final response = await _dio.get('/platillos');
      final List<dynamic> data = response.data as List<dynamic>;

      // 2. Guardar en caché si es exitoso
      await LocalStorageService.cachePlatillos(data.cast<Map<String, dynamic>>());
      
      var validData = data.map((json) => Platillo.fromJson(json as Map<String, dynamic>));

      if (!includeInactive) {
        validData = validData.where((platillo) => platillo.activo);
      }

      return validData.toList();

    } catch (e) {
      // 3. Si falla, intentar cargar del caché
      print('Network error, attempting to load from cache: $e');
      final cachedData = LocalStorageService.getCachedPlatillos();

      if (cachedData != null && cachedData.isNotEmpty) {
        print('Loaded ${cachedData.length} platillos from cache.');
        var validCached = cachedData.map((json) => Platillo.fromJson(json));
        
        if (!includeInactive) {
          validCached = validCached.where((platillo) => platillo.activo);
        }
        
        return validCached.toList();
      }

      // 4. Si no hay caché, propagar error
      if (e is DioException && e.response != null) {
        var errorMessage = 'Error al obtener los platillos.';
        if (e.response?.data is Map<String, dynamic>) {
            errorMessage = e.response?.data['message'] ?? errorMessage;
        }
        throw Exception(errorMessage);
      }
       throw Exception('Sin conexión y sin datos en caché.');
    }
  }

  // Create Platillo (supports image file)
  Future<Platillo> createPlatillo(Map<String, dynamic> data, {File? imageFile}) async {
    try {
      FormData formData = FormData.fromMap(data);
      
      if (imageFile != null) {
        String fileName = imageFile.path.split('/').last;
        formData.files.add(MapEntry(
          'imagen',
          await MultipartFile.fromFile(imageFile.path, filename: fileName),
        ));
      }

      final response = await _dio.post('/platillos', data: formData);
      return Platillo.fromJson(response.data['platillo']);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Update Platillo (supports image file)
  Future<void> updatePlatillo(int id, Map<String, dynamic> data, {File? imageFile}) async {
    try {
      FormData formData = FormData.fromMap(data);

      if (imageFile != null) {
        String fileName = imageFile.path.split('/').last;
        formData.files.add(MapEntry(
          'imagen',
          await MultipartFile.fromFile(imageFile.path, filename: fileName),
        ));
      }

      await _dio.put('/platillos/$id', data: formData);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deletePlatillo(int id) async {
    try {
      await _dio.delete('/platillos/$id');
    } catch (e) {
       if (e is DioException) {
        throw Exception(e.response?.data['message'] ?? 'Error al eliminar platillo');
      }
      throw Exception('Error desconocido al eliminar platillo');
    }
  }

  // Obtener categorías dinámicas
  Future<List<Map<String, dynamic>>> getCategorias() async {
    try {
      final response = await _dio.get('/categorias');
      // Esperamos una lista de objetos {id: 1, nombre: "..."}
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      print('Error al obtener categorías: $e');
      // Fallback a lista estática SOLO si falla la red, para no bloquear la UI completamente
      return [
        {'id': 1, 'nombre': 'Piqueos (Offline)'},
        {'id': 2, 'nombre': 'Hamburguesas (Offline)'},
        {'id': 3, 'nombre': 'Bebidas (Offline)'},
      ];
    }
  }
}
