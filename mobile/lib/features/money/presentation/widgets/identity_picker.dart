import 'package:flutter/material.dart';
import 'package:luqa/design_system/luqa_tokens.dart';

/// The identity spectrum, as the user picks from it.
///
/// The same six hues the rest of Luqa uses for categories, habits and gyms —
/// people are one more kind of thing in a life, not a separate palette. Colour
/// is never the only mark, so a glyph sits beside it.
const identitySpectrum = <int>[
  0xFF2563EB,
  0xFF0F766E,
  0xFF15803D,
  0xFFB45309,
  0xFFC2410C,
  0xFFBE185D,
  0xFF6543E8,
];

class IdentityColorPicker extends StatelessWidget {
  const IdentityColorPicker({
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: LuqaSpacing.sm,
      runSpacing: LuqaSpacing.sm,
      children: [
        for (final value in identitySpectrum)
          _Swatch(
            colorValue: value,
            selected: value == selected,
            onTap: () => onChanged(value),
          ),
      ],
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.colorValue,
    required this.selected,
    required this.onTap,
  });

  final int colorValue;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = Color(colorValue);
    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(LuqaRadii.compact),
        // A 48dp target around a 28dp mark: the swatch is small because a row
        // of them has to be scannable, the target is not.
        child: SizedBox(
          width: 48,
          height: 48,
          child: Center(
            child: AnimatedContainer(
              duration: LuqaMotion.state,
              curve: LuqaMotion.curve,
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(LuqaRadii.compact),
                border: Border.all(
                  color: selected
                      ? Theme.of(context).colorScheme.onSurface
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}

/// A short, deliberately opinionated set. A full emoji keyboard here would be
/// a decision to make rather than a mark to pick.
const _glyphs = <String>[
  '🧡', '🏠', '✈️', '🍕', '🎉', '🐈', '🎮', '☕️', '🚗', '🎓',
];

class IdentityEmojiPicker extends StatelessWidget {
  const IdentityEmojiPicker({
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final String? selected;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: LuqaSpacing.sm,
      runSpacing: LuqaSpacing.sm,
      children: [
        _GlyphOption(
          label: 'None',
          selected: selected == null,
          onTap: () => onChanged(null),
        ),
        for (final glyph in _glyphs)
          _GlyphOption(
            glyph: glyph,
            selected: selected == glyph,
            onTap: () => onChanged(glyph),
          ),
      ],
    );
  }
}

class _GlyphOption extends StatelessWidget {
  const _GlyphOption({
    this.glyph,
    this.label,
    required this.selected,
    required this.onTap,
  });

  final String? glyph;
  final String? label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(LuqaRadii.compact),
        child: Container(
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          padding: const EdgeInsets.symmetric(
            horizontal: LuqaSpacing.sm,
            vertical: LuqaSpacing.sm,
          ),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? LuqaPalette.of(context).raised : null,
            borderRadius: BorderRadius.circular(LuqaRadii.compact),
            border: Border.all(
              color: selected
                  ? theme.colorScheme.onSurface
                  : LuqaPalette.of(context).border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: glyph != null
              ? Text(glyph!, style: const TextStyle(fontSize: 20))
              : Text(label!, style: theme.textTheme.labelLarge),
        ),
      ),
    );
  }
}
