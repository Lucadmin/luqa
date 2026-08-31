---
name: Luqa
description: A bold personal operating system for daily capture and lifelong context.
colors:
  light-background: "#FBFBFA"
  light-surface: "#FFFFFF"
  light-surface-raised: "#F4F4F5"
  light-border: "#D6D6DA"
  light-ink: "#1A1A1E"
  light-muted: "#5F5F68"
  dark-background: "#0B0B0D"
  dark-surface: "#141417"
  dark-surface-raised: "#1C1C20"
  dark-border: "#34343A"
  dark-ink: "#F4F4F5"
  dark-muted: "#A8A8B0"
  purple-light: "#6543E8"
  purple-dark: "#A78BFA"
  purple-on-light: "#FFFFFF"
  purple-on-dark: "#100C19"
  identity-blue-light: "#2563EB"
  identity-blue-dark: "#60A5FA"
  identity-teal-light: "#0F766E"
  identity-teal-dark: "#5EEAD4"
  identity-green-light: "#15803D"
  identity-green-dark: "#4ADE80"
  identity-amber-light: "#B45309"
  identity-amber-dark: "#FBBF24"
  identity-orange-light: "#C2410C"
  identity-orange-dark: "#FB923C"
  identity-pink-light: "#BE185D"
  identity-pink-dark: "#F472B6"
  error-light: "#B42318"
  error-dark: "#FF8A80"
  credit-light: "#127C46"
  credit-dark: "#63E8A3"
  debit-light: "#86280F"
  debit-dark: "#FF8A66"
typography:
  display:
    fontFamily: "Geist Sans, Roboto, sans-serif"
    fontSize: "44px"
    fontWeight: 650
    lineHeight: 1
    letterSpacing: "-0.03em"
  headline:
    fontFamily: "Geist Sans, Roboto, sans-serif"
    fontSize: "32px"
    fontWeight: 650
    lineHeight: 1.08
    letterSpacing: "-0.025em"
  title:
    fontFamily: "Geist Sans, Roboto, sans-serif"
    fontSize: "22px"
    fontWeight: 600
    lineHeight: 1.18
    letterSpacing: "-0.015em"
  body:
    fontFamily: "Geist Sans, Roboto, sans-serif"
    fontSize: "16px"
    fontWeight: 450
    lineHeight: 1.45
    letterSpacing: "normal"
  label:
    fontFamily: "Geist Sans, Roboto, sans-serif"
    fontSize: "13px"
    fontWeight: 600
    lineHeight: 1.2
    letterSpacing: "0.01em"
  numeric:
    fontFamily: "Geist Sans, Roboto, sans-serif"
    fontSize: "36px"
    fontWeight: 650
    lineHeight: 1
    letterSpacing: "-0.025em"
    fontFeature: "tabular-nums"
rounded:
  indicator: "2px"
  compact: "6px"
  control: "8px"
  surface: "12px"
  dialog: "16px"
  full: "999px"
spacing:
  1: "4px"
  2: "8px"
  3: "12px"
  4: "16px"
  6: "24px"
  8: "32px"
  12: "48px"
components:
  button-primary-light:
    backgroundColor: "{colors.light-ink}"
    textColor: "{colors.light-surface}"
    typography: "{typography.label}"
    rounded: "{rounded.control}"
    padding: "12px 20px"
    height: "48px"
  button-primary-dark:
    backgroundColor: "{colors.dark-ink}"
    textColor: "{colors.dark-background}"
    typography: "{typography.label}"
    rounded: "{rounded.control}"
    padding: "12px 20px"
    height: "48px"
  button-accent-light:
    backgroundColor: "{colors.purple-light}"
    textColor: "{colors.purple-on-light}"
    typography: "{typography.label}"
    rounded: "{rounded.control}"
    padding: "12px 20px"
    height: "48px"
  button-accent-dark:
    backgroundColor: "{colors.purple-dark}"
    textColor: "{colors.purple-on-dark}"
    typography: "{typography.label}"
    rounded: "{rounded.control}"
    padding: "12px 20px"
    height: "48px"
  input-light:
    backgroundColor: "{colors.light-surface-raised}"
    textColor: "{colors.light-ink}"
    typography: "{typography.body}"
    rounded: "{rounded.compact}"
    padding: "12px 14px"
    height: "48px"
  input-dark:
    backgroundColor: "{colors.dark-surface-raised}"
    textColor: "{colors.dark-ink}"
    typography: "{typography.body}"
    rounded: "{rounded.compact}"
    padding: "12px 14px"
    height: "48px"
---

# Design System: Luqa

## 1. Overview

**Creative North Star: "The Bold Personal Instrument"**

