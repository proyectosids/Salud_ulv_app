import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:salud_ulv_app/src/core/data/source/network/authenticated_headers.dart';
import 'package:salud_ulv_app/src/core/data/source/network/anthro_controller.dart';
import 'package:salud_ulv_app/src/core/data/source/network/auth_controller.dart';
import 'package:salud_ulv_app/src/core/data/source/network/exercise_controller.dart';
import 'package:salud_ulv_app/src/core/data/source/network/group_controller.dart';
import 'package:salud_ulv_app/src/core/models/exercise_categories.dart';
import 'package:salud_ulv_app/src/core/models/exercises.dart';
import 'package:salud_ulv_app/src/core/models/anthropometrics.dart';
import 'package:salud_ulv_app/src/core/models/user.dart';
import 'package:salud_ulv_app/src/core/repositories/services/token_storage_repo.dart';

class _MemoryTokenStorage implements ITokenStorageRepo {
  String? token;

  _MemoryTokenStorage(this.token);

  @override
  Future<void> deleteToken() async => token = null;

  @override
  Future<String?> getOTPToken() async => null;

  @override
  Future<String?> getUserToken() async => token;

  @override
  Future<void> saveOTPToken(String token) async {}

  @override
  Future<void> saveUserToken(String token) async => this.token = token;
}

Uri _testApiUri(String path) => Uri.parse('https://api.example.test$path');

