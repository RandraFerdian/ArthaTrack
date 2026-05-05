import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:arthatrack/src/core/app_colors.dart';

class AppFont {
  /// Base style menggunakan Plus Jakarta Sans (Sesuai dengan tema aplikasi)
  static TextStyle _baseStyle({
    required double fontSize,
    required FontWeight fontWeight,
    Color? color,
  }) {
    return GoogleFonts.plusJakartaSans(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color ?? AppColors.textPrimary, // Default warna teks putih
    );
  }

  // ==========================================
  // 1. HEADINGS (Untuk Judul, Appbar, Header)
  // ==========================================
  static TextStyle get h1 =>
      _baseStyle(fontSize: 32, fontWeight: FontWeight.bold);
  static TextStyle get h2 =>
      _baseStyle(fontSize: 24, fontWeight: FontWeight.bold);
  static TextStyle get h3 =>
      _baseStyle(fontSize: 20, fontWeight: FontWeight.w700);
  static TextStyle get h4 =>
      _baseStyle(fontSize: 18, fontWeight: FontWeight.w600);

  // ==========================================
  // 2. BODY TEXT (Untuk Teks Umum, Paragraf)
  // ==========================================
  static TextStyle get bodyLarge =>
      _baseStyle(fontSize: 16, fontWeight: FontWeight.normal);
  static TextStyle get bodyMedium =>
      _baseStyle(fontSize: 14, fontWeight: FontWeight.normal);
  static TextStyle get bodySmall =>
      _baseStyle(fontSize: 12, fontWeight: FontWeight.normal);

  // ==========================================
  // 3. SUBTITLE & CAPTION (Untuk Hint, Deskripsi Abu-abu)
  // ==========================================
  /// Teks ukuran sedang dengan warna abu-abu (Secondary)
  static TextStyle get subtitle => _baseStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      );

  /// Teks kecil dengan warna abu-abu (Secondary)
  static TextStyle get caption => _baseStyle(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: AppColors.textSecondary,
      );

  /// Teks sangat kecil (biasanya untuk label tag/tanggal)
  static TextStyle get overline => _baseStyle(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        color: AppColors.textSecondary,
      );
}
