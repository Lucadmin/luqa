import 'package:flutter/widgets.dart';

/// The one place that turns minutes into pixels. Everything on the grid —
/// panes, blocks, the now-line, the draft — measures itself through this, so a
/// zoom change moves the whole surface together.
@immutable
class TimelineMetrics {
  const TimelineMetrics({this.hourHeight = defaultHourHeight});

  /// Comfortable default: a half-hour block still clears the 32 dp needed for
  /// a legible title, and a waking day fits in roughly two screens.
  static const double defaultHourHeight = 68;
  static const double minHourHeight = 44;
  static const double maxHourHeight = 168;

  /// Width reserved for hour labels down the left edge.
  static const double gutter = 56;

  /// Breathing room between a block and the right edge of the screen.
  static const double trailingInset = 8;

  /// Blocks shorter than this only have room for a title.
  static const double compactBlockHeight = 44;

  /// A five-minute block is a few pixels tall at any sane zoom, so every block
  /// is drawn at least this high. Calendars do the same: a sliver nobody can
  /// read or hit is worse than a slightly generous one.
  static const double minBlockHeight = 26;

  /// The grid has fixed geometry, so block text is capped rather than allowed
  /// to overrun its block. The full text is always in the semantics label and
  /// in the editor, both of which scale without limit.
  static const double maxBlockTextScale = 1.2;

  final double hourHeight;

  double get pxPerMinute => hourHeight / 60;

  double get dayHeight => hourHeight * 24;

  double yForMinutes(num minutes) => minutes * pxPerMinute;

  double minutesForY(double y) => y / pxPerMinute;

  TimelineMetrics scaled(double factor) => TimelineMetrics(
    hourHeight: (hourHeight * factor).clamp(minHourHeight, maxHourHeight),
  );

  @override
  bool operator ==(Object other) =>
      other is TimelineMetrics && other.hourHeight == hourHeight;

  @override
  int get hashCode => hourHeight.hashCode;
}
