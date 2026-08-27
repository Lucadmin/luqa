# Luqa Flutter design directions

Status: Bold Personal Instrument selected
Date: 2026-08-27

## Confirmed brief

Luqa should feel bold, modern, precise, technical, and personal. Its foundation
is near-black and near-white with purple as the brand accent. Geometry should
be crisp and visibly structured rather than soft, bubbly, or pill-heavy. Color
is still necessary to identify habits, categories, life periods, charts, and
other user-defined data. Motion should make the app feel responsive and alive
without creating a large implementation or maintenance burden.

Android is the primary platform. The same Luqa identity ships on iOS, while
standard platform behavior is adapted where Flutter makes that inexpensive:
back navigation, sheets, pickers, safe areas, haptics, and reduced motion.

Dark and light modes are equal design targets.

## Reference translation — Trade Republic with a personal touch

Trade Republic is a reference for the following qualities:

- Decisive typographic hierarchy with one unmistakable focal point per screen.
- Stark black/white contrast and visually quiet chrome.
- Large values and titles that are allowed to occupy real space.
- Dense information presented through alignment and rhythm rather than card
  grids.
- Direct, full-width actions with little ambiguity about what happens next.
- Confidence created by removing decoration, not by adding enterprise polish.

Luqa should not copy its financial character. The personal translation is:

- The focal point changes with the task: the active timer, today's rhythm, the
  current gym exercise, an amount being split, or a selected life week.
- The owner's habit, category, person, and period colors make the data feel
  lived-in rather than institutional.
- Human microcopy and remembered context replace financial seriousness.
- Meaningful completions can briefly become expressive; the resting interface
  stays composed.
- Corners remain crisp and slightly tighter than the soft banking-app norm.

Boldness comes from scale, proportion, contrast, and editing. It does not come
from gradients, glow, neon purple, oversized shadows, or making every element
loud.

## The shared color strategy

All three directions use the same separation of responsibilities:

1. **Neutral shell:** backgrounds, surfaces, navigation, typography, dividers,
   and most controls remain monochrome.
2. **Luqa purple:** focus, selection, active navigation, and branded moments.
   The default primary action may use maximum-contrast ink—black in light mode,
   white in dark mode—so purple can remain distinctive rather than coating every
   button. Purple is not decorative wallpaper.
3. **Identity colors:** habits, categories, people, groups, gym locations, and
   life periods own selectable colors. These appear as a glyph, marker, progress
   fill, chart series, or low-opacity tint—not full-saturation cards by default.
4. **Semantic colors:** error, warning, success, syncing, and offline states use
   their own roles and never borrow an identity color without another signal.

This means a green habit remains green without making every successful action
green, and a red category does not look like an error.

### Provisional neutral and brand foundation

| Role | Light | Dark |
| --- | --- | --- |
| Background | `#F7F7F6` | `#09090B` |
| Surface | `#FFFFFF` | `#111114` |
| Raised surface | `#EFEFF1` | `#19191E` |
| Border | `#D9D9DE` | `#292930` |
| Primary text | `#151518` | `#F7F7F5` |
| Secondary text | `#5F5F68` | `#A8A8B0` |
| Luqa purple | `#6543E8` | `#A78BFA` |
| On purple | `#FFFFFF` | `#100C19` |

These are direction-setting values, not final tokens. The selected direction
will receive complete contrast validation and tonal ramps.

## Direction A — Precision Grid

The most restrained and technical option.

### Visual character

- Flat near-black/near-white surfaces separated by precise one-pixel rules.
- Small corner radii: 4 dp for compact controls, 6–8 dp for fields and rows,
  10–12 dp only for sheets and large containers.
- Strong alignment to an 8 dp grid, with occasional 4 dp adjustments.
- A single sans-serif family; tabular or monospaced numerals for time, money,
  weights, and reports.
- Identity color appears mainly as dots, slim progress fills, small glyph
  backgrounds, and chart lines.
- Large areas remain visually continuous instead of becoming stacks of cards.

### Example surfaces

- A habit row is a monochrome row with a colored glyph, name, target, and a
  square progress control. Completion fills the control and briefly expands the
  color into the glyph—not the whole row.
- A timeline category is a crisp colored block with high-contrast text and
  precise start/end labels.
- The Money overview uses typography and alignment for hierarchy; balance color
  is reserved for direction and accompanied by explicit wording.

### Motion

Fast and functional: 120–180 ms press/selection feedback, 180–220 ms
fade-through for state replacement, platform sheet transitions, and almost no
decorative motion.

### Implementation

Lowest complexity. Mostly standard Material components, theme roles, dividers,
and Flutter implicit animations.

### Risk

Without excellent copy and a few personal details, it could feel clinical or
like a developer tool.

## Direction B — Bold Personal Instrument

The selected direction: Trade Republic-like confidence and hierarchy combined
with technical structure, personal data color, and carefully placed warmth.

### Visual character

- The same monochrome foundation as Precision Grid, but with slightly more
  generous spacing and 6–12 dp corner radii.
