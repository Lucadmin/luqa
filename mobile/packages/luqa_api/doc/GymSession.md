# luqa_api.model.GymSession

## Load the model package
```dart
import 'package:luqa_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**id** | **String** |  |
**date** | **String** |  |
**locationId** | **String** |  |
**notes** | **String** |  |
**exercises** | [**List<GymSessionExercise>**](GymSessionExercise.md) |  | [default to const []]
**createdAt** | [**DateTime**](DateTime.md) |  |
**updatedAt** | [**DateTime**](DateTime.md) | Last time anything in the workout changed. What an open workout's idle time is measured from. |
**endedAt** | [**DateTime**](DateTime.md) | When training stopped, or null while the workout is still open. |

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)
