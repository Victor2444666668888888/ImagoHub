import 'package:flutter/material.dart';

class ImagoColors {
  static const ink = Color(0xFF14151B);
  static const muted = Color(0xFF747782);
  static const rail = Color(0xFF131417);
  static const line = Color(0xFFE8E9EF);
  static const surface = Color(0xFFF7F8FB);
  static const brand = Color(0xFF6257ED);
  static const soft = Color(0xFFEFEDFF);
  static const star = Color(0xFFF6C85D);
}

ThemeData imagoTheme(bool dark) {
  final ink = dark ? const Color(0xFFF3F3FA) : ImagoColors.ink;
  final surface = dark ? const Color(0xFF17181F) : Colors.white;
  final line = dark ? const Color(0xFF363744) : ImagoColors.line;
  final scheme =
      ColorScheme.fromSeed(
        seedColor: ImagoColors.brand,
        brightness: dark ? Brightness.dark : Brightness.light,
      ).copyWith(
        primary: ImagoColors.brand,
        surface: surface,
        onSurface: ink,
        outline: line,
      );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: surface,
    fontFamily: 'Inter',
    dividerColor: line,
    splashFactory: InkRipple.splashFactory,
    textTheme: TextTheme(
      bodyMedium: TextStyle(fontSize: 14, color: ink, height: 1.45),
      bodySmall: const TextStyle(
        fontSize: 12,
        color: ImagoColors.muted,
        height: 1.45,
      ),
      titleLarge: TextStyle(
        fontSize: 26,
        height: 1.2,
        fontWeight: FontWeight.w700,
        color: ink,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      hintStyle: const TextStyle(fontSize: 14, color: ImagoColors.muted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: ImagoColors.brand, width: 1.5),
      ),
      errorMaxLines: 2,
      isDense: true,
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: ImagoColors.brand,
        textStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? ImagoColors.brand
            : Colors.transparent,
      ),
      side: BorderSide(color: line),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: const WidgetStatePropertyAll(Colors.white),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? ImagoColors.brand : line,
      ),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}

Color panelColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
    ? const Color(0xFF24252F)
    : ImagoColors.surface;
Color softColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
    ? const Color(0xFF302B50)
    : ImagoColors.soft;
