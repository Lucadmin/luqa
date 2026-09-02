# Flutter People concept

Status: plan v1 — phases 1–6 implemented; Google Contacts outstanding
Date: 2026-08-31
Design system: [DESIGN.md](../DESIGN.md)
Related: [flutter-today-concept.md](flutter-today-concept.md),
[flutter-migration-plan.md](flutter-migration-plan.md)

## Starting position

`Person` is not a new entity. It already exists as a first-class, synced,
tombstoned model (`prisma/schema.prisma`, sync collection `people`, local table
`money_person`) — it is simply owned by Money today, and carries only the four
fields a bill split needs.

So this is not "build a contacts feature next to the money feature". It is
"promote the person Luqa already knows about, and hang the rest of a
relationship off it". Money keeps its ledger; it stops owning identity.

**The one-person rule.** There is exactly one `Person` row, one `people` sync
collection, and one repository that writes people. A second contact model would
mean two names for the same friend, two archive states, and a merge screen
nobody should ever have to use.

## Screen thesis

People is the roster and the reason to open it is almost always a name.

The screen therefore has no filled primary action. Money's focal object is a
number, Today's is a timeline; People's is a single line stating who needs
attention right now — the next birthday, or the person you have gone longest
without seeing — above a continuous list of everyone. Search is the real verb.

This is deliberate restraint. `Add person` is a rare action once Google
Contacts is connected, and promoting it to a filled button would make the tab
look like a CRM.

**No gamification.** DESIGN.md forbids streak shame, and a relationship tracker
is where that temptation is strongest. "Overdue" is a neutral list of elapsed
time, never a red badge, never a score, never a notification in v1.

## Compact Android structure

```text
system status bar

People                              map   search   avatar

Mira Hensel
Birthday in 12 days · turns 29

Overdue
  Jonas Brehm      5 months          every 2 months
  Tessa Lund      11 months          every 6 months

Everyone                                          38
  ● AH  Alina Hoeck        Munich · birthday 4 Sep
  ● JB  Jonas Brehm        Berlin
  ● MH  Mira Hensel        Munich · owes you 24,00 €
  ● PS  Piet Sanders       Hamburg
  ...

Today         Gym         Money         People       Insights
```

The focal line is the display role, exactly as the money tab's net position is.
It falls back in order: a birthday inside 30 days, then the longest-overdue
person, then the roster count when neither applies. One of them, never two.

`Overdue` is omitted entirely when nobody is. Rows are a continuous surface
with dividers, not a card per person.

## Data model

### Server

`Person` gains profile columns; the relationship's contents become child rows.

```prisma
model Person {
  // existing: id userId name color emoji defaultPercent order archivedAt
  //           createdAt updatedAt deletedAt

  nickname  String?
  photoUrl  String?

  // Stored as parts, not a DateTime. Most contacts have a day and month and
  // no year, and a DateTime forces the invention of a year that then shows up
  // as a wrong age.
  birthdayYear  Int?
  birthdayMonth Int?
  birthdayDay   Int?

  // Staying in touch. Null cadence means the person is simply not on a rhythm,
  // which is the honest default for most of a contact list.
  cadenceDays Int?
  lastSeenAt  DateTime?   // manual override; otherwise derived, see below

  googleResourceName String?   // "people/c123…"
  googleEtag         String?
  googleSyncedAt     DateTime?

  places   PersonPlace[]
  channels PersonChannel[]
  notes    PersonNote[]
  gifts    PersonGiftIdea[]
  entries  TimeEntryPerson[]
}

model PersonPlace {
  id, personId, label, city, region, country, address,
  lat Float?, lng Float?, isPrimary Boolean, source PlaceSource,
  createdAt, updatedAt, deletedAt
}

model PersonChannel { id, personId, kind ChannelKind, label, value, source }
model PersonNote    { id, personId, body, pinned, happenedOn String?, … }
model PersonGiftIdea{ id, personId, idea, url String?, givenAt DateTime?, … }

model TimeEntryPerson { timeEntryId, personId  @@id([timeEntryId, personId]) }

model GeocodeCache { query String @id, lat, lng, city, country, resolvedAt }

model GoogleContactsConnection {
  // mirrors GoogleHealthConnection: encrypted tokens, scope, lastSyncedAt
  syncToken String?   // People API nextSyncToken
}
```

### Children are embedded in the person, not synced separately

Places, channels, notes, and gift ideas ride inside `PersonDTO` the way
`memberIds` rides inside `PersonGroupDTO` and `shares` ride inside
`ExpenseDTO`. One row is one whole profile. That buys no new sync collections,
no new cursors, and no new tombstone handling for four small tables whose total
volume is a few hundred rows.

