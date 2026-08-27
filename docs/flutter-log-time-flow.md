# Flutter Log time flow

Status: interaction direction v1
Design system: [DESIGN.md](../DESIGN.md)
Today context: [flutter-today-concept.md](flutter-today-concept.md)
Visual reference: [log-time-flow-v1.png](design/log-time-flow-v1.png)

## Product decision

Retrospective logging is Today’s primary capture workflow. The editor is
optimized for correcting and filling the day, while Start timer remains a
separate secondary action.

The persisted model stays unchanged:

- description, up to 500 characters;
- optional category;
- start date/time;
- end date/time, strictly after start;
- a null end remains reserved for a running timer.

## Entry points

The same editor opens from three places:

1. **Log time:** infer a useful range from the selected day.
2. **Tap an empty timeline gap:** prefill that exact gap.
3. **Tap an existing entry:** edit it with the same field order and controls.

The top-level action defaults to the range from the most recent completed entry
to now, snapped to five minutes. If that range is unavailable or implausibly
large, default to the previous 30 minutes. The user always sees the inferred
range before saving.

## Sheet structure

The editor is a platform-aware modal bottom sheet. It may expand with the
keyboard, but it does not become a small centered dialog.

```text
drag handle

Log time                                      close
Today · Wednesday, 27 August

What did you do?
Writing thesis

Category
purple mark  Master thesis                       >

Start                    End
09:00                    11:45
                 2h 45m

Recent
Writing thesis · Master thesis
Lunch · Food
Gym · Training

[                 Add entry                  ]
```

Description and category are separate, explicit fields. Color supports the
category identity but never replaces its name. Start and end are equal-width,
tabular fields; duration is derived and visually quieter.

## Fast path

1. Tap `Log time` or an empty gap.
2. Tap a recent activity to fill description and category together.
3. Accept or adjust the inferred range.
4. Tap `Add entry`.

With a good time inference, common activities take two taps after opening. The
sheet remembers no hidden draft as if it were saved; unsaved values remain local
until Add entry succeeds.

## Description and recent activities

- The description field uses `What did you do?`, matching retrospective intent.
- Recent suggestions reuse the existing description/category history and rank
  exact query matches first.
- Selecting a suggestion fills both values, but either can be edited afterward.
- Category-only and description-only entries remain possible because the
  current model allows them. When both are empty, the confirmation label becomes
  `Add untitled entry` so the consequence is explicit.
- Suggestions disappear as the query becomes sufficiently specific and never
  cover the primary action.

## Category picker

- Tapping Category opens a searchable sheet over the editor rather than a tiny
  dropdown.
- Each row shows a color mark and category name; the selected row also has a
  checkmark.
- `No category` is an explicit option.
- `Create category` is available after a non-matching search, but full color and
  archive management remain in Settings.
- Returning from the picker preserves every other draft field.

## Time editing

- Start and End use native platform time pickers with five-minute shortcuts.
- Direct numeric entry remains available for speed and accessibility.
- A date row appears once either boundary leaves the selected logical day.
- Crossing midnight is supported and labelled `Tomorrow`; it is never inferred
  from an end time that merely appears earlier.
- A compact `Adjust on timeline` action returns to an inline draggable draft for
  spatial editing. It is secondary, not required for ordinary logging.
- Overlaps are allowed by the current data model. The sheet shows a non-blocking
  warning naming the conflicting entry and offers `Adjust`; it does not silently
  move either entry.

## Save behavior

- `Add entry` is the only filled action in the sheet and remains keyboard-safe.
- Saving changes the label to `Adding…`; repeat taps are ignored.
- Success closes the sheet and resolves the new block into the timeline with a
  short 180–220 ms fade/size transition and light haptic.
- If a partially filled gap remains, a snackbar offers `Fill next gap` rather
  than forcing another editor open.
- Offline saves create a visible pending entry locally and retry safely with a
  stable mutation id. A sync failure leaves the entry editable and exposes
  `Retry`; it never discards the draft.

## Validation and destructive states

- End must be after Start. The duration line becomes an adjacent error and Add
  entry is disabled until corrected.
- Description is limited to 500 characters; the counter appears only near the
  limit.
- Unknown or deleted categories surface an inline Category error and preserve
  the remaining draft.
- Editing replaces `Add entry` with `Save changes` and adds a quiet Delete row.
  Delete requires confirmation because Google Calendar synchronization may
  propagate it.
- Dismissing a changed draft asks whether to discard. An untouched inferred
  draft closes immediately.

## Accessibility and adaptation

- Android targets are at least 48 dp; iOS targets are at least 44 pt.
- Fields have persistent labels, semantic error associations, logical keyboard
  order, and screen-reader announcements for inferred times and save results.
- Large text stacks Start and End vertically and lets the sheet become
  full-height.
- Android uses Material bottom-sheet, time-picker, Back, and IME behavior. iOS
  uses native sheet detents, wheel/compact time selection, and swipe dismissal
  unless a changed draft needs a discard guard.
- Reduced motion uses an immediate state update or crossfade; haptics remain
  optional through system accessibility settings.

## First implementation states

- Empty inferred draft.
- Recent suggestion selected.
- Category search and creation.
- Invalid range.
- Overlap warning.
- Saving and saved.
- Offline pending and retry.
- Edit and delete.
- Cross-midnight entry.
- Large text, dark mode, and reduced motion.
