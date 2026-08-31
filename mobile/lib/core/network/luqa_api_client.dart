import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:luqa/features/auth/data/secure_credential_store.dart';
import 'package:luqa_api/api.dart' as api;

class SessionExpiredException implements Exception {
  const SessionExpiredException();
}

abstract interface class LuqaApi {
  Future<StoredMobileSession?> restoreSession();

  Future<StoredMobileSession> signIn({
    required String email,
    required String password,
    required String deviceName,
  });

  Future<void> signOut();

  Future<List<api.Category>> listCategories();

  Future<api.Category> createCategory(String name, {String? id});

  Future<List<api.TimeEntry>> listTimeEntries(DateTime from, DateTime to);

  Future<api.TimeEntry> createTimeEntry({
    String? id,
    required String description,
    required String? categoryId,
    required DateTime start,
    required DateTime? end,
  });

  Future<api.TimeEntry> updateTimeEntry(
    String id,
    api.UpdateTimeEntryRequest patch,
  );

  Future<void> deleteTimeEntry(String id);

  Future<List<api.SleepEntry>> listSleepEntries(DateTime from, DateTime to);

  Future<api.HealthSyncResponse> pushHealthSync(api.HealthSyncRequest request);

  Future<List<api.HealthSyncState>> healthSyncStates();
}

class LuqaApiClient implements LuqaApi {
  LuqaApiClient({
    required String baseUrl,
    required this.credentialStore,
    required this.httpClient,
    required bool requireHttps,
    DateTime Function()? now,
    this.onSessionExpired,
  }) : _now = now ?? DateTime.now,
       _basePath = _resolveBasePath(baseUrl, requireHttps: requireHttps) {
    _bearerAuth.accessToken = () => _session?.accessToken ?? '';
    _authenticatedClient = _client(authentication: _bearerAuth);
    _unauthenticatedClient = _client();
  }

  static const _requestTimeout = Duration(seconds: 15);
  static const _syncTimeout = Duration(seconds: 60);
  static const _refreshLeeway = Duration(seconds: 30);

  final SecureCredentialStore credentialStore;
  final http.Client httpClient;
  final DateTime Function() _now;
  final String _basePath;
  final api.HttpBearerAuth _bearerAuth = api.HttpBearerAuth();
  final Future<void> Function()? onSessionExpired;

  late final api.ApiClient _authenticatedClient;
  late final api.ApiClient _unauthenticatedClient;
  StoredMobileSession? _session;
  Future<StoredMobileSession?>? _restoring;
  Future<StoredMobileSession>? _refreshing;
  bool _restored = false;

