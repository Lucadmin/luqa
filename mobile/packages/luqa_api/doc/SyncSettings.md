# luqa_api.model.SyncSettings

## Load the model package
```dart
import 'package:luqa_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**currency** | **String** | ISO 4217 code the amounts are in. |
**dayStartHour** | **int** | The hour a logical day flips. Someone who logs a block at 01:00 means it for the day that has not ended yet, so the day a row belongs to is not the day its clock says. |
**weekStartsOn** | **int** | 0 = Sunday, 1 = Monday. Habit weeks are counted from here, so a device that guessed would put a \"3x per week\" quota in the wrong week for half the world. |

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)
