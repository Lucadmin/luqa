//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class HabitsApi {
  HabitsApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Archive a habit
  ///
  /// Habits are archived rather than removed. The logs behind one are the record of a stretch of someone's life, and a streak that can be deleted by accident is worse than a list that needs tidying. Archiving one that is already archived succeeds.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<Response> archiveHabitWithHttpInfo(
    String id, {
    Future<void>? abortTrigger,
  }) async {
    // ignore: prefer_const_declarations
    final path = r'/habits/{id}'.replaceAll('{id}', id);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];

    return apiClient.invokeAPI(
      path,
      'DELETE',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
      abortTrigger: abortTrigger,
    );
  }

  /// Archive a habit
  ///
  /// Habits are archived rather than removed. The logs behind one are the record of a stretch of someone's life, and a streak that can be deleted by accident is worse than a list that needs tidying. Archiving one that is already archived succeeds.
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<void> archiveHabit(
    String id, {
    Future<void>? abortTrigger,
  }) async {
    final response = await archiveHabitWithHttpInfo(
      id,
      abortTrigger: abortTrigger,
    );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Create a habit
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [CreateHabitRequest] createHabitRequest (required):
  Future<Response> createHabitWithHttpInfo(
    CreateHabitRequest createHabitRequest, {
    Future<void>? abortTrigger,
  }) async {
    // ignore: prefer_const_declarations
    final path = r'/habits';

    // ignore: prefer_final_locals
    Object? postBody = createHabitRequest;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];

    return apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
      abortTrigger: abortTrigger,
    );
  }

  /// Create a habit
  ///
  /// Parameters:
  ///
  /// * [CreateHabitRequest] createHabitRequest (required):
  Future<HabitResponse?> createHabit(
    CreateHabitRequest createHabitRequest, {
    Future<void>? abortTrigger,
  }) async {
    final response = await createHabitWithHttpInfo(
      createHabitRequest,
      abortTrigger: abortTrigger,
    );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty &&
        response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(
        await _decodeBodyBytes(response),
        'HabitResponse',
      ) as HabitResponse;
    }
    return null;
  }

  /// Every habit on the account, archived included
  ///
  /// The delta feed is how a device normally stays current. This is the first read after a sign-in, and the recovery path for a cache that had to be thrown away: one page, no cursor, always complete.
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> listHabitsWithHttpInfo({
    Future<void>? abortTrigger,
  }) async {
    // ignore: prefer_const_declarations
    final path = r'/habits';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];

    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
      abortTrigger: abortTrigger,
    );
  }

  /// Every habit on the account, archived included
  ///
  /// The delta feed is how a device normally stays current. This is the first read after a sign-in, and the recovery path for a cache that had to be thrown away: one page, no cursor, always complete.
  Future<HabitListResponse?> listHabits({
    Future<void>? abortTrigger,
  }) async {
    final response = await listHabitsWithHttpInfo(
      abortTrigger: abortTrigger,
    );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty &&
        response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(
        await _decodeBodyBytes(response),
        'HabitListResponse',
      ) as HabitListResponse;
    }
    return null;
  }

  /// Record a day's progress
  ///
  /// A PUT of state rather than a POST of an action. The browser posts \"increment\" and lets the server add one; a queued write cannot, because a retry after a lost response would add one twice. A device resolves habits locally, so it already knows what the day looks like and sends the numbers — replaying the write lands on the same numbers.  Completion is recomputed from the habit's goal rather than taken from the request, so the two clients cannot disagree about what a streak is made of. The moment a day was first completed is kept once it is known.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [String] date (required):
  ///   The logical day, as a YYYY-MM-DD key in the user's timezone.
  ///
  /// * [PutHabitLogRequest] putHabitLogRequest (required):
  Future<Response> putHabitLogWithHttpInfo(
    String id,
    String date,
    PutHabitLogRequest putHabitLogRequest, {
    Future<void>? abortTrigger,
  }) async {
    // ignore: prefer_const_declarations
    final path = r'/habits/{id}/logs/{date}'
        .replaceAll('{id}', id)
        .replaceAll('{date}', date);

    // ignore: prefer_final_locals
    Object? postBody = putHabitLogRequest;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];

    return apiClient.invokeAPI(
      path,
      'PUT',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
      abortTrigger: abortTrigger,
    );
  }

  /// Record a day's progress
  ///
  /// A PUT of state rather than a POST of an action. The browser posts \"increment\" and lets the server add one; a queued write cannot, because a retry after a lost response would add one twice. A device resolves habits locally, so it already knows what the day looks like and sends the numbers — replaying the write lands on the same numbers.  Completion is recomputed from the habit's goal rather than taken from the request, so the two clients cannot disagree about what a streak is made of. The moment a day was first completed is kept once it is known.
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [String] date (required):
  ///   The logical day, as a YYYY-MM-DD key in the user's timezone.
  ///
  /// * [PutHabitLogRequest] putHabitLogRequest (required):
  Future<HabitLogResponse?> putHabitLog(
    String id,
    String date,
    PutHabitLogRequest putHabitLogRequest, {
    Future<void>? abortTrigger,
  }) async {
    final response = await putHabitLogWithHttpInfo(
      id,
      date,
      putHabitLogRequest,
      abortTrigger: abortTrigger,
    );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty &&
        response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(
        await _decodeBodyBytes(response),
        'HabitLogResponse',
      ) as HabitLogResponse;
    }
    return null;
  }

  /// Persist a new ordering of habits
  ///
  /// The whole ordering rather than one habit's new position, so a replayed write restates the order instead of shuffling it again. Ids the account does not own are ignored rather than refused.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [ReorderHabitsRequest] reorderHabitsRequest (required):
  Future<Response> reorderHabitsWithHttpInfo(
    ReorderHabitsRequest reorderHabitsRequest, {
    Future<void>? abortTrigger,
  }) async {
    // ignore: prefer_const_declarations
    final path = r'/habits/reorder';

    // ignore: prefer_final_locals
    Object? postBody = reorderHabitsRequest;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];

    return apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
      abortTrigger: abortTrigger,
    );
  }

  /// Persist a new ordering of habits
  ///
  /// The whole ordering rather than one habit's new position, so a replayed write restates the order instead of shuffling it again. Ids the account does not own are ignored rather than refused.
  ///
  /// Parameters:
  ///
  /// * [ReorderHabitsRequest] reorderHabitsRequest (required):
  Future<HabitListResponse?> reorderHabits(
    ReorderHabitsRequest reorderHabitsRequest, {
    Future<void>? abortTrigger,
  }) async {
    final response = await reorderHabitsWithHttpInfo(
      reorderHabitsRequest,
      abortTrigger: abortTrigger,
    );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty &&
        response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(
        await _decodeBodyBytes(response),
        'HabitListResponse',
      ) as HabitListResponse;
    }
    return null;
  }

  /// Edit a habit's goal, schedule, icon, or archived state
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [UpdateHabitRequest] updateHabitRequest (required):
  Future<Response> updateHabitWithHttpInfo(
    String id,
    UpdateHabitRequest updateHabitRequest, {
    Future<void>? abortTrigger,
  }) async {
    // ignore: prefer_const_declarations
    final path = r'/habits/{id}'.replaceAll('{id}', id);

    // ignore: prefer_final_locals
    Object? postBody = updateHabitRequest;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];

    return apiClient.invokeAPI(
      path,
      'PATCH',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
      abortTrigger: abortTrigger,
    );
  }

  /// Edit a habit's goal, schedule, icon, or archived state
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [UpdateHabitRequest] updateHabitRequest (required):
  Future<HabitResponse?> updateHabit(
    String id,
    UpdateHabitRequest updateHabitRequest, {
    Future<void>? abortTrigger,
  }) async {
    final response = await updateHabitWithHttpInfo(
      id,
      updateHabitRequest,
      abortTrigger: abortTrigger,
    );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty &&
        response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(
        await _decodeBodyBytes(response),
        'HabitResponse',
      ) as HabitResponse;
    }
    return null;
  }
}
