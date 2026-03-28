import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dio/dio.dart';
import 'package:encrocante_app/services/report_service.dart';

class MockDio extends Mock implements Dio {}
class MockResponse extends Mock implements Response {}

void main() {
  group('ReportService Tests', () {
    late ReportService service;
    late MockDio mockDio;

    setUp(() {
       mockDio = MockDio();
       service = ReportService(dio: mockDio);
    });

    test('getSystemStats returns map on success', () async {
       final mockResponse = MockResponse();
       final expectedData = {'total_ordenes': 100, 'tiempo_actividad': 'Online', 'rendimiento': '95%'};
       
       when(() => mockResponse.data).thenReturn(expectedData);
       when(() => mockDio.get('/reportes/stats')).thenAnswer((_) async => mockResponse);

       final result = await service.getSystemStats();
       
       expect(result, expectedData);
       verify(() => mockDio.get('/reportes/stats')).called(1);
    });

    test('getSystemStats returns defaults on error', () async {
       when(() => mockDio.get('/reportes/stats')).thenThrow(DioException(requestOptions: RequestOptions(path: '')));

       final result = await service.getSystemStats();
       
       expect(result['total_ordenes'], 0);
       expect(result['rendimiento'], '0.0%');
       expect(result['tiempo_actividad'], 'Desconocido');
    });
  });
}
