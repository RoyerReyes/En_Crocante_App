import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb; 
import 'dart:io' show Platform; 
import 'secure_storage_service.dart';
import 'logging_interceptor.dart';
import '../constants/api_constants.dart'; // Added

Dio? _dioInstance;

Dio get dio {
  _dioInstance ??= _createDioClient();
  return _dioInstance!;
}

Dio _createDioClient() {
  final baseUrl = ApiConstants.baseUrl;
  print("🌐 Dio Base URL: $baseUrl");

  final dio = Dio(BaseOptions(
    baseUrl: baseUrl, 
    connectTimeout: const Duration(seconds: 15), 
    receiveTimeout: const Duration(seconds: 10),
  ));

  dio.interceptors.add(LoggingInterceptor());
  
  // Retry Logic Interceptor (Inline for now, could be extracted)
  dio.interceptors.add(InterceptorsWrapper(
    onError: (DioException e, handler) async {
      // Retry Logic
      int retryCount = e.requestOptions.extra['retryCount'] ?? 0;
      const int maxRetries = 3;

      if (retryCount < maxRetries && _isRetryable(e)) {
        retryCount++;
        e.requestOptions.extra['retryCount'] = retryCount;
        
        final delay = Duration(seconds: 1 * retryCount);
        print("⚠️ Reintentando petición (${retryCount}/$maxRetries) en ${delay.inSeconds}s...");
        
        await Future.delayed(delay);

        try {
          final response = await dio.fetch(e.requestOptions);
          return handler.resolve(response);
        } catch (retryError) {
          return handler.next(e); 
        }
      }

      return handler.next(e);
    },
  ));

  return dio;
}

bool _isRetryable(DioException e) {
  return e.type == DioExceptionType.connectionTimeout ||
      e.type == DioExceptionType.receiveTimeout ||
      e.type == DioExceptionType.sendTimeout ||
      e.type == DioExceptionType.connectionError ||
      (e.type == DioExceptionType.unknown && e.message?.contains('SocketException') == true);
}
