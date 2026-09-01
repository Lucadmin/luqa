# luqa_api.model.GeocodeResponse

## Load the model package
```dart
import 'package:luqa_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**resolved** | **int** | Places given a point by this call. |
**remaining** | **int** | Places still without one. Above zero means the map is worth asking again; each call is bounded because every miss costs a second of wall clock against the geocoder's rate limit. |

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)