**The invariant this depends on:** every write to a child row must bump the
parent `Person.updatedAt` inside the same transaction. The delta feed orders by
`updatedAt`; a note added without touching the parent is a note no phone ever
hears about. This is the one rule that will silently break the feature if it is
missed, so it lives behind a single `touchPerson(tx, id)` helper that every
child write goes through.

It broke exactly as predicted, on 2026-09-01. `touchPerson` was written as
`person.update({ data: {} })`, on the assumption that any update moves an
`@updatedAt` column. Prisma treats an empty update as a no-op: no SQL, no
timestamp. Every place, note and gift written since the feature shipped reached
the server and no second device, and nothing looked wrong — the writes
succeeded, and every direct read showed them. It surfaced as a map with no pins
on it, weeks of stranded rows later.

Two things came out of that. The timestamp is now written explicitly through
`touchData()`, which lives in `person-profile.ts` so a test with no database
can assert the payload is not empty. And the lesson generalises: a "mark this
changed" write has to be verified against a real database, because the failure
mode of getting it wrong is silence.

Time entries carry `personIds` for the same reason.

### Local store (mobile)

Store version 5:

- `money_person` → `person`, with the profile columns added. A **rename**, not
  a drop-and-refetch: a phone that has been offline is holding rows the server
  has never seen, and discarding them to save a schema step would be deleting
  the user's work. The `pending` flag survives with them, which is what stops
  an incoming delta from reverting an unsent edit.
- New `person_place`, `person_channel`, `person_note`, `person_gift`, keyed
  `(namespace, id)` with a `person_id`.
- New `time_entry_person` (phase 6).

The children are written **whole** rather than merged: the server sends a person
as one row with its record inside, so applying a delta replaces that person's
children outright. Merging would need a per-child tombstone to know that a note
deleted on another device is gone; replacing gets that for free.

### One queue, shared with Money

**This is the decision that differs from the original plan.** People writes do
not get their own outbox — they ride in Money's, as `MoneyMutation` cases.

Two things force it, and both are ways a user loses work:

- A bill references a person by an id this device may have invented. A person
  create and an expense create therefore have to replay in the order they
  happened, and two queues have no order between them. The expense losing that
  race is sent naming somebody the server has never heard of, refused, and
  reported to the user as a lost bill.
- When the server answers a create with a *different* id — because it matched
  somebody by name — everything queued behind it has to be repointed, and a
  queue can only rewrite itself. A note written against the invented id would
  otherwise be orphaned the same way.

So `person`, its children, and the expenses that reference them share one store
and one queue. `LocalFirstPeopleRepository` is the People-shaped face of it.
The seam worth revisiting later is the name: `MoneyLocalStore` and
`MoneyMutation` now carry more than money.

### API

Canonical routes move to `/v1/people` (list, create, patch, archive, delete)
with the child collections nested under them. `/api/money/people` stays for the
web companion so nothing breaks; both call the same domain service.

## Google Contacts sync

Two-way, with write-back deliberately crippled so it cannot lose data.

**The rules, in the order they matter:**

1. Luqa never calls `deleteContact`, ever. Not on archive, not on delete.
2. Luqa never sends a field in `updatePersonFields` unless it is *adding* to
   that field in this specific request.
3. Every write is read-modify-write against a fresh copy: GET the person with
   exactly the fields in the mask, merge Luqa's addition into the existing
   array, PATCH the **full merged array** with the current etag.

Rule 3 is what actually protects the phone numbers. People API's update
semantics replace a masked field wholesale — sending `phoneNumbers` with one
entry deletes the other four. Merging first means every PATCH is a superset of
what was there, so the destructive case is not merely avoided by policy, it is
unreachable by construction.

4. A stale etag (400/409/412) triggers one re-pull and re-merge, then stops and
   surfaces the conflict rather than retrying into a loop.
5. The writable set is small on purpose:
   - contacts **Luqa created**: name, birthday, addresses.
   - contacts **Google owns**: birthday only when Google has none.
   - everything else — colour, emoji, notes, gift ideas, cadence, balances — is
     Luqa-only and never leaves.
6. Contacts deleted in Google (`metadata.deleted` in the incremental feed) are
   **archived** in Luqa, not deleted. They may carry money history that other
   people's balances were computed from.

**Pull.** `people.connections.list` on `people/me` with `requestSyncToken` for
the first pass, then `syncToken` for every later one; page through
`nextPageToken`; a 410 means the token expired and a full resync starts. Field
mask: `metadata,names,nicknames,birthdays,addresses,phoneNumbers,emailAddresses,photos,organizations`.

