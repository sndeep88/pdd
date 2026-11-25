import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const irishGreen = Color(0xFF006B3C);
  static const irishGreenDeep = Color(0xFF004D2A);
  static const emerald = Color(0xFF10B981);
  static const emeraldSoft = Color(0xFF34D399);
  static const gold = Color(0xFFC9A227);
  static const goldLight = Color(0xFFE8C547);
  static const goldDark = Color(0xFF9A7B1A);
  static const ink = Color(0xFF0B1F16);
  static const muted = Color(0xFF5A7266);
  static const mist = Color(0xFFE8F5EE);
  static const bg = Color(0xFFF4FAF7);
  static const danger = Color(0xFFDC2626);
  static const warning = Color(0xFFD97706);
}

class AppTheme {
  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.irishGreen,
        primary: AppColors.irishGreen,
        secondary: AppColors.gold,
        surface: Colors.white,
      ),
      scaffoldBackgroundColor: AppColors.bg,
    );

    return base.copyWith(
      textTheme: GoogleFonts.outfitTextTheme(base.textTheme).apply(
        bodyColor: AppColors.ink,
        displayColor: AppColors.ink,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.irishGreenDeep,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.outfit(
          color: Colors.white,
          fontSize: 19,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: AppColors.irishGreen.withValues(alpha: 0.09)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.irishGreen.withValues(alpha: 0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.irishGreen.withValues(alpha: 0.18)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.irishGreen, width: 1.8),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.irishGreen,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700),
          elevation: 0,
        ),
      ),
    );
  }
}

String formatUsdt(num value) {
  return '${value.toDouble().toStringAsFixed(2)} USDT';
}

Widget statusPill(String status) {
  final s = status.toLowerCase();
  Color bg;
  Color fg;
  if (s == 'active' || s == 'success' || s == 'completed' || s == 'paid') {
    bg = const Color(0xFFDCFCE7);
    fg = const Color(0xFF166534);
  } else if (s == 'failed' || s == 'rejected' || s == 'cancelled') {
    bg = const Color(0xFFFEE2E2);
    fg = const Color(0xFF991B1B);
  } else {
    bg = const Color(0xFFFEF3C7);
    fg = const Color(0xFF92400E);
  }
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      status.isEmpty ? 'pending' : status[0].toUpperCase() + status.substring(1),
      style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w700),
    ),
  );
}
