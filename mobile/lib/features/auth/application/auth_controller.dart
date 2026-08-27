import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:luqa/app/app_config.dart';
import 'package:luqa/core/network/luqa_api_client.dart';
import 'package:luqa/features/auth/data/secure_credential_store.dart';
import 'package:luqa/features/auth/domain/auth_user.dart';
import 'package:luqa_api/api.dart' as api;

final secureCredentialStoreProvider = Provider<SecureCredentialStore>(
  (ref) => FlutterSecureCredentialStore(),
);

final httpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

final luqaApiProvider = Provider<LuqaApi>((ref) {
  return LuqaApiClient(
    baseUrl: AppConfig.apiBaseUrl,
    credentialStore: ref.watch(secureCredentialStoreProvider),
    httpClient: ref.watch(httpClientProvider),
    requireHttps: AppConfig.isProduction,
    onSessionExpired: () async => ref.invalidate(authControllerProvider),
  );
});

final authControllerProvider = AsyncNotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

class AuthController extends AsyncNotifier<AuthState> {
  late LuqaApi _api;

  @override
  Future<AuthState> build() async {
    _api = ref.watch(luqaApiProvider);
    try {
      final session = await _api.restoreSession();
      return session == null
          ? const AuthState.signedOut()
          : AuthState.signedIn(session.user);
    } on Object {
      return const AuthState.signedOut();
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    state = const AsyncLoading<AuthState>();
    try {
      final session = await _api.signIn(
        email: email,
        password: password,
        deviceName: 'Luqa on ${defaultTargetPlatform.name}',
      );
      state = AsyncData(AuthState.signedIn(session.user));
    } on Object catch (error, stackTrace) {
      state = AsyncError<AuthState>(_friendlyError(error), stackTrace);
    }
  }

  Future<void> signOut() async {
    state = const AsyncLoading<AuthState>();
    await _api.signOut();
    state = const AsyncData(AuthState.signedOut());
  }

  Exception _friendlyError(Object error) {
    if (error is api.ApiException && error.code == 401) {
      return const AuthUiException('The email or password is incorrect.');
    }
    if (error is TimeoutException) {
      return const AuthUiException(
        'The server took too long to respond. Check your connection.',
      );
    }
    return const AuthUiException(
      'Luqa could not sign in. Check the connection and try again.',
    );
  }
}

class AuthUiException implements Exception {
  const AuthUiException(this.message);

  final String message;

  @override
  String toString() => message;
}