**Matching.** `googleResourceName` first; for the initial connect only, an exact
case-insensitive name match offers to link an existing Luqa person rather than
creating a duplicate. Automatic fuzzy matching is not attempted — a wrong merge
of two people is worse than two rows the owner merges by hand.

**Scope.** `https://www.googleapis.com/auth/contacts`. Connection lives in
Settings beside Calendar and Health, follows the same OAuth-state cookie and
encrypted-token pattern, and states in plain words what Luqa will and will not
write.

## Places and the map

The question the map answers is "I am in Hamburg on Thursday — who is here?".
That question is city-level, so Luqa stores city-level.

- **A city is chosen, not typed.** `GET /v1/people/places/search` offers
  candidates from Open-Meteo's geocoding API — GeoNames data — each with its
  region, country, population and a stable id. The owner picks one, and the
  place is written with that id and pins immediately. Before this, a typed name
  went to a geocoder that kept whatever it ranked first: nobody could say which
  Springfield they meant, and two people in two different Cambridges shared one
  pin.
- **Search fills a shared cache**, `GeoCity` keyed by GeoNames id and
  `GeoSearch` keyed by normalised query. That is what lets the write path
  resolve a chosen id with a primary-key read and no third-party call, which is
  the constraint the pull-based design exists to satisfy.
- **A typed name still works**, because offline is a real state here. It lands
  unlocated, and `POST /v1/people/places/geocode` resolves a bounded batch of
  them later, guessing the biggest settlement of that name. The same path
  serves addresses imported from Google. Misses are cached in `GeocodeCache`,
  so a misspelt city is not retried for ever.
- Only the **city centroid** is stored, never the street coordinate. It answers
  the question exactly as well, and it keeps a file of friends' home addresses
  from becoming a map of friends' front doors.
- A person may have several places (`Home`, `Parents`, `Summer`), one primary.
- Cities are grouped by chosen id where there is one and by name otherwise, so
  two Cambridges are two pins and places typed before any of this still group
  as they did.

**Map route** `/people/map`, opened from a header action rather than a
segmented control, matching `/money/groups` and `/gym/locations`.

- `flutter_map` + `latlong2`, OSM raster tiles, `© OpenStreetMap contributors`
  attribution as the tile licence requires.
- Tiles are desaturated through a `TileBuilder` colour filter so the map reads
  as Luqa's monochrome shell rather than as OSM's palette. Markers then carry
  the only colour on screen.
- One pin per **city**, not per person: the pin shows a count, and tapping it
  opens a sheet listing the people there. Thirty overlapping pins in Munich is
  not an overview, and this avoids needing clustering at all.
- Pins pair identity colour with initials, per the data-identity rule — colour
  alone never identifies anyone.
- Initial camera fits the bounding box of all places. No location permission in
  v1; "near me" waits until there is a reason to ask for GPS.
- **Offline is a real state here.** Tiles need a network and the rest of the app
  does not. With no connection the map route shows an explicit "the map needs a
  connection" surface, and the city-grouped **list** — which is offline and is
  arguably the better answer anyway — sits one tap away on the same route.

## Birthdays

- Next occurrence computed from month/day; 29 February resolves to 1 March in
  non-leap years, stated here because it is the kind of thing that otherwise
  gets decided by accident.
- Age is shown only when the year is known. No invented ages.
- The People screen surfaces the next one inside 30 days as its focal line and
  lists the next 60 days; `/people/birthdays` shows the full year by month.
- Pushing birthdays into the Luqa Google Calendar is **deferred** — the
  `GoogleConnection` push path already exists, so it stays cheap to add later.

## Stay in touch

- `cadenceDays` per person; null for most people, and null means the person
  never appears in an overdue list.
- `lastSeenAt` is the newest of: a manually set date, the end of the newest
  time entry tagged with them, and the date of the newest expense they share.
  Money already knows you had dinner together; it should not have to be typed
  twice.
- Someone with a cadence and no history counts from the day the cadence was set,
  not from epoch, so setting a cadence does not instantly declare everyone
  neglected.
- Wording is elapsed time — "5 months since Jonas" — not a verdict.

## People on Today's timeline

- `TimeEntryPerson` join; `personIds` embedded in the time-entry DTO.
- The entry editor sheet gains a `With` row opening a person picker built on the
  existing `category_picker_sheet.dart` pattern, multi-select.
- Timeline rows show names on the existing description line. No new colour, no
  avatar row — the timeline's focal object stays the day.
- Person detail gains a `Together` section: shared entries, newest first, and
  hours this year.

## Person detail

Route `/people/:personId`. The money ledger stays at `/money/people/:personId`
as the money facet, linked from here.

