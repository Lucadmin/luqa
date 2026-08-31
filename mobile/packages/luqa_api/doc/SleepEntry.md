# luqa_api.model.SleepEntry

## Load the model package
```dart
import 'package:luqa_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**id** | **String** |  |
**source_** | [**SleepSource**](SleepSource.md) |  |
**title** | **String** |  |
**sourceApp** | **String** | Provider application that recorded the session, when known. |
**startTime** | [**DateTime**](DateTime.md) |  |
**endTime** | [**DateTime**](DateTime.md) |  |
**sleepMinutes** | **int** | Asleep minutes. Null when the provider only reported time in bed. |
**awakeMinutes** | **int** |  |
**awakeInBedMinutes** | **int** |  |
**outOfBedMinutes** | **int** |  |
**lightMinutes** | **int** |  |
**deepMinutes** | **int** |  |
**remMinutes** | **int** |  |
**unknownMinutes** | **int** | Staged time the provider could not classify. |
**inBedMinutes** | **int** | Wall-clock session length. |
**efficiencyPercent** | **num** | Asleep over time in bed, 0-100. |
**latencyMinutes** | **int** | Session start until the first asleep stage. |
**wasoMinutes** | **int** | Wake after sleep onset, before the final wake. |
**awakeningCount** | **int** | Distinct awake blocks after sleep onset. |
**midpoint** | [**DateTime**](DateTime.md) | Midpoint of the asleep span, for chronotype drift. |
**isNap** | **bool** |  |
**recordingMethod** | **String** |  |
**deviceModel** | **String** |  |
**stages** | [**List<SleepStage>**](SleepStage.md) | The night's stage timeline, normalized server-side. Empty when the provider reported totals only. | [default to const []]

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)
