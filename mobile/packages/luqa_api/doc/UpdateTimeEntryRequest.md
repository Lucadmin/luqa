# luqa_api.model.UpdateTimeEntryRequest

## Load the model package
```dart
import 'package:luqa_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**description** | **Optional<String?>** |  | [optional]
**categoryId** | **Optional<String?>** |  | [optional]
**startTime** | [**Optional<DateTime?>**](DateTime.md) |  | [optional]
**endTime** | [**Optional<DateTime?>**](DateTime.md) |  | [optional]
**personIds** | **Optional<List<String>?>** | Who was there. Absent leaves the tags alone; an empty array clears them. Ids that are not this account's are dropped rather than rejected: a phone replaying a queued write may name somebody deleted since, and refusing the whole entry over a tag would lose a block of time to protect it. | [optional] [default to const []]

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)
