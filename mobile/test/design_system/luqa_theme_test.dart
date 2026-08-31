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

  test('the money direction tokens stay readable on their own canvas', () {
    // They carry a number the user is reading at a glance, so they are held to
    // the same bar as body text rather than the 3:1 a decorative mark gets.
    expect(
      _contrast(LuqaColors.creditLight, LuqaColors.lightBackground),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      _contrast(LuqaColors.debitLight, LuqaColors.lightBackground),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      _contrast(LuqaColors.creditDark, LuqaColors.darkBackground),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      _contrast(LuqaColors.debitDark, LuqaColors.darkBackground),
      greaterThanOrEqualTo(4.5),
    );
  });

  test('credit and debit are told apart by more than hue', () {
    // A red and a green of equal luminance are the same colour to the most
    // common form of colour blindness. The pair has to separate by lightness
    // too — on top of the words that always accompany the amount.
    expect(
      _contrast(LuqaColors.creditLight, LuqaColors.debitLight),
      greaterThanOrEqualTo(1.4),
    );
    expect(
      _contrast(LuqaColors.creditDark, LuqaColors.debitDark),
      greaterThanOrEqualTo(1.4),
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
