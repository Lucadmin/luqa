# luqa_api.api.SleepApi

## Load the API package
```dart
import 'package:luqa_api/api.dart';
```

All URIs are relative to */api/v1*

Method | HTTP request | Description
------------- | ------------- | -------------
[**listSleepEntries**](SleepApi.md#listsleepentries) | **GET** /sleep-entries | List sleep sessions that ended inside a half-open UTC window


# **listSleepEntries**
> SleepEntryListResponse listSleepEntries(from, to)

List sleep sessions that ended inside a half-open UTC window

Sessions are attributed to the day they woke up in, which is how the timeline places them. Writes go through `/health/sync`.

### Example
```dart
import 'package:luqa_api/api.dart';
// TODO Configure HTTP Bearer authorization: mobileBearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('mobileBearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('mobileBearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = SleepApi();
final from = 2013-10-20T19:20:30+01:00; // DateTime |
final to = 2013-10-20T19:20:30+01:00; // DateTime |

try {
    final result = api_instance.listSleepEntries(from, to);
    print(result);
} catch (e) {
    print('Exception when calling SleepApi->listSleepEntries: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **from** | **DateTime**|  |
 **to** | **DateTime**|  |

### Return type

[**SleepEntryListResponse**](SleepEntryListResponse.md)

### Authorization

[mobileBearer](../README.md#mobileBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)
