import 'package:flutter/material.dart';
import 'package:dio/dio.dart'; // Importar DioException
import '../models/platillo_model.dart';
import '../services/platillo_service.dart';

class PlatilloProvider with ChangeNotifier {
  final PlatilloService _platilloService = PlatilloService();

  List<Platillo> _platillos = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';
  String _selectedFilter = 'Todos';

  // Datos de demostración para usar en caso de error 403
  final List<Platillo> _dummyPlatillos = [
    Platillo(
      id: 1,
      nombre: 'Agua Mineral',
      precio: 6.00,
      activo: true,
      categoria: Categoria(id: 1, nombre: 'Bebidas'),
    ),
    Platillo(
      id: 2,
      nombre: 'Jugo de Naranja',
      precio: 8.00,
      activo: true,
      categoria: Categoria(id: 1, nombre: 'Bebidas'),
    ),
    Platillo(
      id: 3,
      nombre: 'Lomo Saltado',
      precio: 25.00,
      activo: true,
      categoria: Categoria(id: 2, nombre: 'Platos Fuertes'),
    ),
    Platillo(
      id: 4,
      nombre: 'Arroz con Pollo',
      precio: 20.00,
      activo: true,
      categoria: Categoria(id: 2, nombre: 'Platos Fuertes'),
    ),
    Platillo(
      id: 5,
      nombre: 'Sopa Criolla',
      precio: 15.00,
      activo: true,
      categoria: Categoria(id: 3, nombre: 'Sopas'),
    ),
  ];

  // Getters
  List<Platillo> get platillos => _platillos;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get selectedFilter => _selectedFilter;
  
  List<String> get categorias {
    final categorias = _platillos.map((p) => p.categoria.nombre).toSet().toList();
    return ['Todos', ...categorias];
  }

  List<Platillo> get filteredPlatillos {
    return _platillos.where((platillo) {
      final matchNombre = platillo.nombre.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchCategoria = _selectedFilter == 'Todos' || platillo.categoria.nombre == _selectedFilter;
      return matchNombre && matchCategoria;
    }).toList();
  }

  PlatilloProvider() {
    fetchPlatillos();
  }

  Future<void> fetchPlatillos() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _platillos = await _platilloService.getPlatillos();
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        debugPrint('⚠️ PlatilloProvider: Acceso denegado (403) al cargar platillos. Usando datos de demostración.');
        _platillos = _dummyPlatillos;
        _errorMessage = 'Acceso denegado (403) al cargar platillos. Mostrando datos de demostración.';
      } else {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      }
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setFilter(String filter) {
    _selectedFilter = filter;
    notifyListeners();
  }
}
