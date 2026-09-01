# luqa_api.model.CreateHabitRequest

## Load the model package
```dart
import 'package:luqa_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**id** | **Optional<String?>** | Preferred identity for a habit minted offline. Honoured when it is free; a repeat of one already here answers with that habit rather than making a second. | [optional]
**name** | **String** |  |
**icon** | **Optional<String?>** |  | [optional]
**color** | **Optional<String?>** |  | [optional]
**goalType** | [**Optional<HabitGoalType?>**](HabitGoalType.md) |  | [optional]
**goalPeriod** | [**Optional<HabitGoalPeriod?>**](HabitGoalPeriod.md) |  | [optional]
**targetCount** | **Optional<int?>** |  | [optional]
**targetSeconds** | **Optional<int?>** |  | [optional]
**categoryId** | **Optional<String?>** |  | [optional]
**scheduleType** | [**Optional<HabitScheduleType?>**](HabitScheduleType.md) |  | [optional]
**weekdays** | **Optional<List<int>?>** |  | [optional] [default to const []]
**weekInterval** | **Optional<int?>** |  | [optional]
**intervalDays** | **Optional<int?>** |  | [optional]
**intervalFromLastDone** | **Optional<bool?>** |  | [optional]
**timesPerPeriod** | **Optional<int?>** |  | [optional]
**anchorDate** | **Optional<String?>** |  | [optional]
**dates** | **Optional<List<String>?>** |  | [optional] [default to const []]
**excludedDates** | **Optional<List<String>?>** |  | [optional] [default to const []]

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)
