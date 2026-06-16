import 'package:flutter/material.dart';

import 'app_colors.dart';

import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,

    textTheme: GoogleFonts.fredokaTextTheme(),

    colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),

    scaffoldBackgroundColor: AppColors.background,

    appBarTheme: AppBarTheme(
      centerTitle: true,
      backgroundColor: Colors.white,
      titleTextStyle: GoogleFonts.fredoka(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    ),

    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),

      filled: true,

      fillColor: Colors.white,
    ),
  );
}
