# luqa_api.api.SyncApi

## Load the API package
```dart
import 'package:luqa_api/api.dart';
```

All URIs are relative to */api/v1*

Method | HTTP request | Description
------------- | ------------- | -------------
[**syncChanges**](SyncApi.md#syncchanges) | **GET** /sync | Everything that changed since the cursors the caller holds


# **syncChanges**
> SyncResponse syncChanges(collections, limit, cursorPeriodCategories, cursorPeriodPeople, cursorPeriodGroups, cursorPeriodGymLocations, cursorPeriodExercises, cursorPeriodTimeEntries, cursorPeriodSleepEntries, cursorPeriodExpenses, cursorPeriodSettlements, cursorPeriodGymSessions)

Everything that changed since the cursors the caller holds

The delta feed. A device keeps one cursor per collection and asks for what changed since; omitting a cursor asks for that collection from the beginning, which is what a fresh install does.  Cursors are opaque and per collection, passed as `cursor.<name>`. A collection that reaches `limit` answers `hasMore: true` and is asked again with the cursor it returned. A cursor that cannot be read is treated as absent — the collection resyncs from the start, which is slow but always correct.  Rows and deletions are reported separately: `rows` carries the current state of anything created or changed, `deleted` carries the ids of rows that went away so a device can drop its copies.

### Example
```dart
import 'package:luqa_api/api.dart';
// TODO Configure HTTP Bearer authorization: mobileBearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('mobileBearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('mobileBearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = SyncApi();
final collections = people,expenses; // String | Comma-separated subset to sync. Defaults to all of them. Unknown names are ignored.
final limit = 56; // int | Maximum rows per collection per request.
final cursorPeriodCategories = cursorPeriodCategories_example; // String |
final cursorPeriodPeople = cursorPeriodPeople_example; // String |
final cursorPeriodGroups = cursorPeriodGroups_example; // String |
final cursorPeriodGymLocations = cursorPeriodGymLocations_example; // String |
final cursorPeriodExercises = cursorPeriodExercises_example; // String |
final cursorPeriodTimeEntries = cursorPeriodTimeEntries_example; // String |
final cursorPeriodSleepEntries = cursorPeriodSleepEntries_example; // String |
final cursorPeriodExpenses = cursorPeriodExpenses_example; // String |
final cursorPeriodSettlements = cursorPeriodSettlements_example; // String |
final cursorPeriodGymSessions = cursorPeriodGymSessions_example; // String |

try {
    final result = api_instance.syncChanges(collections, limit, cursorPeriodCategories, cursorPeriodPeople, cursorPeriodGroups, cursorPeriodGymLocations, cursorPeriodExercises, cursorPeriodTimeEntries, cursorPeriodSleepEntries, cursorPeriodExpenses, cursorPeriodSettlements, cursorPeriodGymSessions);
    print(result);
} catch (e) {
    print('Exception when calling SyncApi->syncChanges: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **collections** | **String**| Comma-separated subset to sync. Defaults to all of them. Unknown names are ignored. | [optional]
 **limit** | **int**| Maximum rows per collection per request. | [optional] [default to 200]
 **cursorPeriodCategories** | **String**|  | [optional]
 **cursorPeriodPeople** | **String**|  | [optional]
 **cursorPeriodGroups** | **String**|  | [optional]
 **cursorPeriodGymLocations** | **String**|  | [optional]
 **cursorPeriodExercises** | **String**|  | [optional]
 **cursorPeriodTimeEntries** | **String**|  | [optional]
 **cursorPeriodSleepEntries** | **String**|  | [optional]
 **cursorPeriodExpenses** | **String**|  | [optional]
 **cursorPeriodSettlements** | **String**|  | [optional]
 **cursorPeriodGymSessions** | **String**|  | [optional]

### Return type

[**SyncResponse**](SyncResponse.md)

### Authorization

[mobileBearer](../README.md#mobileBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)