1. Header — avatar, name, nickname, primary city.
2. One focal line — birthday countdown when inside 30 days, otherwise last seen.
3. Quick actions — call, message, and `Log a catch-up`, via `url_launcher`.
4. Balance — one row, linking into the existing ledger, shown only when nonzero.
5. Notes — newest first, add inline, pinned notes on top.
6. Gift ideas — with a `given` state, surfaced by the birthday countdown.
7. Together — shared timeline entries.
8. Places, channels, cadence, and the Google link state.

## Required states for the first prototype

Roster loading, roster empty, offline with cached people, sync error, person
with no birthday, person with no place, archived person, Google not connected,
Google token expired, Google sync conflict, map with no network, map with no
geocoded places, and a person whose Google contact was deleted upstream.

Light and dark goldens for the People screen and person detail, at default and
large text scale.

## Delivery phases

Built screens-first, against a repository the device holds in memory, so the
design could be argued with before a migration was committed to — the same way
`FakeTodayRepository` and `FakeGymRepository` were used.

1. **Server foundation** — ✅ done. Migration `20260831160000_person_profile`;
   `src/lib/server/people.ts` with `touchPerson`/`writeChild`; `/v1/people`
   with nested notes, gifts, places and `seen`; the `people` delta feed now
   includes the children. The create and delete rules live in the service and
   are shared with `/v1/money/people`, so the two contracts cannot drift. The
   pure birthday arithmetic sits in `src/lib/person-profile.ts` — apart from
   the queries, like `sync-cursor.ts` — with its own tests.
2. **Mobile data layer** — ✅ done. Store v5 (rename + children, with a
   migration test); `PeopleSyncService`; `RemotePeopleRepository`;
   `LocalFirstPeopleRepository` over the shared store and queue; nine new
   mutation types with json round-trip, folding, and id-remap coverage.
3. **People screen and person detail** — ✅ done. `Person` moved into
   `features/people/domain/person.dart` and extended in place, re-exported from
   `money_models.dart` so no money caller changed. Roster with the single focal
   line, search across name/nickname/city, "been a while", person detail with
   notes, gift ideas, places and the linked money balance, the birthday year,
   and the city-grouped "where everyone is". `InMemoryPeopleRepository` is the
   whole write surface rather than a stub, so swapping in the local-first
   repository was a provider change. `InMemoryPeopleRepository` now lives in
   `test/helpers/` as the widget and golden fixture.
5. **Map layer** — ✅ done. `flutter_map` + `latlong2`, OSM raster tiles
   desaturated through a `TileBuilder` so the markers carry the only colour on
   screen, one pin per city with a count. A city added through the picker pins
   on write, resolved from the shared `GeoCity` cache that the search itself
   filled. A city that was only typed is **pull, not push**:
   `POST /v1/people/places/geocode` resolves a bounded batch and the client
   asks when it opens the map, so adding stays instant and the pin catches up —
   a serverless request cannot finish background work after replying. Misses
   are cached too, so a misspelt city is not retried for ever.
6. **Timeline tagging** — ✅ done. `TimeEntryPerson`, `personIds` inside the
   entry DTO and the delta feed, a `With` row on the entry editor opening a
   multi-select picker, names on the timeline's existing second line, and a
   `Together` section on the person screen. `lastSeenProvider` derives when
   somebody was really last seen from the newest of: the typed date, a tagged
   block of time, and a shared bill — all from data the device already holds,
   so it is correct offline.
4. **Google Contacts** — the remaining phase. OAuth connection, pull sync,
   additive write-back, settings tile, conflict surface.

Each phase carries the quality bar from the migration plan: domain and
repository tests, contract and authorisation tests, widget tests for every
state above, goldens for the design-critical surfaces, and an accessibility
pass for semantics, contrast, text scaling, and touch targets.

## Known limits

- **OSM tile servers.** The map uses the public OpenStreetMap tiles, which
  `flutter_map` warns about on every launch. Their usage policy is written
  against bulk consumers; a single-owner app rendering a few dozen tiles is
  well inside it. If Luqa ever has more than one owner, this needs a tile
  provider with a contract behind it.
- **Open-Meteo geocoding.** Same shape of dependency: free, no key, no
  contract. `GeoCity` and `GeoSearch` are what keep the app off it — after the
  first person types a prefix, that prefix costs a database read. If it ever
  goes away, picking stops working and every place falls back to being a typed
  name, which is a degraded state the app already handles rather than a broken
  one.
- **`MoneyLocalStore` and `MoneyMutation` now carry more than money.** The
  shared store and queue are correct (see above); the names are not. Worth
  renaming when something else touches them.

## Deliberately out of scope for v1

Birthday notifications and calendar push, relationship graphs (who knows whom
beyond the existing groups), GPS "near me", contact photo upload to Google,
importing from anything other than Google, and merging duplicate people.
