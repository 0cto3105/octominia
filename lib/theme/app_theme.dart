// lib/theme/app_theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData.dark().copyWith(
      primaryColor: Colors.amberAccent[200],
      colorScheme: ColorScheme.fromSwatch(
        primarySwatch: Colors.yellow,
        brightness: Brightness.dark,
      ).copyWith(
        secondary: Colors.amberAccent[200],
      ),
      scaffoldBackgroundColor: Colors.grey[900],
      cardColor: Colors.grey[850],
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.grey[800],
        foregroundColor: Colors.white,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Colors.white70),
        bodyMedium: TextStyle(color: Colors.white60),
        headlineSmall: TextStyle(color: Colors.white),
        titleMedium: TextStyle(color: Colors.white),
        labelLarge: TextStyle(color: Colors.white),
      ),
      iconTheme: const IconThemeData(
        color: Colors.white70,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.yellow,
          foregroundColor: Colors.white,
        ),
      ),
      expansionTileTheme: ExpansionTileThemeData(
        backgroundColor: Colors.grey[800],
        collapsedBackgroundColor: Colors.grey[800],
        iconColor: Colors.redAccent,
        textColor: Colors.white,
        collapsedIconColor: Colors.white70,
        collapsedTextColor: Colors.white70,
      ),
    );
  }
}