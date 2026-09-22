import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  // === WARNA UTAMA ===
  static const Color primaryGreen = Color(0xFF2D9B4B);
  static const Color primaryGreenLight = Color(0xFF4CB96A);
  static const Color primaryGreenDark = Color(0xFF1A7A35);

  // === WARNA SEVERITY ===
  static const Color severityRingan = Color(0xFF2D9B4B); // Hijau
  static const Color severitySedang = Color(0xFFE8A020); // Kuning-Oranye
  static const Color severityBerat = Color(0xFFD93025); // Merah

  // === WARNA NETRAL ===
  static const Color background = Color(0xFFF7F8FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF0F2F5);
  static const Color onSurface = Color(0xFF1A1A2E);
  static const Color onSurfaceVariant = Color(0xFF6B7280);
  static const Color divider = Color(0xFFE5E7EB);

  // === WARNA OVERLAY / KAMERA ===
  static const Color overlayBackground = Color(0xCC000000); // 80% opacity hitam
  static const Color overlayPanel = Color(0xE6111827); // 90% opacity gelap
  static const Color bboxColor = Color(0xFF00FF88); // Hijau terang untuk bbox
  static const Color bboxLabelBg = Color(0xFF2D9B4B);

  // === TIPOGRAFI ===
  // Menggunakan Google Fonts
  static TextTheme get _textTheme => ThemeData.light().textTheme.apply(fontFamily: 'Google Sans').copyWith(
        displayLarge: TextStyle(fontFamily: 'Google Sans', 
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: onSurface,
          letterSpacing: -0.5,
        ),
        displayMedium: TextStyle(fontFamily: 'Google Sans', 
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: onSurface,
        ),
        headlineLarge: TextStyle(fontFamily: 'Google Sans', 
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: onSurface,
        ),
        headlineMedium: TextStyle(fontFamily: 'Google Sans', 
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: onSurface,
        ),
        headlineSmall: TextStyle(fontFamily: 'Google Sans', 
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: onSurface,
        ),
        titleLarge: TextStyle(fontFamily: 'Google Sans', 
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: onSurface,
        ),
        titleMedium: TextStyle(fontFamily: 'Google Sans', 
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: onSurface,
        ),
        titleSmall: TextStyle(fontFamily: 'Google Sans', 
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: onSurfaceVariant,
        ),
        bodyLarge: TextStyle(fontFamily: 'Google Sans', 
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: onSurface,
        ),
        bodyMedium: TextStyle(fontFamily: 'Google Sans', 
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: onSurface,
        ),
        bodySmall: TextStyle(fontFamily: 'Google Sans', 
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: onSurfaceVariant,
        ),
        labelLarge: TextStyle(fontFamily: 'Google Sans', 
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: onSurface,
        ),
        labelMedium: TextStyle(fontFamily: 'Google Sans', 
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: onSurface,
        ),
        labelSmall: TextStyle(fontFamily: 'Google Sans', 
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: onSurfaceVariant,
        ),
      );

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: primaryGreen,
        onPrimary: Colors.white,
        secondary: primaryGreenLight,
        onSecondary: Colors.white,
        surface: surface,
        onSurface: onSurface,
        surfaceContainerHighest: surfaceVariant,
        error: severityBerat,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: background,
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: divider,
        centerTitle: false,
        titleTextStyle: TextStyle(fontFamily: 'Google Sans', 
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: divider, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: TextStyle(fontFamily: 'Google Sans', 
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(color: divider, thickness: 1),
      textTheme: _textTheme,
    );
  }

  // === HELPER METHODS ===

  static Color getSeverityColor(String level) {
    switch (level.toLowerCase()) {
      case 'ringan':
        return severityRingan;
      case 'sedang':
        return severitySedang;
      case 'berat':
        return severityBerat;
      default:
        return onSurfaceVariant;
    }
  }

  static Color getSeverityBgColor(String level) {
    switch (level.toLowerCase()) {
      case 'ringan':
        return severityRingan.withValues(alpha: 0.1);
      case 'sedang':
        return severitySedang.withValues(alpha: 0.1);
      case 'berat':
        return severityBerat.withValues(alpha: 0.1);
      default:
        return surfaceVariant;
    }
  }
}
