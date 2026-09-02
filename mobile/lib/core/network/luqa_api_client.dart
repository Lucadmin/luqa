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
    List<String> personIds = const [],
  });

  Future<api.TimeEntry> updateTimeEntry(
    String id,
    api.UpdateTimeEntryRequest patch,
  );

  Future<void> deleteTimeEntry(String id);

  Future<List<api.SleepEntry>> listSleepEntries(DateTime from, DateTime to);

  Future<api.HealthSyncResponse> pushHealthSync(api.HealthSyncRequest request);

  Future<List<api.HealthSyncState>> healthSyncStates();

  Future<api.GymOverview> getGymOverview({int limit = 30});

  Future<api.GymSession> createGymSession(api.CreateGymSessionRequest request);

  Future<api.GymSession> getGymSession(String id);

  Future<api.GymSession> updateGymSession(
    String id,
    api.UpdateGymSessionRequest request,
  );

  Future<api.GymSessionListResponse> listGymSessions({
    String? cursor,
    int limit = 20,
  });

  Future<api.GymExerciseHistory> getGymExerciseHistory(
    String exerciseId, {
    String? locationId,
    String? beforeSessionId,
  });

  Future<void> deleteGymSession(String id);

  /// Returns the exercise as it now stands, plus the id it was merged into
  /// when the new name already belonged to another exercise.
  Future<api.GymExerciseUpdateResponse> updateGymExercise(
    String id,
    api.UpdateGymExerciseRequest request,
  );

  /// Removes the exercise, or archives it when workouts still reference it.
  Future<api.DeleteGymExerciseResponse> deleteGymExercise(String id);

  Future<api.GymExercise> mergeGymExercise(
    String sourceExerciseId,
    String targetExerciseId,
  );

  Future<api.GymLocation> createGymLocation(
    api.CreateGymLocationRequest request,
  );

  Future<api.GymLocation> updateGymLocation(
    String id,
    api.UpdateGymLocationRequest request,
  );

  Future<api.MoneyOverview> getMoneyOverview();

  Future<api.ExpenseListResponse> listExpenses({
    String? personId,
    String? groupId,
    String? cursor,
    int limit = 20,
  });

  Future<api.Expense> createExpense(api.CreateExpenseRequest request);

  Future<api.Expense> updateExpense(
    String id,
    api.UpdateExpenseRequest request,
  );

  Future<void> deleteExpense(String id);

  Future<api.PersonLedger> getPersonLedger(String personId);

  Future<api.Person> createPerson(api.CreatePersonRequest request);

  Future<api.Person> updatePerson(String id, api.UpdatePersonRequest request);

  Future<void> deletePerson(String id);

  // The People contract. Every write here answers with the whole person
  // rather than the child it touched: one row is one profile, so the caller
  // replaces what it holds instead of splicing a note into it.

  Future<List<api.Person>> listPeople();

  Future<api.Person> markPersonSeen(String id, api.MarkSeenRequest request);

  Future<api.Person> addPersonNote(
    String personId,
    api.CreatePersonNoteRequest request,
  );

  Future<api.Person> updatePersonNote(
    String personId,
    String noteId,
    api.UpdatePersonNoteRequest request,
  );

  Future<api.Person> deletePersonNote(String personId, String noteId);

  Future<api.Person> addPersonGift(
    String personId,
    api.CreatePersonGiftRequest request,
  );

  Future<api.Person> updatePersonGift(
    String personId,
    String giftId,
    api.UpdatePersonGiftRequest request,
  );

  Future<api.Person> deletePersonGift(String personId, String giftId);

  Future<api.Person> addPersonPlace(
    String personId,
    api.CreatePersonPlaceRequest request,
  );

  Future<api.Person> deletePersonPlace(String personId, String placeId);

  /// The cities a typed name might mean, so the owner can say which one.
  /// Cached server-side, which is what makes calling it per keystroke sane.
  Future<List<api.CityCandidate>> searchCities(String query);

  /// Resolves cities that have no point yet — the ones that were typed rather
  /// than chosen. Bounded per call; `remaining` says whether it is worth
  /// asking again.
  Future<api.GeocodeResponse> geocodePendingPlaces();

  Future<api.PersonGroup> createGroup(api.CreateGroupRequest request);

  Future<api.PersonGroup> updateGroup(
    String id,
    api.UpdateGroupRequest request,
  );

  Future<void> deleteGroup(String id);

  Future<api.Settlement> createSettlement(
    api.CreateSettlementRequest request,
  );

  Future<void> deleteSettlement(String id);

  Future<List<api.Habit>> listHabits();

  Future<api.Habit> createHabit(api.CreateHabitRequest request);

  Future<api.Habit> updateHabit(String id, api.UpdateHabitRequest request);

  Future<void> archiveHabit(String id);

  Future<List<api.Habit>> reorderHabits(List<String> ids);

  /// A day's progress as this device resolved it, rather than an action to
  /// replay. Sending the numbers is what makes a queued check-in safe to
  /// retry.
  Future<api.HabitLog> putHabitLog(
    String habitId,
    String date,
    api.PutHabitLogRequest request,
  );

  /// Everything that changed since the cursors this device holds.
  Future<api.SyncResponse> syncChanges({
    String? collections,
    int? limit,
    Map<String, String> cursors = const {},
  });
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

  /// Health pushes and sync pages both carry far more than an ordinary
  /// request — and a first sync walks the whole history — so they get longer
  /// before they are called dead.
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
    List<String> personIds = const [],
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
            personIds: api.Optional.present(personIds),
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

  @override
  Future<api.GymOverview> getGymOverview({int limit = 30}) =>
      _authorized((client) async {
        final response = await api.GymApi(
          client,
        ).getGymOverview(limit: limit).timeout(_requestTimeout);
        if (response == null) throw api.ApiException(500, 'Empty response');
        return response.overview;
      });

  @override
  Future<api.GymSession> createGymSession(
    api.CreateGymSessionRequest request,
  ) => _authorized((client) async {
    final response = await api.GymApi(
      client,
    ).createGymSession(request).timeout(_requestTimeout);
    if (response == null) throw api.ApiException(500, 'Empty response');
    return response.session;
  });

  @override
  Future<api.GymSession> getGymSession(String id) =>
      _authorized((client) async {
        final response = await api.GymApi(
          client,
        ).getGymSession(id).timeout(_requestTimeout);
        if (response == null) throw api.ApiException(500, 'Empty response');
        return response.session;
      });

  @override
  Future<api.GymSession> updateGymSession(
    String id,
    api.UpdateGymSessionRequest request,
  ) => _authorized((client) async {
    final response = await api.GymApi(
      client,
    ).updateGymSession(id, request).timeout(_requestTimeout);
    if (response == null) throw api.ApiException(500, 'Empty response');
    return response.session;
  });

  @override
  Future<api.GymSessionListResponse> listGymSessions({
    String? cursor,
    int limit = 20,
  }) => _authorized((client) async {
    final response = await api.GymApi(
      client,
    ).listGymSessions(cursor: cursor, limit: limit).timeout(_requestTimeout);
    if (response == null) throw api.ApiException(500, 'Empty response');
    return response;
  });

  @override
  Future<api.GymExerciseHistory> getGymExerciseHistory(
    String exerciseId, {
    String? locationId,
    String? beforeSessionId,
  }) => _authorized((client) async {
    final response = await api.GymApi(client)
        .getGymExerciseHistory(
          exerciseId,
          locationId: locationId,
          beforeSessionId: beforeSessionId,
        )
        .timeout(_requestTimeout);
    if (response == null) throw api.ApiException(500, 'Empty response');
    return response.history;
  });

  @override
  Future<void> deleteGymSession(String id) => _authorized(
    (client) => api.GymApi(client).deleteGymSession(id).timeout(_requestTimeout),
  );

  @override
  Future<api.GymExerciseUpdateResponse> updateGymExercise(
    String id,
    api.UpdateGymExerciseRequest request,
  ) => _authorized((client) async {
    final response = await api.GymApi(
      client,
    ).updateGymExercise(id, request).timeout(_requestTimeout);
    if (response == null) throw api.ApiException(500, 'Empty response');
    return response;
  });

  @override
  Future<api.DeleteGymExerciseResponse> deleteGymExercise(String id) =>
      _authorized((client) async {
        final response = await api.GymApi(
          client,
        ).deleteGymExercise(id).timeout(_requestTimeout);
        if (response == null) throw api.ApiException(500, 'Empty response');
        return response;
      });

  @override
  Future<api.GymExercise> mergeGymExercise(
    String sourceExerciseId,
    String targetExerciseId,
  ) => _authorized((client) async {
    final response = await api.GymApi(client)
        .mergeGymExercise(
          sourceExerciseId,
          api.MergeGymExerciseRequest(targetExerciseId: targetExerciseId),
        )
        .timeout(_requestTimeout);
    if (response == null) throw api.ApiException(500, 'Empty response');
    return response.exercise;
  });

  @override
  Future<api.GymLocation> createGymLocation(
    api.CreateGymLocationRequest request,
  ) => _authorized((client) async {
    final response = await api.GymApi(
      client,
    ).createGymLocation(request).timeout(_requestTimeout);
    if (response == null) throw api.ApiException(500, 'Empty response');
    return response.location;
  });

  @override
  Future<api.GymLocation> updateGymLocation(
    String id,
    api.UpdateGymLocationRequest request,
  ) => _authorized((client) async {
    final response = await api.GymApi(
      client,
    ).updateGymLocation(id, request).timeout(_requestTimeout);
    if (response == null) throw api.ApiException(500, 'Empty response');
    return response.location;
  });

  @override
  Future<List<api.Habit>> listHabits() => _authorized((client) async {
    final response = await api.HabitsApi(
      client,
    ).listHabits().timeout(_requestTimeout);
    if (response == null) throw api.ApiException(500, 'Empty response');
    return response.habits;
  });

  @override
  Future<api.Habit> createHabit(api.CreateHabitRequest request) =>
      _authorized((client) async {
        final response = await api.HabitsApi(
          client,
        ).createHabit(request).timeout(_requestTimeout);
        if (response == null) throw api.ApiException(500, 'Empty response');
        return response.habit;
      });

  @override
  Future<api.Habit> updateHabit(String id, api.UpdateHabitRequest request) =>
      _authorized((client) async {
        final response = await api.HabitsApi(
          client,
        ).updateHabit(id, request).timeout(_requestTimeout);
        if (response == null) throw api.ApiException(500, 'Empty response');
        return response.habit;
      });

  @override
  Future<void> archiveHabit(String id) => _authorized((client) async {
    await api.HabitsApi(client).archiveHabit(id).timeout(_requestTimeout);
  });

  @override
  Future<List<api.Habit>> reorderHabits(List<String> ids) =>
      _authorized((client) async {
        final response = await api.HabitsApi(client)
            .reorderHabits(api.ReorderHabitsRequest(ids: ids))
            .timeout(_requestTimeout);
        if (response == null) throw api.ApiException(500, 'Empty response');
        return response.habits;
      });

  @override
  Future<api.HabitLog> putHabitLog(
    String habitId,
    String date,
    api.PutHabitLogRequest request,
  ) => _authorized((client) async {
    final response = await api.HabitsApi(
      client,
    ).putHabitLog(habitId, date, request).timeout(_requestTimeout);
    if (response == null) throw api.ApiException(500, 'Empty response');
    return response.log;
  });

  @override
  Future<api.SyncResponse> syncChanges({
    String? collections,
    int? limit,
    Map<String, String> cursors = const {},
  }) => _authorized((client) async {
    final response = await api.SyncApi(client)
        .syncChanges(
          collections: collections,
          limit: limit,
          cursorPeriodCategories: cursors['categories'],
          cursorPeriodPeople: cursors['people'],
          cursorPeriodGroups: cursors['groups'],
          cursorPeriodGymLocations: cursors['gymLocations'],
          cursorPeriodExercises: cursors['exercises'],
          cursorPeriodHabits: cursors['habits'],
          cursorPeriodTimeEntries: cursors['timeEntries'],
          cursorPeriodSleepEntries: cursors['sleepEntries'],
          cursorPeriodExpenses: cursors['expenses'],
          cursorPeriodSettlements: cursors['settlements'],
          cursorPeriodGymSessions: cursors['gymSessions'],
          cursorPeriodHabitLogs: cursors['habitLogs'],
        )
        // A first sync pages through history, so it is given more room than an
        // ordinary request before it is called dead.
        .timeout(_syncTimeout);
    if (response == null) throw api.ApiException(500, 'Empty response');
    return response;
  });

  @override
  Future<api.MoneyOverview> getMoneyOverview() => _authorized((client) async {
    final response = await api.MoneyApi(
      client,
    ).getMoneyOverview().timeout(_requestTimeout);
    if (response == null) throw api.ApiException(500, 'Empty response');
    return response.overview;
  });

  @override
  Future<api.ExpenseListResponse> listExpenses({
    String? personId,
    String? groupId,
    String? cursor,
    int limit = 20,
  }) => _authorized((client) async {
    final response = await api.MoneyApi(client)
        .listExpenses(
          personId: personId,
          groupId: groupId,
          cursor: cursor,
          limit: limit,
        )
        .timeout(_requestTimeout);
    if (response == null) throw api.ApiException(500, 'Empty response');
    return response;
  });

  @override
  Future<api.Expense> createExpense(api.CreateExpenseRequest request) =>
      _authorized((client) async {
        final response = await api.MoneyApi(
          client,
        ).createExpense(request).timeout(_requestTimeout);
        if (response == null) throw api.ApiException(500, 'Empty response');
        return response.expense;
      });

  @override
  Future<api.Expense> updateExpense(
    String id,
    api.UpdateExpenseRequest request,
  ) => _authorized((client) async {
    final response = await api.MoneyApi(
      client,
    ).updateExpense(id, request).timeout(_requestTimeout);
    if (response == null) throw api.ApiException(500, 'Empty response');
    return response.expense;
  });

  @override
  Future<void> deleteExpense(String id) => _authorized(
    (client) => api.MoneyApi(client).deleteExpense(id).timeout(_requestTimeout),
  );

  @override
  Future<api.PersonLedger> getPersonLedger(String personId) =>
      _authorized((client) async {
        final response = await api.MoneyApi(
          client,
        ).getPersonLedger(personId).timeout(_requestTimeout);
        if (response == null) throw api.ApiException(500, 'Empty response');
        return response.ledger;
      });

  @override
  Future<api.Person> createPerson(api.CreatePersonRequest request) =>
      _authorized((client) async {
        final response = await api.MoneyApi(
          client,
        ).createPerson(request).timeout(_requestTimeout);
        if (response == null) throw api.ApiException(500, 'Empty response');
        return response.person;
      });

  @override
  Future<api.Person> updatePerson(
    String id,
    api.UpdatePersonRequest request,
  ) => _authorized((client) async {
    final response = await api.MoneyApi(
      client,
    ).updatePerson(id, request).timeout(_requestTimeout);
    if (response == null) throw api.ApiException(500, 'Empty response');
    return response.person;
  });

  @override
  Future<void> deletePerson(String id) => _authorized(
    (client) => api.MoneyApi(client).deletePerson(id).timeout(_requestTimeout),
  );

  /// Every People write answers with the person, so they all unwrap the same
  /// way.
  Future<api.Person> _person(
    Future<api.PersonResponse?> Function(api.PeopleApi api) call,
  ) => _authorized((client) async {
    final response = await call(api.PeopleApi(client)).timeout(_requestTimeout);
    if (response == null) throw api.ApiException(500, 'Empty response');
    return response.person;
  });

  @override
  Future<List<api.Person>> listPeople() => _authorized((client) async {
    final response = await api.PeopleApi(
      client,
    ).listPeopleProfiles().timeout(_requestTimeout);
    if (response == null) throw api.ApiException(500, 'Empty response');
    return response.people;
  });

  @override
  Future<api.Person> markPersonSeen(String id, api.MarkSeenRequest request) =>
      _person((people) => people.markPersonSeen(id, markSeenRequest: request));

  @override
  Future<api.Person> addPersonNote(
    String personId,
    api.CreatePersonNoteRequest request,
  ) => _person((people) => people.addPersonNote(personId, request));

  @override
  Future<api.Person> updatePersonNote(
    String personId,
    String noteId,
    api.UpdatePersonNoteRequest request,
  ) => _person((people) => people.updatePersonNote(personId, noteId, request));

  @override
  Future<api.Person> deletePersonNote(String personId, String noteId) =>
      _person((people) => people.deletePersonNote(personId, noteId));

  @override
  Future<api.Person> addPersonGift(
    String personId,
    api.CreatePersonGiftRequest request,
  ) => _person((people) => people.addPersonGift(personId, request));

  @override
  Future<api.Person> updatePersonGift(
    String personId,
    String giftId,
    api.UpdatePersonGiftRequest request,
  ) => _person((people) => people.updatePersonGift(personId, giftId, request));

  @override
  Future<api.Person> deletePersonGift(String personId, String giftId) =>
      _person((people) => people.deletePersonGift(personId, giftId));

  @override
  Future<api.Person> addPersonPlace(
    String personId,
    api.CreatePersonPlaceRequest request,
  ) => _person((people) => people.addPersonPlace(personId, request));

  @override
  Future<api.Person> deletePersonPlace(String personId, String placeId) =>
      _person((people) => people.deletePersonPlace(personId, placeId));

  @override
  Future<List<api.CityCandidate>> searchCities(String query) =>
      _authorized((client) async {
        final response = await api.PeopleApi(
          client,
        ).searchCities(query).timeout(_requestTimeout);
        return response?.results ?? const [];
      });

  @override
  Future<api.GeocodeResponse> geocodePendingPlaces() =>
      _authorized((client) async {
        final response = await api.PeopleApi(
          client,
        ).geocodePendingPlaces().timeout(_requestTimeout);
        if (response == null) throw api.ApiException(500, 'Empty response');
        return response;
      });

  @override
  Future<api.PersonGroup> createGroup(api.CreateGroupRequest request) =>
      _authorized((client) async {
        final response = await api.MoneyApi(
          client,
        ).createGroup(request).timeout(_requestTimeout);
        if (response == null) throw api.ApiException(500, 'Empty response');
        return response.group;
      });

  @override
  Future<api.PersonGroup> updateGroup(
    String id,
    api.UpdateGroupRequest request,
  ) => _authorized((client) async {
    final response = await api.MoneyApi(
      client,
    ).updateGroup(id, request).timeout(_requestTimeout);
    if (response == null) throw api.ApiException(500, 'Empty response');
    return response.group;
  });

  @override
  Future<void> deleteGroup(String id) => _authorized(
    (client) => api.MoneyApi(client).deleteGroup(id).timeout(_requestTimeout),
  );

  @override
  Future<api.Settlement> createSettlement(
    api.CreateSettlementRequest request,
  ) => _authorized((client) async {
    final response = await api.MoneyApi(
      client,
    ).createSettlement(request).timeout(_requestTimeout);
    if (response == null) throw api.ApiException(500, 'Empty response');
    return response.settlement;
  });

  @override
  Future<void> deleteSettlement(String id) => _authorized(
    (client) =>
        api.MoneyApi(client).deleteSettlement(id).timeout(_requestTimeout),
  );

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
