import 'package:flutter/material.dart';
import 'package:luqa/design_system/luqa_tokens.dart';

/// A person or a group, as a mark.
///
/// Identity colour is never the only signal: the avatar always carries the
/// glyph the user picked or the initials of the name, so the row is readable
/// to someone who cannot tell the colours apart.
class PersonAvatar extends StatelessWidget {
  const PersonAvatar({
    required this.name,
    required this.colorValue,
    this.emoji,
    this.size = 40,
    this.dimmed = false,
    super.key,
  });

  final String name;
  final int colorValue;
  final String? emoji;
  final double size;

  /// Archived people keep their identity but stop competing for attention.
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final color = Color(colorValue);
    final glyph = emoji?.trim();
    final scale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.6);
    final box = size * scale;

    return Container(
      width: box,
      height: box,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        // The tint ceiling: identity colour holds a surface at low opacity,
        // and reaches full strength only in the mark itself.
        color: color.withValues(alpha: dimmed ? 0.10 : 0.16),
        borderRadius: BorderRadius.circular(LuqaRadii.compact),
        border: Border.all(color: color.withValues(alpha: dimmed ? 0.2 : 0.4)),
      ),
      child: glyph != null && glyph.isNotEmpty
          ? Text(glyph, style: TextStyle(fontSize: box * 0.44))
          : Text(
              initialsOf(name),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: _readable(context, color),
                fontSize: box * 0.36,
                height: 1,
              ),
            ),
    );
  }

  /// Nudges an identity colour until it is readable on the tinted square it
  /// sits in — a user-chosen colour cannot be trusted to have contrast.
  Color _readable(BuildContext context, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness(isDark ? hsl.lightness.clamp(0.62, 1.0) : hsl.lightness.clamp(0.0, 0.42))
        .toColor();
  }
}

/// One letter for a single name, two for a full one.
String initialsOf(String name) {
  final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
  if (words.isEmpty) return '?';
  if (words.length == 1) return words.first.characters.first.toUpperCase();
  return (words.first.characters.first + words.last.characters.first)
      .toUpperCase();
}
