# luqa_api.model.CreatePersonRequest

## Load the model package
```dart
import 'package:luqa_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**id** | **Optional<String?>** | Preferred identity for someone added offline. Honoured only when free; an existing person with the same name wins, so the response is authoritative. | [optional]
**name** | **String** |  |
**color** | **Optional<String?>** |  | [optional]
**emoji** | **Optional<String?>** |  | [optional]
**defaultPercent** | **Optional<int?>** |  | [optional]
**nickname** | **Optional<String?>** |  | [optional]
**photoUrl** | **Optional<String?>** |  | [optional]
**birthdayYear** | **Optional<int?>** |  | [optional]
**birthdayMonth** | **Optional<int?>** |  | [optional]
**birthdayDay** | **Optional<int?>** |  | [optional]
**cadenceDays** | **Optional<int?>** |  | [optional]
**lastSeenAt** | [**Optional<DateTime?>**](DateTime.md) |  | [optional]

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)
