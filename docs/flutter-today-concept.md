# Flutter Today concept

Status: visual direction v3
Design system: [DESIGN.md](../DESIGN.md)
Visual reference: [today-concept-v3.png](design/today-concept-v3.png)

## Screen thesis

Today is not a dashboard. It is the working surface for the current day.

The dominant workflow is retrospective: reviewing the recorded day, filling
gaps, and correcting entries. One object dominates at a time:

- In the default state, the timeline and `Log time` action are the focal point.
- While a timer runs, it appears in a compact persistent row without displacing
  the timeline.
- When viewing another day, the date and recorded timeline take priority.

Sleep and habits remain immediately actionable context. The timer remains an
important secondary capture method, not the default screen composition. The
timeline is the screen's durable backbone, not a secondary card below a summary
dashboard.

## Compact Android structure

```text
system status bar

Today                         settings  profile
Wednesday, 27 August

[             + Log time             ] [Start timer]

moon  7h 17m sleep                              >

Water  5/8       Read  20m       Stretch  1/3       >

08:00  |  Food · Breakfast           08:10-08:40
09:00  |  Master thesis              09:00-11:45
       |  Writing thesis
10:00  |
11:00  |
12:00  |  Training · Gym             12:30-13:45
13:00  |

Today         Gym         Money         People       Insights
```

The screen is edge-to-edge and uses a continuous background. Dividers, rhythm,
and typography separate regions. Sleep, habits, and timeline entries do not sit
inside nested generic cards.

## Header and date navigation

- `Today` uses the headline role. The full localized date sits below it.
- The trailing action cluster contains separate Settings and Profile targets.
  Settings opens app preferences and integrations; Profile opens the account
  and user identity surface. Both remain available when the header collapses.
- Tapping the date opens the platform date picker.
- Horizontal day navigation is available through a deliberate swipe on the
  date/timeline surface and through accessibility actions. System Back remains
  navigation Back, never "previous day."
- When viewing another date, the title changes to the weekday/date and a clear
  `Return to today` action appears.
- As the timeline scrolls, the large header collapses. The primary log action
  remains reachable through a compact floating or app-bar action.

## Capture actions

- `Log time` is the primary action. It opens a focused editor for category,
  description, start time, and end time, prefilled around the most relevant
  timeline gap.
- `Start timer` is a smaller secondary action. It asks for category and
  description, then resolves into the compact running state.
- Tapping or long-pressing an empty timeline range offers the same retrospective
  entry flow without forcing the user back to the top of the screen.
- Recently used categories and descriptions are suggestions, never silently
  committed defaults.

## Active timer state

- Category color appears as a compact identity mark and explicit category
  label. Category and description are never collapsed into one ambiguous line.
- The compact row shows category, description, a tabular elapsed value, and a
  clear Stop action without turning the timer into the screen's focal card.
- Elapsed time updates without changing width. Stop uses maximum-contrast ink:
  dark in light mode, light in dark mode.
- Tapping the description/category opens a focused editor without stopping the
  timer.
- Stopping gives immediate haptic feedback, freezes the value, and resolves the
  running state into a timeline entry.

## Sleep row

- Shows the sleep duration attributed to the logical day.
- Uses a moon glyph plus explicit `sleep` text; purple alone never identifies
  sleep.
- Tapping opens the sleep detail/editor sheet with source, start/end,
  efficiency, and stage information.
- If sleep data is unavailable, show a quiet actionable state rather than
  hiding the row and causing the layout to jump unpredictably.

## Habit strip

- Scheduled habits occupy one slim, horizontally scrollable action row rather
  than a second dashboard section.
- Each item shows glyph/name and explicit progress in one line. The whole item
  is the primary target; persistent plus/minus controls are omitted here.
- Habit color belongs to the glyph and progress. Resting labels remain neutral.
- Completing a task uses a 180–220 ms progress resolution and light haptic. No
  confetti or page-wide color wash.
- Horizontal overflow is allowed when necessary, with the next item visibly
  clipped enough to communicate scrollability.
- A trailing affordance, the section label, or a horizontal overflow action
  opens the full Habits route. Creation and schedule management stay there
  rather than competing with daily actions.

## Timeline

- The left time rail is quiet and fixed-width. Entries occupy the remaining
  width.
- Hour rules are subtle; the current-time rule is the only high-attention line.
- Entry blocks use flat identity-color tints with a saturated compact mark. The
  generated visual's soft color gradients are not part of the production
  system.
- Name is left aligned; exact time range is right aligned with tabular figures.
- Very short entries preserve a useful touch target through an interaction
  overlay without falsifying their visual duration.
- Sleep may appear in the timeline when it overlaps the visible range, using a
  moon glyph and stage-aware detail only after opening it.

### Timeline interaction

- Tap an entry to edit it in a bottom sheet.
- Tap an empty slot to create a default 30-minute inline draft.
- Long-press and drag selects a precise time range; drag begins only after the
  long-press threshold so ordinary vertical scrolling remains reliable.
- Once a draft exists, visible handles adjust start/end in five-minute steps.
- A running entry is controlled by the compact timer row rather than behaving
  like an ordinary completed block.
- Offline-created entries show a small explicit pending-sync mark and remain
  editable.

## Bottom navigation

Compact navigation contains exactly five destinations:

1. Today
2. Gym
3. Money
4. People
5. Insights

The active destination uses purple plus label weight. Inactive destinations are
monochrome and readable. On expanded widths this becomes a navigation rail.
Habits remain first-class, but their daily actions live on Today and their full
management route opens from the habit strip instead of consuming a sixth tab.
People receives the top-level destination requested for relationships, groups,
and person-led context. Settings and Profile are distinct header actions.

## Theme behavior

Light and dark use the same hierarchy but not mechanical inversion:

- Light mode is high-key and direct. Structural rules remain visible without
  surrounding every region with gray containers.
- Dark mode uses three deliberate neutral levels so entries and controls do not
  dissolve into black.
- Identity tints are recalculated per theme. Dark mode does not reuse light-mode
  opacity values blindly.
- Maximum-contrast actions reverse from ink-on-light to light-on-ink.

## Motion specification

- Button press: 120 ms scale to 0.98; release completes immediately.
- Habit completion: 200 ms progress resolution with strong ease-out.
- Timer stop-to-entry: 220 ms shared-object/fade-through transition.
- Header collapse: follows scroll directly; it does not play a delayed
  animation after scrolling stops.
- Entry sheet: platform bottom-sheet transition.
- Day change: 200 ms shared-axis movement for adjacent days; distant date jumps
  use a fade-through.
- Reduced motion replaces spatial transitions with crossfades or immediate state
  changes.

## Required states for the first prototype

- Light and dark.
- Timer idle and running.
- Today and a historical day.
- Loading skeleton with stable geometry.
- No habits scheduled.
- Empty timeline.
- Offline with cached data.
- Pending local mutation.
- API error with retry.
- Large system text.
- Reduced motion.

## Implementation boundary

The visual direction is achievable with Flutter theme extensions, ordinary
layout widgets, a custom-painted timeline, implicit animations, standard route
and bottom-sheet transitions, and platform haptics. It does not require a game
engine, animation asset pipeline, shader, or general motion framework.
