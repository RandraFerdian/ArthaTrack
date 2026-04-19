import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ArthaTheme {
  // Warna sesuai referensi gambar kamu
  static const Color darkBg = Color(0xFF121212);
  static const Color cardBg = Color(0xFF1E1E1E);
  static const Color accentGreen = Color(0xFF00C853);
  static const Color accentRed = Color(0xFFFF5252);

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: accentGreen,
    scaffoldBackgroundColor: darkBg,
    textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
    cardTheme: CardThemeData(
      color: cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 4,
    ),
  );
}
