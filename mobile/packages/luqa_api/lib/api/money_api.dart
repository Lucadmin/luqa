//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class MoneyApi {
  MoneyApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Log a bill and who carries what
  ///
  /// The split is recomputed server-side from `splitMode`, `includeMe` and `participants`, so the stored shares can never disagree with the rules the editor previewed. Shares plus the user's own slice always add up to the bill exactly.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [CreateExpenseRequest] createExpenseRequest (required):
  Future<Response> createExpenseWithHttpInfo(
    CreateExpenseRequest createExpenseRequest, {
    Future<void>? abortTrigger,
  }) async {
    // ignore: prefer_const_declarations
    final path = r'/money/expenses';

    // ignore: prefer_final_locals
    Object? postBody = createExpenseRequest;

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

  /// Log a bill and who carries what
  ///
  /// The split is recomputed server-side from `splitMode`, `includeMe` and `participants`, so the stored shares can never disagree with the rules the editor previewed. Shares plus the user's own slice always add up to the bill exactly.
  ///
  /// Parameters:
  ///
  /// * [CreateExpenseRequest] createExpenseRequest (required):
  Future<ExpenseResponse?> createExpense(
    CreateExpenseRequest createExpenseRequest, {
    Future<void>? abortTrigger,
  }) async {
    final response = await createExpenseWithHttpInfo(
      createExpenseRequest,
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
        'ExpenseResponse',
      ) as ExpenseResponse;
    }
    return null;
  }

  /// Create a group from a set of people
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [CreateGroupRequest] createGroupRequest (required):
  Future<Response> createGroupWithHttpInfo(
    CreateGroupRequest createGroupRequest, {
    Future<void>? abortTrigger,
  }) async {
    // ignore: prefer_const_declarations
    final path = r'/money/groups';

    // ignore: prefer_final_locals
    Object? postBody = createGroupRequest;

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

  /// Create a group from a set of people
  ///
  /// Parameters:
  ///
  /// * [CreateGroupRequest] createGroupRequest (required):
  Future<GroupResponse?> createGroup(
    CreateGroupRequest createGroupRequest, {
    Future<void>? abortTrigger,
  }) async {
    final response = await createGroupWithHttpInfo(
      createGroupRequest,
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
        'GroupResponse',
      ) as GroupResponse;
    }
    return null;
  }

  /// Add someone to split with
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [CreatePersonRequest] createPersonRequest (required):
  Future<Response> createPersonWithHttpInfo(
    CreatePersonRequest createPersonRequest, {
    Future<void>? abortTrigger,
  }) async {
    // ignore: prefer_const_declarations
    final path = r'/money/people';

    // ignore: prefer_final_locals
    Object? postBody = createPersonRequest;

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

  /// Add someone to split with
  ///
  /// Parameters:
  ///
  /// * [CreatePersonRequest] createPersonRequest (required):
  Future<PersonResponse?> createPerson(
    CreatePersonRequest createPersonRequest, {
    Future<void>? abortTrigger,
  }) async {
    final response = await createPersonWithHttpInfo(
      createPersonRequest,
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
        'PersonResponse',
      ) as PersonResponse;
    }
    return null;
  }

  /// Record a payback
  ///
  /// Moves the balance without touching any of the bills behind it, so the history stays readable.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [CreateSettlementRequest] createSettlementRequest (required):
  Future<Response> createSettlementWithHttpInfo(
    CreateSettlementRequest createSettlementRequest, {
    Future<void>? abortTrigger,
  }) async {
    // ignore: prefer_const_declarations
    final path = r'/money/settlements';

    // ignore: prefer_final_locals
    Object? postBody = createSettlementRequest;

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

  /// Record a payback
  ///
  /// Moves the balance without touching any of the bills behind it, so the history stays readable.
  ///
  /// Parameters:
  ///
  /// * [CreateSettlementRequest] createSettlementRequest (required):
  Future<SettlementResponse?> createSettlement(
    CreateSettlementRequest createSettlementRequest, {
    Future<void>? abortTrigger,
  }) async {
    final response = await createSettlementWithHttpInfo(
      createSettlementRequest,
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
        'SettlementResponse',
      ) as SettlementResponse;
    }
    return null;
  }

  /// Drop a bill and every share on it
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<Response> deleteExpenseWithHttpInfo(
    String id, {
    Future<void>? abortTrigger,
  }) async {
    // ignore: prefer_const_declarations
    final path = r'/money/expenses/{id}'.replaceAll('{id}', id);

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

  /// Drop a bill and every share on it
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<void> deleteExpense(
    String id, {
    Future<void>? abortTrigger,
  }) async {
    final response = await deleteExpenseWithHttpInfo(
      id,
      abortTrigger: abortTrigger,
    );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Remove a group
  ///
  /// Past bills keep their people and amounts; they simply lose the label.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<Response> deleteGroupWithHttpInfo(
    String id, {
    Future<void>? abortTrigger,
  }) async {
    // ignore: prefer_const_declarations
    final path = r'/money/groups/{id}'.replaceAll('{id}', id);

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

  /// Remove a group
  ///
  /// Past bills keep their people and amounts; they simply lose the label.
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<void> deleteGroup(
    String id, {
    Future<void>? abortTrigger,
  }) async {
    final response = await deleteGroupWithHttpInfo(
      id,
      abortTrigger: abortTrigger,
    );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Remove someone
  ///
  /// Anyone who has been on a bill is archived instead, so the history that produced their balance survives. `deleted` says which happened.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<Response> deletePersonWithHttpInfo(
    String id, {
    Future<void>? abortTrigger,
  }) async {
    // ignore: prefer_const_declarations
    final path = r'/money/people/{id}'.replaceAll('{id}', id);

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

  /// Remove someone
  ///
  /// Anyone who has been on a bill is archived instead, so the history that produced their balance survives. `deleted` says which happened.
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<DeletePersonResponse?> deletePerson(
    String id, {
    Future<void>? abortTrigger,
  }) async {
    final response = await deletePersonWithHttpInfo(
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
        'DeletePersonResponse',
      ) as DeletePersonResponse;
    }
    return null;
  }

  /// Undo a payback
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<Response> deleteSettlementWithHttpInfo(
    String id, {
    Future<void>? abortTrigger,
  }) async {
    // ignore: prefer_const_declarations
    final path = r'/money/settlements/{id}'.replaceAll('{id}', id);

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

  /// Undo a payback
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<void> deleteSettlement(
    String id, {
    Future<void>? abortTrigger,
  }) async {
    final response = await deleteSettlementWithHttpInfo(
      id,
      abortTrigger: abortTrigger,
    );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Load every balance, the groups, and the headline totals
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> getMoneyOverviewWithHttpInfo({
    Future<void>? abortTrigger,
  }) async {
    // ignore: prefer_const_declarations
    final path = r'/money';

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

  /// Load every balance, the groups, and the headline totals
  Future<MoneyOverviewResponse?> getMoneyOverview({
    Future<void>? abortTrigger,
  }) async {
    final response = await getMoneyOverviewWithHttpInfo(
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
        'MoneyOverviewResponse',
      ) as MoneyOverviewResponse;
    }
    return null;
  }

  /// Load one person's whole history with the user
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<Response> getPersonLedgerWithHttpInfo(
    String id, {
    Future<void>? abortTrigger,
  }) async {
    // ignore: prefer_const_declarations
    final path = r'/money/people/{id}/ledger'.replaceAll('{id}', id);

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

  /// Load one person's whole history with the user
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<PersonLedgerResponse?> getPersonLedger(
    String id, {
    Future<void>? abortTrigger,
  }) async {
    final response = await getPersonLedgerWithHttpInfo(
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
        'PersonLedgerResponse',
      ) as PersonLedgerResponse;
    }
    return null;
  }

  /// List bills newest first
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] personId:
  ///   Only bills this person is on, or fronted.
  ///
  /// * [String] groupId:
  ///
  /// * [String] cursor:
  ///
  /// * [int] limit:
  Future<Response> listExpensesWithHttpInfo({
    String? personId,
    String? groupId,
    String? cursor,
    int? limit,
    Future<void>? abortTrigger,
  }) async {
    // ignore: prefer_const_declarations
    final path = r'/money/expenses';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (personId != null) {
      queryParams.addAll(_queryParams('', 'personId', personId));
    }
    if (groupId != null) {
      queryParams.addAll(_queryParams('', 'groupId', groupId));
    }
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

  /// List bills newest first
  ///
  /// Parameters:
  ///
  /// * [String] personId:
  ///   Only bills this person is on, or fronted.
  ///
  /// * [String] groupId:
  ///
  /// * [String] cursor:
  ///
  /// * [int] limit:
  Future<ExpenseListResponse?> listExpenses({
    String? personId,
    String? groupId,
    String? cursor,
    int? limit,
    Future<void>? abortTrigger,
  }) async {
    final response = await listExpensesWithHttpInfo(
      personId: personId,
      groupId: groupId,
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
        'ExpenseListResponse',
      ) as ExpenseListResponse;
    }
    return null;
  }

  /// List groups with their member ids
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> listGroupsWithHttpInfo({
    Future<void>? abortTrigger,
  }) async {
    // ignore: prefer_const_declarations
    final path = r'/money/groups';

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

  /// List groups with their member ids
  Future<GroupListResponse?> listGroups({
    Future<void>? abortTrigger,
  }) async {
    final response = await listGroupsWithHttpInfo(
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
        'GroupListResponse',
      ) as GroupListResponse;
    }
    return null;
  }

  /// List everyone, archived included, in display order
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> listPeopleWithHttpInfo({
    Future<void>? abortTrigger,
  }) async {
    // ignore: prefer_const_declarations
    final path = r'/money/people';

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

  /// List everyone, archived included, in display order
  Future<PersonListResponse?> listPeople({
    Future<void>? abortTrigger,
  }) async {
    final response = await listPeopleWithHttpInfo(
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
        'PersonListResponse',
      ) as PersonListResponse;
    }
    return null;
  }

  /// List paybacks, newest first
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] personId:
  Future<Response> listSettlementsWithHttpInfo({
    String? personId,
    Future<void>? abortTrigger,
  }) async {
    // ignore: prefer_const_declarations
    final path = r'/money/settlements';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (personId != null) {
      queryParams.addAll(_queryParams('', 'personId', personId));
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

  /// List paybacks, newest first
  ///
  /// Parameters:
  ///
  /// * [String] personId:
  Future<SettlementListResponse?> listSettlements({
    String? personId,
    Future<void>? abortTrigger,
  }) async {
    final response = await listSettlementsWithHttpInfo(
      personId: personId,
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
        'SettlementListResponse',
      ) as SettlementListResponse;
    }
    return null;
  }

  /// Edit a bill
  ///
  /// Omitted fields stay unchanged. Anything that can move the numbers re-runs the split; fields left out of a re-split fall back to how the bill already looks.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [UpdateExpenseRequest] updateExpenseRequest (required):
  Future<Response> updateExpenseWithHttpInfo(
    String id,
    UpdateExpenseRequest updateExpenseRequest, {
    Future<void>? abortTrigger,
  }) async {
    // ignore: prefer_const_declarations
    final path = r'/money/expenses/{id}'.replaceAll('{id}', id);

    // ignore: prefer_final_locals
    Object? postBody = updateExpenseRequest;

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

  /// Edit a bill
  ///
  /// Omitted fields stay unchanged. Anything that can move the numbers re-runs the split; fields left out of a re-split fall back to how the bill already looks.
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [UpdateExpenseRequest] updateExpenseRequest (required):
  Future<ExpenseResponse?> updateExpense(
    String id,
    UpdateExpenseRequest updateExpenseRequest, {
    Future<void>? abortTrigger,
  }) async {
    final response = await updateExpenseWithHttpInfo(
      id,
      updateExpenseRequest,
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
        'ExpenseResponse',
      ) as ExpenseResponse;
    }
    return null;
  }

  /// Rename, restyle, change membership, archive, or restore a group
  ///
  /// Sending `memberIds` replaces the membership wholesale; omitting it leaves the members alone.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [UpdateGroupRequest] updateGroupRequest (required):
  Future<Response> updateGroupWithHttpInfo(
    String id,
    UpdateGroupRequest updateGroupRequest, {
    Future<void>? abortTrigger,
  }) async {
    // ignore: prefer_const_declarations
    final path = r'/money/groups/{id}'.replaceAll('{id}', id);

    // ignore: prefer_final_locals
    Object? postBody = updateGroupRequest;

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

  /// Rename, restyle, change membership, archive, or restore a group
  ///
  /// Sending `memberIds` replaces the membership wholesale; omitting it leaves the members alone.
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [UpdateGroupRequest] updateGroupRequest (required):
  Future<GroupResponse?> updateGroup(
    String id,
    UpdateGroupRequest updateGroupRequest, {
    Future<void>? abortTrigger,
  }) async {
    final response = await updateGroupWithHttpInfo(
      id,
      updateGroupRequest,
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
        'GroupResponse',
      ) as GroupResponse;
    }
    return null;
  }

  /// Rename, restyle, reorder, archive, or restore someone
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [UpdatePersonRequest] updatePersonRequest (required):
  Future<Response> updatePersonWithHttpInfo(
    String id,
    UpdatePersonRequest updatePersonRequest, {
    Future<void>? abortTrigger,
  }) async {
    // ignore: prefer_const_declarations
    final path = r'/money/people/{id}'.replaceAll('{id}', id);

    // ignore: prefer_final_locals
    Object? postBody = updatePersonRequest;

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

  /// Rename, restyle, reorder, archive, or restore someone
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [UpdatePersonRequest] updatePersonRequest (required):
  Future<PersonResponse?> updatePerson(
    String id,
    UpdatePersonRequest updatePersonRequest, {
    Future<void>? abortTrigger,
  }) async {
    final response = await updatePersonWithHttpInfo(
      id,
      updatePersonRequest,
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
        'PersonResponse',
      ) as PersonResponse;
    }
    return null;
  }

  /// Correct a payback
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [UpdateSettlementRequest] updateSettlementRequest (required):
  Future<Response> updateSettlementWithHttpInfo(
    String id,
    UpdateSettlementRequest updateSettlementRequest, {
    Future<void>? abortTrigger,
  }) async {
    // ignore: prefer_const_declarations
    final path = r'/money/settlements/{id}'.replaceAll('{id}', id);

    // ignore: prefer_final_locals
    Object? postBody = updateSettlementRequest;

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

  /// Correct a payback
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [UpdateSettlementRequest] updateSettlementRequest (required):
  Future<SettlementResponse?> updateSettlement(
    String id,
    UpdateSettlementRequest updateSettlementRequest, {
    Future<void>? abortTrigger,
  }) async {
    final response = await updateSettlementWithHttpInfo(
      id,
      updateSettlementRequest,
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
        'SettlementResponse',
      ) as SettlementResponse;
    }
    return null;
  }
}
