import 'package:flutter/material.dart';

class GoogleColors {
  static const Color blue = Color(0xFF4285F4);
  static const Color red = Color(0xFFEA4335);
  static const Color yellow = Color(0xFFFBBC04);
  static const Color green = Color(0xFF34A853);
  
  static const Color blueLight = Color(0xFF8AB4F8);
  static const Color blueDark = Color(0xFF1A73E8);
  
  static const Color greyLight = Color(0xFFF8F9FA);
  static const Color grey = Color(0xFF9AA0A6);
  static const Color greyDark = Color(0xFF5F6368);
  static const Color greyVeryDark = Color(0xFF3C4043);
  
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);

  static ThemeData googleTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: blue,
      brightness: Brightness.light,
      primary: blue,
      secondary: green,
      surface: greyLight,
      background: white,
      error: red,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: blue,
      foregroundColor: white,
      elevation: 0,
      centerTitle: true,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: blue,
        foregroundColor: white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: blue,
      foregroundColor: white,
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: const BorderSide(color: grey),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: const BorderSide(color: grey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: const BorderSide(color: blue, width: 2),
      ),
      filled: true,
      fillColor: greyLight,
    ),
  );

  static ThemeData googleDarkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: blue,
      brightness: Brightness.dark,
      primary: blueLight,
      secondary: green,
      surface: greyVeryDark,
      background: greyVeryDark,
      error: red,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: greyVeryDark,
      foregroundColor: white,
      elevation: 0,
      centerTitle: true,
    ),
  );
}