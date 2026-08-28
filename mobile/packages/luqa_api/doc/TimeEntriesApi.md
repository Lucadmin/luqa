# luqa_api.api.TimeEntriesApi

## Load the API package
```dart
import 'package:luqa_api/api.dart';
```

All URIs are relative to */api/v1*

Method | HTTP request | Description
------------- | ------------- | -------------
[**createTimeEntry**](TimeEntriesApi.md#createtimeentry) | **POST** /time-entries | Create a completed block or running timer
[**deleteTimeEntry**](TimeEntriesApi.md#deletetimeentry) | **DELETE** /time-entries/{id} | Soft-delete an entry
[**listTimeEntries**](TimeEntriesApi.md#listtimeentries) | **GET** /time-entries | List entries overlapping a half-open UTC window
[**updateTimeEntry**](TimeEntriesApi.md#updatetimeentry) | **PATCH** /time-entries/{id} | Edit an entry, or stop a running timer by giving it an end


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

# **deleteTimeEntry**
> deleteTimeEntry(id)

Soft-delete an entry

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
final id = id_example; // String |

try {
    api_instance.deleteTimeEntry(id);
} catch (e) {
    print('Exception when calling TimeEntriesApi->deleteTimeEntry: $e\n');
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

# **updateTimeEntry**
> TimeEntryResponse updateTimeEntry(id, updateTimeEntryRequest)

Edit an entry, or stop a running timer by giving it an end

Every field is optional; omitted fields are left untouched. Sending `endTime: null` reopens the entry as a running timer.

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
final id = id_example; // String |
final updateTimeEntryRequest = UpdateTimeEntryRequest(); // UpdateTimeEntryRequest |

try {
    final result = api_instance.updateTimeEntry(id, updateTimeEntryRequest);
    print(result);
} catch (e) {
    print('Exception when calling TimeEntriesApi->updateTimeEntry: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  |
 **updateTimeEntryRequest** | [**UpdateTimeEntryRequest**](UpdateTimeEntryRequest.md)|  |

### Return type

[**TimeEntryResponse**](TimeEntryResponse.md)

### Authorization

[mobileBearer](../README.md#mobileBearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)
