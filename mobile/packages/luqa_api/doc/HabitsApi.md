# luqa_api.api.HabitsApi

## Load the API package
```dart
import 'package:luqa_api/api.dart';
```

All URIs are relative to */api/v1*

Method | HTTP request | Description
------------- | ------------- | -------------
[**archiveHabit**](HabitsApi.md#archivehabit) | **DELETE** /habits/{id} | Archive a habit
[**createHabit**](HabitsApi.md#createhabit) | **POST** /habits | Create a habit
[**listHabits**](HabitsApi.md#listhabits) | **GET** /habits | Every habit on the account, archived included
[**putHabitLog**](HabitsApi.md#puthabitlog) | **PUT** /habits/{id}/logs/{date} | Record a day's progress
[**reorderHabits**](HabitsApi.md#reorderhabits) | **POST** /habits/reorder | Persist a new ordering of habits
[**updateHabit**](HabitsApi.md#updatehabit) | **PATCH** /habits/{id} | Edit a habit's goal, schedule, icon, or archived state


# **archiveHabit**
> archiveHabit(id)

Archive a habit

Habits are archived rather than removed. The logs behind one are the record of a stretch of someone's life, and a streak that can be deleted by accident is worse than a list that needs tidying. Archiving one that is already archived succeeds.

### Example
```dart
import 'package:luqa_api/api.dart';
// TODO Configure HTTP Bearer authorization: mobileBearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('mobileBearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('mobileBearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = HabitsApi();
final id = id_example; // String |

try {
    api_instance.archiveHabit(id);
} catch (e) {
    print('Exception when calling HabitsApi->archiveHabit: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  |

### Return type

void (empty response body)

### Authorization

[mobileBearer](../README.md#mobileBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **createHabit**
> HabitResponse createHabit(createHabitRequest)

Create a habit

### Example
```dart
import 'package:luqa_api/api.dart';
// TODO Configure HTTP Bearer authorization: mobileBearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('mobileBearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('mobileBearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = HabitsApi();
final createHabitRequest = CreateHabitRequest(); // CreateHabitRequest |

try {
    final result = api_instance.createHabit(createHabitRequest);
    print(result);
} catch (e) {
    print('Exception when calling HabitsApi->createHabit: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **createHabitRequest** | [**CreateHabitRequest**](CreateHabitRequest.md)|  |

### Return type

[**HabitResponse**](HabitResponse.md)

### Authorization

[mobileBearer](../README.md#mobileBearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listHabits**
> HabitListResponse listHabits()

Every habit on the account, archived included

The delta feed is how a device normally stays current. This is the first read after a sign-in, and the recovery path for a cache that had to be thrown away: one page, no cursor, always complete.

### Example
```dart
import 'package:luqa_api/api.dart';
// TODO Configure HTTP Bearer authorization: mobileBearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('mobileBearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('mobileBearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = HabitsApi();

try {
    final result = api_instance.listHabits();
    print(result);
} catch (e) {
    print('Exception when calling HabitsApi->listHabits: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**HabitListResponse**](HabitListResponse.md)

### Authorization

[mobileBearer](../README.md#mobileBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **putHabitLog**
> HabitLogResponse putHabitLog(id, date, putHabitLogRequest)

Record a day's progress

A PUT of state rather than a POST of an action. The browser posts \"increment\" and lets the server add one; a queued write cannot, because a retry after a lost response would add one twice. A device resolves habits locally, so it already knows what the day looks like and sends the numbers — replaying the write lands on the same numbers.  Completion is recomputed from the habit's goal rather than taken from the request, so the two clients cannot disagree about what a streak is made of. The moment a day was first completed is kept once it is known.

### Example
```dart
import 'package:luqa_api/api.dart';
// TODO Configure HTTP Bearer authorization: mobileBearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('mobileBearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('mobileBearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = HabitsApi();
final id = id_example; // String |
final date = date_example; // String | The logical day, as a YYYY-MM-DD key in the user's timezone.
final putHabitLogRequest = PutHabitLogRequest(); // PutHabitLogRequest |

try {
    final result = api_instance.putHabitLog(id, date, putHabitLogRequest);
    print(result);
} catch (e) {
    print('Exception when calling HabitsApi->putHabitLog: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  |
 **date** | **String**| The logical day, as a YYYY-MM-DD key in the user's timezone. |
 **putHabitLogRequest** | [**PutHabitLogRequest**](PutHabitLogRequest.md)|  |

### Return type

[**HabitLogResponse**](HabitLogResponse.md)

### Authorization

[mobileBearer](../README.md#mobileBearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **reorderHabits**
> HabitListResponse reorderHabits(reorderHabitsRequest)

Persist a new ordering of habits

The whole ordering rather than one habit's new position, so a replayed write restates the order instead of shuffling it again. Ids the account does not own are ignored rather than refused.

### Example
```dart
import 'package:luqa_api/api.dart';
// TODO Configure HTTP Bearer authorization: mobileBearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('mobileBearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('mobileBearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = HabitsApi();
final reorderHabitsRequest = ReorderHabitsRequest(); // ReorderHabitsRequest |

try {
    final result = api_instance.reorderHabits(reorderHabitsRequest);
    print(result);
} catch (e) {
    print('Exception when calling HabitsApi->reorderHabits: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **reorderHabitsRequest** | [**ReorderHabitsRequest**](ReorderHabitsRequest.md)|  |

### Return type

[**HabitListResponse**](HabitListResponse.md)

### Authorization

[mobileBearer](../README.md#mobileBearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **updateHabit**
> HabitResponse updateHabit(id, updateHabitRequest)

Edit a habit's goal, schedule, icon, or archived state

### Example
```dart
import 'package:luqa_api/api.dart';
// TODO Configure HTTP Bearer authorization: mobileBearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('mobileBearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('mobileBearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = HabitsApi();
final id = id_example; // String |
final updateHabitRequest = UpdateHabitRequest(); // UpdateHabitRequest |

try {
    final result = api_instance.updateHabit(id, updateHabitRequest);
    print(result);
} catch (e) {
    print('Exception when calling HabitsApi->updateHabit: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  |
 **updateHabitRequest** | [**UpdateHabitRequest**](UpdateHabitRequest.md)|  |

### Return type

[**HabitResponse**](HabitResponse.md)

### Authorization

[mobileBearer](../README.md#mobileBearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)
