# luqa_api.model.SleepSessionImport

## Load the model package
```dart
import 'package:luqa_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**externalId** | **Optional<String?>** | Provider record id. Falls back to a start/end key when absent. | [optional]
**title** | **Optional<String?>** |  | [optional]
**notes** | **Optional<String?>** |  | [optional]
**sourceApp** | **Optional<String?>** |  | [optional]
**startTime** | [**DateTime**](DateTime.md) |  |
**endTime** | [**DateTime**](DateTime.md) |  |
**startZoneOffset** | **Optional<String?>** |  | [optional]
**endZoneOffset** | **Optional<String?>** |  | [optional]
**sleepMinutes** | **Optional<int?>** |  | [optional]
**awakeMinutes** | **Optional<int?>** |  | [optional]
**awakeInBedMinutes** | **Optional<int?>** |  | [optional]
**outOfBedMinutes** | **Optional<int?>** |  | [optional]
**lightMinutes** | **Optional<int?>** |  | [optional]
**deepMinutes** | **Optional<int?>** |  | [optional]
**remMinutes** | **Optional<int?>** |  | [optional]
**unknownMinutes** | **Optional<int?>** |  | [optional]
**isNap** | **Optional<bool?>** |  | [optional]
**recordingMethod** | **Optional<String?>** |  | [optional]
**deviceModel** | **Optional<String?>** |  | [optional]
**stages** | [**Optional<List<SleepStage>?>**](SleepStage.md) |  | [optional] [default to const []]

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)
