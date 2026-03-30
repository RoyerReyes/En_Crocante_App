import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../models/presa_model.dart';
import 'secure_storage_service.dart';

class PresaService {
  final SecureStorageService _storage = SecureStorageService();

  Future<List<Presa>> getPresas() async {
    final token = await _storage.getToken();
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/presas'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => Presa.fromJson(json)).toList();
    } else {
      throw Exception('Error al cargar presas');
    }
  }

  Future<void> togglePresa(int id, bool activo) async {
    final token = await _storage.getToken();
    final response = await http.put(
      Uri.parse('${ApiConstants.baseUrl}/presas/$id/toggle'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({'activo': activo}),
    );

    if (response.statusCode != 200) {
      throw Exception('Error al actualizar la presa');
    }
  }

  Future<void> addPresa(String nombre, bool activo) async {
    final token = await _storage.getToken();
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/presas'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({'nombre': nombre, 'activo': activo}),
    );

    if (response.statusCode != 201) {
      throw Exception('Error al agregar presa');
    }
  }

  Future<void> updatePresa(int id, String nombre, bool activo) async {
    final token = await _storage.getToken();
    final response = await http.put(
      Uri.parse('${ApiConstants.baseUrl}/presas/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({'nombre': nombre, 'activo': activo}),
    );

    if (response.statusCode != 200) {
      throw Exception('Error al editar presa');
    }
  }

  Future<void> deletePresa(int id) async {
    final token = await _storage.getToken();
    final response = await http.delete(
      Uri.parse('${ApiConstants.baseUrl}/presas/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      throw Exception('Error al eliminar presa');
    }
  }
}
