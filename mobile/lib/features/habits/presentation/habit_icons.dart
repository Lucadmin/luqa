import 'package:flutter/material.dart';

/// The habit icon set, under the same names the browser uses.
///
/// The web stores a Lucide icon name on the habit; this maps each of those to
/// its closest Material equivalent so a habit made on a laptop arrives on the
/// phone wearing the mark it was given, rather than falling back to a dot.
/// The names are the contract — not the glyphs — so either side can restyle
/// without the other having to agree.
const Map<String, IconData> habitIcons = <String, IconData>{
  'dumbbell': Icons.fitness_center_rounded,
  'bookOpen': Icons.menu_book_rounded,
  'droplet': Icons.water_drop_rounded,
  'pill': Icons.medication_rounded,
  'brain': Icons.psychology_rounded,
  'heart': Icons.favorite_rounded,
  'bed': Icons.bed_rounded,
  'footprints': Icons.directions_walk_rounded,
  'apple': Icons.local_dining_rounded,
  'coffee': Icons.coffee_rounded,
  'code': Icons.code_rounded,
  'music': Icons.music_note_rounded,
  'pencil': Icons.edit_rounded,
  'briefcase': Icons.work_rounded,
  'sparkles': Icons.auto_awesome_rounded,
  'sun': Icons.wb_sunny_rounded,
  'moon': Icons.nightlight_round,
  'leaf': Icons.eco_rounded,
  'bike': Icons.directions_bike_rounded,
  'noSmoking': Icons.smoke_free_rounded,
  'piggyBank': Icons.savings_rounded,
  'camera': Icons.photo_camera_rounded,
  'paintbrush': Icons.brush_rounded,
  'languages': Icons.translate_rounded,
  'graduation': Icons.school_rounded,
  'carrot': Icons.local_florist_rounded,
  'salad': Icons.rice_bowl_rounded,
  'bath': Icons.bathtub_rounded,
  'flower': Icons.local_florist_rounded,
  'mountain': Icons.terrain_rounded,
  'waves': Icons.pool_rounded,
  'wind': Icons.air_rounded,
  'sprout': Icons.grass_rounded,
  'target': Icons.adjust_rounded,
  'flame': Icons.local_fire_department_rounded,
  'trophy': Icons.emoji_events_rounded,
  'star': Icons.star_rounded,
  'smile': Icons.sentiment_satisfied_rounded,
  'glasses': Icons.visibility_rounded,
  'guitar': Icons.queue_music_rounded,
  'timer': Icons.timer_rounded,
};

/// The order the picker offers them in.
final List<String> habitIconNames = habitIcons.keys.toList(growable: false);

const String defaultHabitIcon = 'target';

/// The glyph for a stored name, falling back rather than failing: a habit made
/// by a newer build that knows an icon this one does not still has to draw.
IconData habitIconFor(String? name) =>
    habitIcons[name] ?? habitIcons[defaultHabitIcon]!;

/// The accent colours a habit can be given, shared with the browser's picker
/// so the same habit is the same colour in both places.
const List<int> habitColorValues = <int>[
  0xFFF5C451,
  0xFF6366F1,
  0xFFEC4899,
  0xFF10B981,
  0xFF3B82F6,
  0xFF8B5CF6,
  0xFFEF4444,
  0xFF14B8A6,
  0xFFF97316,
  0xFF06B6D4,
  0xFF84CC16,
  0xFFA855F7,
];

const int defaultHabitColorValue = 0xFFF5C451;
