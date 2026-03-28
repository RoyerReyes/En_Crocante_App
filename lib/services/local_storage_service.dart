import 'package:hive_flutter/hive_flutter.dart';

class LocalStorageService {
  static const String boxPlatillos = 'platillos_cache';
  static const String boxOfflineOrders = 'offline_orders';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(boxPlatillos);
    await Hive.openBox(boxOfflineOrders);
  }

  // Generic Cache Methods
  static Future<void> saveCache(String boxName, String key, dynamic value) async {
    final box = Hive.box(boxName);
    await box.put(key, value);
  }

  static dynamic getCache(String boxName, String key) {
    final box = Hive.box(boxName);
    return box.get(key);
  }
  
  static Future<void> clearCache(String boxName) async {
     final box = Hive.box(boxName);
     await box.clear();
  }

  // --- Specific Helpers ---

  // Guarda lista de platillos como lista de Mapas JSON
  static Future<void> cachePlatillos(List<Map<String, dynamic>> platillosJson) async {
    await saveCache(boxPlatillos, 'all_platillos', platillosJson);
  }

  static List<Map<String, dynamic>>? getCachedPlatillos() {
    final data = getCache(boxPlatillos, 'all_platillos');
    if (data == null) return null;
    // Hive retorna dynamic, castear con cuidado
    return (data as List).cast<Map<String, dynamic>>();
  }

  // Encodes orders
  static Future<void> queueOfflineOrder(Map<String, dynamic> orderJson) async {
    final box = Hive.box(boxOfflineOrders);
    await box.add(orderJson); // Auto-increment key
  }

  // Returns orders with their Hive Keys to allow deletion after sync
  static List<Map<String, dynamic>> getOfflineOrders() {
    final box = Hive.box(boxOfflineOrders);
    List<Map<String, dynamic>> orders = [];
    for (var i = 0; i < box.length; i++) {
      final order = Map<String, dynamic>.from(box.getAt(i) as Map);
      order['_hiveKey'] = box.keyAt(i); // Inject Key for deletion
      orders.add(order);
    }
    return orders;
  }

  static Future<void> removeOfflineOrder(int key) async {
    final box = Hive.box(boxOfflineOrders);
    await box.delete(key);
  }
}
