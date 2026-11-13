import 'package:material_ui/material_ui.dart';

/// Shared Material 3 tokens. Typography follows the device's font and text scale.
abstract final class PacoColors {
  static const forest = Color(0xFF163C32);
  static const lime = Color(0xFFD9EE83);
  static const cream = Color(0xFFF6F7F2);
}

ThemeData buildPacoTheme({Brightness brightness = Brightness.light}) {
  final dark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(
    seedColor: PacoColors.forest,
    brightness: brightness,
    primary: dark ? PacoColors.lime : PacoColors.forest,
    onPrimary: dark ? PacoColors.forest : Colors.white,
    secondary: dark ? const Color(0xFFBBCF91) : const Color(0xFF4D6535),
    secondaryContainer: PacoColors.lime,
    onSecondaryContainer: PacoColors.forest,
    surface: dark ? const Color(0xFF111C17) : PacoColors.cream,
  );
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    brightness: brightness,
    visualDensity: VisualDensity.standard,
    materialTapTargetSize: MaterialTapTargetSize.padded,
  );
  final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(16));
  return base.copyWith(
    scaffoldBackgroundColor: scheme.surface,
    textTheme: base.textTheme.copyWith(
      headlineLarge: base.textTheme.headlineLarge?.copyWith(
        fontSize: 30,
        fontWeight: FontWeight.w700,
        height: 1.2,
        letterSpacing: -0.7,
      ),
      headlineMedium: base.textTheme.headlineMedium?.copyWith(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        height: 1.25,
        letterSpacing: -0.5,
      ),
      titleLarge: base.textTheme.titleLarge?.copyWith(
        fontSize: 21,
        fontWeight: FontWeight.w700,
        height: 1.3,
      ),
      titleMedium: base.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        height: 1.4,
      ),
      bodyLarge: base.textTheme.bodyLarge?.copyWith(height: 1.55),
      bodyMedium: base.textTheme.bodyMedium?.copyWith(height: 1.5),
      labelLarge: base.textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w600,
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 1,
      titleTextStyle: base.textTheme.titleLarge?.copyWith(
        color: scheme.onSurface,
        fontSize: 19,
        fontWeight: FontWeight.w700,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: dark ? scheme.surfaceContainer : Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        shape: shape,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        shape: shape,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: shape,
        side: BorderSide(color: scheme.outline),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: shape,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.all(12),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: dark ? scheme.surfaceContainer : Colors.white,
      indicatorColor: scheme.secondaryContainer,
      surfaceTintColor: Colors.transparent,
      height: 80,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => base.textTheme.labelMedium?.copyWith(
          color: scheme.onSurface,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w500,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? scheme.onSecondaryContainer
              : scheme.onSurfaceVariant,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: dark ? scheme.surfaceContainer : Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.primary, width: 2),
      ),
      errorMaxLines: 3,
    ),
    chipTheme: base.chipTheme.copyWith(
      side: BorderSide.none,
      backgroundColor: scheme.surfaceContainerHighest,
      selectedColor: scheme.secondaryContainer,
      labelStyle: base.textTheme.labelMedium?.copyWith(color: scheme.onSurface),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: scheme.primary,
      linearTrackColor: scheme.secondaryContainer,
      linearMinHeight: 6,
      borderRadius: BorderRadius.circular(8),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: dark ? PacoColors.lime : PacoColors.forest,
      contentTextStyle: base.textTheme.bodyMedium?.copyWith(
        color: dark ? PacoColors.forest : Colors.white,
      ),
      actionTextColor: dark ? PacoColors.forest : PacoColors.lime,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    dividerTheme: DividerThemeData(color: scheme.outlineVariant, thickness: 1),
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
    ),
  );
}
