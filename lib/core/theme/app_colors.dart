
import 'package:flutter/material.dart';

/// Muslims Pro - Global Color System.
///
/// Emerald green represents trust and tranquility.
/// Gold represents elegance and spiritual identity.
class AppColors {
  AppColors._();

  // ============================================================
  // BRAND COLORS
  // ============================================================

  static const Color emerald = Color(0xFF087F5B);
  static const Color emeraldLight = Color(0xFF12A77A);
  static const Color emeraldDark = Color(0xFF064E3B);
  static const Color deepGreen = Color(0xFF032B25);

  // ============================================================
  // GOLD ACCENTS
  // ============================================================

  static const Color gold = Color(0xFFC6A76A);
  static const Color goldLight = Color(0xFFE3CB91);
  static const Color goldDark = Color(0xFF9C7A3D);

  // ============================================================
  // DARK MODE
  // ============================================================

  static const Color darkBackground = Color(0xFF061713);
  static const Color darkSurface = Color(0xFF10251F);
  static const Color darkSurfaceLight = Color(0xFF18352C);
  static const Color darkSurfaceElevated = Color(0xFF203D32);

  // ============================================================
  // LIGHT MODE
  // ============================================================

  static const Color lightBackground = Color(0xFFF3F7F4);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceSoft = Color(0xFFEAF1EC);
  static const Color lightSurfaceElevated = Color(0xFFF9FCFA);

  // ============================================================
  // TEXT COLORS
  // ============================================================

  static const Color textDark = Color(0xFF17382E);
  static const Color textLight = Color(0xFFF4F8F5);

  static const Color muted = Color(0xFF91A99E);
  static const Color mutedDark = Color(0xFF627B70);
  static const Color mutedLight = Color(0xFFB6C9BF);

  // ============================================================
  // BORDER COLORS
  // ============================================================

  static const Color border = Color(0x337DAE98);
  static const Color borderLight = Color(0xFFE1EAE3);
  static const Color borderDark = Color(0xFF29483C);

  // ============================================================
  // STATUS COLORS
  // ============================================================

  static const Color success = Color(0xFF2E9D70);
  static const Color successLight = Color(0xFFBCE8D2);

  static const Color warning = Color(0xFFE5A83B);
  static const Color warningLight = Color(0xFFFFE8B8);

  static const Color error = Color(0xFFE65B5B);
  static const Color errorLight = Color(0xFFFFDADA);

  static const Color info = Color(0xFF4D91C7);
  static const Color infoLight = Color(0xFFD9ECFA);

  // ============================================================
  // SPECIAL QURAN COLORS
  // ============================================================

  static const Color quranPaper = Color(0xFFFFFCF3);
  static const Color quranInk = Color(0xFF26382C);
  static const Color quranGold = Color(0xFFB99A58);

  static const Color quranPaperDark = Color(0xFF202A23);
  static const Color quranInkDark = Color(0xFFE8DFC9);

  // ============================================================
  // OVERLAYS
  // ============================================================

  static const Color overlay = Color(0x80000000);
  static const Color overlayLight = Color(0x14000000);

  // ============================================================
  // GRADIENTS
  // ============================================================

  static const List<Color> emeraldGradient = [
    Color(0xFF12A77A),
    Color(0xFF087F5B),
    Color(0xFF064E3B),
  ];

  static const List<Color> darkGradient = [
    Color(0xFF18352C),
    Color(0xFF061713),
  ];

  static const List<Color> goldGradient = [
    Color(0xFFE3CB91),
    Color(0xFFC6A76A),
    Color(0xFF9C7A3D),
  ];
}
