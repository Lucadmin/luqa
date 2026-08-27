# luqa_api.api.HealthApi

## Load the API package
```dart
import 'package:luqa_api/api.dart';
```

All URIs are relative to */api/v1*

Method | HTTP request | Description
------------- | ------------- | -------------
[**getHealthSyncState**](HealthApi.md#gethealthsyncstate) | **GET** /health/sync | Read what the server last accepted, per source and metric
[**pushHealthSync**](HealthApi.md#pushhealthsync) | **POST** /health/sync | Push sleep sessions and samples read from the device


# **getHealthSyncState**
> HealthSyncStateListResponse getHealthSyncState()

Read what the server last accepted, per source and metric

### Example
```dart
import 'package:luqa_api/api.dart';
// TODO Configure HTTP Bearer authorization: mobileBearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('mobileBearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('mobileBearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = HealthApi();

try {
    final result = api_instance.getHealthSyncState();
    print(result);
} catch (e) {
    print('Exception when calling HealthApi->getHealthSyncState: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**HealthSyncStateListResponse**](HealthSyncStateListResponse.md)

### Authorization

[mobileBearer](../README.md#mobileBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **pushHealthSync**
> HealthSyncResponse pushHealthSync(healthSyncRequest)

Push sleep sessions and samples read from the device

Idempotent by provider record id. Supply `sleep.window` only when the device re-read a full range: it authorizes the server to soft-delete sessions inside that range it no longer sees.

### Example
```dart
import 'package:luqa_api/api.dart';
// TODO Configure HTTP Bearer authorization: mobileBearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('mobileBearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('mobileBearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = HealthApi();
final healthSyncRequest = HealthSyncRequest(); // HealthSyncRequest |

try {
    final result = api_instance.pushHealthSync(healthSyncRequest);
    print(result);
} catch (e) {
    print('Exception when calling HealthApi->pushHealthSync: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **healthSyncRequest** | [**HealthSyncRequest**](HealthSyncRequest.md)|  |

### Return type

[**HealthSyncResponse**](HealthSyncResponse.md)

### Authorization

[mobileBearer](../README.md#mobileBearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)
