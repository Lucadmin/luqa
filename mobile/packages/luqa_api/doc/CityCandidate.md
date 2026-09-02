# luqa_api.model.CityCandidate

## Load the model package
```dart
import 'package:luqa_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**id** | **int** | The GeoNames id. Stable, and the only thing the client sends back when this candidate is chosen. |
**name** | **String** |  |
**admin1** | **String** | State, province or Land. The single most useful field for telling Springfield, Illinois from Springfield, Missouri. |
**country** | **String** |  |
**countryCode** | **String** |  |
**latitude** | **num** |  |
**longitude** | **num** |  |
**timezone** | **String** |  |
**population** | **int** | Shown beside each candidate, because size is how a person actually recognises which city was meant. |
**featureCode** | **String** | GeoNames' kind: PPLC for a national capital, PPLA for a regional one, PPL for an ordinary settlement. |

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)
