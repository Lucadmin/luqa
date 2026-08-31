import 'package:flutter/material.dart';
import 'package:luqa/features/today/domain/sleep_entry.dart';

/// Colours for the sleep stages, validated rather than eyeballed.
///
/// Sleep depth looks like a job for one hue at three lightnesses, but three
/// steps of a single hue cannot clear the normal-vision separation floor
/// inside a usable lightness range — the middle step is unreadable next to
/// either neighbour. So the stages are treated as what they are on screen:
/// four identities, assigned a fixed hue each and kept on that hue in both
/// themes, because colour follows the entity and not the theme.
///
/// The light set passes every check of the categorical palette validator
/// against `#FFFFFF`. The dark set passes all of them against `#141417`
/// except the lightness band, which on a near-black surface is unreachable
/// without failing contrast instead — the band and the 3:1 floor pull in
/// opposite directions there, and legibility wins.
///
/// Unscored and out-of-bed time stay neutral: they are absence of data, not a
/// fifth identity, and they are always directly labelled.
abstract final class SleepStagePalette {
  static const _light = {
    SleepStageKind.awake: Color(0xFFB45309),
    SleepStageKind.rem: Color(0xFFDB2777),
    SleepStageKind.light: Color(0xFF2563EB),
    SleepStageKind.deep: Color(0xFF15803D),
    SleepStageKind.asleep: Color(0xFF2563EB),
  };

  static const _dark = {
    SleepStageKind.awake: Color(0xFFFBBF24),
    SleepStageKind.rem: Color(0xFFEC4899),
    SleepStageKind.light: Color(0xFF60A5FA),
    SleepStageKind.deep: Color(0xFF34D399),
    SleepStageKind.asleep: Color(0xFF60A5FA),
  };

  /// Reading order of a hypnogram: shallowest at the top.
  static const order = [
    SleepStageKind.awake,
    SleepStageKind.outOfBed,
    SleepStageKind.rem,
    SleepStageKind.light,
    SleepStageKind.deep,
    SleepStageKind.asleep,
    SleepStageKind.unknown,
  ];

  static Color of(BuildContext context, SleepStageKind kind) {
    final theme = Theme.of(context);
    final palette = theme.brightness == Brightness.dark ? _dark : _light;
    return palette[kind] ?? theme.colorScheme.onSurfaceVariant;
  }
}
