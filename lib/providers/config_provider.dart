import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'dart:io';
import '../services/dio_client.dart'; // Ensure global dio instance is available

class ConfigProvider extends ChangeNotifier {
  // Claves para SharedPreferences
  static const String _keyNombreRestaurante = 'nombreRestaurante';
  static const String _keyNumeroMesas = 'numeroMesas';
  static const String _keyMoneda = 'moneda';
  static const String _keyNotifPedidoListo = 'notifPedidoListo';
  static const String _keyNotifPedidoEnPreparacion = 'notifPedidoEnPreparacion'; // New
  static const String _keyNotifTiempoEspera = 'notifTiempoEspera';
  static const String _keyNotifStockBajo = 'notifStockBajo';
  static const String _keyQrImagenUrl = 'qrImagenUrl'; // New Key

  // Valores default
  String _nombreRestaurante = 'Restaurante El Buen Sabor';
  int _numeroMesas = 25;
  String _moneda = 'Soles';
  bool _notifPedidoListo = true;
  bool _notifPedidoEnPreparacion = true; 
  bool _notifTiempoEspera = true;
  bool _notifStockBajo = true;
  String? _qrImagenUrl; // New Variable

  SharedPreferences? _prefs;

  ConfigProvider() {
    loadPreferences();
    fetchRemoteConfig();
  }

  // Getters
  String get nombreRestaurante => _nombreRestaurante;
  int get numeroMesas => _numeroMesas;
  String get moneda => _moneda;
  bool get notifPedidoListo => _notifPedidoListo;
  bool get notifPedidoEnPreparacion => _notifPedidoEnPreparacion;
  bool get notifTiempoEspera => _notifTiempoEspera;
  bool get notifStockBajo => _notifStockBajo;
  String? get qrImagenUrl => _qrImagenUrl; // New Getter

  Future<void> loadPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    _nombreRestaurante = _prefs?.getString(_keyNombreRestaurante) ?? 'Restaurante El Buen Sabor';
    _numeroMesas = _prefs?.getInt(_keyNumeroMesas) ?? 25;
    _moneda = _prefs?.getString(_keyMoneda) ?? 'Soles';
    _notifPedidoListo = _prefs?.getBool(_keyNotifPedidoListo) ?? true;
    _notifPedidoEnPreparacion = _prefs?.getBool(_keyNotifPedidoEnPreparacion) ?? true;
    _notifTiempoEspera = _prefs?.getBool(_keyNotifTiempoEspera) ?? true;
    _notifStockBajo = _prefs?.getBool(_keyNotifStockBajo) ?? true;
    _qrImagenUrl = _prefs?.getString(_keyQrImagenUrl); // Load QR
    notifyListeners();
  }
  
  Future<SharedPreferences> get _safePrefs async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  // Setters con persistencia
  Future<void> setNombreRestaurante(String value) async {
    _nombreRestaurante = value;
    (await _safePrefs).setString(_keyNombreRestaurante, value);
    notifyListeners();
  }

  Future<void> setNumeroMesas(int value) async {
    _numeroMesas = value;
    (await _safePrefs).setInt(_keyNumeroMesas, value);
    notifyListeners();
  }

  Future<void> setMoneda(String value) async {
    _moneda = value;
    (await _safePrefs).setString(_keyMoneda, value);
    notifyListeners();
  }

  Future<void> setNotifPedidoListo(bool value) async {
    _notifPedidoListo = value;
    (await _safePrefs).setBool(_keyNotifPedidoListo, value);
    notifyListeners();
  }

  Future<void> setNotifPedidoEnPreparacion(bool value) async {
    _notifPedidoEnPreparacion = value;
    (await _safePrefs).setBool(_keyNotifPedidoEnPreparacion, value);
    notifyListeners();
  }

  Future<void> setNotifTiempoEspera(bool value) async {
    _notifTiempoEspera = value;
    (await _safePrefs).setBool(_keyNotifTiempoEspera, value);
    notifyListeners();
  }

  Future<void> setNotifStockBajo(bool value) async {
    _notifStockBajo = value;
    (await _safePrefs).setBool(_keyNotifStockBajo, value);
    notifyListeners();
  }

  // QR Upload Logic
  Future<void> uploadQrImage(File imageFile) async {
    try {
      String fileName = imageFile.path.split('/').last;
      FormData formData = FormData.fromMap({
        'imagen': await MultipartFile.fromFile(imageFile.path, filename: fileName),
      });

      final response = await dio.post('/config/upload-qr', data: formData);

      if (response.statusCode == 200) {
        final url = response.data['imagen_url'];
        _qrImagenUrl = url;
        (await _safePrefs).setString(_keyQrImagenUrl, url);
        notifyListeners();
        debugPrint('✅ QR subido con éxito: $url');
      } else {
        throw Exception('Error subiendo imagen');
      }
    } catch (e) {
      debugPrint('❌ Error subiendo QR: $e');
      rethrow;
    }
  }

  // --- LOYALTY CONFIG ---
  int _solesPorPunto = 10;
  int _puntosPorSolCanje = 1;

  int get solesPorPunto => _solesPorPunto;
  int get puntosPorSolCanje => _puntosPorSolCanje;

  // --- OTA CONFIG ---
  String _otaVersion = "1.0.0";
  String _otaUrl = "";
  bool _otaForceUpdate = true;

  String get otaVersion => _otaVersion;
  String get otaUrl => _otaUrl;
  bool get otaForceUpdate => _otaForceUpdate;

  Future<void> fetchRemoteConfig() async {
    try {
      final response = await dio.get('/config');
      if (response.statusCode == 200) {
        final data = response.data;
        if (data['puntos'] != null) {
          _solesPorPunto = data['puntos']['SOLES_POR_PUNTO'] ?? 10;
          _puntosPorSolCanje = data['puntos']['PUNTOS_POR_SOL_CANJE'] ?? 1;
        }
        if (data['ota'] != null) {
          _otaVersion = data['ota']['ANDROID_VERSION'] ?? "1.0.0";
          _otaUrl = data['ota']['ANDROID_URL'] ?? "";
          _otaForceUpdate = data['ota']['FORCE_UPDATE'] ?? true;
        }
        notifyListeners();
        debugPrint('✅ Config remota cargada. OTA Version: $_otaVersion');
      }
    } catch (e) {
      debugPrint('⚠️ Error cargando config remota: $e');
    }
  }
}
