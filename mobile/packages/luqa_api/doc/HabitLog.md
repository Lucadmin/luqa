# luqa_api.model.HabitLog

## Load the model package
```dart
import 'package:luqa_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**id** | **String** |  |
**habitId** | **String** |  |
**date** | **String** |  |
**count** | **int** | Reps done for a COUNT goal, or 0/1 for a TASK. |
**seconds** | **int** | Seconds banked toward an unlinked TIME goal. |
**runningSince** | [**DateTime**](DateTime.md) | When an unlinked timer started. The elapsed time is added as it runs rather than written every second, so a device that is asleep still shows the right total when it wakes. |
**completedAt** | [**DateTime**](DateTime.md) | The first moment the day's goal was met. A seventh glass of water does not re-complete the day. |

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)
