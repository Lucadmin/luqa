import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:luqa/features/auth/domain/auth_user.dart';
import 'package:luqa_api/api.dart' as api;

class StoredMobileSession {
  const StoredMobileSession({
    required this.user,
    required this.accessToken,
    required this.accessExpiresAt,
    required this.refreshToken,
    required this.refreshExpiresAt,
  });

  factory StoredMobileSession.fromCredentials(api.SessionCredentials value) =>
      StoredMobileSession(
        user: AuthUser(
          id: value.user.id,
          email: value.user.email,
          name: value.user.name,
        ),
        accessToken: value.accessToken,
        accessExpiresAt: value.accessExpiresAt,
        refreshToken: value.refreshToken,
        refreshExpiresAt: value.refreshExpiresAt,
      );

  factory StoredMobileSession.fromJson(Map<String, Object?> json) =>
      StoredMobileSession(
        user: AuthUser(
          id: json['userId']! as String,
          email: json['email']! as String,
          name: json['name'] as String?,
        ),
        accessToken: json['accessToken']! as String,
        accessExpiresAt: DateTime.parse(json['accessExpiresAt']! as String),
        refreshToken: json['refreshToken']! as String,
        refreshExpiresAt: DateTime.parse(json['refreshExpiresAt']! as String),
      );

  final AuthUser user;
  final String accessToken;
  final DateTime accessExpiresAt;
  final String refreshToken;
  final DateTime refreshExpiresAt;

  bool refreshIsExpired(DateTime now) => !refreshExpiresAt.isAfter(now);

  /// The contract requires a refresh token of at least 32 characters, so a
  /// stored one below that can never be redeemed. Treating it as a session
  /// would leave the app "signed in" while every request is refused, with no
  /// route back to the sign-in screen.
  bool get hasRedeemableRefreshToken => refreshToken.trim().length >= 32;

  Map<String, Object?> toJson() => {
    'userId': user.id,
    'email': user.email,
    'name': user.name,
    'accessToken': accessToken,
    'accessExpiresAt': accessExpiresAt.toUtc().toIso8601String(),
    'refreshToken': refreshToken,
    'refreshExpiresAt': refreshExpiresAt.toUtc().toIso8601String(),
  };
}

abstract interface class SecureCredentialStore {
  Future<StoredMobileSession?> readSession();

  Future<void> writeSession(StoredMobileSession session);

  Future<void> clearSession();

  Future<String> getOrCreateDeviceId();
}

class FlutterSecureCredentialStore implements SecureCredentialStore {
  FlutterSecureCredentialStore({FlutterSecureStorage? storage})
    : _storage =
          storage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(),
            iOptions: IOSOptions(
              accessibility: KeychainAccessibility.first_unlock_this_device,
            ),
          );

  static const _sessionKey = 'luqa.mobile.session.v1';
  static const _deviceIdKey = 'luqa.mobile.installation.v1';

  final FlutterSecureStorage _storage;

  @override
  Future<StoredMobileSession?> readSession() async {
    final encoded = await _storage.read(key: _sessionKey);
    if (encoded == null) return null;
    try {
      final json = jsonDecode(encoded) as Map<String, Object?>;
      return StoredMobileSession.fromJson(json);
    } on Object {
      await clearSession();
      return null;
    }
  }

  @override
  Future<void> writeSession(StoredMobileSession session) =>
      _storage.write(key: _sessionKey, value: jsonEncode(session.toJson()));

  @override
  Future<void> clearSession() => _storage.delete(key: _sessionKey);

  @override
  Future<String> getOrCreateDeviceId() async {
    final existing = await _storage.read(key: _deviceIdKey);
    if (existing != null && existing.length >= 8) return existing;

    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    final id =
        'install_${bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join()}';
    await _storage.write(key: _deviceIdKey, value: id);
    return id;
  }
}
