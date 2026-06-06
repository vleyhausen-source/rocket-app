import 'package:flutter/material.dart';

/// Einheitliches Farbschema und Typografie für das Rocket Game
class RocketTheme {
  RocketTheme._();

  // ==========================================================================
  // FARBEN
  // ==========================================================================

  static const Color bgDeep     = Color(0xFF03020A); // Tiefstes Schwarz-Blau
  static const Color bgDark     = Color(0xFF0A0818); // Haupt-Hintergrund
  static const Color bgCard     = Color(0xFF12102A); // Karten
  static const Color bgCardBorder = Color(0xFF2A2650); // Kartenrand

  static const Color primaryPurple  = Color(0xFF7C4DFF); // Haupt-Akzent
  static const Color primaryGlow    = Color(0xFFB39DDB); // Helleres Lila
  static const Color accentOrange   = Color(0xFFFF6D00); // Triebwerk/Feuer
  static const Color accentGold     = Color(0xFFFFD600); // Coins/Score
  static const Color accentCyan     = Color(0xFF00E5FF); // Spezial
  static const Color accentGreen    = Color(0xFF69F0AE); // Erfolg
  static const Color accentRed      = Color(0xFFFF1744); // Gefahr/Absturz

  static const Color textPrimary    = Color(0xFFF5F5FF);
  static const Color textSecondary  = Color(0xFF9E9BC0);
  static const Color textMuted      = Color(0xFF5C5880);

  // Zonen-Farben
  static const Color zoneTropo     = Color(0xFF1E88E5);
  static const Color zoneUpper     = Color(0xFF3949AB);
  static const Color zoneStrato    = Color(0xFF6A1B9A);
  static const Color zoneSpace     = Color(0xFF212121);

  // ==========================================================================
  // GRADIENTS
  // ==========================================================================

  static const LinearGradient bgGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [bgDeep, bgDark],
  );

  static const LinearGradient purpleGradient = LinearGradient(
    colors: [Color(0xFF7C4DFF), Color(0xFF651FFF)],
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFFFD600), Color(0xFFFF6F00)],
  );

  static const LinearGradient fireGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFEB3B), Color(0xFFFF6D00), Color(0xFFD32F2F)],
  );

  // ==========================================================================
  // TEXT-STYLES
  // ==========================================================================

  static const TextStyle displayLarge = TextStyle(
    fontFamily: 'monospace',
    fontSize: 52,
    fontWeight: FontWeight.w900,
    color: textPrimary,
    letterSpacing: 10,
    height: 1.0,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontFamily: 'monospace',
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: textPrimary,
    letterSpacing: 4,
  );

  static const TextStyle labelBold = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.bold,
    color: textPrimary,
    letterSpacing: 2,
  );

  static const TextStyle mono = TextStyle(
    fontFamily: 'monospace',
    fontSize: 14,
    color: textSecondary,
  );

  // ==========================================================================
  // MATERIAL THEME
  // ==========================================================================

  static ThemeData get materialTheme => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: bgDark,
    colorScheme: const ColorScheme.dark(
      primary: primaryPurple,
      secondary: accentCyan,
      surface: bgCard,
      error: accentRed,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: bgDark,
      foregroundColor: textPrimary,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: 'monospace',
        fontSize: 18,
        fontWeight: FontWeight.bold,
        letterSpacing: 3,
        color: textPrimary,
      ),
    ),
    tabBarTheme: const TabBarThemeData(
      labelColor: textPrimary,
      unselectedLabelColor: textMuted,
      indicatorColor: primaryPurple,
      dividerColor: bgCardBorder,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryPurple,
        foregroundColor: textPrimary,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(
          fontFamily: 'monospace',
          fontWeight: FontWeight.bold,
          letterSpacing: 3,
        ),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: bgCard,
      contentTextStyle: const TextStyle(color: textPrimary),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      behavior: SnackBarBehavior.floating,
    ),
    useMaterial3: true,
  );

  // ==========================================================================
  // HELPER WIDGETS
  // ==========================================================================

  /// Neon-Glow Effekt um einen Text
  static Widget glowText(
    String text, {
    required Color color,
    double fontSize = 48,
    double blurRadius = 20,
  }) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: 'monospace',
        fontSize: fontSize,
        fontWeight: FontWeight.w900,
        color: color,
        letterSpacing: 8,
        shadows: [
          Shadow(color: color.withValues(alpha: 0.9), blurRadius: blurRadius),
          Shadow(color: color.withValues(alpha: 0.5), blurRadius: blurRadius * 2),
        ],
      ),
    );
  }

  /// Glasmorphismus-Container
  static Widget glassCard({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(20),
    Color borderColor = bgCardBorder,
    double borderRadius = 16,
  }) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bgCard.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: primaryPurple.withValues(alpha: 0.08),
            blurRadius: 24,
            spreadRadius: 2,
          ),
        ],
      ),
      child: child,
    );
  }
}
