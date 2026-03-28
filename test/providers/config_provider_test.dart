import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:encrocante_app/providers/config_provider.dart';

void main() {
  group('ConfigProvider Tests', () {
    late ConfigProvider configProvider;

    setUp(() async {
      SharedPreferences.setMockInitialValues({
        'nombreRestaurante': 'Mock Restaurant',
        'numeroMesas': 10,
        'moneda': 'USD',
        'notifPedidoListo': false,
      });
      configProvider = ConfigProvider();
      // Wait for loadPreferences to complete since it's called in constructor but async
      await Future.delayed(Duration.zero); 
    });

    test('Initial values loaded from SharedPreferences', () async {
      // Need to await loading if not awaited in constructor (it isn't awaited in constructor)
      await configProvider.loadPreferences(); 
      
      expect(configProvider.nombreRestaurante, 'Mock Restaurant');
      expect(configProvider.numeroMesas, 10);
      expect(configProvider.moneda, 'USD');
      expect(configProvider.notifPedidoListo, false);
    });

    test('setNombreRestaurante updates value and persists', () async {
      await configProvider.setNombreRestaurante('New Name');
      expect(configProvider.nombreRestaurante, 'New Name');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('nombreRestaurante'), 'New Name');
    });

    test('setNumeroMesas updates value and persists', () async {
      await configProvider.setNumeroMesas(50);
      expect(configProvider.numeroMesas, 50);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('numeroMesas'), 50);
    });

    test('setNotifPedidoListo updates value and persists', () async {
      await configProvider.setNotifPedidoListo(true);
      expect(configProvider.notifPedidoListo, true);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('notifPedidoListo'), true);
    });
  });
}
