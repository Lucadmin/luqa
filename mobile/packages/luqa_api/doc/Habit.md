# luqa_api.model.Habit

## Load the model package
```dart
import 'package:luqa_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**id** | **String** |  |
**name** | **String** |  |
**icon** | **String** | Name from the shared habit icon set. |
**color** | **String** |  |
**order** | **int** |  |
**goalType** | [**HabitGoalType**](HabitGoalType.md) |  |
**goalPeriod** | [**HabitGoalPeriod**](HabitGoalPeriod.md) |  |
**targetCount** | **int** | Reps needed for a COUNT goal. Always 1 for TASK. |
**targetSeconds** | **int** | Duration goal in seconds for a TIME habit. |
**categoryId** | **String** | A TIME habit linked to a tracking category draws its progress from the time tracked on that category, and its timer is a real time entry rather than a number kept beside one. |
**scheduleType** | [**HabitScheduleType**](HabitScheduleType.md) |  |
**weekdays** | **List<int>** | For WEEKDAYS — 0 is Sunday, 6 is Saturday. | [default to const []]
**weekInterval** | **int** | For WEEKDAYS — every N weeks. |
**intervalDays** | **int** | For INTERVAL — every N days from the anchor. |
**timesPerPeriod** | **int** | For TIMES_PER_* — the quota within each period. |
**anchorDate** | **String** | YYYY-MM-DD the interval counts from. Null falls back to the day the habit was created. |
**dates** | **List<String>** | For DATES — the explicit YYYY-MM-DD days. | [default to const []]
**excludedDates** | **List<String>** | Days to skip, whatever the schedule would otherwise say. | [default to const []]
**archived** | **bool** | Archived habits stay in the feed so a device is told one it is showing has been put away. |
**createdAt** | [**DateTime**](DateTime.md) |  |

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)
