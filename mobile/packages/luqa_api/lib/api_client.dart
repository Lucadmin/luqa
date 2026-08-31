//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class ApiClient {
  ApiClient({
    this.basePath = '/api/v1',
    this.authentication,
  });

  final String basePath;
  final Authentication? authentication;

  var _client = Client();
  final _defaultHeaderMap = <String, String>{};

  /// Returns the current HTTP [Client] instance to use in this class.
  ///
  /// The return value is guaranteed to never be null.
  Client get client => _client;

  /// Requests to use a new HTTP [Client] in this class.
  set client(Client newClient) {
    _client = newClient;
  }

  Map<String, String> get defaultHeaderMap => _defaultHeaderMap;

  void addDefaultHeader(String key, String value) {
    _defaultHeaderMap[key] = value;
  }

  // We don't use a Map<String, String> for queryParams.
  // If collectionFormat is 'multi', a key might appear multiple times.
  Future<Response> invokeAPI(
    String path,
    String method,
    List<QueryParam> queryParams,
    Object? body,
    Map<String, String> headerParams,
    Map<String, String> formParams,
    String? contentType, {
    Future<void>? abortTrigger,
  }) async {
    await authentication?.applyToParams(queryParams, headerParams);

    headerParams.addAll(_defaultHeaderMap);
    if (contentType != null) {
      headerParams['Content-Type'] = contentType;
    }

    final urlEncodedQueryParams = queryParams.map((param) => '$param');
    final queryString = urlEncodedQueryParams.isNotEmpty
        ? '?${urlEncodedQueryParams.join('&')}'
        : '';
    final uri = Uri.parse('$basePath$path$queryString');

    try {
      // Special case for uploading a single file which isn't a 'multipart/form-data'.
      if (body is MultipartFile &&
          (contentType == null ||
              !contentType.toLowerCase().startsWith('multipart/form-data'))) {
        final request =
            AbortableStreamedRequest(method, uri, abortTrigger: abortTrigger);
        request.headers.addAll(headerParams);
        request.contentLength = body.length;
        body.finalize().listen(
              request.sink.add,
              onDone: request.sink.close,
              // ignore: avoid_types_on_closure_parameters
              onError: (Object error, StackTrace trace) => request.sink.close(),
              cancelOnError: true,
            );
        final response = await _client.send(request);
        return Response.fromStream(response);
      }

      if (body is MultipartRequest) {
        final request =
            AbortableMultipartRequest(method, uri, abortTrigger: abortTrigger);
        request.fields.addAll(body.fields);
        request.files.addAll(body.files);
        request.headers.addAll(body.headers);
        request.headers.addAll(headerParams);
        final response = await _client.send(request);
        return Response.fromStream(response);
      }

      final msgBody = contentType == 'application/x-www-form-urlencoded'
          ? formParams
          : await serializeAsync(body);
      final nullableHeaderParams = headerParams.isEmpty ? null : headerParams;

      final request = AbortableRequest(method, uri, abortTrigger: abortTrigger);
      if (nullableHeaderParams != null) {
        request.headers.addAll(nullableHeaderParams);
      }
      if (msgBody is String && msgBody.isNotEmpty) {
        request.body = msgBody;
      } else if (msgBody is List<int> && msgBody.isNotEmpty) {
        request.bodyBytes = msgBody;
      } else if (msgBody is Map<String, String>) {
        request.bodyFields = msgBody;
      }
      final response = await _client.send(request);
      return Response.fromStream(response);
    } on SocketException catch (error, trace) {
      throw ApiException.withInner(
        HttpStatus.badRequest,
        'Socket operation failed: $method $path',
        error,
        trace,
      );
    } on TlsException catch (error, trace) {
      throw ApiException.withInner(
        HttpStatus.badRequest,
        'TLS/SSL communication failed: $method $path',
        error,
        trace,
      );
    } on IOException catch (error, trace) {
      throw ApiException.withInner(
        HttpStatus.badRequest,
        'I/O operation failed: $method $path',
        error,
        trace,
      );
    } on ClientException catch (error, trace) {
      throw ApiException.withInner(
        HttpStatus.badRequest,
        'HTTP connection failed: $method $path',
        error,
        trace,
      );
    } on Exception catch (error, trace) {
      throw ApiException.withInner(
        HttpStatus.badRequest,
        'Exception occurred: $method $path',
        error,
        trace,
      );
    }
  }

  Future<dynamic> deserializeAsync(
    String value,
    String targetType, {
    bool growable = false,
  }) async =>
      // ignore: deprecated_member_use_from_same_package
      deserialize(value, targetType, growable: growable);

  @Deprecated(
      'Scheduled for removal in OpenAPI Generator 6.x. Use deserializeAsync() instead.')
  dynamic deserialize(
    String value,
    String targetType, {
    bool growable = false,
  }) {
    // Remove all spaces. Necessary for regular expressions as well.
    targetType =
        targetType.replaceAll(' ', ''); // ignore: parameter_assignments

    // If the expected target type is String, nothing to do...
    return targetType == 'String'
        ? value
        : fromJson(json.decode(value), targetType, growable: growable);
  }

  // ignore: deprecated_member_use_from_same_package
  Future<String> serializeAsync(Object? value) async => serialize(value);

  @Deprecated(
      'Scheduled for removal in OpenAPI Generator 6.x. Use serializeAsync() instead.')
  String serialize(Object? value) => value == null ? '' : json.encode(value);

  /// Returns a native instance of an OpenAPI class matching the [specified type][targetType].
  static dynamic fromJson(
    dynamic value,
    String targetType, {
    bool growable = false,
  }) {
    try {
      switch (targetType) {
        case 'String':
          return value is String ? value : value.toString();
        case 'int':
          return value is int ? value : int.parse('$value');
        case 'double':
          return value is double ? value : double.parse('$value');
        case 'bool':
          if (value is bool) {
            return value;
          }
          final valueString = '$value'.toLowerCase();
          return valueString == 'true' || valueString == '1';
        case 'DateTime':
          return value is DateTime ? value : DateTime.tryParse(value);
        case 'Category':
          return Category.fromJson(value);
        case 'CategoryListResponse':
          return CategoryListResponse.fromJson(value);
        case 'CategoryResponse':
          return CategoryResponse.fromJson(value);
        case 'CreateCategoryRequest':
          return CreateCategoryRequest.fromJson(value);
        case 'CreateExpenseRequest':
          return CreateExpenseRequest.fromJson(value);
        case 'CreateGroupRequest':
          return CreateGroupRequest.fromJson(value);
        case 'CreateGymLocationRequest':
          return CreateGymLocationRequest.fromJson(value);
        case 'CreateGymSessionRequest':
          return CreateGymSessionRequest.fromJson(value);
        case 'CreatePersonRequest':
          return CreatePersonRequest.fromJson(value);
        case 'CreateSessionRequest':
          return CreateSessionRequest.fromJson(value);
        case 'CreateSettlementRequest':
          return CreateSettlementRequest.fromJson(value);
        case 'CreateTimeEntryRequest':
          return CreateTimeEntryRequest.fromJson(value);
        case 'DeletePersonResponse':
          return DeletePersonResponse.fromJson(value);
        case 'DeviceHealthSource':
          return DeviceHealthSourceTypeTransformer().decode(value);
        case 'EntrySource':
          return EntrySourceTypeTransformer().decode(value);
        case 'ErrorDetail':
          return ErrorDetail.fromJson(value);
        case 'ErrorResponse':
          return ErrorResponse.fromJson(value);
        case 'Expense':
          return Expense.fromJson(value);
        case 'ExpenseListResponse':
          return ExpenseListResponse.fromJson(value);
        case 'ExpenseParticipantInput':
          return ExpenseParticipantInput.fromJson(value);
        case 'ExpenseResponse':
          return ExpenseResponse.fromJson(value);
        case 'ExpenseShare':
          return ExpenseShare.fromJson(value);
        case 'GroupListResponse':
          return GroupListResponse.fromJson(value);
        case 'GroupResponse':
          return GroupResponse.fromJson(value);
        case 'GymExercise':
          return GymExercise.fromJson(value);
        case 'GymExerciseHistory':
          return GymExerciseHistory.fromJson(value);
        case 'GymExerciseHistoryResponse':
          return GymExerciseHistoryResponse.fromJson(value);
        case 'GymExercisePoint':
          return GymExercisePoint.fromJson(value);
        case 'GymExerciseReference':
          return GymExerciseReference.fromJson(value);
        case 'GymLocation':
          return GymLocation.fromJson(value);
        case 'GymLocationResponse':
          return GymLocationResponse.fromJson(value);
        case 'GymOverview':
          return GymOverview.fromJson(value);
        case 'GymOverviewResponse':
          return GymOverviewResponse.fromJson(value);
        case 'GymSession':
          return GymSession.fromJson(value);
        case 'GymSessionExercise':
          return GymSessionExercise.fromJson(value);
        case 'GymSessionExerciseInput':
          return GymSessionExerciseInput.fromJson(value);
        case 'GymSessionListResponse':
          return GymSessionListResponse.fromJson(value);
        case 'GymSessionResponse':
          return GymSessionResponse.fromJson(value);
        case 'GymSet':
          return GymSet.fromJson(value);
        case 'GymSetInput':
          return GymSetInput.fromJson(value);
        case 'HealthMetricType':
          return HealthMetricTypeTypeTransformer().decode(value);
        case 'HealthSampleImport':
          return HealthSampleImport.fromJson(value);
        case 'HealthSampleRef':
          return HealthSampleRef.fromJson(value);
        case 'HealthSyncCounts':
          return HealthSyncCounts.fromJson(value);
        case 'HealthSyncRequest':
          return HealthSyncRequest.fromJson(value);
        case 'HealthSyncResponse':
          return HealthSyncResponse.fromJson(value);
        case 'HealthSyncState':
          return HealthSyncState.fromJson(value);
        case 'HealthSyncStateListResponse':
          return HealthSyncStateListResponse.fromJson(value);
        case 'LedgerItem':
          return LedgerItem.fromJson(value);
        case 'MobileUser':
          return MobileUser.fromJson(value);
        case 'MoneyOverview':
          return MoneyOverview.fromJson(value);
        case 'MoneyOverviewResponse':
          return MoneyOverviewResponse.fromJson(value);
        case 'Person':
          return Person.fromJson(value);
        case 'PersonBalance':
          return PersonBalance.fromJson(value);
        case 'PersonGroup':
          return PersonGroup.fromJson(value);
        case 'PersonLedger':
          return PersonLedger.fromJson(value);
        case 'PersonLedgerResponse':
          return PersonLedgerResponse.fromJson(value);
        case 'PersonListResponse':
          return PersonListResponse.fromJson(value);
        case 'PersonResponse':
          return PersonResponse.fromJson(value);
        case 'RefreshSessionRequest':
          return RefreshSessionRequest.fromJson(value);
        case 'SessionCredentials':
          return SessionCredentials.fromJson(value);
        case 'Settlement':
          return Settlement.fromJson(value);
        case 'SettlementDirection':
          return SettlementDirectionTypeTransformer().decode(value);
        case 'SettlementListResponse':
          return SettlementListResponse.fromJson(value);
        case 'SettlementResponse':
          return SettlementResponse.fromJson(value);
        case 'SleepEntry':
          return SleepEntry.fromJson(value);
        case 'SleepEntryListResponse':
          return SleepEntryListResponse.fromJson(value);
        case 'SleepSessionImport':
          return SleepSessionImport.fromJson(value);
        case 'SleepSource':
          return SleepSourceTypeTransformer().decode(value);
        case 'SleepStage':
          return SleepStage.fromJson(value);
        case 'SleepSyncPayload':
          return SleepSyncPayload.fromJson(value);
        case 'SleepSyncWindow':
          return SleepSyncWindow.fromJson(value);
        case 'SplitMode':
          return SplitModeTypeTransformer().decode(value);
        case 'TimeEntry':
          return TimeEntry.fromJson(value);
        case 'TimeEntryListResponse':
          return TimeEntryListResponse.fromJson(value);
        case 'TimeEntryResponse':
          return TimeEntryResponse.fromJson(value);
        case 'UpdateExpenseRequest':
          return UpdateExpenseRequest.fromJson(value);
        case 'UpdateGroupRequest':
          return UpdateGroupRequest.fromJson(value);
        case 'UpdateGymLocationRequest':
          return UpdateGymLocationRequest.fromJson(value);
        case 'UpdateGymSessionRequest':
          return UpdateGymSessionRequest.fromJson(value);
        case 'UpdatePersonRequest':
          return UpdatePersonRequest.fromJson(value);
        case 'UpdateSettlementRequest':
          return UpdateSettlementRequest.fromJson(value);
        case 'UpdateTimeEntryRequest':
          return UpdateTimeEntryRequest.fromJson(value);
        default:
          dynamic match;
          if (value is List &&
              (match = _regList.firstMatch(targetType)?.group(1)) != null) {
            return value
                .map<dynamic>((dynamic v) => fromJson(
                      v,
                      match,
                      growable: growable,
                    ))
                .toList(growable: growable);
          }
          if (value is Set &&
              (match = _regSet.firstMatch(targetType)?.group(1)) != null) {
            return value
                .map<dynamic>((dynamic v) => fromJson(
                      v,
                      match,
                      growable: growable,
                    ))
                .toSet();
          }
          if (value is Map &&
              (match = _regMap.firstMatch(targetType)?.group(1)) != null) {
            return Map<String, dynamic>.fromIterables(
              value.keys.cast<String>(),
              value.values.map<dynamic>((dynamic v) => fromJson(
                    v,
                    match,
                    growable: growable,
                  )),
            );
          }
      }
    } on Exception catch (error, trace) {
      throw ApiException.withInner(
        HttpStatus.internalServerError,
        'Exception during deserialization.',
        error,
        trace,
      );
    }
    throw ApiException(
      HttpStatus.internalServerError,
      'Could not find a suitable class for deserialization',
    );
  }
}

