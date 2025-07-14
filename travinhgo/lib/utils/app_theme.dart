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
    textTheme: GoogleFonts.montserratTextTheme(
      ThemeData(brightness: Brightness.light).textTheme,
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF2E2E48),
      brightness: Brightness.dark,
      secondary: Colors.amber,
    ).copyWith(
      primary: const Color(0xFF2E2E48),
    ),
    dividerTheme: const DividerThemeData(
      color: Color.fromARGB(255, 255, 255, 255),
      thickness: 1,
    ),
    fontFamily: 'Montserrat',
    textTheme: GoogleFonts.montserratTextTheme(
      ThemeData(brightness: Brightness.dark).textTheme,
    ).apply(
      bodyColor: const Color(0xFFFFFFFF),
      displayColor: const Color(0xFFFFFFFF),
    ),
  );
}
