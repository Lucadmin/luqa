# luqa_api.model.UpdateGymSessionRequest

## Load the model package
```dart
import 'package:luqa_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**date** | **Optional<String?>** |  | [optional]
**locationId** | **Optional<String?>** |  | [optional]
**notes** | **Optional<String?>** |  | [optional]
**exercises** | [**Optional<List<GymSessionExerciseInput>?>**](GymSessionExerciseInput.md) |  | [optional] [default to const []]
**endedAt** | [**Optional<DateTime?>**](DateTime.md) | Finishes the workout, or reopens it when null. Omitting it leaves the workout open or finished exactly as it was, which is what every autosave does. | [optional]

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)
