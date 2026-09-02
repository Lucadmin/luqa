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
**region** | **String** | The first-level administrative area — state, province, Land. What tells two cities of the same name apart in a list. |
**country** | **String** |  |
**address** | **String** | Kept for reference. Never the thing that gets plotted. |
**cityId** | **int** | The GeoNames id of the city that was chosen from the search list. Null for a name that was only typed — offline, or imported from a contact book — which is the place the geocoding batch is for. Two places sharing this id are the same city whatever their names look like, which is how two Cambridges stay two pins. |
**timezone** | **String** | The IANA zone of that city, e.g. \"Europe/Berlin\". |
**latitude** | **num** | City centroid. Present from the start for a chosen city; null for a typed one until the batch resolves it — a place that lists but does not yet pin. |
**longitude** | **num** |  |
**isPrimary** | **bool** |  |
**source_** | **String** |  |

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)
