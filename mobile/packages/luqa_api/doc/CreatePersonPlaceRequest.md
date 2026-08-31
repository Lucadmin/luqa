# luqa_api.model.CreatePersonPlaceRequest

## Load the model package
```dart
import 'package:luqa_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**id** | **Optional<String?>** |  | [optional]
**label** | **String** |  |
**city** | **String** |  |
**region** | **Optional<String?>** |  | [optional]
**country** | **Optional<String?>** |  | [optional]
**address** | **Optional<String?>** |  | [optional]
**isPrimary** | **Optional<bool?>** | The first place is primary whether or not this is set: a person with exactly one city and no primary has no answer to \"where are they\". | [optional]

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)