void main() {
  group('authentication requests', () {
    final user = User(
      userUUID: 'B0EEBC99-9C0B-4EF8-BB6D-6BB9BD380A11',
      userCode: '123456',
      firstname: 'Test',
      surname: 'User',
      lastname: '',
      email: 'member@example.test',
      createdAt: DateTime.utc(2026, 10, 8),
    );

    test('registration accepts a created response', () async {
      final controller = AuthHTTPController(
        apiUri: _testApiUri,
        client: MockClient((request) async {
          expect(request.url.path, '/auth/register');
          return http.Response('{}', 201);
        }),
      );

      expect(
        await controller.registerMember(user, 'secure-password', 1, 'receipt'),
        isTrue,
      );
    });

    test('registration explains an existing account conflict', () async {
      final controller = AuthHTTPController(
        apiUri: _testApiUri,
        client: MockClient((_) async => http.Response('{}', 409)),
      );

      expect(
        () => controller.registerMember(user, 'secure-password', 1, 'receipt'),
        throwsA(
          isA<AuthRequestException>().having(
            (error) => error.message,
            'message',
            contains('Ya existe una cuenta'),
          ),
        ),
      );
    });

    test('login maps unauthorized responses to a useful message', () async {
      final controller = AuthHTTPController(
        apiUri: _testApiUri,
        client: MockClient((_) async => http.Response('{}', 401)),
      );

      expect(
        () => controller.loginWithEmailOrCode('member@example.test', 'wrong'),
        throwsA(
          isA<AuthRequestException>().having(
            (error) => error.message,
            'message',
            'Usuario o contraseña incorrectos.',
          ),
        ),
      );
    });
  });

  group('authenticated requests', () {
    test('builds a bearer header from secure token storage', () async {
      final provider = AuthenticatedHeadersProvider(
        tokenStorage: _MemoryTokenStorage('session-token'),
      );

      expect(await provider.json(), {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer session-token',
      });
    });

    test('fails before sending a request when the token is missing', () async {
      final provider = AuthenticatedHeadersProvider(
        tokenStorage: _MemoryTokenStorage(null),
      );

      expect(provider.json(), throwsA(isA<AuthenticationRequiredException>()));
    });

    test('group requests include the bearer token', () async {
      late http.Request captured;
      final controller = GroupController(
        tokenStorage: _MemoryTokenStorage('group-token'),
        apiUri: _testApiUri,
        client: MockClient((request) async {
          captured = request;
          return http.Response(jsonEncode({'data': <Object>[]}), 200);
        }),
      );

      expect(await controller.getGroupsList(1), isEmpty);
      expect(captured.headers['authorization'], 'Bearer group-token');
      expect(captured.url.path, '/groups/get/1');
    });

    test(
      'group joins use the authenticated identity, not a body UUID',
      () async {
        late http.Request captured;
        final controller = GroupController(
          tokenStorage: _MemoryTokenStorage('group-token'),
          apiUri: _testApiUri,
          client: MockClient((request) async {
            captured = request;
            return http.Response('{}', 201);
          }),
        );

        await controller.joinGroup('B0EEBC99-9C0B-4EF8-BB6D-6BB9BD380A11', 7);

        expect(captured.headers['authorization'], 'Bearer group-token');
        expect(captured.url.path, '/groups/add');
        expect(jsonDecode(captured.body), {'groupID': 7});
      },
    );

    test('anthropometric writes include auth and accept any 2xx', () async {
      late http.Request captured;
      final controller = AnthroController(
        tokenStorage: _MemoryTokenStorage('anthro-token'),
        apiUri: _testApiUri,
        client: MockClient((request) async {
          captured = request;
          return http.Response('{}', 201);
        }),
      );

      await controller.send(
        Anthropometrics(
          anthropometricID: 'A3EEBC99-9C0B-4EF8-BB6D-6BB9BD380A11',
          userUUID: 'B0EEBC99-9C0B-4EF8-BB6D-6BB9BD380A11',
          height: 170,
          weight: 70,
          smm: 30,
          fatMass: 15,
          bodyFatPercentage: 20,
          bmi: 24.2,
          whr: 0.9,
          registeredAt: DateTime.utc(2026, 10, 7),
        ),
      );

      expect(captured.headers['authorization'], 'Bearer anthro-token');
      expect(captured.url.path, '/anthropometric/save');
      expect(
        (jsonDecode(captured.body) as Map<String, dynamic>),
        isNot(contains('userUUID')),
      );
    });
  });

  group('exercise synchronization contract', () {
    final registeredAt = DateTime.utc(2026, 10, 7, 12);

    final activities = <(IPhysicalActivity, int)>[
      (
        Walk(
          activityID: 'A0EEBC99-9C0B-4EF8-BB6D-6BB9BD380A11',
          userUUID: 'B0EEBC99-9C0B-4EF8-BB6D-6BB9BD380A11',
          category: ExerciseCategoryIds.walk,
          duration: const Duration(minutes: 1),
          caloriesBurned: 10,
          registeredAt: registeredAt,
          distance: 100,
          avgPace: 600,
          elevationGain: 1,
          avgCadence: 100,
          steps: 120,
          avgSteps: 120,
        ),
        ExerciseCategoryIds.walk,
      ),
      (
        Running(
          activityID: 'A1EEBC99-9C0B-4EF8-BB6D-6BB9BD380A11',
          userUUID: 'B0EEBC99-9C0B-4EF8-BB6D-6BB9BD380A11',
          category: ExerciseCategoryIds.running,
          duration: const Duration(minutes: 1),
          caloriesBurned: 15,
          registeredAt: registeredAt,
          distance: 200,
          avgPace: 300,
          elevationGain: 2,
          avgCadence: 160,
          speed: 3.3,
          avgSpeed: 3.1,
        ),
        ExerciseCategoryIds.running,
      ),
      (
        Cycling(
          activityID: 'A2EEBC99-9C0B-4EF8-BB6D-6BB9BD380A11',
          userUUID: 'B0EEBC99-9C0B-4EF8-BB6D-6BB9BD380A11',
          category: ExerciseCategoryIds.cycling,
          duration: const Duration(minutes: 1),
          caloriesBurned: 12,
          registeredAt: registeredAt,
          distance: 300,
          avgPace: 200,
          elevationGain: 3,
          avgCadence: 80,
          speed: 5,
          avgSpeed: 4.8,
          avgElevation: 2,
        ),
        ExerciseCategoryIds.cycling,
      ),
    ];

    for (final (activity, expectedCategory) in activities) {
      test(
        'serializes category $expectedCategory with authentication',
        () async {
          late http.Request captured;
          final controller = ExerciseController(
            tokenStorage: _MemoryTokenStorage('exercise-token'),
            apiUri: _testApiUri,
            client: MockClient((request) async {
              captured = request;
              return http.Response('{}', 200);
            }),
          );

          await controller.send(activity);

          final body = jsonDecode(captured.body) as Map<String, dynamic>;
          expect(captured.headers['authorization'], 'Bearer exercise-token');
          expect(captured.url.path, '/exercise/save');
          expect(body['categoryID'], expectedCategory);
          expect(body, isNot(contains('userUUID')));
        },
      );
    }
  });
}
