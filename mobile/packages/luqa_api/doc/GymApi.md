# luqa_api.api.GymApi

## Load the API package
```dart
import 'package:luqa_api/api.dart';
```

All URIs are relative to */api/v1*

Method | HTTP request | Description
------------- | ------------- | -------------
[**createGymLocation**](GymApi.md#creategymlocation) | **POST** /gym/locations | Add a gym
[**createGymSession**](GymApi.md#creategymsession) | **POST** /gym/sessions | Start an autosaved workout
[**getGymExerciseHistory**](GymApi.md#getgymexercisehistory) | **GET** /gym/exercises/{id}/history | Load one exercise's progress history
[**getGymOverview**](GymApi.md#getgymoverview) | **GET** /gym | Load gyms, exercises, per-gym references, and recent workouts
[**getGymSession**](GymApi.md#getgymsession) | **GET** /gym/sessions/{id} | Load one workout
[**listGymSessions**](GymApi.md#listgymsessions) | **GET** /gym/sessions | List workouts newest first
[**mergeGymExercise**](GymApi.md#mergegymexercise) | **POST** /gym/exercises/{id}/merge | Merge a duplicate exercise into another exercise
[**updateGymLocation**](GymApi.md#updategymlocation) | **PATCH** /gym/locations/{id} | Edit, archive, or restore a gym
[**updateGymSession**](GymApi.md#updategymsession) | **PATCH** /gym/sessions/{id} | Autosave a workout draft


# **createGymLocation**
> GymLocationResponse createGymLocation(createGymLocationRequest)

Add a gym

### Example
```dart
import 'package:luqa_api/api.dart';
// TODO Configure HTTP Bearer authorization: mobileBearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('mobileBearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('mobileBearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = GymApi();
final createGymLocationRequest = CreateGymLocationRequest(); // CreateGymLocationRequest |

try {
    final result = api_instance.createGymLocation(createGymLocationRequest);
    print(result);
} catch (e) {
    print('Exception when calling GymApi->createGymLocation: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **createGymLocationRequest** | [**CreateGymLocationRequest**](CreateGymLocationRequest.md)|  |

### Return type

[**GymLocationResponse**](GymLocationResponse.md)

### Authorization

[mobileBearer](../README.md#mobileBearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **createGymSession**
> GymSessionResponse createGymSession(createGymSessionRequest)

Start an autosaved workout

### Example
```dart
import 'package:luqa_api/api.dart';
// TODO Configure HTTP Bearer authorization: mobileBearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('mobileBearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('mobileBearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = GymApi();
final createGymSessionRequest = CreateGymSessionRequest(); // CreateGymSessionRequest |

try {
    final result = api_instance.createGymSession(createGymSessionRequest);
    print(result);
} catch (e) {
    print('Exception when calling GymApi->createGymSession: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **createGymSessionRequest** | [**CreateGymSessionRequest**](CreateGymSessionRequest.md)|  |

### Return type

[**GymSessionResponse**](GymSessionResponse.md)

### Authorization

[mobileBearer](../README.md#mobileBearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getGymExerciseHistory**
> GymExerciseHistoryResponse getGymExerciseHistory(id, locationId, beforeSessionId)

Load one exercise's progress history

### Example
```dart
import 'package:luqa_api/api.dart';
// TODO Configure HTTP Bearer authorization: mobileBearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('mobileBearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('mobileBearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = GymApi();
final id = id_example; // String |
final locationId = locationId_example; // String | Keep machine stacks from different gyms separate.
final beforeSessionId = beforeSessionId_example; // String | Return only performances before this workout.

try {
    final result = api_instance.getGymExerciseHistory(id, locationId, beforeSessionId);
    print(result);
} catch (e) {
    print('Exception when calling GymApi->getGymExerciseHistory: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  |
 **locationId** | **String**| Keep machine stacks from different gyms separate. | [optional]
 **beforeSessionId** | **String**| Return only performances before this workout. | [optional]

### Return type

[**GymExerciseHistoryResponse**](GymExerciseHistoryResponse.md)

### Authorization

[mobileBearer](../README.md#mobileBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getGymOverview**
> GymOverviewResponse getGymOverview(limit)

Load gyms, exercises, per-gym references, and recent workouts

### Example
```dart
import 'package:luqa_api/api.dart';
// TODO Configure HTTP Bearer authorization: mobileBearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('mobileBearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('mobileBearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = GymApi();
final limit = 56; // int |

try {
    final result = api_instance.getGymOverview(limit);
    print(result);
} catch (e) {
    print('Exception when calling GymApi->getGymOverview: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **limit** | **int**|  | [optional] [default to 30]

### Return type

[**GymOverviewResponse**](GymOverviewResponse.md)

### Authorization

[mobileBearer](../README.md#mobileBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getGymSession**
> GymSessionResponse getGymSession(id)

Load one workout

### Example
```dart
import 'package:luqa_api/api.dart';
// TODO Configure HTTP Bearer authorization: mobileBearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('mobileBearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('mobileBearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = GymApi();
final id = id_example; // String |

try {
    final result = api_instance.getGymSession(id);
    print(result);
} catch (e) {
    print('Exception when calling GymApi->getGymSession: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  |

### Return type

[**GymSessionResponse**](GymSessionResponse.md)

### Authorization

[mobileBearer](../README.md#mobileBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listGymSessions**
> GymSessionListResponse listGymSessions(cursor, limit)

List workouts newest first

### Example
```dart
import 'package:luqa_api/api.dart';
// TODO Configure HTTP Bearer authorization: mobileBearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('mobileBearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('mobileBearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = GymApi();
final cursor = cursor_example; // String |
final limit = 56; // int |

try {
    final result = api_instance.listGymSessions(cursor, limit);
    print(result);
} catch (e) {
    print('Exception when calling GymApi->listGymSessions: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **cursor** | **String**|  | [optional]
 **limit** | **int**|  | [optional] [default to 20]

### Return type

[**GymSessionListResponse**](GymSessionListResponse.md)

### Authorization

[mobileBearer](../README.md#mobileBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **mergeGymExercise**
> GymExerciseMergeResponse mergeGymExercise(id, mergeGymExerciseRequest)

Merge a duplicate exercise into another exercise

Moves every logged performance to the target exercise, keeps the target name, and removes the source exercise from the library.

### Example
```dart
import 'package:luqa_api/api.dart';
// TODO Configure HTTP Bearer authorization: mobileBearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('mobileBearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('mobileBearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = GymApi();
final id = id_example; // String | Exercise whose history will be moved and then removed.
final mergeGymExerciseRequest = MergeGymExerciseRequest(); // MergeGymExerciseRequest |

try {
    final result = api_instance.mergeGymExercise(id, mergeGymExerciseRequest);
    print(result);
} catch (e) {
    print('Exception when calling GymApi->mergeGymExercise: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**| Exercise whose history will be moved and then removed. |
 **mergeGymExerciseRequest** | [**MergeGymExerciseRequest**](MergeGymExerciseRequest.md)|  |

### Return type

[**GymExerciseMergeResponse**](GymExerciseMergeResponse.md)

### Authorization

[mobileBearer](../README.md#mobileBearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **updateGymLocation**
> GymLocationResponse updateGymLocation(id, updateGymLocationRequest)

Edit, archive, or restore a gym

### Example
```dart
import 'package:luqa_api/api.dart';
// TODO Configure HTTP Bearer authorization: mobileBearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('mobileBearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('mobileBearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = GymApi();
final id = id_example; // String |
final updateGymLocationRequest = UpdateGymLocationRequest(); // UpdateGymLocationRequest |

try {
    final result = api_instance.updateGymLocation(id, updateGymLocationRequest);
    print(result);
} catch (e) {
    print('Exception when calling GymApi->updateGymLocation: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  |
 **updateGymLocationRequest** | [**UpdateGymLocationRequest**](UpdateGymLocationRequest.md)|  |

### Return type

[**GymLocationResponse**](GymLocationResponse.md)

### Authorization

[mobileBearer](../README.md#mobileBearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **updateGymSession**
> GymSessionResponse updateGymSession(id, updateGymSessionRequest)

Autosave a workout draft

Omitted fields stay unchanged. Sending exercises replaces the ordered exercise list; empty sets are ignored server-side.

### Example
```dart
import 'package:luqa_api/api.dart';
// TODO Configure HTTP Bearer authorization: mobileBearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('mobileBearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('mobileBearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = GymApi();
final id = id_example; // String |
final updateGymSessionRequest = UpdateGymSessionRequest(); // UpdateGymSessionRequest |

try {
    final result = api_instance.updateGymSession(id, updateGymSessionRequest);
    print(result);
} catch (e) {
    print('Exception when calling GymApi->updateGymSession: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  |
 **updateGymSessionRequest** | [**UpdateGymSessionRequest**](UpdateGymSessionRequest.md)|  |

### Return type

[**GymSessionResponse**](GymSessionResponse.md)

### Authorization

[mobileBearer](../README.md#mobileBearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)
