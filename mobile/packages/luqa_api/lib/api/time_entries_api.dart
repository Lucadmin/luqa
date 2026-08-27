//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class TimeEntriesApi {
  TimeEntriesApi([ApiClient? apiClient])
      : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Create a completed block or running timer
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [CreateTimeEntryRequest] createTimeEntryRequest (required):
  Future<Response> createTimeEntryWithHttpInfo(
    CreateTimeEntryRequest createTimeEntryRequest, {
    Future<void>? abortTrigger,
  }) async {
    // ignore: prefer_const_declarations
    final path = r'/time-entries';

    // ignore: prefer_final_locals
    Object? postBody = createTimeEntryRequest;

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

  /// Create a completed block or running timer
  ///
  /// Parameters:
  ///
  /// * [CreateTimeEntryRequest] createTimeEntryRequest (required):
  Future<TimeEntryResponse?> createTimeEntry(
    CreateTimeEntryRequest createTimeEntryRequest, {
    Future<void>? abortTrigger,
  }) async {
    final response = await createTimeEntryWithHttpInfo(
      createTimeEntryRequest,
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
        'TimeEntryResponse',
      ) as TimeEntryResponse;
    }
    return null;
  }

  /// List entries overlapping a half-open UTC window
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [DateTime] from (required):
  ///
  /// * [DateTime] to (required):
  Future<Response> listTimeEntriesWithHttpInfo(
    DateTime from,
    DateTime to, {
    Future<void>? abortTrigger,
  }) async {
    // ignore: prefer_const_declarations
    final path = r'/time-entries';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    queryParams.addAll(_queryParams('', 'from', from));
    queryParams.addAll(_queryParams('', 'to', to));

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

  /// List entries overlapping a half-open UTC window
  ///
  /// Parameters:
  ///
  /// * [DateTime] from (required):
  ///
  /// * [DateTime] to (required):
  Future<TimeEntryListResponse?> listTimeEntries(
    DateTime from,
    DateTime to, {
    Future<void>? abortTrigger,
  }) async {
    final response = await listTimeEntriesWithHttpInfo(
      from,
      to,
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
        'TimeEntryListResponse',
      ) as TimeEntryListResponse;
    }
    return null;
  }
}
