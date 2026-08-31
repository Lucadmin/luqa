# luqa_api.model.LedgerItem

## Load the model package
```dart
import 'package:luqa_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**kind** | **String** |  |
**id** | **String** |  |
**date** | **String** |  |
**title** | **String** |  |
**deltaCents** | **int** | Effect on the balance. Positive raises what they owe the user; a gift is zero. |
**shareCents** | **int** |  |
**gifted** | **bool** |  |
**amountCents** | **int** | The whole bill, for context. Null on paybacks. |
**paidByPersonId** | **String** |  |
**direction** | [**SettlementDirection**](SettlementDirection.md) |  |
**expense** | [**Expense**](Expense.md) | Full editor state for bill rows. Null on paybacks. |
**createdAt** | [**DateTime**](DateTime.md) |  |

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)