- Crisp rectangles and bottom sheets rather than rounded floating-card stacks.
- Maximum-contrast ink anchors primary actions. Purple anchors focus, active
  navigation, selection, and Luqa-specific moments. User-defined colors can
  create restrained 8–16% tints behind selected or expanded data.
- Each screen gets one dominant element; supporting content is deliberately
  quieter rather than uniformly medium-sized.
- Data-heavy values use tabular numerals; ordinary language stays in the main
  sans family.
- Playfulness comes from responsive state changes, icons, personal microcopy,
  haptics, and occasional geometric details—not mascots or confetti.
- High-value personal moments may temporarily let one data color occupy more
  space: a completed habit, a personal record, a life milestone, or a settled
  balance.

### Example surfaces

- A habit begins as a clean row. Pressing its control gives immediate haptic and
  scale feedback, then the colored progress shape resolves into its new state.
  The label and count never jump.
- A gym session is one continuous working surface. Each exercise is separated
  by rhythm and rules rather than nested cards; the current exercise receives a
  subtle location/exercise tint.
- An expense flow begins with a large amount field on a quiet surface. Selected
  people become compact colored identity tiles; purple remains reserved for
  Save and focus.
- The Life wall is primarily neutral at overview scale. Personal periods and
  milestones reveal color as the user zooms or focuses a year.

### Motion

Responsive rather than theatrical:

- Press feedback: 100–140 ms, scale to roughly 0.98, optional light haptic.
- Selection and completion: 160–220 ms ease-out or a tightly damped spring.
- Content replacement: 180–220 ms fade-through with at most 4–8 dp movement.
- Sheets and navigation: standard platform-aware transitions.
- Rare delight moments: 240–300 ms and tied to an actual achievement or
  resolution.
- Reduced motion: crossfade or immediate state change; no spatial travel.

### Implementation

Low-to-medium complexity. The system can be built with standard Material 3
components, theme extensions, `AnimatedContainer`, `AnimatedSwitcher`, `Hero`
for a few spatial transitions, and platform haptics. It does not require Rive,
Lottie, custom shaders, or a general animation framework.

### Risk

The color restraint must be enforced through tokens. If individual screens use
arbitrary tints, it will drift toward a generic colorful tracker.

## Direction C — Module Spectrum

The most expressive and playful option.

### Visual character

- The app shell stays monochrome, but each major domain receives a secondary
  atmosphere: Today violet, Habits lime or amber, Gym orange, Money cyan, and
  Life magenta or blue.
- Module colors can tint headers, charts, empty states, and transitions.
- Corners stay crisp, but layouts can shift slightly between domains to reflect
  their task.
- More illustrations, celebratory states, and color-led wayfinding.

### Example surfaces

- Entering Gym subtly changes the top surface and active-navigation treatment
  to its module color.
- Reports inherit the color of the data currently being inspected.
- Life becomes the most expressive space, with periods and milestones allowed
  to create larger compositions.

### Motion

More container transformations, color transitions, and one-off achievement
moments. Still under 300 ms for ordinary interactions.

### Implementation

Medium complexity. Every component needs both global and module-aware color
roles across light/dark themes, plus more golden-test coverage. The logic is not
difficult, but maintaining visual coherence takes more work.

### Risk

It can fragment Luqa into several small apps and compete with user-defined habit
and category colors.

## Selected direction

Use **Bold Personal Instrument**, with Trade Republic's decisive hierarchy and
Precision Grid's color discipline.

It matches the desired tension:

- Technical, because geometry, typography, and alignment are precise.
- Bold, because one focal point clearly dominates each screen.
- Modern, because the supporting hierarchy is quiet and interaction states are
  polished.
- Personal, because the owner's colors and history are allowed to surface.
- Playful, because meaningful actions respond with motion and haptics.
- Practical, because nearly all of it maps to standard Flutter theming,
  components, and implicit animations.

The core rule is:

> The shell belongs to Luqa; the colors belong to Luca's life.

## Proposed component geometry

- 4 dp: tiny indicators and compact internal shapes.
- 6 dp: text fields, segmented controls, compact buttons.
- 8 dp: ordinary buttons, list selections, habit controls.
- 12 dp: sheets, dialogs, larger focused surfaces.
- Full circle: avatars, icon controls when a circle is semantically natural,
  and progress rings.
- Full pill: only chips, tags, and binary/status capsules—not every button.

## Motion implementation boundary

Use ordinary Flutter primitives first:

- Implicit animations for color, border, opacity, position, and small scale
  changes.
- `AnimatedSwitcher` for state replacement.
- Platform navigation and bottom-sheet transitions.
- `Hero` only where one object genuinely moves between two views.
- Haptics for selection, completion, destructive confirmation, and meaningful
  milestones.

Avoid continuous ambient animation, staggered page-load choreography, large
bounces, animated backgrounds, custom shaders, and animation assets that must
be maintained separately from the components.

## Next design artifact

Once a direction is selected, convert it into `DESIGN.md` with final semantic
tokens, light/dark tonal ramps, typography roles, spacing, shapes, elevation,
motion curves, component states, chart/data-color rules, and accessibility
requirements. Then build the Flutter component gallery and the four key screen
prototypes.
