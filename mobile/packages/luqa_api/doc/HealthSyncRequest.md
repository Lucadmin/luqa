# luqa_api.model.HealthSyncRequest

## Load the model package
```dart
import 'package:luqa_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**source_** | [**Optional<DeviceHealthSource?>**](DeviceHealthSource.md) |  | [optional]
**deviceId** | **Optional<String?>** |  | [optional]
**sleep** | [**Optional<SleepSyncPayload?>**](SleepSyncPayload.md) |  | [optional]
**samples** | [**Optional<List<HealthSampleImport>?>**](HealthSampleImport.md) |  | [optional] [default to const []]
**deletedSamples** | [**Optional<List<HealthSampleRef>?>**](HealthSampleRef.md) |  | [optional] [default to const []]

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)
