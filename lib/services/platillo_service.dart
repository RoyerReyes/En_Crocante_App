import 'package:dio/dio.dart';
import '../models/platillo_model.dart';
import 'secure_storage_service.dart';

class PlatilloService {
  final Dio _dio = Dio();
  final SecureStorageService _storageService = SecureStorageService(); 
  
  // CORRECCIÓN FINAL: La URL base se establece exactamente como en la documentación
  // 'http://<tu-servidor>:<puerto>/api/platillos'
  final String _baseUrl = 'http://192.168.18.39:3000/api/platillos';

  PlatilloService() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storageService.getToken(); 
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
    ));
  }

  Future<List<Platillo>> getPlatillos() async {
    try {
      // La petición ahora se hará directamente a la URL base:
      // 'http://192.168.18.39:3000/api/platillos'
      final response = await _dio.get(_baseUrl);
      
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data as List<dynamic>;
        
        return data
            .map((json) => Platillo.fromJson(json as Map<String, dynamic>))
            .where((platillo) => platillo.activo)
            .toList();
      } else {
        throw Exception('Error al obtener los platillos: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Endpoint no encontrado. La URL: \'${_baseUrl}\' no existe en el backend. (Error 404)');
      }
      print('Error de Dio al obtener platillos: $e');
      throw Exception('No se pudo conectar al servidor. Revisa tu conexión y la URL del backend.');
    } catch (e) {
      print('Error inesperado al obtener platillos: $e');
      throw Exception('Ocurrió un error inesperado.');
    }
  }
}
