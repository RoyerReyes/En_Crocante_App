import 'package:dio/dio.dart';
import 'package:encrocante_app/models/usuario_model.dart';
import 'package:encrocante_app/services/user_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio mockDio;
  late UserService userService;

  setUp(() {
    mockDio = MockDio();
    userService = UserService(dioClient: mockDio);
  });

  group('UserService Tests', () {
    test('getUsers returns list of users on 200', () async {
      final usersData = [
        {'id': 1, 'nombre': 'Admin', 'usuario': 'admin', 'rol': 'admin', 'activo': true},
        {'id': 2, 'nombre': 'Mesero', 'usuario': 'mesero', 'rol': 'mesero', 'activo': true},
        {'id': 3, 'nombre': 'Inactivo', 'usuario': 'inactivo', 'rol': 'mesero', 'activo': false}, // Should be filtered out
      ];

      when(() => mockDio.get('/usuarios')).thenAnswer(
        (_) async => Response(
          data: usersData,
          statusCode: 200,
          requestOptions: RequestOptions(path: '/usuarios'),
        ),
      );

      final users = await userService.getUsers();

      expect(users.length, 2);
      expect(users[0].nombre, 'Admin');
      expect(users[1].nombre, 'Mesero');
      verify(() => mockDio.get('/usuarios')).called(1);
    });

    test('getUsers throws Exception on non-200 status', () async {
      when(() => mockDio.get('/usuarios')).thenAnswer(
        (_) async => Response(
          data: {'message': 'Server Error'},
          statusCode: 500,
          requestOptions: RequestOptions(path: '/usuarios'),
        ),
      );

      expect(() => userService.getUsers(), throwsException);
    });

    test('createUser calls post with correct data', () async {
      final newUser = {'id': 10, 'nombre': 'New', 'usuario': 'newuser', 'rol': 'cocinero', 'activo': true};

      when(() => mockDio.post(
            any(),
            data: any(named: 'data'),
          )).thenAnswer(
        (_) async => Response(
          data: newUser,
          statusCode: 201,
          requestOptions: RequestOptions(path: '/auth/register'),
        ),
      );

      final result = await userService.createUser('New', 'newuser', 'pass', 'cocinero');

      expect(result.nombre, 'New');
      verify(() => mockDio.post(
            '/auth/register',
            data: {
              'nombre': 'New',
              'email': 'newuser',
              'password': 'pass',
              'rol': 'cocinero',
            },
          )).called(1);
    });

    test('deleteUser calls delete correct endpoint', () async {
      when(() => mockDio.delete(any())).thenAnswer(
        (_) async => Response(
          data: {},
          statusCode: 204,
          requestOptions: RequestOptions(path: '/usuarios/1'),
        ),
      );

      await userService.deleteUser(1);

      verify(() => mockDio.delete('/usuarios/1')).called(1);
    });
    
    test('Handles DioException correctly', () async {
       when(() => mockDio.get('/usuarios')).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/usuarios'),
          error: 'Connection Timeout',
          type: DioExceptionType.connectionTimeout
        )
      );

      expect(userService.getUsers(), throwsException);
    });
  });
}
