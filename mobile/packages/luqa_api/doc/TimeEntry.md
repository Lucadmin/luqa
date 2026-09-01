# luqa_api.model.TimeEntry

## Load the model package
```dart
import 'package:luqa_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**id** | **String** |  |
**description** | **String** |  |
**categoryId** | **String** |  |
**startTime** | [**DateTime**](DateTime.md) |  |
**endTime** | [**DateTime**](DateTime.md) |  |
**source_** | [**EntrySource**](EntrySource.md) |  |
**personIds** | **List<String>** | Who was there. Rides inside the entry rather than syncing on its own, the same way a person's notes ride inside them: one row is one whole block of time. This is what lets \"last seen\" be a fact the app already knows rather than one the owner types twice. | [default to const []]

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)
