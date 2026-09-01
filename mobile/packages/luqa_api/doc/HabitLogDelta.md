# luqa_api.model.HabitLogDelta

## Load the model package
```dart
import 'package:luqa_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**rows** | [**List<HabitLog>**](HabitLog.md) | Current state of everything created or changed. | [default to const []]
**deleted** | **List<String>** | Always empty. A log is only ever written, never removed. | [default to const []]
**cursor** | **Optional<String?>** | Where to resume. Null when this collection has never had a row, in which case the caller keeps the cursor it already had. | [optional]
**hasMore** | **bool** | True when the limit was reached and another page waits. |

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)
