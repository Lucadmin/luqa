import 'package:flutter/material.dart';

abstract final class LuqaColors {
  static const lightBackground = Color(0xFFFBFBFA);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightRaised = Color(0xFFF4F4F5);
  static const lightBorder = Color(0xFFD6D6DA);
  static const lightInk = Color(0xFF1A1A1E);
  static const lightMuted = Color(0xFF5F5F68);

  static const darkBackground = Color(0xFF0B0B0D);
  static const darkSurface = Color(0xFF141417);
  static const darkRaised = Color(0xFF1C1C20);
  static const darkBorder = Color(0xFF34343A);
  static const darkInk = Color(0xFFF4F4F5);
  static const darkMuted = Color(0xFFA8A8B0);

  static const purpleLight = Color(0xFF6543E8);
  static const purpleDark = Color(0xFFA78BFA);
  static const purpleOnLight = Color(0xFFFFFFFF);
  static const purpleOnDark = Color(0xFF100C19);

  static const blueLight = Color(0xFF2563EB);
  static const blueDark = Color(0xFF60A5FA);
  static const tealLight = Color(0xFF0F766E);
  static const tealDark = Color(0xFF5EEAD4);
  static const greenLight = Color(0xFF15803D);
  static const greenDark = Color(0xFF4ADE80);
  static const amberLight = Color(0xFFB45309);
  static const amberDark = Color(0xFFFBBF24);
  static const orangeLight = Color(0xFFC2410C);
  static const orangeDark = Color(0xFFFB923C);
  static const pinkLight = Color(0xFFBE185D);
  static const pinkDark = Color(0xFFF472B6);

  static const errorLight = Color(0xFFB42318);
  static const errorDark = Color(0xFFFF8A80);
}

abstract final class LuqaSpacing {
  static const xxs = 2.0;
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
  static const section = 40.0;
}

abstract final class LuqaRadii {
  static const compact = 6.0;
  static const control = 8.0;
  static const surface = 12.0;
  static const sheet = 16.0;
}

abstract final class LuqaMotion {
  static const press = Duration(milliseconds: 120);
  static const state = Duration(milliseconds: 200);
  static const emphasis = Duration(milliseconds: 280);
  static const curve = Curves.easeOutQuart;
}

@immutable
class LuqaPalette extends ThemeExtension<LuqaPalette> {
  const LuqaPalette({
    required this.canvas,
    required this.workingSurface,
    required this.raised,
    required this.border,
    required this.muted,
    required this.blue,
    required this.teal,
    required this.green,
    required this.amber,
    required this.orange,
    required this.pink,
  });

  final Color canvas;
  final Color workingSurface;
  final Color raised;
  final Color border;
  final Color muted;
  final Color blue;
  final Color teal;
  final Color green;
  final Color amber;
  final Color orange;
  final Color pink;

  static LuqaPalette of(BuildContext context) =>
      Theme.of(context).extension<LuqaPalette>()!;

  @override
  LuqaPalette copyWith({
    Color? canvas,
    Color? workingSurface,
    Color? raised,
    Color? border,
    Color? muted,
    Color? blue,
    Color? teal,
    Color? green,
    Color? amber,
    Color? orange,
    Color? pink,
  }) {
    return LuqaPalette(
      canvas: canvas ?? this.canvas,
      workingSurface: workingSurface ?? this.workingSurface,
      raised: raised ?? this.raised,
      border: border ?? this.border,
      muted: muted ?? this.muted,
      blue: blue ?? this.blue,
      teal: teal ?? this.teal,
      green: green ?? this.green,
      amber: amber ?? this.amber,
      orange: orange ?? this.orange,
      pink: pink ?? this.pink,
    );
  }

  @override
  LuqaPalette lerp(covariant LuqaPalette? other, double t) {
    if (other == null) return this;
    return LuqaPalette(
      canvas: Color.lerp(canvas, other.canvas, t)!,
      workingSurface: Color.lerp(workingSurface, other.workingSurface, t)!,
      raised: Color.lerp(raised, other.raised, t)!,
      border: Color.lerp(border, other.border, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      blue: Color.lerp(blue, other.blue, t)!,
      teal: Color.lerp(teal, other.teal, t)!,
      green: Color.lerp(green, other.green, t)!,
      amber: Color.lerp(amber, other.amber, t)!,
      orange: Color.lerp(orange, other.orange, t)!,
      pink: Color.lerp(pink, other.pink, t)!,
    );
  }
}
