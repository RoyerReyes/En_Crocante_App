import 'package:dio/dio.dart';
import 'package:encrocante_app/services/secure_storage_service.dart';

class LoggingInterceptor extends Interceptor {
  final SecureStorageService _storageService = SecureStorageService();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // 1. Inyectar Token (Auth Logic)
    try {
      String? token = await _storageService.getToken();
      if (token != null) {
        options.headers["Authorization"] = "Bearer $token";
      }
    } catch (e) {
      print("⚠️ Error leyendo token: $e");
    }

    // 2. Logging
    print("🚀 [REQ] ${options.method} ${options.path}");
    if (options.data != null) {
      // print("   📦 Body: ${options.data}"); // Descomentar para debug profundo
    }

    return handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // Logging Response
    print("✅ [RES] ${response.statusCode} ${response.requestOptions.path}");
    return handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Logging Error
    print("❌ [ERR] ${err.requestOptions.path}");
    print("   Msg: ${err.message}");
    if (err.response != null) {
      print("   Status: ${err.response?.statusCode}");
      print("   Data: ${err.response?.data}");
    }

    return handler.next(err);
  }
}
