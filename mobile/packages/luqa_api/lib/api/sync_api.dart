//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class SyncApi {
  SyncApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Everything that changed since the cursors the caller holds
  ///
  /// The delta feed. A device keeps one cursor per collection and asks for what changed since; omitting a cursor asks for that collection from the beginning, which is what a fresh install does.  Cursors are opaque and per collection, passed as `cursor.<name>`. A collection that reaches `limit` answers `hasMore: true` and is asked again with the cursor it returned. A cursor that cannot be read is treated as absent — the collection resyncs from the start, which is slow but always correct.  Rows and deletions are reported separately: `rows` carries the current state of anything created or changed, `deleted` carries the ids of rows that went away so a device can drop its copies.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] collections:
  ///   Comma-separated subset to sync. Defaults to all of them. Unknown names are ignored.
  ///
  /// * [int] limit:
  ///   Maximum rows per collection per request.
  ///
  /// * [String] cursorPeriodCategories:
  ///
  /// * [String] cursorPeriodPeople:
  ///
  /// * [String] cursorPeriodGroups:
  ///
  /// * [String] cursorPeriodGymLocations:
  ///
  /// * [String] cursorPeriodExercises:
  ///
  /// * [String] cursorPeriodTimeEntries:
  ///
  /// * [String] cursorPeriodSleepEntries:
  ///
  /// * [String] cursorPeriodExpenses:
  ///
  /// * [String] cursorPeriodSettlements:
  ///
  /// * [String] cursorPeriodGymSessions:
  Future<Response> syncChangesWithHttpInfo({
    String? collections,
    int? limit,
    String? cursorPeriodCategories,
    String? cursorPeriodPeople,
    String? cursorPeriodGroups,
    String? cursorPeriodGymLocations,
    String? cursorPeriodExercises,
    String? cursorPeriodTimeEntries,
    String? cursorPeriodSleepEntries,
    String? cursorPeriodExpenses,
    String? cursorPeriodSettlements,
    String? cursorPeriodGymSessions,
    Future<void>? abortTrigger,
  }) async {
    // ignore: prefer_const_declarations
    final path = r'/sync';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (collections != null) {
      queryParams.addAll(_queryParams('', 'collections', collections));
    }
    if (limit != null) {
      queryParams.addAll(_queryParams('', 'limit', limit));
    }
    if (cursorPeriodCategories != null) {
      queryParams.addAll(
          _queryParams('', 'cursor.categories', cursorPeriodCategories));
    }
    if (cursorPeriodPeople != null) {
      queryParams.addAll(_queryParams('', 'cursor.people', cursorPeriodPeople));
    }
    if (cursorPeriodGroups != null) {
      queryParams.addAll(_queryParams('', 'cursor.groups', cursorPeriodGroups));
    }
    if (cursorPeriodGymLocations != null) {
      queryParams.addAll(
          _queryParams('', 'cursor.gymLocations', cursorPeriodGymLocations));
    }
    if (cursorPeriodExercises != null) {
      queryParams
          .addAll(_queryParams('', 'cursor.exercises', cursorPeriodExercises));
    }
    if (cursorPeriodTimeEntries != null) {
      queryParams.addAll(
          _queryParams('', 'cursor.timeEntries', cursorPeriodTimeEntries));
    }
    if (cursorPeriodSleepEntries != null) {
      queryParams.addAll(
          _queryParams('', 'cursor.sleepEntries', cursorPeriodSleepEntries));
    }
    if (cursorPeriodExpenses != null) {
      queryParams
          .addAll(_queryParams('', 'cursor.expenses', cursorPeriodExpenses));
    }
    if (cursorPeriodSettlements != null) {
      queryParams.addAll(
          _queryParams('', 'cursor.settlements', cursorPeriodSettlements));
    }
    if (cursorPeriodGymSessions != null) {
      queryParams.addAll(
          _queryParams('', 'cursor.gymSessions', cursorPeriodGymSessions));
    }

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

  /// Everything that changed since the cursors the caller holds
  ///
  /// The delta feed. A device keeps one cursor per collection and asks for what changed since; omitting a cursor asks for that collection from the beginning, which is what a fresh install does.  Cursors are opaque and per collection, passed as `cursor.<name>`. A collection that reaches `limit` answers `hasMore: true` and is asked again with the cursor it returned. A cursor that cannot be read is treated as absent — the collection resyncs from the start, which is slow but always correct.  Rows and deletions are reported separately: `rows` carries the current state of anything created or changed, `deleted` carries the ids of rows that went away so a device can drop its copies.
  ///
  /// Parameters:
  ///
  /// * [String] collections:
  ///   Comma-separated subset to sync. Defaults to all of them. Unknown names are ignored.
  ///
  /// * [int] limit:
  ///   Maximum rows per collection per request.
  ///
  /// * [String] cursorPeriodCategories:
  ///
  /// * [String] cursorPeriodPeople:
  ///
  /// * [String] cursorPeriodGroups:
  ///
  /// * [String] cursorPeriodGymLocations:
  ///
  /// * [String] cursorPeriodExercises:
  ///
  /// * [String] cursorPeriodTimeEntries:
  ///
  /// * [String] cursorPeriodSleepEntries:
  ///
  /// * [String] cursorPeriodExpenses:
  ///
  /// * [String] cursorPeriodSettlements:
  ///
  /// * [String] cursorPeriodGymSessions:
  Future<SyncResponse?> syncChanges({
    String? collections,
    int? limit,
    String? cursorPeriodCategories,
    String? cursorPeriodPeople,
    String? cursorPeriodGroups,
    String? cursorPeriodGymLocations,
    String? cursorPeriodExercises,
    String? cursorPeriodTimeEntries,
    String? cursorPeriodSleepEntries,
    String? cursorPeriodExpenses,
    String? cursorPeriodSettlements,
    String? cursorPeriodGymSessions,
    Future<void>? abortTrigger,
  }) async {
    final response = await syncChangesWithHttpInfo(
      collections: collections,
      limit: limit,
      cursorPeriodCategories: cursorPeriodCategories,
      cursorPeriodPeople: cursorPeriodPeople,
      cursorPeriodGroups: cursorPeriodGroups,
      cursorPeriodGymLocations: cursorPeriodGymLocations,
      cursorPeriodExercises: cursorPeriodExercises,
      cursorPeriodTimeEntries: cursorPeriodTimeEntries,
      cursorPeriodSleepEntries: cursorPeriodSleepEntries,
      cursorPeriodExpenses: cursorPeriodExpenses,
      cursorPeriodSettlements: cursorPeriodSettlements,
      cursorPeriodGymSessions: cursorPeriodGymSessions,
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
        'SyncResponse',
      ) as SyncResponse;
    }
    return null;
  }
}
