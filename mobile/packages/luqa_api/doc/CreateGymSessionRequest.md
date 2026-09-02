# luqa_api.model.CreateGymSessionRequest

## Load the model package
```dart
import 'package:luqa_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**id** | **Optional<String?>** | Client-minted identity for the workout, so one started with no signal can still be opened and saved into. Supplying it makes the create idempotent. | [optional]
**date** | **Optional<String?>** |  | [optional]
**locationId** | **Optional<String?>** |  | [optional]
**notes** | **Optional<String?>** |  | [optional]
**exercises** | [**Optional<List<GymSessionExerciseInput>?>**](GymSessionExerciseInput.md) |  | [optional] [default to const []]
**endedAt** | [**Optional<DateTime?>**](DateTime.md) | When training stopped. Omitted on a workout being started, which opens it. | [optional]

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)
