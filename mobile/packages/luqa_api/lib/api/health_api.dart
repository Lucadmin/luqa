//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class HealthApi {
  HealthApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Read what the server last accepted, per source and metric
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> getHealthSyncStateWithHttpInfo({
    Future<void>? abortTrigger,
  }) async {
    // ignore: prefer_const_declarations
    final path = r'/health/sync';

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

  /// Read what the server last accepted, per source and metric
  Future<HealthSyncStateListResponse?> getHealthSyncState({
    Future<void>? abortTrigger,
  }) async {
    final response = await getHealthSyncStateWithHttpInfo(
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
        'HealthSyncStateListResponse',
      ) as HealthSyncStateListResponse;
    }
    return null;
  }

  /// Push sleep sessions and samples read from the device
  ///
  /// Idempotent by provider record id. Supply `sleep.window` only when the device re-read a full range: it authorizes the server to soft-delete sessions inside that range it no longer sees.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [HealthSyncRequest] healthSyncRequest (required):
  Future<Response> pushHealthSyncWithHttpInfo(
    HealthSyncRequest healthSyncRequest, {
    Future<void>? abortTrigger,
  }) async {
    // ignore: prefer_const_declarations
    final path = r'/health/sync';

    // ignore: prefer_final_locals
    Object? postBody = healthSyncRequest;

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

  /// Push sleep sessions and samples read from the device
  ///
  /// Idempotent by provider record id. Supply `sleep.window` only when the device re-read a full range: it authorizes the server to soft-delete sessions inside that range it no longer sees.
  ///
  /// Parameters:
  ///
  /// * [HealthSyncRequest] healthSyncRequest (required):
  Future<HealthSyncResponse?> pushHealthSync(
    HealthSyncRequest healthSyncRequest, {
    Future<void>? abortTrigger,
  }) async {
    final response = await pushHealthSyncWithHttpInfo(
      healthSyncRequest,
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
        'HealthSyncResponse',
      ) as HealthSyncResponse;
    }
    return null;
  }
}
