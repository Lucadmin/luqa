import 'package:flutter/material.dart';
import 'package:luqa/design_system/luqa_tokens.dart';

abstract final class LuqaTheme {
  static final light = _build(Brightness.light);
  static final dark = _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final background = isDark
        ? LuqaColors.darkBackground
        : LuqaColors.lightBackground;
    final surface = isDark ? LuqaColors.darkSurface : LuqaColors.lightSurface;
    final raised = isDark ? LuqaColors.darkRaised : LuqaColors.lightRaised;
    final border = isDark ? LuqaColors.darkBorder : LuqaColors.lightBorder;
    final ink = isDark ? LuqaColors.darkInk : LuqaColors.lightInk;
    final muted = isDark ? LuqaColors.darkMuted : LuqaColors.lightMuted;
    final purple = isDark ? LuqaColors.purpleDark : LuqaColors.purpleLight;
    final onPurple = isDark
        ? LuqaColors.purpleOnDark
        : LuqaColors.purpleOnLight;
    final error = isDark ? LuqaColors.errorDark : LuqaColors.errorLight;

    final scheme = ColorScheme(
      brightness: brightness,
      primary: purple,
      onPrimary: onPurple,
      primaryContainer: isDark
          ? const Color(0xFF302160)
          : const Color(0xFFE5DFFF),
      onPrimaryContainer: isDark
          ? const Color(0xFFEEE9FF)
          : const Color(0xFF281064),
      secondary: ink,
      onSecondary: surface,
      secondaryContainer: raised,
      onSecondaryContainer: ink,
      tertiary: isDark ? LuqaColors.tealDark : LuqaColors.tealLight,
      onTertiary: isDark ? const Color(0xFF08201E) : Colors.white,
      error: error,
      onError: isDark ? const Color(0xFF2B0000) : Colors.white,
      surface: surface,
      onSurface: ink,
      onSurfaceVariant: muted,
      outline: border,
      outlineVariant: border.withValues(alpha: 0.65),
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: ink,
      onInverseSurface: surface,
      inversePrimary: isDark ? LuqaColors.purpleLight : LuqaColors.purpleDark,
      surfaceTint: Colors.transparent,
    );

    final baseText = ThemeData(
      brightness: brightness,
      useMaterial3: true,
    ).textTheme.apply(bodyColor: ink, displayColor: ink);

    final textTheme = baseText.copyWith(
      displaySmall: baseText.displaySmall?.copyWith(
        fontSize: 44,
        height: 1,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.2,
      ),
      headlineLarge: baseText.headlineLarge?.copyWith(
        fontSize: 32,
        height: 1.08,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.7,
      ),
      titleLarge: baseText.titleLarge?.copyWith(
        fontSize: 22,
        height: 1.18,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: baseText.bodyLarge?.copyWith(
        fontSize: 16,
        height: 1.45,
        fontWeight: FontWeight.w400,
      ),
      bodyMedium: baseText.bodyMedium?.copyWith(
        fontSize: 14,
        height: 1.4,
        fontWeight: FontWeight.w400,
      ),
      labelLarge: baseText.labelLarge?.copyWith(
        fontSize: 14,
        height: 1.2,
        fontWeight: FontWeight.w600,
      ),
      labelMedium: baseText.labelMedium?.copyWith(
        fontSize: 13,
        height: 1.2,
        fontWeight: FontWeight.w600,
      ),
    );

    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(LuqaRadii.compact),
      borderSide: BorderSide(color: border),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      dividerColor: border,
      textTheme: textTheme,
      visualDensity: VisualDensity.standard,
      extensions: <ThemeExtension<dynamic>>[
        LuqaPalette(
          canvas: background,
          workingSurface: surface,
          raised: raised,
          border: border,
          muted: muted,
          blue: isDark ? LuqaColors.blueDark : LuqaColors.blueLight,
          teal: isDark ? LuqaColors.tealDark : LuqaColors.tealLight,
          green: isDark ? LuqaColors.greenDark : LuqaColors.greenLight,
          amber: isDark ? LuqaColors.amberDark : LuqaColors.amberLight,
          orange: isDark ? LuqaColors.orangeDark : LuqaColors.orangeLight,
          pink: isDark ? LuqaColors.pinkDark : LuqaColors.pinkLight,
          credit: isDark ? LuqaColors.creditDark : LuqaColors.creditLight,
          debit: isDark ? LuqaColors.debitDark : LuqaColors.debitLight,
        ),
      ],
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: textTheme.titleLarge,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 76,
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        indicatorColor: purple.withValues(alpha: isDark ? 0.18 : 0.12),
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LuqaRadii.control),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected) ? purple : muted,
            size: 24,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => textTheme.labelMedium?.copyWith(
            color: states.contains(WidgetState.selected) ? purple : muted,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
          ),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: background,
        indicatorColor: purple.withValues(alpha: isDark ? 0.18 : 0.12),
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LuqaRadii.control),
        ),
        selectedIconTheme: IconThemeData(color: purple),
        unselectedIconTheme: IconThemeData(color: muted),
        selectedLabelTextStyle: textTheme.labelMedium?.copyWith(color: purple),
        unselectedLabelTextStyle: textTheme.labelMedium?.copyWith(color: muted),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 48),
          backgroundColor: ink,
          foregroundColor: surface,
          disabledBackgroundColor: muted.withValues(alpha: 0.22),
          disabledForegroundColor: muted,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(LuqaRadii.control),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          foregroundColor: ink,
          side: BorderSide(color: border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(LuqaRadii.control),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(48, 48),
          foregroundColor: ink,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(LuqaRadii.control),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: raised,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        labelStyle: TextStyle(color: muted),
        hintStyle: TextStyle(color: muted),
        border: inputBorder,
        enabledBorder: inputBorder,
        focusedBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: purple, width: 2),
        ),
        errorBorder: inputBorder.copyWith(borderSide: BorderSide(color: error)),
        focusedErrorBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: error, width: 2),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: surface,
        modalElevation: 8,
        showDragHandle: true,
        dragHandleColor: muted.withValues(alpha: 0.7),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(LuqaRadii.sheet),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: ink,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: surface),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LuqaRadii.control),
        ),
      ),
      dividerTheme: DividerThemeData(color: border, thickness: 1, space: 1),
      cardTheme: CardThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LuqaRadii.surface),
          side: BorderSide(color: border),
        ),
      ),
    );
  }
}
