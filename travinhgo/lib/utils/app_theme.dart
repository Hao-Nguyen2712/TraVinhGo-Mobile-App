import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF158247),
      brightness: Brightness.light,
      secondary: Colors.amber,
    ).copyWith(
      primary: const Color(0xFF158247),
    ),
    fontFamily: 'Montserrat',
    textTheme: _applyW800ToTextTheme(
      GoogleFonts.montserratTextTheme(
        ThemeData(brightness: Brightness.light).textTheme,
      ).apply(
        bodyColor: const Color(0xFF000000),
        displayColor: const Color(0xFF000000),
        decorationColor: const Color(0xFF000000),
      ),
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF2E2E48),
            brightness: Brightness.dark,
            secondary: Colors.amber,
            onSecondary: Colors.white)
        .copyWith(
      primary: const Color(0xFF2E2E48),
    ),
    fontFamily: 'Montserrat',
    textTheme: _applyW800ToTextTheme(
      GoogleFonts.montserratTextTheme(
        ThemeData(brightness: Brightness.dark).textTheme,
      ).apply(
        bodyColor: const Color(0xFFFFFFFF),
        displayColor: const Color(0xFFFFFFFF),
        decorationColor: const Color(0xFFFFFFFF),
      ),
    ),
  );
}

TextTheme _applyW800ToTextTheme(TextTheme base) {
  const w800 = TextStyle(fontWeight: FontWeight.w800);
  return base.copyWith(
    displayLarge: base.displayLarge?.merge(w800),
    displayMedium: base.displayMedium?.merge(w800),
    displaySmall: base.displaySmall?.merge(w800),
    headlineLarge: base.headlineLarge?.merge(w800),
    headlineMedium: base.headlineMedium?.merge(w800),
    headlineSmall: base.headlineSmall?.merge(w800),
    titleLarge: base.titleLarge?.merge(w800),
    titleMedium: base.titleMedium?.merge(w800),
    titleSmall: base.titleSmall?.merge(w800),
    bodyLarge: base.bodyLarge?.merge(w800),
    bodyMedium: base.bodyMedium?.merge(w800),
    bodySmall: base.bodySmall?.merge(w800),
    labelLarge: base.labelLarge?.merge(w800),
    labelMedium: base.labelMedium?.merge(w800),
    labelSmall: base.labelSmall?.merge(w800),
  );
}