Luqa combines Trade Republic-like decisiveness with the intimacy of a private
life record. Every screen has one unmistakable focal point, while supporting
information becomes deliberately quieter. Scale, contrast, alignment, and open
space create boldness; decoration does not.

The shell is almost monochrome and uses crisp geometry. Purple identifies Luqa,
focus, and active state. User-defined colors identify the actual contents of a
life: habits, categories, people, groups, locations, periods, and charts. Dark
and light are separately tuned schemes with equal product status.

Android behavior is the primary reference. iOS keeps the same visual identity
while adopting inexpensive native guarantees such as safe areas, edge-swipe
back, platform pickers, sheet behavior, and reduced motion.

**Key Characteristics:**

- One dominant idea per screen.
- Stark neutral contrast with rare, meaningful purple.
- Personal data color on an otherwise quiet shell.
- Crisp 6–12 px corners; pills only where their semantics require them.
- Flat, continuous working surfaces instead of nested card grids.
- Responsive motion and haptics, without page choreography.

**The One Focal Point Rule.** Every screen chooses a single dominant object:
today's editable timeline, the current exercise, an amount being split, a
balance, or a selected life week. If three elements compete, none is bold.

## 2. Colors

The palette is true neutral rather than warm paper or blue-black technology.
Ink and white do most of the work; purple is rare enough to remain recognizable.

### Primary

- **Luqa Purple** (`purple-light` / `purple-dark`): focus rings, active
  navigation, selection, branded progress, and rare Luqa-specific moments. It
  is not the automatic background of every primary button.
- **Maximum-Contrast Ink** (`light-ink` / `dark-ink`): the default filled action
  and the strongest typographic hierarchy. It reverses across themes.

### Secondary

- **Identity Spectrum** (`identity-*-light` / `identity-*-dark`): user-selectable
  colors for habits, categories, people, groups, gym locations, life periods,
  and chart series. Every identity color is accompanied by a name, icon, shape,
  or position.

### Tertiary

- **System Error** (`error-light` / `error-dark`): destructive actions and
  failed states only. Success, warning, syncing, and offline roles will receive
  separate semantic tokens when their components are implemented; they never
  borrow identity colors by implication.
- **Money Direction** (`credit-*` / `debit-*`): which way a balance points —
  credit is owed to the owner, debit is owed by them. Neither is success or
  failure and neither is an error, so neither borrows the error token or an
  identity color. The pair is separated by lightness as well as hue, because a
  red and a green of equal luminance are the same color to the most common form
  of color blindness, and every amount drawn in them carries the words that
  state the direction on their own.

### Neutral

- **Open Canvas** (`light-background` / `dark-background`): the continuous app
  background.
- **Working Surface** (`light-surface` / `dark-surface`): sheets, editors, and
  content areas that need separation from the canvas.
- **Raised Tone** (`light-surface-raised` / `dark-surface-raised`): selected
  rows, grouped controls, inputs, and temporary elevation.
- **Structural Rule** (`light-border` / `dark-border`): separators and focused
  structure. Borders are quiet and complete, never decorative side stripes.
- **Supporting Ink** (`light-muted` / `dark-muted`): secondary copy that remains
  readable at WCAG AA contrast.

**The Shell and Life Rule.** The shell belongs to Luqa; the colors belong to
Luca's life. Neutral surfaces and purple define the product. Identity colors
define the data.

**The Tint Ceiling.** Identity color may tint a selected or expanded surface at
8–16% opacity. Full saturation is reserved for compact marks, progress, charts,
and rare meaningful moments.

**The No Dynamic Recolor Rule.** Android wallpaper colors must not replace the
Luqa scheme. Dynamic Color would blur the difference between brand, identity,
and semantic roles.

The validated core text pairs range from 5.96:1 to 19.66:1. Component-level
contrast must still be checked after opacity, disabled state, and identity-color
tints are applied.

## 3. Typography

**Display Font:** Geist Sans (with Roboto and system sans fallback)
**Body Font:** Geist Sans (with Roboto and system sans fallback)
**Label/Mono Font:** Geist Sans with tabular figures; Geist Mono is reserved for
technical identifiers, never ordinary values.

**Character:** A single modern grotesk keeps the product decisive and coherent.
Personality comes from dramatic scale contrast, not a decorative font pairing.
Numerals align cleanly for time, money, weights, counts, and reports without
turning the app into a terminal.

### Hierarchy

- **Display** (650, 44 px, 1.0): one focal value or phrase on a top-level screen.
- **Headline** (650, 32 px, 1.08): top-level page titles and focused section
  statements.
- **Title** (600, 22 px, 1.18): editor titles and primary content groups.
- **Body** (450, 16 px, 1.45): ordinary descriptions, values, and form content.
- **Label** (600, 13 px, 1.2): controls, navigation, metadata, and compact state.
- **Numeric** (650, 36 px, 1.0, tabular figures): important changing values
  whose alignment matters.

