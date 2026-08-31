# luqa_api.model.PersonBalance

## Load the model package
```dart
import 'package:luqa_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**id** | **String** |  |
**name** | **String** |  |
**color** | **String** |  |
**emoji** | **String** |  |
**defaultPercent** | **int** |  |
**order** | **int** |  |
**archived** | **bool** |  |
**balanceCents** | **int** | Positive means they owe the user, negative means the user owes them, zero means settled up. |
**coveredCents** | **int** | All-time total the user covered for them as a treat. Recorded, but never part of a balance. |
**lastActivity** | **String** |  |

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)
