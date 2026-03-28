import 'package:dio/dio.dart';
import 'package:encrocante_app/services/dio_client.dart';

class ConfigService {
  final Dio _dio = dio;

  Future<Map<String, dynamic>> getAppConfig() async {
    try {
      final response = await _dio.get('/config');
      return response.data;
    } catch (e) {
      print('Error fetching config: $e');
      // Fallback defaults if offline
      return {
        'puntos': {
          'SOLES_POR_PUNTO': 10,
          'PUNTOS_POR_SOL_CANJE': 1
        }
      };
    }
  }
}