All roles scale with the operating-system text setting. Compact layouts reflow;
they do not silently cap accessible text size.

**The Scale Contrast Rule.** Do not solve hierarchy with a procession of 16,
18, and 20 px medium-weight labels. One element becomes clearly large, ordinary
content stays ordinary, and metadata becomes quiet but readable.

**The Numerals Are Content Rule.** Tabular figures align data; monospaced type
does not decorate the interface or impersonate a technical console.

## 4. Elevation

Luqa is flat by default. Depth comes from tonal surface changes, complete
borders, modality, and motion. Ordinary cards do not combine borders with wide
shadows. Shadows are reserved for modal sheets, dialogs, menus, and an object
being actively dragged above another surface.

### Shadow Vocabulary

- **Modal Lift** (`0 8px 24px rgba(0,0,0,0.18)`): dialogs and floating menus
  only; Android tonal elevation remains present underneath.
- **Drag Lift** (`0 4px 8px rgba(0,0,0,0.16)`): temporary feedback while a row
  or block is being reordered.

**The Flat-at-Rest Rule.** If a surface is not modal, floating, or being dragged,
it earns hierarchy through tone, border, space, or typography—not shadow.

## 5. Components

Components are tactile and confident. Every interactive primitive includes
default, focused, pressed, disabled, loading, error, and reduced-motion states.
Android touch targets are at least 48 dp; iOS targets are at least 44 pt.

### Buttons

- **Shape:** crisp rectangular control with 8 px corners.
- **Primary:** maximum-contrast ink fill, 48 px high, 20 px horizontal padding.
  Use one primary action in a visible task area.
- **Accent:** purple fill for Luqa-specific commitment or a branded moment, not
  as an interchangeable second primary beside an ink button.
- **Secondary:** raised neutral tone or a complete structural border.
- **Ghost:** no container at rest; the pressed state gains a neutral tone.
- **Pressed:** 100–140 ms scale to approximately 0.98 with light haptic feedback
  where repetition remains comfortable.
- **Focus:** 2 px purple ring with sufficient separation from the component
  border.

### Chips

- **Style:** 6 px corners for filters and compact selections; full pills are
  reserved for true tags and statuses.
- **State:** neutral at rest, raised neutral when selected, with a purple mark or
  user identity color plus a non-color signal.

### Cards / Containers

- **Corner Style:** 12 px for isolated focused surfaces; ordinary content rows
  remain part of a continuous surface.
- **Background:** canvas, working surface, or raised tone only.
- **Shadow Strategy:** flat at rest.
- **Border:** a complete one-pixel structural rule when separation is necessary.
- **Internal Padding:** 16 px compact, 24 px standard, 32 px for a rare focal
  composition.

Nested cards are prohibited. If a surface contains several related rows, use
spacing and dividers instead of a card per row.

### Today capture hierarchy

- The timeline is the primary working surface because most time is logged and
  corrected retrospectively.
- `Log time` is the default primary action; `Start timer` is a smaller secondary
  action beside it.
- A running timer uses one compact persistent row with category, description,
  elapsed time, and Stop. It never displaces the timeline with a dashboard-sized
  timer card.
- Timeline entries expose category and description as distinct information when
  both exist, using identity color as support rather than as the only label.
- Retrospective entry uses a keyboard-safe modal bottom sheet. Description,
  category, Start, and End retain persistent labels; derived duration remains
  subordinate.
- Recent activity rows fill description and category together. They are plain
  list rows, not a cloud of pills or a generic recommendation card.
- The single filled sheet action is `Add entry` or `Save changes`. Category
  selection and spatial timeline adjustment use progressive disclosure.

### Abandoned writes

Luqa answers every write from the device and sends it later, so there is one
case the interface has to be able to admit: the server understood a change and
refused it, the queue gave up, and the user's work is gone.

- It is reported in place, on the surface that owns the queue, not in a
  snackbar. A snackbar is gone in four seconds whether or not anybody read it,
  and this is the last trace of work somebody did.
- It names what was lost in the user's own terms — "the €42.50 dinner",
  "Tuesday's workout" — because the only useful response is entering it again.
- It offers no retry. The server understood the request and said no; a retry
  button would be a lie.
- It is recorded durably. A queue often drains on the resume just before the
  phone goes back in a pocket, so a notice that lived only in memory would be
  the second time that change vanished without anybody being told.
- It stays until the user dismisses it. A stuck queue clears itself when the
  network returns; a lost write never stops being lost.

### Money hierarchy

