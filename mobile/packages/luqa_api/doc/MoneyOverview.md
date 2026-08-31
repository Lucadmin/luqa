# luqa_api.model.MoneyOverview

## Load the model package
```dart
import 'package:luqa_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**currency** | **String** |  |
**people** | [**List<PersonBalance>**](PersonBalance.md) | Biggest outstanding balance first; settled people sink to the bottom. Archived people are included — they may still carry a balance, and their names have to resolve on old bills. | [default to const []]
**groups** | [**List<PersonGroup>**](PersonGroup.md) |  | [default to const []]
**owedToYouCents** | **int** |  |
**youOweCents** | **int** | Sum of the negative balances, as a positive number. |
**netCents** | **int** |  |
**coveredCents** | **int** |  |

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)
