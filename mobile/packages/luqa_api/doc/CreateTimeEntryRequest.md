# luqa_api.model.CreateTimeEntryRequest

## Load the model package
```dart
import 'package:luqa_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**id** | **Optional<String?>** | Client-minted identity for the row, so a device can name a block before the server has seen it. Supplying it makes the create idempotent: repeating the request returns the row it already made. | [optional]
**description** | **Optional<String?>** |  | [optional] [default to '']
**categoryId** | **Optional<String?>** |  | [optional]
**startTime** | [**DateTime**](DateTime.md) |  |
**endTime** | [**Optional<DateTime?>**](DateTime.md) |  | [optional]
**personIds** | **Optional<List<String>?>** | Who was there. Ids that are not this account's are dropped rather than rejected: a phone replaying a queued write may name somebody deleted since, and refusing the whole entry over a tag would lose a block of time to protect it. | [optional] [default to const []]

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)
