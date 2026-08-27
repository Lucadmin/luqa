import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luqa/design_system/luqa_theme.dart';
import 'package:luqa/design_system/luqa_tokens.dart';

void main() {
  test('core text pairs retain WCAG AA contrast', () {
    expect(
      _contrast(LuqaColors.lightInk, LuqaColors.lightBackground),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      _contrast(LuqaColors.lightMuted, LuqaColors.lightBackground),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      _contrast(LuqaColors.darkInk, LuqaColors.darkBackground),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      _contrast(LuqaColors.darkMuted, LuqaColors.darkBackground),
      greaterThanOrEqualTo(4.5),
    );
  });

  test('light and dark themes are Material 3 and preserve Luqa purple', () {
    expect(LuqaTheme.light.useMaterial3, isTrue);
    expect(LuqaTheme.dark.useMaterial3, isTrue);
    expect(LuqaTheme.light.colorScheme.primary, LuqaColors.purpleLight);
    expect(LuqaTheme.dark.colorScheme.primary, LuqaColors.purpleDark);
  });
}

double _contrast(Color foreground, Color background) {
  final lighter = foreground.computeLuminance() > background.computeLuminance()
      ? foreground
      : background;
  final darker = identical(lighter, foreground) ? background : foreground;
  return (lighter.computeLuminance() + 0.05) /
      (darker.computeLuminance() + 0.05);
}
