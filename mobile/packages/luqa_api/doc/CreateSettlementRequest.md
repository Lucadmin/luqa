# luqa_api.model.CreateSettlementRequest

## Load the model package
```dart
import 'package:luqa_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**id** | **Optional<String?>** | Client-minted identity, so a payback recorded offline is not double-counted when the create is retried. | [optional]
**personId** | **String** |  |
**amountCents** | **int** |  |
**direction** | [**Optional<SettlementDirection?>**](SettlementDirection.md) |  | [optional]
**date** | **Optional<String?>** |  | [optional]
**notes** | **Optional<String?>** |  | [optional]

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)
