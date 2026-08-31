# luqa_api.model.UpdateExpenseRequest

## Load the model package
```dart
import 'package:luqa_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**description** | **Optional<String?>** |  | [optional]
**amountCents** | **Optional<int?>** |  | [optional]
**date** | **Optional<String?>** |  | [optional]
**paidByPersonId** | **Optional<String?>** |  | [optional]
**groupId** | **Optional<String?>** |  | [optional]
**splitMode** | [**Optional<SplitMode?>**](SplitMode.md) |  | [optional]
**includeMe** | **Optional<bool?>** |  | [optional]
**participants** | [**Optional<List<ExpenseParticipantInput>?>**](ExpenseParticipantInput.md) |  | [optional] [default to const []]
**notes** | **Optional<String?>** |  | [optional]

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)
