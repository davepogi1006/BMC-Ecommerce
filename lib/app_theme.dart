import 'package:flutter/material.dart';

class AppTheme {
  static const Color lightAccent = Color(0xFF006B5B);
  static const Color darkAccent = Color(0xFF4EDCC6);
  static const Color accent = lightAccent;
  static const Color darkPrice = darkAccent;
  static const Color _neutralSeed = Color(0xFF777777);
  static const Color ink = Color(0xFF09090B);
  static const Color lightCanvas = Color(0xFFF7F7F4);

  static ThemeData get light => _buildTheme(Brightness.light);
  static ThemeData get dark => _buildTheme(Brightness.dark);

  static Color accentColor(Brightness brightness) =>
      brightness == Brightness.dark ? darkAccent : lightAccent;

  static Color onAccentColor(Brightness brightness) =>
      brightness == Brightness.dark ? ink : Colors.white;

  static Color priceColor(Brightness brightness) => accentColor(brightness);

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final accent = accentColor(brightness);
    final onAccent = onAccentColor(brightness);
    final neutral = isDark ? const Color(0xFFB8B8BC) : const Color(0xFF45454A);
    final onSurface =
        isDark ? const Color(0xFFF2F2EF) : const Color(0xFF171719);
    final scheme = ColorScheme.fromSeed(
      seedColor: _neutralSeed,
      brightness: brightness,
      surface: isDark ? ink : lightCanvas,
    ).copyWith(
      primary: accent,
      onPrimary: onAccent,
      secondary: neutral,
      onSecondary: isDark ? ink : Colors.white,
      tertiary: neutral,
      onTertiary: isDark ? ink : Colors.white,
      primaryFixed: const Color(0xFFE6E6E6),
      primaryFixedDim: const Color(0xFFD6D6D6),
      onPrimaryFixed: const Color(0xFF171717),
      onPrimaryFixedVariant: const Color(0xFF454545),
      secondaryFixed: const Color(0xFFE6E6E6),
      secondaryFixedDim: const Color(0xFFD6D6D6),
      onSecondaryFixed: const Color(0xFF171717),
      onSecondaryFixedVariant: const Color(0xFF454545),
      tertiaryFixed: const Color(0xFFE6E6E6),
      tertiaryFixedDim: const Color(0xFFD6D6D6),
      onTertiaryFixed: const Color(0xFF171717),
      onTertiaryFixedVariant: const Color(0xFF454545),
      inversePrimary: neutral,
      surfaceTint: neutral,
      error: isDark ? const Color(0xFFE0E0E0) : const Color(0xFF39393D),
      onError: isDark ? ink : Colors.white,
      surface: isDark ? ink : lightCanvas,
      onSurface: onSurface,
      surfaceDim: isDark ? ink : const Color(0xFFE3E3DF),
      surfaceBright: isDark ? const Color(0xFF252529) : Colors.white,
      onSurfaceVariant:
          isDark ? const Color(0xFFB3B3B7) : const Color(0xFF55555A),
      outline: isDark ? const Color(0xFF505055) : const Color(0xFF77777B),
      outlineVariant:
          isDark ? const Color(0xFF262626) : const Color(0xFFD4D4D0),
      surfaceContainerLowest: isDark ? const Color(0xFF0D0D0F) : Colors.white,
      surfaceContainerLow:
          isDark ? const Color(0xFF121214) : const Color(0xFFF0F0EC),
      surfaceContainer:
          isDark ? const Color(0xFF171719) : const Color(0xFFEAEAE6),
      surfaceContainerHigh:
          isDark ? const Color(0xFF1D1D20) : const Color(0xFFE3E3DF),
      surfaceContainerHighest:
          isDark ? const Color(0xFF252529) : const Color(0xFFDADAD6),
      primaryContainer:
          isDark ? const Color(0xFF242426) : const Color(0xFFE7E7E3),
      onPrimaryContainer: onSurface,
      secondaryContainer:
          isDark ? const Color(0xFF242426) : const Color(0xFFE7E7E3),
      onSecondaryContainer: onSurface,
      tertiaryContainer:
          isDark ? const Color(0xFF242426) : const Color(0xFFE7E7E3),
      onTertiaryContainer: onSurface,
      errorContainer:
          isDark ? const Color(0xFF262628) : const Color(0xFFE8E8E4),
      onErrorContainer: onSurface,
      inverseSurface: isDark ? lightCanvas : ink,
      onInverseSurface: isDark ? ink : Colors.white,
      shadow: Colors.black,
      scrim: Colors.black,
    );
    final borderRadius = BorderRadius.circular(2);
    final textTheme = ThemeData(brightness: brightness).textTheme.apply(
          bodyColor: scheme.onSurface,
          displayColor: scheme.onSurface,
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      visualDensity: VisualDensity.standard,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
        ),
        shape: Border(
          bottom: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: borderRadius,
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLow,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        labelStyle: TextStyle(color: scheme.onSurfaceVariant),
        hintStyle: TextStyle(color: scheme.onSurfaceVariant),
        border: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide(color: scheme.onSurface, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide(color: scheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide(color: scheme.error, width: 2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          backgroundColor: accent,
          foregroundColor: onAccent,
          disabledBackgroundColor:
              isDark ? const Color(0xFF303034) : const Color(0xFFDADAD6),
          disabledForegroundColor: scheme.onSurfaceVariant,
          shape: RoundedRectangleBorder(borderRadius: borderRadius),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: 0.1,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          foregroundColor: scheme.onSurface,
          side: BorderSide(color: scheme.outline),
          shape: RoundedRectangleBorder(borderRadius: borderRadius),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          foregroundColor: scheme.onSurface,
          shape: RoundedRectangleBorder(borderRadius: borderRadius),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(borderRadius: borderRadius),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        backgroundColor: scheme.surface,
        indicatorColor: accent,
        surfaceTintColor: Colors.transparent,
        iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
              color: states.contains(WidgetState.selected)
                  ? onAccent
                  : scheme.onSurfaceVariant,
            )),
        labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
              color: states.contains(WidgetState.selected)
                  ? onAccent
                  : scheme.onSurfaceVariant,
              fontSize: 11,
              fontWeight: states.contains(WidgetState.selected)
                  ? FontWeight.w800
                  : FontWeight.w500,
            )),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: accent,
        selectedIconTheme: IconThemeData(color: onAccent),
        unselectedIconTheme: IconThemeData(color: scheme.onSurfaceVariant),
        selectedLabelTextStyle: TextStyle(
          color: onAccent,
          fontWeight: FontWeight.w800,
        ),
        unselectedLabelTextStyle: TextStyle(color: scheme.onSurfaceVariant),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        selectedColor: accent,
        secondarySelectedColor: accent,
        disabledColor: scheme.surfaceContainer,
        labelStyle: TextStyle(color: scheme.onSurface),
        secondaryLabelStyle: TextStyle(color: onAccent),
        side: BorderSide(color: scheme.outlineVariant),
        shape: RoundedRectangleBorder(borderRadius: borderRadius),
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor:
            isDark ? const Color(0xFF262628) : const Color(0xFF222224),
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: borderRadius),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: borderRadius,
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      textTheme: textTheme.copyWith(
        displayLarge: textTheme.displayLarge?.copyWith(
          fontWeight: FontWeight.w900,
          letterSpacing: -2.2,
          height: 0.98,
        ),
        displayMedium: textTheme.displayMedium?.copyWith(
          fontWeight: FontWeight.w900,
          letterSpacing: -1.6,
        ),
        headlineLarge: textTheme.headlineLarge?.copyWith(
          fontWeight: FontWeight.w900,
          letterSpacing: -1.1,
          height: 1.05,
        ),
        headlineMedium: textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -0.8,
        ),
        headlineSmall: textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
          height: 1.1,
        ),
        titleLarge: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        labelSmall: textTheme.labelSmall?.copyWith(
          fontFamily: 'monospace',
          letterSpacing: 0.4,
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.onSurfaceVariant,
        linearTrackColor: scheme.surfaceContainerHigh,
        circularTrackColor: scheme.surfaceContainerHigh,
      ),
      focusColor: isDark
          ? Colors.white.withValues(alpha: 0.08)
          : Colors.black.withValues(alpha: 0.06),
      splashFactory: InkSparkle.splashFactory,
    );
  }
}
