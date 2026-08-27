import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:luqa/core/network/luqa_api_client.dart';
import 'package:luqa/features/auth/data/secure_credential_store.dart';
import 'package:luqa/features/auth/domain/auth_user.dart';

void main() {
  final now = DateTime.utc(2026, 8, 27, 18);

  test('sign in stores the returned device credentials', () async {
    final store = MemoryCredentialStore();
    final client = LuqaApiClient(
      baseUrl: 'https://luqa.example',
      credentialStore: store,
      httpClient: MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/v1/auth/session');
        final body = jsonDecode(request.body) as Map<String, Object?>;
        expect(body['email'], 'luca@example.com');
        expect(body['password'], 'secret-password');
        expect(body['deviceId'], 'install_test');
        return http.Response(
          jsonEncode(_credentialsJson(now: now)),
          201,
          headers: {'content-type': 'application/json'},
        );
      }),
      requireHttps: true,
      now: () => now,
    );

    final session = await client.signIn(
      email: ' luca@example.com ',
      password: 'secret-password',
      deviceName: 'Pixel',
    );

    expect(session.accessToken, 'access-new');
    expect(store.session, same(session));
    expect(store.deviceIdReads, 1);
  });

  test(
    'expired access token is refreshed once for concurrent requests',
    () async {
      final store = MemoryCredentialStore(
        session: _storedSession(
          now: now,
          accessToken: 'access-old',
          accessExpiresAt: now.subtract(const Duration(minutes: 1)),
        ),
      );
      var refreshes = 0;
      final protectedHeaders = <String?>[];
      final client = LuqaApiClient(
        baseUrl: 'https://luqa.example',
        credentialStore: store,
        httpClient: MockClient((request) async {
          if (request.url.path == '/api/v1/auth/refresh') {
            refreshes += 1;
            await Future<void>.delayed(const Duration(milliseconds: 10));
            return http.Response(
              jsonEncode(_credentialsJson(now: now)),
              200,
              headers: {'content-type': 'application/json'},
            );
          }

          protectedHeaders.add(request.headers['authorization']);
          if (request.url.path == '/api/v1/categories') {
            return http.Response(
              jsonEncode({'categories': <Object>[]}),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          if (request.url.path == '/api/v1/time-entries') {
            return http.Response(
              jsonEncode({'entries': <Object>[]}),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          return http.Response('Not found', 404);
        }),
        requireHttps: true,
        now: () => now,
      );

      await Future.wait([
        client.listCategories(),
        client.listTimeEntries(
          DateTime.utc(2026, 8, 27),
          DateTime.utc(2026, 8, 28),
        ),
      ]);

      expect(refreshes, 1);
      expect(protectedHeaders, ['Bearer access-new', 'Bearer access-new']);
      expect(store.session?.refreshToken, 'refresh-new');
    },
  );

  test('rejected refresh clears the local session', () async {
    final store = MemoryCredentialStore(
      session: _storedSession(
        now: now,
        accessExpiresAt: now.subtract(const Duration(minutes: 1)),
      ),
    );
    var expirationCallbacks = 0;
    final client = LuqaApiClient(
      baseUrl: 'https://luqa.example',
      credentialStore: store,
      httpClient: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'error': {'code': 'UNAUTHORIZED', 'message': 'Expired'},
          }),
          401,
          headers: {'content-type': 'application/json'},
        ),
      ),
      requireHttps: true,
      now: () => now,
      onSessionExpired: () async => expirationCallbacks += 1,
    );

    await expectLater(
      client.listCategories(),
      throwsA(isA<SessionExpiredException>()),
    );
    expect(store.session, isNull);
    expect(store.clears, 1);
    expect(expirationCallbacks, 1);
  });
}

Map<String, Object?> _credentialsJson({required DateTime now}) => {
  'user': {'id': 'user-1', 'email': 'luca@example.com', 'name': 'Luca'},
  'accessToken': 'access-new',
  'accessExpiresAt': now.add(const Duration(minutes: 15)).toIso8601String(),
  'refreshToken': 'refresh-new',
  'refreshExpiresAt': now.add(const Duration(days: 30)).toIso8601String(),
};

StoredMobileSession _storedSession({
  required DateTime now,
  String accessToken = 'access-old',
  DateTime? accessExpiresAt,
}) => StoredMobileSession(
  user: const AuthUser(id: 'user-1', email: 'luca@example.com', name: 'Luca'),
  accessToken: accessToken,
  accessExpiresAt: accessExpiresAt ?? now.add(const Duration(minutes: 15)),
  refreshToken: 'refresh-old',
  refreshExpiresAt: now.add(const Duration(days: 30)),
);

class MemoryCredentialStore implements SecureCredentialStore {
  MemoryCredentialStore({this.session});

  StoredMobileSession? session;
  int clears = 0;
  int deviceIdReads = 0;

  @override
  Future<void> clearSession() async {
    clears += 1;
    session = null;
  }

  @override
  Future<String> getOrCreateDeviceId() async {
    deviceIdReads += 1;
    return 'install_test';
  }

  @override
  Future<StoredMobileSession?> readSession() async => session;

  @override
  Future<void> writeSession(StoredMobileSession value) async {
    session = value;
  }
}
