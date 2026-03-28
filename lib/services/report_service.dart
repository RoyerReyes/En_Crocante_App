import 'package:dio/dio.dart';
import 'dio_client.dart';

class ReportService {
  final Dio _dio;

  ReportService({Dio? dio}) : _dio = dio ?? getDioClient();
  
  static Dio getDioClient() => dio; // From dio_client.dart

  Future<List<dynamic>> getTopPlatillos({DateTime? start, DateTime? end, String? metodoPago}) async {
    try {
      final response = await _dio.get('/reportes/platillos-mas-vendidos', queryParameters: _buildDateParams(start, end, metodoPago, null));
      return response.data;
    } catch (e) {
      throw Exception('Error al obtener top platillos: $e');
    }
  }

  Future<List<dynamic>> getVentasDiarias({DateTime? start, DateTime? end, String? metodoPago, String? preset}) async {
    try {
      final response = await _dio.get('/reportes/ventas-diarias', queryParameters: _buildDateParams(start, end, metodoPago, preset));
      return response.data;
    } catch (e) {
      throw Exception('Error al obtener ventas diarias: $e');
    }
  }

  Future<List<dynamic>> getRendimientoMozos({DateTime? start, DateTime? end}) async {
    try {
      final response = await dio.get('/reportes/rendimiento-mozos', queryParameters: _buildDateParams(start, end, null, null));
      return response.data;
    } catch (e) {
      throw Exception('Error al obtener rendimiento mozos: $e');
    }
  }

  Map<String, dynamic> _buildDateParams(DateTime? start, DateTime? end, String? metodoPago, String? preset) {
    var params = <String, dynamic>{};
    
    if (preset != null) {
      params['preset'] = preset;
    }
    
    if (start != null && end != null) {
      // Format manual YYYY-MM-DD HH:mm:ss to avoid ISO 'T' issues in MySQL
      String startStr = "${start.year}-${_twoDigits(start.month)}-${_twoDigits(start.day)} ${_twoDigits(start.hour)}:${_twoDigits(start.minute)}:${_twoDigits(start.second)}";
      String endStr = "${end.year}-${_twoDigits(end.month)}-${_twoDigits(end.day)} ${_twoDigits(end.hour)}:${_twoDigits(end.minute)}:${_twoDigits(end.second)}";
      
      params['startDate'] = startStr;
      params['endDate'] = endStr;
    }
    if (metodoPago != null && metodoPago != 'Todos') {
      params['metodoPago'] = metodoPago;
    }
    return params;
  }

  String _twoDigits(int n) => n.toString().padLeft(2, "0");

  Future<Map<String, dynamic>> getSystemStats() async {
    try {
      final response = await dio.get('/reportes/stats');
      return response.data;
    } catch (e) {
      // Retornar defaults en caso de error para no romper la UI
      return {
        'total_ordenes': 0,
        'rendimiento': '0.0%',
        'tiempo_actividad': 'Desconocido'
      };
    }
  }
}