/// Primarily intended for use in an isolate.
class DeserializationMessage {
  const DeserializationMessage({
    required this.json,
    required this.targetType,
    this.growable = false,
  });

  /// The JSON value to deserialize.
  final String json;

  /// Target type to deserialize to.
  final String targetType;

  /// Whether to make deserialized lists or maps growable.
  final bool growable;
}

/// Primarily intended for use in an isolate.
Future<dynamic> decodeAsync(DeserializationMessage message) async {
  // Remove all spaces. Necessary for regular expressions as well.
  final targetType = message.targetType.replaceAll(' ', '');

  // If the expected target type is String, nothing to do...
  return targetType == 'String' ? message.json : json.decode(message.json);
}

/// Primarily intended for use in an isolate.
Future<dynamic> deserializeAsync(DeserializationMessage message) async {
  // Remove all spaces. Necessary for regular expressions as well.
  final targetType = message.targetType.replaceAll(' ', '');

  // If the expected target type is String, nothing to do...
  return targetType == 'String'
      ? message.json
      : ApiClient.fromJson(
          json.decode(message.json),
          targetType,
          growable: message.growable,
        );
}

/// Primarily intended for use in an isolate.
Future<String> serializeAsync(Object? value) async =>
    value == null ? '' : json.encode(value);
