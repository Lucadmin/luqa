# luqa_api.api.AuthenticationApi

## Load the API package
```dart
import 'package:luqa_api/api.dart';
```

All URIs are relative to */api/v1*

Method | HTTP request | Description
------------- | ------------- | -------------
[**createMobileSession**](AuthenticationApi.md#createmobilesession) | **POST** /auth/session | Exchange owner credentials for a device session
[**refreshMobileSession**](AuthenticationApi.md#refreshmobilesession) | **POST** /auth/refresh | Rotate a refresh token and issue a new credential pair
[**revokeMobileSession**](AuthenticationApi.md#revokemobilesession) | **DELETE** /auth/session | Revoke the current device session


# **createMobileSession**
> SessionCredentials createMobileSession(createSessionRequest)

Exchange owner credentials for a device session

### Example
```dart
import 'package:luqa_api/api.dart';

final api_instance = AuthenticationApi();
final createSessionRequest = CreateSessionRequest(); // CreateSessionRequest |

try {
    final result = api_instance.createMobileSession(createSessionRequest);
    print(result);
} catch (e) {
    print('Exception when calling AuthenticationApi->createMobileSession: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **createSessionRequest** | [**CreateSessionRequest**](CreateSessionRequest.md)|  |

### Return type

[**SessionCredentials**](SessionCredentials.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **refreshMobileSession**
> SessionCredentials refreshMobileSession(refreshSessionRequest)

Rotate a refresh token and issue a new credential pair

### Example
```dart
import 'package:luqa_api/api.dart';

final api_instance = AuthenticationApi();
final refreshSessionRequest = RefreshSessionRequest(); // RefreshSessionRequest |

try {
    final result = api_instance.refreshMobileSession(refreshSessionRequest);
    print(result);
} catch (e) {
    print('Exception when calling AuthenticationApi->refreshMobileSession: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **refreshSessionRequest** | [**RefreshSessionRequest**](RefreshSessionRequest.md)|  |

### Return type

[**SessionCredentials**](SessionCredentials.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **revokeMobileSession**
> revokeMobileSession()

Revoke the current device session

### Example
```dart
import 'package:luqa_api/api.dart';
// TODO Configure HTTP Bearer authorization: mobileBearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('mobileBearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('mobileBearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = AuthenticationApi();

try {
    api_instance.revokeMobileSession();
} catch (e) {
    print('Exception when calling AuthenticationApi->revokeMobileSession: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

void (empty response body)

### Authorization

[mobileBearer](../README.md#mobileBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)
