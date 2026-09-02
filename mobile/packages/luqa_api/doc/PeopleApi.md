# luqa_api.api.PeopleApi

## Load the API package
```dart
import 'package:luqa_api/api.dart';
```

All URIs are relative to */api/v1*

Method | HTTP request | Description
------------- | ------------- | -------------
[**addPersonGift**](PeopleApi.md#addpersongift) | **POST** /people/{id}/gifts | Something to give them
[**addPersonNote**](PeopleApi.md#addpersonnote) | **POST** /people/{id}/notes | Write something down about them
[**addPersonPlace**](PeopleApi.md#addpersonplace) | **POST** /people/{id}/places | A city they can be found in
[**createPersonProfile**](PeopleApi.md#createpersonprofile) | **POST** /people | Add someone, identity and profile in one write
[**deletePersonGift**](PeopleApi.md#deletepersongift) | **DELETE** /people/{id}/gifts/{giftId} | Drop a gift idea
[**deletePersonNote**](PeopleApi.md#deletepersonnote) | **DELETE** /people/{id}/notes/{noteId} | Remove a note
[**deletePersonPlace**](PeopleApi.md#deletepersonplace) | **DELETE** /people/{id}/places/{placeId} | Drop a city
[**deletePersonProfile**](PeopleApi.md#deletepersonprofile) | **DELETE** /people/{id} | Remove someone, as far as it is safe to
[**geocodePendingPlaces**](PeopleApi.md#geocodependingplaces) | **POST** /people/places/geocode | Put points on the cities that have none yet
[**getPersonProfile**](PeopleApi.md#getpersonprofile) | **GET** /people/{id} | One person, whole profile
[**listPeopleProfiles**](PeopleApi.md#listpeopleprofiles) | **GET** /people | Everyone, archived included, each with their whole profile
[**markPersonSeen**](PeopleApi.md#markpersonseen) | **POST** /people/{id}/seen | Record that they were actually seen
[**searchCities**](PeopleApi.md#searchcities) | **GET** /people/places/search | The cities a name might mean
[**updatePersonGift**](PeopleApi.md#updatepersongift) | **PATCH** /people/{id}/gifts/{giftId} | Reword an idea, or mark it given
[**updatePersonNote**](PeopleApi.md#updatepersonnote) | **PATCH** /people/{id}/notes/{noteId} | Edit or pin a note
[**updatePersonProfile**](PeopleApi.md#updatepersonprofile) | **PATCH** /people/{id} | Rename, restyle, or change the profile


# **addPersonGift**
> PersonResponse addPersonGift(id, createPersonGiftRequest)

Something to give them

### Example
```dart
import 'package:luqa_api/api.dart';
// TODO Configure HTTP Bearer authorization: mobileBearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('mobileBearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('mobileBearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = PeopleApi();
final id = id_example; // String |
final createPersonGiftRequest = CreatePersonGiftRequest(); // CreatePersonGiftRequest |

try {
    final result = api_instance.addPersonGift(id, createPersonGiftRequest);
    print(result);
} catch (e) {
    print('Exception when calling PeopleApi->addPersonGift: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  |
 **createPersonGiftRequest** | [**CreatePersonGiftRequest**](CreatePersonGiftRequest.md)|  |

### Return type

[**PersonResponse**](PersonResponse.md)

### Authorization

[mobileBearer](../README.md#mobileBearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **addPersonNote**
> PersonResponse addPersonNote(id, createPersonNoteRequest)

Write something down about them

Answers with the whole person rather than the note: one row is one profile, so the client replaces what it has instead of splicing a child into it.

### Example
```dart
import 'package:luqa_api/api.dart';
// TODO Configure HTTP Bearer authorization: mobileBearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('mobileBearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('mobileBearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = PeopleApi();
final id = id_example; // String |
final createPersonNoteRequest = CreatePersonNoteRequest(); // CreatePersonNoteRequest |

try {
    final result = api_instance.addPersonNote(id, createPersonNoteRequest);
    print(result);
} catch (e) {
    print('Exception when calling PeopleApi->addPersonNote: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  |
 **createPersonNoteRequest** | [**CreatePersonNoteRequest**](CreatePersonNoteRequest.md)|  |

### Return type

[**PersonResponse**](PersonResponse.md)

### Authorization

[mobileBearer](../README.md#mobileBearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **addPersonPlace**
> PersonResponse addPersonPlace(id, createPersonPlaceRequest)

A city they can be found in

### Example
```dart
import 'package:luqa_api/api.dart';
// TODO Configure HTTP Bearer authorization: mobileBearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('mobileBearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('mobileBearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = PeopleApi();
final id = id_example; // String |
final createPersonPlaceRequest = CreatePersonPlaceRequest(); // CreatePersonPlaceRequest |

try {
    final result = api_instance.addPersonPlace(id, createPersonPlaceRequest);
    print(result);
} catch (e) {
    print('Exception when calling PeopleApi->addPersonPlace: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  |
 **createPersonPlaceRequest** | [**CreatePersonPlaceRequest**](CreatePersonPlaceRequest.md)|  |

### Return type

[**PersonResponse**](PersonResponse.md)

### Authorization

[mobileBearer](../README.md#mobileBearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **createPersonProfile**
> PersonResponse createPersonProfile(createPersonRequest)

Add someone, identity and profile in one write

One write rather than a create plus a patch, because the editor asks for a name, a birthday and a rhythm on the same sheet — and two queue entries for one action leaves the second one strandable on its own.

### Example
```dart
import 'package:luqa_api/api.dart';
// TODO Configure HTTP Bearer authorization: mobileBearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('mobileBearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('mobileBearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = PeopleApi();
final createPersonRequest = CreatePersonRequest(); // CreatePersonRequest |

try {
    final result = api_instance.createPersonProfile(createPersonRequest);
    print(result);
} catch (e) {
    print('Exception when calling PeopleApi->createPersonProfile: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **createPersonRequest** | [**CreatePersonRequest**](CreatePersonRequest.md)|  |

### Return type

[**PersonResponse**](PersonResponse.md)

### Authorization

[mobileBearer](../README.md#mobileBearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **deletePersonGift**
> PersonResponse deletePersonGift(id, giftId)

Drop a gift idea

### Example
```dart
import 'package:luqa_api/api.dart';
// TODO Configure HTTP Bearer authorization: mobileBearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('mobileBearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('mobileBearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = PeopleApi();
final id = id_example; // String |
final giftId = giftId_example; // String |

try {
    final result = api_instance.deletePersonGift(id, giftId);
    print(result);
} catch (e) {
    print('Exception when calling PeopleApi->deletePersonGift: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  |
 **giftId** | **String**|  |

### Return type

[**PersonResponse**](PersonResponse.md)

### Authorization

[mobileBearer](../README.md#mobileBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **deletePersonNote**
> PersonResponse deletePersonNote(id, noteId)

Remove a note

Succeeds on a note that is already gone, so a removal replayed from a queue cannot fail on its second attempt.

### Example
```dart
import 'package:luqa_api/api.dart';
// TODO Configure HTTP Bearer authorization: mobileBearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('mobileBearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('mobileBearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = PeopleApi();
final id = id_example; // String |
final noteId = noteId_example; // String |

try {
    final result = api_instance.deletePersonNote(id, noteId);
    print(result);
} catch (e) {
    print('Exception when calling PeopleApi->deletePersonNote: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  |
 **noteId** | **String**|  |

### Return type

[**PersonResponse**](PersonResponse.md)

### Authorization

[mobileBearer](../README.md#mobileBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **deletePersonPlace**
> PersonResponse deletePersonPlace(id, placeId)

Drop a city

Removing the primary promotes the oldest remaining place, so \"where are they\" does not go blank while cities are still on file.

### Example
```dart
import 'package:luqa_api/api.dart';
// TODO Configure HTTP Bearer authorization: mobileBearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('mobileBearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('mobileBearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = PeopleApi();
final id = id_example; // String |
final placeId = placeId_example; // String |

try {
    final result = api_instance.deletePersonPlace(id, placeId);
    print(result);
} catch (e) {
    print('Exception when calling PeopleApi->deletePersonPlace: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  |
 **placeId** | **String**|  |

### Return type

[**PersonResponse**](PersonResponse.md)

### Authorization

[mobileBearer](../README.md#mobileBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **deletePersonProfile**
> DeletePersonResponse deletePersonProfile(id)

Remove someone, as far as it is safe to

Anyone who has been on a bill is archived rather than deleted: their shares are what produced everyone else's balances, and a name that stops resolving turns old bills into arithmetic nobody can check. `deleted` says which happened, so the client knows whether to expect the row back.

### Example
```dart
import 'package:luqa_api/api.dart';
// TODO Configure HTTP Bearer authorization: mobileBearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('mobileBearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('mobileBearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = PeopleApi();
final id = id_example; // String |

try {
    final result = api_instance.deletePersonProfile(id);
    print(result);
} catch (e) {
    print('Exception when calling PeopleApi->deletePersonProfile: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  |

### Return type

[**DeletePersonResponse**](DeletePersonResponse.md)

### Authorization

[mobileBearer](../README.md#mobileBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **geocodePendingPlaces**
> GeocodeResponse geocodePendingPlaces()

Put points on the cities that have none yet

Pull rather than push. Adding a city answers instantly and the pin catches up: geocoding on the write path would make typing a city name wait on a rate-limited third party, and a serverless request cannot promise to finish background work after replying.  Only the city is ever sent to the geocoder, and only its centroid is stored. The map answers \"who is in this city\", which a centroid answers exactly as well as a street address would — without turning a record of friends' addresses into a map of their front doors.  Call it when opening the map, and again while `remaining` is above zero.

### Example
```dart
import 'package:luqa_api/api.dart';
// TODO Configure HTTP Bearer authorization: mobileBearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('mobileBearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('mobileBearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = PeopleApi();

try {
    final result = api_instance.geocodePendingPlaces();
    print(result);
} catch (e) {
    print('Exception when calling PeopleApi->geocodePendingPlaces: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**GeocodeResponse**](GeocodeResponse.md)

### Authorization

[mobileBearer](../README.md#mobileBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getPersonProfile**
> PersonResponse getPersonProfile(id)

One person, whole profile

### Example
```dart
import 'package:luqa_api/api.dart';
// TODO Configure HTTP Bearer authorization: mobileBearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('mobileBearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('mobileBearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = PeopleApi();
final id = id_example; // String |

try {
    final result = api_instance.getPersonProfile(id);
    print(result);
} catch (e) {
    print('Exception when calling PeopleApi->getPersonProfile: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  |

### Return type

[**PersonResponse**](PersonResponse.md)

### Authorization

[mobileBearer](../README.md#mobileBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listPeopleProfiles**
> PersonListResponse listPeopleProfiles()

Everyone, archived included, each with their whole profile

### Example
```dart
import 'package:luqa_api/api.dart';
// TODO Configure HTTP Bearer authorization: mobileBearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('mobileBearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('mobileBearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = PeopleApi();

try {
    final result = api_instance.listPeopleProfiles();
    print(result);
} catch (e) {
    print('Exception when calling PeopleApi->listPeopleProfiles: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**PersonListResponse**](PersonListResponse.md)

### Authorization

[mobileBearer](../README.md#mobileBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **markPersonSeen**
> PersonResponse markPersonSeen(id, markSeenRequest)

Record that they were actually seen

Its own endpoint rather than a PATCH field, because it carries a rule a general update does not: a \"saw them on Tuesday\" replayed from a queue on Friday must not drag the date back past a sighting already recorded since.

### Example
```dart
import 'package:luqa_api/api.dart';
// TODO Configure HTTP Bearer authorization: mobileBearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('mobileBearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('mobileBearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = PeopleApi();
final id = id_example; // String |
final markSeenRequest = MarkSeenRequest(); // MarkSeenRequest |

try {
    final result = api_instance.markPersonSeen(id, markSeenRequest);
    print(result);
} catch (e) {
    print('Exception when calling PeopleApi->markPersonSeen: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  |
 **markSeenRequest** | [**MarkSeenRequest**](MarkSeenRequest.md)|  | [optional]

### Return type

[**PersonResponse**](PersonResponse.md)

### Authorization

[mobileBearer](../README.md#mobileBearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **searchCities**
> CitySearchResponse searchCities(q, limit)

The cities a name might mean

So that the owner decides which Springfield, rather than a geocoder deciding for them. Each candidate carries its administrative area, its country and its population — the fields that make two rows both reading \"Springfield\" tellable apart — and a stable id, which is what the place then stores.  Answering also fills the server's city cache, which is what lets the subsequent `POST /people/{id}/places` resolve that id without touching a third party.  Safe to call per keystroke behind a short debounce: repeated queries are answered from the cache.

### Example
```dart
import 'package:luqa_api/api.dart';
// TODO Configure HTTP Bearer authorization: mobileBearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('mobileBearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('mobileBearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = PeopleApi();
final q = q_example; // String | What has been typed so far. Under two characters answers with nothing.
final limit = 56; // int |

try {
    final result = api_instance.searchCities(q, limit);
    print(result);
} catch (e) {
    print('Exception when calling PeopleApi->searchCities: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **q** | **String**| What has been typed so far. Under two characters answers with nothing. |
 **limit** | **int**|  | [optional]

### Return type

[**CitySearchResponse**](CitySearchResponse.md)

### Authorization

[mobileBearer](../README.md#mobileBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **updatePersonGift**
> PersonResponse updatePersonGift(id, giftId, updatePersonGiftRequest)

Reword an idea, or mark it given

### Example
```dart
import 'package:luqa_api/api.dart';
// TODO Configure HTTP Bearer authorization: mobileBearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('mobileBearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('mobileBearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = PeopleApi();
final id = id_example; // String |
final giftId = giftId_example; // String |
final updatePersonGiftRequest = UpdatePersonGiftRequest(); // UpdatePersonGiftRequest |

try {
    final result = api_instance.updatePersonGift(id, giftId, updatePersonGiftRequest);
    print(result);
} catch (e) {
    print('Exception when calling PeopleApi->updatePersonGift: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  |
 **giftId** | **String**|  |
 **updatePersonGiftRequest** | [**UpdatePersonGiftRequest**](UpdatePersonGiftRequest.md)|  |

### Return type

[**PersonResponse**](PersonResponse.md)

### Authorization

[mobileBearer](../README.md#mobileBearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **updatePersonNote**
> PersonResponse updatePersonNote(id, noteId, updatePersonNoteRequest)

Edit or pin a note

### Example
```dart
import 'package:luqa_api/api.dart';
// TODO Configure HTTP Bearer authorization: mobileBearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('mobileBearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('mobileBearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = PeopleApi();
final id = id_example; // String |
final noteId = noteId_example; // String |
final updatePersonNoteRequest = UpdatePersonNoteRequest(); // UpdatePersonNoteRequest |

try {
    final result = api_instance.updatePersonNote(id, noteId, updatePersonNoteRequest);
    print(result);
} catch (e) {
    print('Exception when calling PeopleApi->updatePersonNote: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  |
 **noteId** | **String**|  |
 **updatePersonNoteRequest** | [**UpdatePersonNoteRequest**](UpdatePersonNoteRequest.md)|  |

### Return type

[**PersonResponse**](PersonResponse.md)

### Authorization

[mobileBearer](../README.md#mobileBearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **updatePersonProfile**
> PersonResponse updatePersonProfile(id, updatePersonRequest)

Rename, restyle, or change the profile

### Example
```dart
import 'package:luqa_api/api.dart';
// TODO Configure HTTP Bearer authorization: mobileBearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('mobileBearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('mobileBearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = PeopleApi();
final id = id_example; // String |
final updatePersonRequest = UpdatePersonRequest(); // UpdatePersonRequest |

try {
    final result = api_instance.updatePersonProfile(id, updatePersonRequest);
    print(result);
} catch (e) {
    print('Exception when calling PeopleApi->updatePersonProfile: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  |
 **updatePersonRequest** | [**UpdatePersonRequest**](UpdatePersonRequest.md)|  |

### Return type

[**PersonResponse**](PersonResponse.md)

### Authorization

[mobileBearer](../README.md#mobileBearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)
