import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminColors {
  static const background = Color(0xFFF8F5F7);
  static const primary = Color(0xFFE85D85);
  static const primaryLight = Color(0xFFF9DDE4);
  static const textDark = Color(0xFF3F2D38);
  static const textSoft = Color(0xFF8A6A7A);
  static const white = Color(0xFFFFFFFF);
}

class AdminTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AdminColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AdminColors.primary,
        primary: AdminColors.primary,
      ),
      textTheme: GoogleFonts.nunitoTextTheme(),
    );
  }
}

class AdminTextStyles {

  static const pageTitle = TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.bold,
    color: AdminColors.textDark,
  );

  static const pageSubtitle = TextStyle(
    fontSize: 15,
    color: AdminColors.textSoft,
  );

}