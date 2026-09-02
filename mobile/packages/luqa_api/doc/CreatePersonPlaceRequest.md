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
**cityId** | **Optional<int?>** | The city the owner picked, as a GeoNames id from `GET /people/places/search`. Sending it is what makes the place pin on write: the server resolves the point from the cache that search filled, so no third party is on this path. Leave it out for a city that was only typed — offline, say — and the place lands unlocated for the geocoding batch to guess at.  Note what this request cannot carry: coordinates. The client says which city, never where it is. | [optional]
**isPrimary** | **Optional<bool?>** | The first place is primary whether or not this is set: a person with exactly one city and no primary has no answer to \"where are they\". | [optional]

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)
