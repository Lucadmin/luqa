# luqa_api.api.TimeEntriesApi

## Load the API package
```dart
import 'package:luqa_api/api.dart';
```

All URIs are relative to */api/v1*

Method | HTTP request | Description
------------- | ------------- | -------------
[**createTimeEntry**](TimeEntriesApi.md#createtimeentry) | **POST** /time-entries | Create a completed block or running timer
[**listTimeEntries**](TimeEntriesApi.md#listtimeentries) | **GET** /time-entries | List entries overlapping a half-open UTC window


# **createTimeEntry**
> TimeEntryResponse createTimeEntry(createTimeEntryRequest)

Create a completed block or running timer

### Example
```dart
import 'package:luqa_api/api.dart';
// TODO Configure HTTP Bearer authorization: mobileBearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('mobileBearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('mobileBearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = TimeEntriesApi();
final createTimeEntryRequest = CreateTimeEntryRequest(); // CreateTimeEntryRequest |

try {
    final result = api_instance.createTimeEntry(createTimeEntryRequest);
    print(result);
} catch (e) {
    print('Exception when calling TimeEntriesApi->createTimeEntry: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **createTimeEntryRequest** | [**CreateTimeEntryRequest**](CreateTimeEntryRequest.md)|  |

### Return type

[**TimeEntryResponse**](TimeEntryResponse.md)

### Authorization

[mobileBearer](../README.md#mobileBearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listTimeEntries**
> TimeEntryListResponse listTimeEntries(from, to)

List entries overlapping a half-open UTC window

### Example
```dart
import 'package:luqa_api/api.dart';
// TODO Configure HTTP Bearer authorization: mobileBearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('mobileBearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('mobileBearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = TimeEntriesApi();
final from = 2013-10-20T19:20:30+01:00; // DateTime |
final to = 2013-10-20T19:20:30+01:00; // DateTime |

try {
    final result = api_instance.listTimeEntries(from, to);
    print(result);
} catch (e) {
    print('Exception when calling TimeEntriesApi->listTimeEntries: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **from** | **DateTime**|  |
 **to** | **DateTime**|  |

### Return type

[**TimeEntryListResponse**](TimeEntryListResponse.md)

### Authorization

[mobileBearer](../README.md#mobileBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)
