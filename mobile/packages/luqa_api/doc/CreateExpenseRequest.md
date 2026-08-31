# luqa_api.model.CreateExpenseRequest

## Load the model package
```dart
import 'package:luqa_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**id** | **Optional<String?>** | Client-minted identity for the bill, so one split at the table with no signal can still be edited and referred to. Supplying it makes the create idempotent. | [optional]
**description** | **Optional<String?>** |  | [optional]
**amountCents** | **int** |  |
**date** | **Optional<String?>** |  | [optional]
**paidByPersonId** | **Optional<String?>** |  | [optional]
**groupId** | **Optional<String?>** |  | [optional]
**splitMode** | [**Optional<SplitMode?>**](SplitMode.md) |  | [optional]
**includeMe** | **Optional<bool?>** | EQUAL mode: whether the user is one of the equal parts. | [optional]
**participants** | [**Optional<List<ExpenseParticipantInput>?>**](ExpenseParticipantInput.md) |  | [optional] [default to const []]
**notes** | **Optional<String?>** |  | [optional]

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)
