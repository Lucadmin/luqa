# luqa_api.api.MoneyApi

## Load the API package
```dart
import 'package:luqa_api/api.dart';
```

All URIs are relative to */api/v1*

Method | HTTP request | Description
------------- | ------------- | -------------
[**createExpense**](MoneyApi.md#createexpense) | **POST** /money/expenses | Log a bill and who carries what
[**createGroup**](MoneyApi.md#creategroup) | **POST** /money/groups | Create a group from a set of people
[**createPerson**](MoneyApi.md#createperson) | **POST** /money/people | Add someone to split with
[**createSettlement**](MoneyApi.md#createsettlement) | **POST** /money/settlements | Record a payback
[**deleteExpense**](MoneyApi.md#deleteexpense) | **DELETE** /money/expenses/{id} | Drop a bill and every share on it
[**deleteGroup**](MoneyApi.md#deletegroup) | **DELETE** /money/groups/{id} | Remove a group
[**deletePerson**](MoneyApi.md#deleteperson) | **DELETE** /money/people/{id} | Remove someone
[**deleteSettlement**](MoneyApi.md#deletesettlement) | **DELETE** /money/settlements/{id} | Undo a payback
[**getMoneyOverview**](MoneyApi.md#getmoneyoverview) | **GET** /money | Load every balance, the groups, and the headline totals
[**getPersonLedger**](MoneyApi.md#getpersonledger) | **GET** /money/people/{id}/ledger | Load one person's whole history with the user
[**listExpenses**](MoneyApi.md#listexpenses) | **GET** /money/expenses | List bills newest first
[**listGroups**](MoneyApi.md#listgroups) | **GET** /money/groups | List groups with their member ids
[**listPeople**](MoneyApi.md#listpeople) | **GET** /money/people | List everyone, archived included, in display order
[**listSettlements**](MoneyApi.md#listsettlements) | **GET** /money/settlements | List paybacks, newest first
[**updateExpense**](MoneyApi.md#updateexpense) | **PATCH** /money/expenses/{id} | Edit a bill
[**updateGroup**](MoneyApi.md#updategroup) | **PATCH** /money/groups/{id} | Rename, restyle, change membership, archive, or restore a group
[**updatePerson**](MoneyApi.md#updateperson) | **PATCH** /money/people/{id} | Rename, restyle, reorder, archive, or restore someone
[**updateSettlement**](MoneyApi.md#updatesettlement) | **PATCH** /money/settlements/{id} | Correct a payback


# **createExpense**
> ExpenseResponse createExpense(createExpenseRequest)

Log a bill and who carries what

The split is recomputed server-side from `splitMode`, `includeMe` and `participants`, so the stored shares can never disagree with the rules the editor previewed. Shares plus the user's own slice always add up to the bill exactly.

### Example
```dart
import 'package:luqa_api/api.dart';
// TODO Configure HTTP Bearer authorization: mobileBearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('mobileBearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('mobileBearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = MoneyApi();
final createExpenseRequest = CreateExpenseRequest(); // CreateExpenseRequest |

try {
    final result = api_instance.createExpense(createExpenseRequest);
    print(result);
} catch (e) {
    print('Exception when calling MoneyApi->createExpense: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **createExpenseRequest** | [**CreateExpenseRequest**](CreateExpenseRequest.md)|  |

### Return type

[**ExpenseResponse**](ExpenseResponse.md)

### Authorization

[mobileBearer](../README.md#mobileBearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **createGroup**
> GroupResponse createGroup(createGroupRequest)

Create a group from a set of people

### Example
```dart
import 'package:luqa_api/api.dart';
// TODO Configure HTTP Bearer authorization: mobileBearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('mobileBearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('mobileBearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = MoneyApi();
final createGroupRequest = CreateGroupRequest(); // CreateGroupRequest |

try {
    final result = api_instance.createGroup(createGroupRequest);
    print(result);
} catch (e) {
    print('Exception when calling MoneyApi->createGroup: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **createGroupRequest** | [**CreateGroupRequest**](CreateGroupRequest.md)|  |

### Return type

[**GroupResponse**](GroupResponse.md)

### Authorization

[mobileBearer](../README.md#mobileBearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **createPerson**
> PersonResponse createPerson(createPersonRequest)

Add someone to split with

### Example
```dart
import 'package:luqa_api/api.dart';
// TODO Configure HTTP Bearer authorization: mobileBearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('mobileBearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('mobileBearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = MoneyApi();
final createPersonRequest = CreatePersonRequest(); // CreatePersonRequest |

try {
    final result = api_instance.createPerson(createPersonRequest);
    print(result);
} catch (e) {
    print('Exception when calling MoneyApi->createPerson: $e\n');
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

# **createSettlement**
> SettlementResponse createSettlement(createSettlementRequest)

Record a payback

Moves the balance without touching any of the bills behind it, so the history stays readable.

### Example
```dart
import 'package:luqa_api/api.dart';
// TODO Configure HTTP Bearer authorization: mobileBearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('mobileBearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('mobileBearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = MoneyApi();
final createSettlementRequest = CreateSettlementRequest(); // CreateSettlementRequest |

try {
    final result = api_instance.createSettlement(createSettlementRequest);
    print(result);
} catch (e) {
    print('Exception when calling MoneyApi->createSettlement: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **createSettlementRequest** | [**CreateSettlementRequest**](CreateSettlementRequest.md)|  |

### Return type

[**SettlementResponse**](SettlementResponse.md)

### Authorization

[mobileBearer](../README.md#mobileBearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **deleteExpense**
> deleteExpense(id)

Drop a bill and every share on it

### Example
```dart
import 'package:luqa_api/api.dart';
// TODO Configure HTTP Bearer authorization: mobileBearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('mobileBearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('mobileBearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = MoneyApi();
final id = id_example; // String |

try {
    api_instance.deleteExpense(id);
} catch (e) {
    print('Exception when calling MoneyApi->deleteExpense: $e\n');
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

# **deleteGroup**
> deleteGroup(id)

Remove a group

Past bills keep their people and amounts; they simply lose the label.

### Example
```dart
import 'package:luqa_api/api.dart';
// TODO Configure HTTP Bearer authorization: mobileBearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('mobileBearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('mobileBearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = MoneyApi();
final id = id_example; // String |

try {
    api_instance.deleteGroup(id);
} catch (e) {
    print('Exception when calling MoneyApi->deleteGroup: $e\n');
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

# **deletePerson**
> DeletePersonResponse deletePerson(id)

Remove someone

Anyone who has been on a bill is archived instead, so the history that produced their balance survives. `deleted` says which happened.

### Example
```dart
import 'package:luqa_api/api.dart';
// TODO Configure HTTP Bearer authorization: mobileBearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('mobileBearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('mobileBearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = MoneyApi();
final id = id_example; // String |

try {
    final result = api_instance.deletePerson(id);
    print(result);
} catch (e) {
    print('Exception when calling MoneyApi->deletePerson: $e\n');
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

# **deleteSettlement**
> deleteSettlement(id)

Undo a payback

### Example
```dart
import 'package:luqa_api/api.dart';
// TODO Configure HTTP Bearer authorization: mobileBearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('mobileBearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('mobileBearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = MoneyApi();
final id = id_example; // String |

try {
    api_instance.deleteSettlement(id);
} catch (e) {
    print('Exception when calling MoneyApi->deleteSettlement: $e\n');
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

# **getMoneyOverview**
> MoneyOverviewResponse getMoneyOverview()

Load every balance, the groups, and the headline totals

### Example
```dart
import 'package:luqa_api/api.dart';
// TODO Configure HTTP Bearer authorization: mobileBearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('mobileBearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('mobileBearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = MoneyApi();

try {
    final result = api_instance.getMoneyOverview();
    print(result);
} catch (e) {
    print('Exception when calling MoneyApi->getMoneyOverview: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**MoneyOverviewResponse**](MoneyOverviewResponse.md)

### Authorization

[mobileBearer](../README.md#mobileBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getPersonLedger**
> PersonLedgerResponse getPersonLedger(id)

Load one person's whole history with the user

### Example
```dart
import 'package:luqa_api/api.dart';
// TODO Configure HTTP Bearer authorization: mobileBearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('mobileBearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('mobileBearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = MoneyApi();
final id = id_example; // String |

try {
    final result = api_instance.getPersonLedger(id);
    print(result);
} catch (e) {
    print('Exception when calling MoneyApi->getPersonLedger: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  |

### Return type

[**PersonLedgerResponse**](PersonLedgerResponse.md)

### Authorization

[mobileBearer](../README.md#mobileBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listExpenses**
> ExpenseListResponse listExpenses(personId, groupId, cursor, limit)

List bills newest first

### Example
```dart
import 'package:luqa_api/api.dart';
// TODO Configure HTTP Bearer authorization: mobileBearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('mobileBearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('mobileBearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = MoneyApi();
final personId = personId_example; // String | Only bills this person is on, or fronted.
final groupId = groupId_example; // String |
final cursor = cursor_example; // String |
final limit = 56; // int |

try {
    final result = api_instance.listExpenses(personId, groupId, cursor, limit);
    print(result);
} catch (e) {
    print('Exception when calling MoneyApi->listExpenses: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **personId** | **String**| Only bills this person is on, or fronted. | [optional]
 **groupId** | **String**|  | [optional]
 **cursor** | **String**|  | [optional]
 **limit** | **int**|  | [optional] [default to 20]

### Return type

[**ExpenseListResponse**](ExpenseListResponse.md)

### Authorization

[mobileBearer](../README.md#mobileBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listGroups**
> GroupListResponse listGroups()

List groups with their member ids

### Example
```dart
import 'package:luqa_api/api.dart';
// TODO Configure HTTP Bearer authorization: mobileBearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('mobileBearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('mobileBearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = MoneyApi();

try {
    final result = api_instance.listGroups();
    print(result);
} catch (e) {
    print('Exception when calling MoneyApi->listGroups: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**GroupListResponse**](GroupListResponse.md)

### Authorization

[mobileBearer](../README.md#mobileBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listPeople**
> PersonListResponse listPeople()

List everyone, archived included, in display order

### Example
```dart
import 'package:luqa_api/api.dart';
// TODO Configure HTTP Bearer authorization: mobileBearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('mobileBearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('mobileBearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = MoneyApi();

try {
    final result = api_instance.listPeople();
    print(result);
} catch (e) {
    print('Exception when calling MoneyApi->listPeople: $e\n');
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

# **listSettlements**
> SettlementListResponse listSettlements(personId)

List paybacks, newest first

### Example
```dart
import 'package:luqa_api/api.dart';
// TODO Configure HTTP Bearer authorization: mobileBearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('mobileBearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('mobileBearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = MoneyApi();
final personId = personId_example; // String |

try {
    final result = api_instance.listSettlements(personId);
    print(result);
} catch (e) {
    print('Exception when calling MoneyApi->listSettlements: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **personId** | **String**|  | [optional]

### Return type

[**SettlementListResponse**](SettlementListResponse.md)

### Authorization

[mobileBearer](../README.md#mobileBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **updateExpense**
> ExpenseResponse updateExpense(id, updateExpenseRequest)

Edit a bill

Omitted fields stay unchanged. Anything that can move the numbers re-runs the split; fields left out of a re-split fall back to how the bill already looks.

### Example
```dart
import 'package:luqa_api/api.dart';
// TODO Configure HTTP Bearer authorization: mobileBearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('mobileBearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('mobileBearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = MoneyApi();
final id = id_example; // String |
final updateExpenseRequest = UpdateExpenseRequest(); // UpdateExpenseRequest |

try {
    final result = api_instance.updateExpense(id, updateExpenseRequest);
    print(result);
} catch (e) {
    print('Exception when calling MoneyApi->updateExpense: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  |
 **updateExpenseRequest** | [**UpdateExpenseRequest**](UpdateExpenseRequest.md)|  |

### Return type

[**ExpenseResponse**](ExpenseResponse.md)

### Authorization

[mobileBearer](../README.md#mobileBearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **updateGroup**
> GroupResponse updateGroup(id, updateGroupRequest)

Rename, restyle, change membership, archive, or restore a group

Sending `memberIds` replaces the membership wholesale; omitting it leaves the members alone.

### Example
```dart
import 'package:luqa_api/api.dart';
// TODO Configure HTTP Bearer authorization: mobileBearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('mobileBearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('mobileBearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = MoneyApi();
final id = id_example; // String |
final updateGroupRequest = UpdateGroupRequest(); // UpdateGroupRequest |

try {
    final result = api_instance.updateGroup(id, updateGroupRequest);
    print(result);
} catch (e) {
    print('Exception when calling MoneyApi->updateGroup: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  |
 **updateGroupRequest** | [**UpdateGroupRequest**](UpdateGroupRequest.md)|  |

### Return type

[**GroupResponse**](GroupResponse.md)

### Authorization

[mobileBearer](../README.md#mobileBearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **updatePerson**
> PersonResponse updatePerson(id, updatePersonRequest)

Rename, restyle, reorder, archive, or restore someone

### Example
```dart
import 'package:luqa_api/api.dart';
// TODO Configure HTTP Bearer authorization: mobileBearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('mobileBearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('mobileBearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = MoneyApi();
final id = id_example; // String |
final updatePersonRequest = UpdatePersonRequest(); // UpdatePersonRequest |

try {
    final result = api_instance.updatePerson(id, updatePersonRequest);
    print(result);
} catch (e) {
    print('Exception when calling MoneyApi->updatePerson: $e\n');
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

# **updateSettlement**
> SettlementResponse updateSettlement(id, updateSettlementRequest)

Correct a payback

### Example
```dart
import 'package:luqa_api/api.dart';
// TODO Configure HTTP Bearer authorization: mobileBearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('mobileBearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('mobileBearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = MoneyApi();
final id = id_example; // String |
final updateSettlementRequest = UpdateSettlementRequest(); // UpdateSettlementRequest |

try {
    final result = api_instance.updateSettlement(id, updateSettlementRequest);
    print(result);
} catch (e) {
    print('Exception when calling MoneyApi->updateSettlement: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**|  |
 **updateSettlementRequest** | [**UpdateSettlementRequest**](UpdateSettlementRequest.md)|  |

### Return type

[**SettlementResponse**](SettlementResponse.md)

### Authorization

[mobileBearer](../README.md#mobileBearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)
