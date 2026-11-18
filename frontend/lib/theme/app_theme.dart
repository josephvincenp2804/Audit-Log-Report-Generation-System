import 'package:flutter/material.dart';

/// Nexcent Design System Theme
/// Accurately extracted from the Nexcent design reference:
/// - Primary Green: #4CAF4F / #2E7D32
/// - Neutral Dark: #263238
/// - Body Text: #717171
/// - Background Silver: #F5F7FA
/// - Pure White: #FFFFFF
/// - Subtle Border: #E0E0E0
class AppTheme {
  // Nexcent Brand Colors
  static const Color nexcentGreen = Color(0xFF4CAF4F);
  static const Color nexcentGreenDark = Color(0xFF2E7D32);
  static const Color nexcentGreenLight = Color(0xFFE8F5E9);
  static const Color nexcentGreenHover = Color(0xFF43A047);

  // Nexcent Neutrals & Surfaces
  static const Color neutralDark = Color(0xFF263238);
  static const Color neutralGrey = Color(0xFF4D4D4D);
  static const Color bodyGrey = Color(0xFF717171);
  static const Color lightGrey = Color(0xFF89939E);
  static const Color scaffoldBackground = Color(0xFFF5F7FA);
  static const Color silverBg = Color(0xFFF5F7FA);
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color cardBorder = Color(0xFFE8ECEF);

  // Legacy mappings for seamless compatibility
  static const Color primaryNavy = neutralDark;
  static const Color secondaryNavy = Color(0xFF37474F);
  static const Color accentBlue = nexcentGreen;
  static const Color lightBlue = nexcentGreenHover;
  static const Color subtleBlue = nexcentGreenLight;

  static const Color textPrimary = neutralDark;
  static const Color textSecondary = bodyGrey;
  static const Color textMuted = lightGrey;

  // Audit Action Colors (Refined to Nexcent Palette)
  static const Color insertGreen = Color(0xFF4CAF4F);
  static const Color insertBg = Color(0xFFE8F5E9);
  static const Color updateAmber = Color(0xFFF57C00);
  static const Color updateBg = Color(0xFFFFF3E0);
  static const Color deleteRed = Color(0xFFE53935);
  static const Color deleteBg = Color(0xFFFFEBEE);

  static Color getActionColor(String action) {
    switch (action.toUpperCase()) {
      case 'INSERT':
        return insertGreen;
      case 'UPDATE':
        return updateAmber;
      case 'DELETE':
        return deleteRed;
      default:
        return bodyGrey;
    }
  }

  static Color getActionBgColor(String action) {
    switch (action.toUpperCase()) {
      case 'INSERT':
        return insertBg;
      case 'UPDATE':
        return updateBg;
      case 'DELETE':
        return deleteBg;
      default:
        return const Color(0xFFECEFF1);
    }
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: nexcentGreen,
        primary: nexcentGreen,
        secondary: nexcentGreenDark,
        surface: surfaceWhite,
        surfaceContainerLowest: scaffoldBackground,
        error: deleteRed,
      ),
      scaffoldBackgroundColor: scaffoldBackground,
      fontFamily: 'Segoe UI',
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceWhite,
        foregroundColor: neutralDark,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: neutralDark,
          letterSpacing: 0.2,
        ),
        iconTheme: IconThemeData(color: neutralDark),
      ),
      cardTheme: CardThemeData(
        color: surfaceWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: cardBorder, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceWhite,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: nexcentGreen, width: 1.5),
        ),
        labelStyle: const TextStyle(color: bodyGrey, fontSize: 14),
        hintStyle: const TextStyle(color: lightGrey, fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: nexcentGreen,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: neutralDark,
          side: const BorderSide(color: cardBorder),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: nexcentGreenLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: const BorderSide(color: Colors.transparent),
        ),
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: nexcentGreenDark),
      ),
      dividerTheme: const DividerThemeData(
        color: cardBorder,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
