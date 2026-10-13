import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Central design system for the Freelancer app.
/// All colors, gradients, radii, and text styles live here.
abstract class AppTheme {
  // ── Palette ─────────────────────────────────────────────────────────────────

  /// Deep forest ink — scaffold / page background.
  static const Color bgDeep = Color(0xFF08100D);

  /// Dark pine — card surfaces.
  static const Color bgCard = Color(0xFF0F1B16);

  /// Very dark surface used inside glass cards.
  static const Color bgSurface = Color(0xFF15261F);

  /// Elegant emerald — the primary accent colour (name kept for compatibility).
  static const Color emerald = Color(0xFF2FB584);

  /// Dimmer emerald for secondary/disabled states.
  static const Color emeraldDim = Color(0xFF1E8A63);

  /// Soft emerald glow used in shadows / halos.
  static const Color emeraldGlow = Color(0x2E2FB584); // 25 % opacity

  /// Text — full white.
  static const Color textPrimary = Color(0xFFF4FAF7);

  /// Text — muted 60 % white.
  static const Color textSecondary = Color(0xB3E3EEE8);

  /// Text — very muted 35 % white.
  static const Color textHint = Color(0x73E3EEE8);

  /// Error / overdue red.
  static const Color errorRed = Color(0xFFD96C6C);

  /// Warning / pending amber.
  static const Color warningAmber = Color(0xFFD9B26F);

  /// Warm secondary accent used for premium affordances and attention cues.
  static const Color orange = Color(0xFFD0A15E);

  /// Glass card border colour.
  static const Color glassBorder = Color(0x2640C494); // 15 % white

  /// Electric blue / cyan accent used for Quotes/Devis.
  static const Color electricBlue = Color(0xFF8FA6C4);

  // ── Gradients ───────────────────────────────────────────────────────────────

  static const LinearGradient emeraldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF5FD3A4), Color(0xFF2FB584), Color(0xFF1E8A63)],
  );

  static const LinearGradient bgGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0F1A16), Color(0xFF08100D)],
  );

  static const LinearGradient glassGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0x1440C494), Color(0x06FFFFFF)],
  );

  // ── Radii ───────────────────────────────────────────────────────────────────

  static const double radiusXL = 28.0;
  static const double radiusLG = 20.0;
  static const double radiusMD = 14.0;
  static const double radiusSM = 10.0;

  // ── Typography ──────────────────────────────────────────────────────────────

  static TextStyle displayLarge({Color color = Colors.white}) =>
      GoogleFonts.playfairDisplay(
        fontSize: 42,
        fontWeight: FontWeight.w800,
        color: color,
        letterSpacing: -0.8,
        height: 1.1,
      );

  static TextStyle headlineMedium({Color color = Colors.white}) =>
      GoogleFonts.playfairDisplay(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: -0.5,
      );

  static TextStyle titleLarge({Color color = Colors.white}) =>
      GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: color,
      );

  static TextStyle bodyLarge({Color color = Colors.white}) => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: color,
  );

  static TextStyle bodyMedium({Color color = const Color(0x99FFFFFF)}) =>
      GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: color,
      );

  static TextStyle labelSmall({Color color = const Color(0x59FFFFFF)}) =>
      GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: color,
        letterSpacing: 0.8,
      );

  // ── MaterialApp ThemeData ───────────────────────────────────────────────────

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgDeep,
      colorScheme: ColorScheme.dark(
        primary: emerald,
        secondary: emeraldDim,
        surface: bgCard,
        error: errorRed,
        onPrimary: bgDeep,
        onSecondary: bgDeep,
        onSurface: textPrimary,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bgSurface,
        hintStyle: GoogleFonts.inter(color: textHint, fontSize: 14),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: const BorderSide(color: glassBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: const BorderSide(color: glassBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: const BorderSide(color: emerald, width: 1.2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: emerald,
          foregroundColor: bgDeep,
          elevation: 0,
          textStyle:
              GoogleFonts.inter(fontWeight: FontWeight.w600, letterSpacing: 0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMD),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: emerald,
          foregroundColor: bgDeep,
          textStyle:
              GoogleFonts.inter(fontWeight: FontWeight.w600, letterSpacing: 0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMD),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLG),
          side: const BorderSide(color: glassBorder),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: bgCard,
        surfaceTintColor: Colors.transparent,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: bgSurface,
        behavior: SnackBarBehavior.floating,
        contentTextStyle: GoogleFonts.inter(color: textPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMD),
        ),
      ),
      cardTheme: CardThemeData(
        color: bgCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLG),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: titleLarge(),
        iconTheme: const IconThemeData(color: textPrimary),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0x1A40C494),
        thickness: 1,
      ),
      iconTheme: const IconThemeData(color: textSecondary),
    );
  }
}
