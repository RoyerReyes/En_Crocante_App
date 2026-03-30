import 'package:flutter/foundation.dart';
import '../models/salsa_model.dart';
import '../services/salsa_service.dart';

class SalsaProvider with ChangeNotifier {
  final SalsaService _salsaService = SalsaService();
  List<Salsa> _salsas = [];
  bool _isLoading = false;

  List<Salsa> get salsas => _salsas;
  bool get isLoading => _isLoading;

  Future<void> fetchSalsas() async {
    _isLoading = true;
    notifyListeners();
    try {
      _salsas = await _salsaService.getSalsas();
    } catch (e) {
      if (kDebugMode) {
        print("Error fetching salsas: $e");
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleSalsa(int id, bool activo) async {
    try {
      await _salsaService.toggleSalsa(id, activo);
      // Update local state instantly avoiding another network call
      final index = _salsas.indexWhere((s) => s.id == id);
      if (index != -1) {
        _salsas[index].activo = activo;
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error al togglear salsa: $e");
      }
      throw e;
    }
  }
}
