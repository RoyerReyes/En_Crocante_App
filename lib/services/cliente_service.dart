import 'package:dio/dio.dart';
import 'dio_client.dart';
import '../models/cliente_model.dart';

class ClienteService {
  Future<List<Cliente>> buscarClientes(String query) async {
    try {
      final response = await dio.get('/clientes', queryParameters: {'q': query});
      final List<dynamic> data = response.data;
      return data.map((json) => Cliente.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error buscando clientes: $e');
    }
  }

  Future<Cliente> crearCliente(Map<String, dynamic> data) async {
    try {
      final response = await dio.post('/clientes', data: data);
      return Cliente.fromJson(response.data);
    } catch (e) {
       if (e is DioException && e.response?.statusCode == 400) {
         throw Exception(e.response?.data['message'] ?? 'Error de validación');
       }
      throw Exception('Error creando cliente: $e');
    }
  }
}
