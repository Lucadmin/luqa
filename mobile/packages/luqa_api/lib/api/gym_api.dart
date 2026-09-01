//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class GymApi {
  GymApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Add a gym
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [CreateGymLocationRequest] createGymLocationRequest (required):
  Future<Response> createGymLocationWithHttpInfo(
    CreateGymLocationRequest createGymLocationRequest, {
    Future<void>? abortTrigger,
  }) async {
    // ignore: prefer_const_declarations
    final path = r'/gym/locations';

    // ignore: prefer_final_locals
    Object? postBody = createGymLocationRequest;

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

  /// Add a gym
  ///
  /// Parameters:
  ///
  /// * [CreateGymLocationRequest] createGymLocationRequest (required):
  Future<GymLocationResponse?> createGymLocation(
    CreateGymLocationRequest createGymLocationRequest, {
    Future<void>? abortTrigger,
  }) async {
    final response = await createGymLocationWithHttpInfo(
      createGymLocationRequest,
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
        'GymLocationResponse',
      ) as GymLocationResponse;
    }
    return null;
  }

  /// Start an autosaved workout
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [CreateGymSessionRequest] createGymSessionRequest (required):
  Future<Response> createGymSessionWithHttpInfo(
    CreateGymSessionRequest createGymSessionRequest, {
    Future<void>? abortTrigger,
  }) async {
    // ignore: prefer_const_declarations
    final path = r'/gym/sessions';

    // ignore: prefer_final_locals
    Object? postBody = createGymSessionRequest;

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

  /// Start an autosaved workout
  ///
  /// Parameters:
  ///
  /// * [CreateGymSessionRequest] createGymSessionRequest (required):
  Future<GymSessionResponse?> createGymSession(
    CreateGymSessionRequest createGymSessionRequest, {
    Future<void>? abortTrigger,
  }) async {
    final response = await createGymSessionWithHttpInfo(
      createGymSessionRequest,
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
        'GymSessionResponse',
      ) as GymSessionResponse;
    }
    return null;
  }

  /// Remove an exercise from the library
  ///
  /// An exercise nothing has been logged against is deleted. One with history is archived instead, so the workouts that used it keep reading the way they were written. `deleted` says which happened.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<Response> deleteGymExerciseWithHttpInfo(
    String id, {
    Future<void>? abortTrigger,
  }) async {
    // ignore: prefer_const_declarations
    final path = r'/gym/exercises/{id}'.replaceAll('{id}', id);

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

  /// Remove an exercise from the library
  ///
  /// An exercise nothing has been logged against is deleted. One with history is archived instead, so the workouts that used it keep reading the way they were written. `deleted` says which happened.
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<DeleteGymExerciseResponse?> deleteGymExercise(
    String id, {
    Future<void>? abortTrigger,
  }) async {
    final response = await deleteGymExerciseWithHttpInfo(
      id,
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
        'DeleteGymExerciseResponse',
      ) as DeleteGymExerciseResponse;
    }
    return null;
  }

  /// Delete a workout
  ///
  /// Soft-deletes the workout and everything logged in it, including one that was only just started. The exercise library is untouched.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<Response> deleteGymSessionWithHttpInfo(
    String id, {
    Future<void>? abortTrigger,
  }) async {
    // ignore: prefer_const_declarations
    final path = r'/gym/sessions/{id}'.replaceAll('{id}', id);

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

  /// Delete a workout
  ///
  /// Soft-deletes the workout and everything logged in it, including one that was only just started. The exercise library is untouched.
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<void> deleteGymSession(
    String id, {
    Future<void>? abortTrigger,
  }) async {
    final response = await deleteGymSessionWithHttpInfo(
      id,
      abortTrigger: abortTrigger,
    );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Load one exercise's progress history
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [String] locationId:
  ///   Keep machine stacks from different gyms separate.
  ///
  /// * [String] beforeSessionId:
  ///   Return only performances before this workout.
  Future<Response> getGymExerciseHistoryWithHttpInfo(
    String id, {
    String? locationId,
    String? beforeSessionId,
    Future<void>? abortTrigger,
  }) async {
    // ignore: prefer_const_declarations
    final path = r'/gym/exercises/{id}/history'.replaceAll('{id}', id);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (locationId != null) {
      queryParams.addAll(_queryParams('', 'locationId', locationId));
    }
    if (beforeSessionId != null) {
      queryParams.addAll(_queryParams('', 'beforeSessionId', beforeSessionId));
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

  /// Load one exercise's progress history
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [String] locationId:
  ///   Keep machine stacks from different gyms separate.
  ///
  /// * [String] beforeSessionId:
  ///   Return only performances before this workout.
  Future<GymExerciseHistoryResponse?> getGymExerciseHistory(
    String id, {
    String? locationId,
    String? beforeSessionId,
    Future<void>? abortTrigger,
  }) async {
    final response = await getGymExerciseHistoryWithHttpInfo(
      id,
      locationId: locationId,
      beforeSessionId: beforeSessionId,
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
        'GymExerciseHistoryResponse',
      ) as GymExerciseHistoryResponse;
    }
    return null;
  }

  /// Load gyms, exercises, per-gym references, and recent workouts
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [int] limit:
  Future<Response> getGymOverviewWithHttpInfo({
    int? limit,
    Future<void>? abortTrigger,
  }) async {
    // ignore: prefer_const_declarations
    final path = r'/gym';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (limit != null) {
      queryParams.addAll(_queryParams('', 'limit', limit));
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

  /// Load gyms, exercises, per-gym references, and recent workouts
  ///
  /// Parameters:
  ///
  /// * [int] limit:
  Future<GymOverviewResponse?> getGymOverview({
    int? limit,
    Future<void>? abortTrigger,
  }) async {
    final response = await getGymOverviewWithHttpInfo(
      limit: limit,
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
        'GymOverviewResponse',
      ) as GymOverviewResponse;
    }
    return null;
  }

  /// Load one workout
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<Response> getGymSessionWithHttpInfo(
    String id, {
    Future<void>? abortTrigger,
  }) async {
    // ignore: prefer_const_declarations
    final path = r'/gym/sessions/{id}'.replaceAll('{id}', id);

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

  /// Load one workout
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<GymSessionResponse?> getGymSession(
    String id, {
    Future<void>? abortTrigger,
  }) async {
    final response = await getGymSessionWithHttpInfo(
      id,
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
        'GymSessionResponse',
      ) as GymSessionResponse;
    }
    return null;
  }

  /// List workouts newest first
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] cursor:
  ///
  /// * [int] limit:
  Future<Response> listGymSessionsWithHttpInfo({
    String? cursor,
    int? limit,
    Future<void>? abortTrigger,
  }) async {
    // ignore: prefer_const_declarations
    final path = r'/gym/sessions';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (cursor != null) {
      queryParams.addAll(_queryParams('', 'cursor', cursor));
    }
    if (limit != null) {
      queryParams.addAll(_queryParams('', 'limit', limit));
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

  /// List workouts newest first
  ///
  /// Parameters:
  ///
  /// * [String] cursor:
  ///
  /// * [int] limit:
  Future<GymSessionListResponse?> listGymSessions({
    String? cursor,
    int? limit,
    Future<void>? abortTrigger,
  }) async {
    final response = await listGymSessionsWithHttpInfo(
      cursor: cursor,
      limit: limit,
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
        'GymSessionListResponse',
      ) as GymSessionListResponse;
    }
    return null;
  }

  /// Merge a duplicate exercise into another exercise
  ///
  /// Moves every logged performance to the target exercise, keeps the target name, and removes the source exercise from the library.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///   Exercise whose history will be moved and then removed.
  ///
  /// * [MergeGymExerciseRequest] mergeGymExerciseRequest (required):
  Future<Response> mergeGymExerciseWithHttpInfo(
    String id,
    MergeGymExerciseRequest mergeGymExerciseRequest, {
    Future<void>? abortTrigger,
  }) async {
    // ignore: prefer_const_declarations
    final path = r'/gym/exercises/{id}/merge'.replaceAll('{id}', id);

    // ignore: prefer_final_locals
    Object? postBody = mergeGymExerciseRequest;

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

  /// Merge a duplicate exercise into another exercise
  ///
  /// Moves every logged performance to the target exercise, keeps the target name, and removes the source exercise from the library.
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///   Exercise whose history will be moved and then removed.
  ///
  /// * [MergeGymExerciseRequest] mergeGymExerciseRequest (required):
  Future<GymExerciseMergeResponse?> mergeGymExercise(
    String id,
    MergeGymExerciseRequest mergeGymExerciseRequest, {
    Future<void>? abortTrigger,
  }) async {
    final response = await mergeGymExerciseWithHttpInfo(
      id,
      mergeGymExerciseRequest,
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
        'GymExerciseMergeResponse',
      ) as GymExerciseMergeResponse;
    }
    return null;
  }

  /// Rename, annotate, archive, or restore an exercise
  ///
  /// Renaming onto a name another exercise already uses merges the two rather than failing, which is the fix for years of spelling drift. `mergedInto` names the surviving exercise when that happened.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [UpdateGymExerciseRequest] updateGymExerciseRequest (required):
  Future<Response> updateGymExerciseWithHttpInfo(
    String id,
    UpdateGymExerciseRequest updateGymExerciseRequest, {
    Future<void>? abortTrigger,
  }) async {
    // ignore: prefer_const_declarations
    final path = r'/gym/exercises/{id}'.replaceAll('{id}', id);

    // ignore: prefer_final_locals
    Object? postBody = updateGymExerciseRequest;

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

  /// Rename, annotate, archive, or restore an exercise
  ///
  /// Renaming onto a name another exercise already uses merges the two rather than failing, which is the fix for years of spelling drift. `mergedInto` names the surviving exercise when that happened.
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [UpdateGymExerciseRequest] updateGymExerciseRequest (required):
  Future<GymExerciseUpdateResponse?> updateGymExercise(
    String id,
    UpdateGymExerciseRequest updateGymExerciseRequest, {
    Future<void>? abortTrigger,
  }) async {
    final response = await updateGymExerciseWithHttpInfo(
      id,
      updateGymExerciseRequest,
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
        'GymExerciseUpdateResponse',
      ) as GymExerciseUpdateResponse;
    }
    return null;
  }

  /// Edit, archive, or restore a gym
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [UpdateGymLocationRequest] updateGymLocationRequest (required):
  Future<Response> updateGymLocationWithHttpInfo(
    String id,
    UpdateGymLocationRequest updateGymLocationRequest, {
    Future<void>? abortTrigger,
  }) async {
    // ignore: prefer_const_declarations
    final path = r'/gym/locations/{id}'.replaceAll('{id}', id);

    // ignore: prefer_final_locals
    Object? postBody = updateGymLocationRequest;

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

  /// Edit, archive, or restore a gym
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [UpdateGymLocationRequest] updateGymLocationRequest (required):
  Future<GymLocationResponse?> updateGymLocation(
    String id,
    UpdateGymLocationRequest updateGymLocationRequest, {
    Future<void>? abortTrigger,
  }) async {
    final response = await updateGymLocationWithHttpInfo(
      id,
      updateGymLocationRequest,
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
        'GymLocationResponse',
      ) as GymLocationResponse;
    }
    return null;
  }

  /// Autosave a workout draft
  ///
  /// Omitted fields stay unchanged. Sending exercises replaces the ordered exercise list; empty sets are ignored server-side.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [UpdateGymSessionRequest] updateGymSessionRequest (required):
  Future<Response> updateGymSessionWithHttpInfo(
    String id,
    UpdateGymSessionRequest updateGymSessionRequest, {
    Future<void>? abortTrigger,
  }) async {
    // ignore: prefer_const_declarations
    final path = r'/gym/sessions/{id}'.replaceAll('{id}', id);

    // ignore: prefer_final_locals
    Object? postBody = updateGymSessionRequest;

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

  /// Autosave a workout draft
  ///
  /// Omitted fields stay unchanged. Sending exercises replaces the ordered exercise list; empty sets are ignored server-side.
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [UpdateGymSessionRequest] updateGymSessionRequest (required):
  Future<GymSessionResponse?> updateGymSession(
    String id,
    UpdateGymSessionRequest updateGymSessionRequest, {
    Future<void>? abortTrigger,
  }) async {
    final response = await updateGymSessionWithHttpInfo(
      id,
      updateGymSessionRequest,
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
        'GymSessionResponse',
      ) as GymSessionResponse;
    }
    return null;
  }
}
