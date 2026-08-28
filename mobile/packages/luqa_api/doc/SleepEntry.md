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
**lightMinutes** | **int** |  |
**deepMinutes** | **int** |  |
**remMinutes** | **int** |  |
**efficiencyPercent** | **Optional<num?>** |  | [optional]
**isNap** | **bool** |  |

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)
