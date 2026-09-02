//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class PeopleApi {
  PeopleApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Something to give them
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [CreatePersonGiftRequest] createPersonGiftRequest (required):
  Future<Response> addPersonGiftWithHttpInfo(
    String id,
    CreatePersonGiftRequest createPersonGiftRequest, {
    Future<void>? abortTrigger,
  }) async {
    // ignore: prefer_const_declarations
    final path = r'/people/{id}/gifts'.replaceAll('{id}', id);

    // ignore: prefer_final_locals
    Object? postBody = createPersonGiftRequest;

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

  /// Something to give them
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [CreatePersonGiftRequest] createPersonGiftRequest (required):
  Future<PersonResponse?> addPersonGift(
    String id,
    CreatePersonGiftRequest createPersonGiftRequest, {
    Future<void>? abortTrigger,
  }) async {
    final response = await addPersonGiftWithHttpInfo(
      id,
      createPersonGiftRequest,
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

  /// Write something down about them
  ///
  /// Answers with the whole person rather than the note: one row is one profile, so the client replaces what it has instead of splicing a child into it.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [CreatePersonNoteRequest] createPersonNoteRequest (required):
  Future<Response> addPersonNoteWithHttpInfo(
    String id,
    CreatePersonNoteRequest createPersonNoteRequest, {
    Future<void>? abortTrigger,
  }) async {
    // ignore: prefer_const_declarations
    final path = r'/people/{id}/notes'.replaceAll('{id}', id);

    // ignore: prefer_final_locals
    Object? postBody = createPersonNoteRequest;

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

  /// Write something down about them
  ///
  /// Answers with the whole person rather than the note: one row is one profile, so the client replaces what it has instead of splicing a child into it.
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [CreatePersonNoteRequest] createPersonNoteRequest (required):
  Future<PersonResponse?> addPersonNote(
    String id,
    CreatePersonNoteRequest createPersonNoteRequest, {
    Future<void>? abortTrigger,
  }) async {
    final response = await addPersonNoteWithHttpInfo(
      id,
      createPersonNoteRequest,
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

  /// A city they can be found in
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [CreatePersonPlaceRequest] createPersonPlaceRequest (required):
  Future<Response> addPersonPlaceWithHttpInfo(
    String id,
    CreatePersonPlaceRequest createPersonPlaceRequest, {
    Future<void>? abortTrigger,
  }) async {
    // ignore: prefer_const_declarations
    final path = r'/people/{id}/places'.replaceAll('{id}', id);

    // ignore: prefer_final_locals
    Object? postBody = createPersonPlaceRequest;

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

  /// A city they can be found in
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [CreatePersonPlaceRequest] createPersonPlaceRequest (required):
  Future<PersonResponse?> addPersonPlace(
    String id,
    CreatePersonPlaceRequest createPersonPlaceRequest, {
    Future<void>? abortTrigger,
  }) async {
    final response = await addPersonPlaceWithHttpInfo(
      id,
      createPersonPlaceRequest,
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

  /// Add someone, identity and profile in one write
  ///
  /// One write rather than a create plus a patch, because the editor asks for a name, a birthday and a rhythm on the same sheet — and two queue entries for one action leaves the second one strandable on its own.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [CreatePersonRequest] createPersonRequest (required):
  Future<Response> createPersonProfileWithHttpInfo(
    CreatePersonRequest createPersonRequest, {
    Future<void>? abortTrigger,
  }) async {
    // ignore: prefer_const_declarations
    final path = r'/people';

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

  /// Add someone, identity and profile in one write
  ///
  /// One write rather than a create plus a patch, because the editor asks for a name, a birthday and a rhythm on the same sheet — and two queue entries for one action leaves the second one strandable on its own.
  ///
  /// Parameters:
  ///
  /// * [CreatePersonRequest] createPersonRequest (required):
  Future<PersonResponse?> createPersonProfile(
    CreatePersonRequest createPersonRequest, {
    Future<void>? abortTrigger,
  }) async {
    final response = await createPersonProfileWithHttpInfo(
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

  /// Drop a gift idea
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [String] giftId (required):
  Future<Response> deletePersonGiftWithHttpInfo(
    String id,
    String giftId, {
    Future<void>? abortTrigger,
  }) async {
    // ignore: prefer_const_declarations
    final path = r'/people/{id}/gifts/{giftId}'
        .replaceAll('{id}', id)
        .replaceAll('{giftId}', giftId);

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

  /// Drop a gift idea
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [String] giftId (required):
  Future<PersonResponse?> deletePersonGift(
    String id,
    String giftId, {
    Future<void>? abortTrigger,
  }) async {
    final response = await deletePersonGiftWithHttpInfo(
      id,
      giftId,
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

  /// Remove a note
  ///
  /// Succeeds on a note that is already gone, so a removal replayed from a queue cannot fail on its second attempt.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [String] noteId (required):
  Future<Response> deletePersonNoteWithHttpInfo(
    String id,
    String noteId, {
    Future<void>? abortTrigger,
  }) async {
    // ignore: prefer_const_declarations
    final path = r'/people/{id}/notes/{noteId}'
        .replaceAll('{id}', id)
        .replaceAll('{noteId}', noteId);

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

  /// Remove a note
  ///
  /// Succeeds on a note that is already gone, so a removal replayed from a queue cannot fail on its second attempt.
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [String] noteId (required):
  Future<PersonResponse?> deletePersonNote(
    String id,
    String noteId, {
    Future<void>? abortTrigger,
  }) async {
    final response = await deletePersonNoteWithHttpInfo(
      id,
      noteId,
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

  /// Drop a city
  ///
  /// Removing the primary promotes the oldest remaining place, so \"where are they\" does not go blank while cities are still on file.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [String] placeId (required):
  Future<Response> deletePersonPlaceWithHttpInfo(
    String id,
    String placeId, {
    Future<void>? abortTrigger,
  }) async {
    // ignore: prefer_const_declarations
    final path = r'/people/{id}/places/{placeId}'
        .replaceAll('{id}', id)
        .replaceAll('{placeId}', placeId);

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

  /// Drop a city
  ///
  /// Removing the primary promotes the oldest remaining place, so \"where are they\" does not go blank while cities are still on file.
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [String] placeId (required):
  Future<PersonResponse?> deletePersonPlace(
    String id,
    String placeId, {
    Future<void>? abortTrigger,
  }) async {
    final response = await deletePersonPlaceWithHttpInfo(
      id,
      placeId,
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

  /// Remove someone, as far as it is safe to
  ///
  /// Anyone who has been on a bill is archived rather than deleted: their shares are what produced everyone else's balances, and a name that stops resolving turns old bills into arithmetic nobody can check. `deleted` says which happened, so the client knows whether to expect the row back.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<Response> deletePersonProfileWithHttpInfo(
    String id, {
    Future<void>? abortTrigger,
  }) async {
    // ignore: prefer_const_declarations
    final path = r'/people/{id}'.replaceAll('{id}', id);

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

  /// Remove someone, as far as it is safe to
  ///
  /// Anyone who has been on a bill is archived rather than deleted: their shares are what produced everyone else's balances, and a name that stops resolving turns old bills into arithmetic nobody can check. `deleted` says which happened, so the client knows whether to expect the row back.
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<DeletePersonResponse?> deletePersonProfile(
    String id, {
    Future<void>? abortTrigger,
  }) async {
    final response = await deletePersonProfileWithHttpInfo(
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

  /// Put points on the cities that have none yet
  ///
  /// Pull rather than push. Adding a city answers instantly and the pin catches up: geocoding on the write path would make typing a city name wait on a rate-limited third party, and a serverless request cannot promise to finish background work after replying.  Only the city is ever sent to the geocoder, and only its centroid is stored. The map answers \"who is in this city\", which a centroid answers exactly as well as a street address would — without turning a record of friends' addresses into a map of their front doors.  Call it when opening the map, and again while `remaining` is above zero.
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> geocodePendingPlacesWithHttpInfo({
    Future<void>? abortTrigger,
  }) async {
    // ignore: prefer_const_declarations
    final path = r'/people/places/geocode';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];

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

  /// Put points on the cities that have none yet
  ///
  /// Pull rather than push. Adding a city answers instantly and the pin catches up: geocoding on the write path would make typing a city name wait on a rate-limited third party, and a serverless request cannot promise to finish background work after replying.  Only the city is ever sent to the geocoder, and only its centroid is stored. The map answers \"who is in this city\", which a centroid answers exactly as well as a street address would — without turning a record of friends' addresses into a map of their front doors.  Call it when opening the map, and again while `remaining` is above zero.
  Future<GeocodeResponse?> geocodePendingPlaces({
    Future<void>? abortTrigger,
  }) async {
    final response = await geocodePendingPlacesWithHttpInfo(
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
        'GeocodeResponse',
      ) as GeocodeResponse;
    }
    return null;
  }

  /// One person, whole profile
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<Response> getPersonProfileWithHttpInfo(
    String id, {
    Future<void>? abortTrigger,
  }) async {
    // ignore: prefer_const_declarations
    final path = r'/people/{id}'.replaceAll('{id}', id);

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

  /// One person, whole profile
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  Future<PersonResponse?> getPersonProfile(
    String id, {
    Future<void>? abortTrigger,
  }) async {
    final response = await getPersonProfileWithHttpInfo(
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
        'PersonResponse',
      ) as PersonResponse;
    }
    return null;
  }

  /// Everyone, archived included, each with their whole profile
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> listPeopleProfilesWithHttpInfo({
    Future<void>? abortTrigger,
  }) async {
    // ignore: prefer_const_declarations
    final path = r'/people';

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

  /// Everyone, archived included, each with their whole profile
  Future<PersonListResponse?> listPeopleProfiles({
    Future<void>? abortTrigger,
  }) async {
    final response = await listPeopleProfilesWithHttpInfo(
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

  /// Record that they were actually seen
  ///
  /// Its own endpoint rather than a PATCH field, because it carries a rule a general update does not: a \"saw them on Tuesday\" replayed from a queue on Friday must not drag the date back past a sighting already recorded since.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [MarkSeenRequest] markSeenRequest:
  Future<Response> markPersonSeenWithHttpInfo(
    String id, {
    MarkSeenRequest? markSeenRequest,
    Future<void>? abortTrigger,
  }) async {
    // ignore: prefer_const_declarations
    final path = r'/people/{id}/seen'.replaceAll('{id}', id);

    // ignore: prefer_final_locals
    Object? postBody = markSeenRequest;

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

  /// Record that they were actually seen
  ///
  /// Its own endpoint rather than a PATCH field, because it carries a rule a general update does not: a \"saw them on Tuesday\" replayed from a queue on Friday must not drag the date back past a sighting already recorded since.
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [MarkSeenRequest] markSeenRequest:
  Future<PersonResponse?> markPersonSeen(
    String id, {
    MarkSeenRequest? markSeenRequest,
    Future<void>? abortTrigger,
  }) async {
    final response = await markPersonSeenWithHttpInfo(
      id,
      markSeenRequest: markSeenRequest,
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

  /// The cities a name might mean
  ///
  /// So that the owner decides which Springfield, rather than a geocoder deciding for them. Each candidate carries its administrative area, its country and its population — the fields that make two rows both reading \"Springfield\" tellable apart — and a stable id, which is what the place then stores.  Answering also fills the server's city cache, which is what lets the subsequent `POST /people/{id}/places` resolve that id without touching a third party.  Safe to call per keystroke behind a short debounce: repeated queries are answered from the cache.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] q (required):
  ///   What has been typed so far. Under two characters answers with nothing.
  ///
  /// * [int] limit:
  Future<Response> searchCitiesWithHttpInfo(
    String q, {
    int? limit,
    Future<void>? abortTrigger,
  }) async {
    // ignore: prefer_const_declarations
    final path = r'/people/places/search';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    queryParams.addAll(_queryParams('', 'q', q));
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

  /// The cities a name might mean
  ///
  /// So that the owner decides which Springfield, rather than a geocoder deciding for them. Each candidate carries its administrative area, its country and its population — the fields that make two rows both reading \"Springfield\" tellable apart — and a stable id, which is what the place then stores.  Answering also fills the server's city cache, which is what lets the subsequent `POST /people/{id}/places` resolve that id without touching a third party.  Safe to call per keystroke behind a short debounce: repeated queries are answered from the cache.
  ///
  /// Parameters:
  ///
  /// * [String] q (required):
  ///   What has been typed so far. Under two characters answers with nothing.
  ///
  /// * [int] limit:
  Future<CitySearchResponse?> searchCities(
    String q, {
    int? limit,
    Future<void>? abortTrigger,
  }) async {
    final response = await searchCitiesWithHttpInfo(
      q,
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
        'CitySearchResponse',
      ) as CitySearchResponse;
    }
    return null;
  }

  /// Reword an idea, or mark it given
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [String] giftId (required):
  ///
  /// * [UpdatePersonGiftRequest] updatePersonGiftRequest (required):
  Future<Response> updatePersonGiftWithHttpInfo(
    String id,
    String giftId,
    UpdatePersonGiftRequest updatePersonGiftRequest, {
    Future<void>? abortTrigger,
  }) async {
    // ignore: prefer_const_declarations
    final path = r'/people/{id}/gifts/{giftId}'
        .replaceAll('{id}', id)
        .replaceAll('{giftId}', giftId);

    // ignore: prefer_final_locals
    Object? postBody = updatePersonGiftRequest;

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

  /// Reword an idea, or mark it given
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [String] giftId (required):
  ///
  /// * [UpdatePersonGiftRequest] updatePersonGiftRequest (required):
  Future<PersonResponse?> updatePersonGift(
    String id,
    String giftId,
    UpdatePersonGiftRequest updatePersonGiftRequest, {
    Future<void>? abortTrigger,
  }) async {
    final response = await updatePersonGiftWithHttpInfo(
      id,
      giftId,
      updatePersonGiftRequest,
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

  /// Edit or pin a note
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [String] noteId (required):
  ///
  /// * [UpdatePersonNoteRequest] updatePersonNoteRequest (required):
  Future<Response> updatePersonNoteWithHttpInfo(
    String id,
    String noteId,
    UpdatePersonNoteRequest updatePersonNoteRequest, {
    Future<void>? abortTrigger,
  }) async {
    // ignore: prefer_const_declarations
    final path = r'/people/{id}/notes/{noteId}'
        .replaceAll('{id}', id)
        .replaceAll('{noteId}', noteId);

    // ignore: prefer_final_locals
    Object? postBody = updatePersonNoteRequest;

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

  /// Edit or pin a note
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [String] noteId (required):
  ///
  /// * [UpdatePersonNoteRequest] updatePersonNoteRequest (required):
  Future<PersonResponse?> updatePersonNote(
    String id,
    String noteId,
    UpdatePersonNoteRequest updatePersonNoteRequest, {
    Future<void>? abortTrigger,
  }) async {
    final response = await updatePersonNoteWithHttpInfo(
      id,
      noteId,
      updatePersonNoteRequest,
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

  /// Rename, restyle, or change the profile
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [UpdatePersonRequest] updatePersonRequest (required):
  Future<Response> updatePersonProfileWithHttpInfo(
    String id,
    UpdatePersonRequest updatePersonRequest, {
    Future<void>? abortTrigger,
  }) async {
    // ignore: prefer_const_declarations
    final path = r'/people/{id}'.replaceAll('{id}', id);

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

  /// Rename, restyle, or change the profile
  ///
  /// Parameters:
  ///
  /// * [String] id (required):
  ///
  /// * [UpdatePersonRequest] updatePersonRequest (required):
  Future<PersonResponse?> updatePersonProfile(
    String id,
    UpdatePersonRequest updatePersonRequest, {
    Future<void>? abortTrigger,
  }) async {
    final response = await updatePersonProfileWithHttpInfo(
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
}