- The money tab has one focal object: the net position, at display size, above
  a divided rule showing what is out in each direction to scale. There is no
  chart, because there is no series — only two numbers and the ratio between
  them.
- `Add expense` is the single filled action. Group and person chips beneath it
  are shortcuts into the same composer, not a second class of action.
- Balances and bills are rows on a continuous surface. A list of cards turns
  fifteen people into fifteen competing objects.
- The bill composer is amount-first: the number opens focused at display size,
  and everything else on the sheet qualifies it.
- A split is previewed in exact cents while it is being decided, using the same
  allocation the server re-runs on save — down to which person absorbs the odd
  cent. The number read off the screen at the table is the number that is owed.
- A person's screen leads with their balance; settling up opens pre-filled with
  the whole outstanding amount, because settling in full is what a payback
  almost always is.

### Inputs / Fields

- **Style:** raised neutral tone, 6 px corners, 48 px minimum height, persistent
  label when ambiguity is possible.
- **Focus:** purple caret and focus ring; layout does not move when the border
  changes.
- **Error / Disabled:** error copy is explicit and adjacent. Disabled states
  keep readable text and cannot rely on opacity alone.
- **Numeric entry:** amount, time, reps, and weight inputs allow the value to
  dominate while unit and validation remain visually quieter.

### Navigation

- **Compact Android:** five-destination Material navigation bar with predictive
  Back support and edge-to-edge insets. Destinations are Today, Gym, Money,
  People, and Insights.
- **Expanded Android:** navigation rail; never stretch the phone bar across a
  tablet.
- **iOS:** preserve system back swipe and platform-safe tab/sheet behavior.
- **Active state:** purple icon/marker plus label weight; inactive destinations
  are monochrome and readable.
- **Habits:** today's actions remain in a slim strip on Today. The strip opens a
  dedicated planning and history route, avoiding a sixth compact destination.
- **Account entry point:** one avatar target in the top-right header opens
  Settings, which contains profile identity, account actions, preferences, and
  integrations in one surface.

### Sheets and Focused Tasks

Expense entry, gym logging, habit editing, and weekly review use focused sheets
or full-height tasks rather than tiny centered modals. The sheet uses 12–16 px
top corners, a clear title, one obvious completion action, keyboard-safe insets,
and interruption-safe drafts where data entry is substantial.

### Data Identity

A habit, category, person, group, gym location, or life period combines its
identity color with at least one of: name, icon, glyph, avatar, pattern, or fixed
position. Charts expose labels or accessible summaries; a legend of color dots
alone is insufficient.

### Motion Vocabulary

- **Press:** 100–140 ms, transform only.
- **State:** 160–220 ms strong ease-out for selection, completion, and content
  replacement.
- **Spatial:** standard platform navigation, sheets, and occasional shared-object
  transitions.
- **Emphasis:** 240–300 ms for a real completion, record, settlement, or
  milestone; never generic page entry.
- **Reduced motion:** crossfade or immediate state change with no spatial travel.

Use Flutter implicit animations and platform transitions first. Springs are
reserved for interruptible gestures. Rive, Lottie, custom shaders, animated
backgrounds, and a general animation framework are outside the default system.

## 6. Do's and Don'ts

### Do:

- **Do** give each screen one dominant focal object and make the remainder
  support it.
- **Do** use black/white inversion for ordinary primary actions so purple stays
  distinctive.
- **Do** use identity colors for the owner's data and always pair color with a
  label, icon, shape, or position.
- **Do** design and golden-test dark and light themes independently.
- **Do** create hierarchy with scale, alignment, space, tone, and complete
  borders before introducing containers.
- **Do** use responsive motion and haptics to confirm state, then get out of the
  user's way.
- **Do** preserve Android system Back, edge-to-edge insets, text scaling, and
  48 dp touch targets.

### Don't:

- **Don't** make Luqa resemble a corporate SaaS dashboard.
- **Don't** make Luqa resemble a neon cyberpunk console: no purple gradients,
  glowing borders, animated grids, or terminal typography as decoration.
- **Don't** make Luqa resemble a childish gamified habit app: no constant
  confetti, mascot rewards, streak shame, or inflated celebration.
- **Don't** build a collection of excessively rounded cards and pills. Cards
  stop at 12–16 px; pills are reserved for tags and statuses.
- **Don't** copy Trade Republic's financial metaphors or impersonal tone. Copy
  no screen literally; extract confidence, hierarchy, and restraint.
- **Don't** use glassmorphism as a surface language.
- **Don't** use identity color as a substitute for semantic success, warning,
  or error state.
- **Don't** place a colored stripe on one side of a card or pair a complete
  border with a wide decorative shadow.
- **Don't** animate every list or page entrance. Frequent actions must feel
  immediate, not choreographed.
