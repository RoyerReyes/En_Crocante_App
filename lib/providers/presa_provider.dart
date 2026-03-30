import 'package:flutter/foundation.dart';
import '../models/presa_model.dart';
import '../services/presa_service.dart';

class PresaProvider with ChangeNotifier {
  final PresaService _presaService = PresaService();
  List<Presa> _presas = [];
  bool _isLoading = false;

  List<Presa> get presas => _presas;
  bool get isLoading => _isLoading;

  Future<void> fetchPresas() async {
    _isLoading = true;
    notifyListeners();
    try {
      _presas = await _presaService.getPresas();
    } catch (e) {
      if (kDebugMode) {
        print("Error fetching presas: $e");
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> togglePresa(int id, bool activo) async {
    try {
      await _presaService.togglePresa(id, activo);
      final index = _presas.indexWhere((p) => p.id == id);
      if (index != -1) {
        _presas[index].activo = activo;
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error al togglear presa: $e");
      }
      throw e;
    }
  }

  Future<void> addPresa(String nombre, bool activo) async {
    try {
      await _presaService.addPresa(nombre, activo);
      await fetchPresas();
    } catch (e) {
      if (kDebugMode) print("Error al agregar presa: $e");
      throw e;
    }
  }

  Future<void> updatePresa(int id, String nombre, bool activo) async {
    try {
      await _presaService.updatePresa(id, nombre, activo);
      await fetchPresas();
    } catch (e) {
      if (kDebugMode) print("Error al actualizar presa: $e");
      throw e;
    }
  }

  Future<void> deletePresa(int id) async {
    try {
      await _presaService.deletePresa(id);
      _presas.removeWhere((p) => p.id == id);
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print("Error al eliminar presa: $e");
      throw e;
    }
  }
}
