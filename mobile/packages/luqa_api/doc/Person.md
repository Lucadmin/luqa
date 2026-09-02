# luqa_api.model.Person

## Load the model package
```dart
import 'package:luqa_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**id** | **String** |  |
**name** | **String** |  |
**color** | **String** |  |
**emoji** | **String** |  |
**defaultPercent** | **int** | The cut of a bill this person usually carries, in whole percent. Null means share equally with everyone else on it. |
**order** | **int** |  |
**archived** | **bool** |  |
**nickname** | **String** | What the owner actually calls them. |
**photoUrl** | **String** |  |
**birthdayYear** | **int** | Null far more often than not. Most contacts carry a day and a month and no year, and inventing one produces a confidently wrong age, so a missing year is simply missing and no age is offered. |
**birthdayMonth** | **int** |  |
**birthdayDay** | **int** | 29 February is storable, because it is a real birthday. Which day it falls on in a common year is the client's next-occurrence rule. |
**cadenceDays** | **int** | How often being in touch is worth aiming for. Null for most people, and null means they are never reported as overdue. |
**closeness** | **int** | Explicitly chosen by the owner: 1 familiar, 2 in my life, 3 close, 4 inner circle. Never inferred from activity. |
**lastSeenAt** | [**DateTime**](DateTime.md) |  |
**googleResourceName** | **String** | The People API resource this row is linked to. Null for someone who exists only in Luqa. |
**places** | [**List<PersonPlace>**](PersonPlace.md) |  | [default to const []]
**channels** | [**List<PersonChannel>**](PersonChannel.md) |  | [default to const []]
**notes** | [**List<PersonNote>**](PersonNote.md) |  | [default to const []]
**gifts** | [**List<PersonGiftIdea>**](PersonGiftIdea.md) |  | [default to const []]
**connections** | [**List<PersonConnection>**](PersonConnection.md) | Symmetric links to other people. A link is stored on one endpoint only, so clients build the graph from every person's list. | [default to const []]

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)
