# luqa_api.model.Expense

## Load the model package
```dart
import 'package:luqa_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**id** | **String** |  |
**description** | **String** |  |
**amountCents** | **int** |  |
**date** | **String** |  |
**paidByPersonId** | **String** | Who fronted the money. Null means the user did. When someone else paid, only the user's own share moves a balance. |
**groupId** | **String** |  |
**splitMode** | [**SplitMode**](SplitMode.md) |  |
**myShareCents** | **int** | The user's own slice. Shares plus this equals the bill. |
**notes** | **String** |  |
**shares** | [**List<ExpenseShare>**](ExpenseShare.md) |  | [default to const []]
**createdAt** | [**DateTime**](DateTime.md) |  |

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)
