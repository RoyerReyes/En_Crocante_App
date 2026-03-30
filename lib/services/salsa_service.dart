import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../models/salsa_model.dart';
import 'secure_storage_service.dart';

class SalsaService {
  final SecureStorageService _storage = SecureStorageService();

  Future<List<Salsa>> getSalsas() async {
    final token = await _storage.getToken();
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/salsas'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => Salsa.fromJson(json)).toList();
    } else {
      throw Exception('Error al cargar salsas');
    }
  }

  Future<void> toggleSalsa(int id, bool activo) async {
    final token = await _storage.getToken();
    final response = await http.put(
      Uri.parse('${ApiConstants.baseUrl}/salsas/$id/toggle'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({'activo': activo}),
    );

    if (response.statusCode != 200) {
      throw Exception('Error al actualizar la salsa');
    }
  }
}
