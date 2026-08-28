//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class SleepApi {
  SleepApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// List sleep sessions that ended inside a half-open UTC window
  ///
  /// Sessions are attributed to the day they woke up in, which is how the timeline places them. Writes go through `/health/sync`.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [DateTime] from (required):
  ///
  /// * [DateTime] to (required):
  Future<Response> listSleepEntriesWithHttpInfo(
    DateTime from,
    DateTime to, {
    Future<void>? abortTrigger,
  }) async {
    // ignore: prefer_const_declarations
    final path = r'/sleep-entries';

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

  /// List sleep sessions that ended inside a half-open UTC window
  ///
  /// Sessions are attributed to the day they woke up in, which is how the timeline places them. Writes go through `/health/sync`.
  ///
  /// Parameters:
  ///
  /// * [DateTime] from (required):
  ///
  /// * [DateTime] to (required):
  Future<SleepEntryListResponse?> listSleepEntries(
    DateTime from,
    DateTime to, {
    Future<void>? abortTrigger,
  }) async {
    final response = await listSleepEntriesWithHttpInfo(
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
        'SleepEntryListResponse',
      ) as SleepEntryListResponse;
    }
    return null;
  }
}