  static String _resolveBasePath(String baseUrl, {required bool requireHttps}) {
    final normalized = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final uri = Uri.tryParse(normalized);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      throw ArgumentError.value(baseUrl, 'baseUrl', 'Expected an absolute URL');
    }
    if (requireHttps && uri.scheme != 'https') {
      throw StateError('LUQA_API_BASE_URL must use HTTPS in production.');
    }
    return '$normalized/api/v1';
  }

  api.ApiClient _client({api.Authentication? authentication}) {
    final client = api.ApiClient(
      basePath: _basePath,
      authentication: authentication,
    )..client = httpClient;
    client.addDefaultHeader('Accept', 'application/json');
    return client;
  }

  @override
  Future<StoredMobileSession?> restoreSession() {
    if (_restored) return Future.value(_session);
    final existing = _restoring;
    if (existing != null) return existing;

    final future = _performRestore();
    _restoring = future;
    return future.whenComplete(() {
      if (identical(_restoring, future)) _restoring = null;
    });
  }

  Future<StoredMobileSession?> _performRestore() async {
    final stored = await credentialStore.readSession();
    if (stored == null) {
      _restored = true;
      return null;
    }
    if (stored.refreshIsExpired(_now()) || !stored.hasRedeemableRefreshToken) {
      await credentialStore.clearSession();
      _restored = true;
      return null;
    }
    _session = stored;
    _restored = true;
    return stored;
  }

  @override
  Future<StoredMobileSession> signIn({
    required String email,
    required String password,
    required String deviceName,
  }) async {
    final deviceId = await credentialStore.getOrCreateDeviceId();
    final response = await api.AuthenticationApi(_unauthenticatedClient)
        .createMobileSession(
          api.CreateSessionRequest(
            email: email.trim(),
            password: password,
            deviceId: deviceId,
            deviceName: api.Optional.present(deviceName),
          ),
        )
        .timeout(_requestTimeout);
    if (response == null) throw api.ApiException(500, 'Empty response');

    final stored = StoredMobileSession.fromCredentials(response);
    await credentialStore.writeSession(stored);
    _session = stored;
    _restored = true;
    return stored;
  }

  @override
  Future<void> signOut() async {
    try {
      await _authorized<void>(
        (client) => api.AuthenticationApi(
          client,
        ).revokeMobileSession().timeout(_requestTimeout),
      );
    } on Object {
      // Local sign-out must remain possible when the device is offline. The
      // unreachable server session still expires and can be revoked later.
    } finally {
      _session = null;
      _restored = true;
      await credentialStore.clearSession();
    }
  }

  @override
  Future<List<api.Category>> listCategories() => _authorized((client) async {
    final response = await api.CategoriesApi(
      client,
    ).listCategories().timeout(_requestTimeout);
    return response?.categories ?? const [];
  });

  @override
  Future<api.Category> createCategory(String name, {String? id}) =>
      _authorized((client) async {
        final response = await api.CategoriesApi(client)
            .createCategory(
              api.CreateCategoryRequest(
                name: name,
                id: id == null
                    ? const api.Optional.absent()
                    : api.Optional.present(id),
              ),
            )
            .timeout(_requestTimeout);
        if (response == null) throw api.ApiException(500, 'Empty response');
        return response.category;
      });

  @override
  Future<List<api.TimeEntry>> listTimeEntries(DateTime from, DateTime to) =>
      _authorized((client) async {
        final response = await api.TimeEntriesApi(
          client,
        ).listTimeEntries(from.toUtc(), to.toUtc()).timeout(_requestTimeout);
        return response?.entries ?? const [];
      });

  @override
  Future<api.TimeEntry> createTimeEntry({
    String? id,
    required String description,
    required String? categoryId,
    required DateTime start,
    required DateTime? end,
  }) => _authorized((client) async {
    final response = await api.TimeEntriesApi(client)
        .createTimeEntry(
          api.CreateTimeEntryRequest(
            id: id == null
                ? const api.Optional.absent()
                : api.Optional.present(id),
            startTime: start.toUtc(),
            description: api.Optional.present(description),
            categoryId: api.Optional.present(categoryId),
            endTime: api.Optional.present(end?.toUtc()),
          ),
        )
        .timeout(_requestTimeout);
    if (response == null) throw api.ApiException(500, 'Empty response');
    return response.entry;
  });

  @override
  Future<api.TimeEntry> updateTimeEntry(
    String id,
    api.UpdateTimeEntryRequest patch,
  ) => _authorized((client) async {
    final response = await api.TimeEntriesApi(
      client,
    ).updateTimeEntry(id, patch).timeout(_requestTimeout);
    if (response == null) throw api.ApiException(500, 'Empty response');
    return response.entry;
  });

  @override
  Future<void> deleteTimeEntry(String id) => _authorized(
    (client) =>
        api.TimeEntriesApi(client).deleteTimeEntry(id).timeout(_requestTimeout),
  );

  @override
  Future<List<api.SleepEntry>> listSleepEntries(DateTime from, DateTime to) =>
      _authorized((client) async {
        final response = await api.SleepApi(
          client,
        ).listSleepEntries(from.toUtc(), to.toUtc()).timeout(_requestTimeout);
        return response?.entries ?? const [];
      });

  @override
  Future<api.HealthSyncResponse> pushHealthSync(
    api.HealthSyncRequest request,
  ) => _authorized((client) async {
    // A backfill carries a lot more than a routine push, so this gets a
    // longer ceiling than the standard request timeout.
    final response = await api.HealthApi(
      client,
    ).pushHealthSync(request).timeout(_syncTimeout);
    if (response == null) throw api.ApiException(500, 'Empty response');
    return response;
  });

  @override
  Future<List<api.HealthSyncState>> healthSyncStates() =>
      _authorized((client) async {
        final response = await api.HealthApi(
          client,
        ).getHealthSyncState().timeout(_requestTimeout);
        return response?.states ?? const [];
      });

  Future<T> _authorized<T>(
    Future<T> Function(api.ApiClient client) request,
  ) async {
    await _ensureFreshAccess();
    try {
      return await request(_authenticatedClient);
    } on api.ApiException catch (error) {
      if (error.code != 401) rethrow;
      await _refreshSession();
      return request(_authenticatedClient);
    }
  }

  Future<void> _ensureFreshAccess() async {
    final session = await restoreSession();
    if (session == null) throw const SessionExpiredException();
    if (session.accessExpiresAt.isAfter(_now().add(_refreshLeeway))) return;
    await _refreshSession();
  }

  Future<StoredMobileSession> _refreshSession() {
    final existing = _refreshing;
    if (existing != null) return existing;

    final future = _performRefresh();
    _refreshing = future;
    return future.whenComplete(() {
      if (identical(_refreshing, future)) _refreshing = null;
    });
  }

  Future<StoredMobileSession> _performRefresh() async {
    final session = _session ?? await restoreSession();
    if (session == null || session.refreshIsExpired(_now())) {
      return _expireSession();
    }
    try {
      final response = await api.AuthenticationApi(_unauthenticatedClient)
          .refreshMobileSession(
            api.RefreshSessionRequest(refreshToken: session.refreshToken),
          )
          .timeout(_requestTimeout);
      if (response == null) {
        throw api.ApiException(500, 'Empty response');
      }
      final stored = StoredMobileSession.fromCredentials(response);
      await credentialStore.writeSession(stored);
      _session = stored;
      return stored;
    } on api.ApiException catch (error) {
      // Any genuine refusal of the refresh token leaves the session unusable,
      // not just a 401: propagating it would strand every screen with no way
      // back, while expiring sends the user to sign-in, which actually fixes
      // it.
      //
      // Transport failures must not take that path. The generated client
      // reports them as a synthetic 400 carrying the real cause, so without
      // the inner-exception check a tunnel or a dropped port forward would
      // silently sign the user out. Server faults are not our credential's
      // fault either.
      if (error.innerException != null || error.code >= 500) rethrow;
      return _expireSession();
    }
  }

  Future<Never> _expireSession() async {
    _session = null;
    _restored = true;
    await credentialStore.clearSession();
    await onSessionExpired?.call();
    throw const SessionExpiredException();
  }
}
