# luqa_api.model.PersonPlace

## Load the model package
```dart
import 'package:luqa_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**id** | **String** |  |
**label** | **String** | What this place is to them — \"Home\", \"Parents\", \"Summer\". |
**city** | **String** |  |
**region** | **String** |  |
**country** | **String** |  |
**address** | **String** | Kept for reference. Never the thing that gets plotted. |
**latitude** | **num** | City centroid, once geocoded. Null until then: a place that lists but does not yet pin. |
**longitude** | **num** |  |
**isPrimary** | **bool** |  |
**source_** | **String** |  |

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)
