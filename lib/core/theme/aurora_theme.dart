import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AuroraColors {
  static const Color backgroundDark  = Color(0xFF0D0D2B);
  static const Color backgroundDeep  = Color(0xFF1A0A2E);
  static const Color pink            = Color(0xFFF472B6);
  static const Color indigo          = Color(0xFF818CF8);
  static const Color green           = Color(0xFF34D399);
  static const Color blue            = Color(0xFF60A5FA);
  static const Color textPrimary     = Color(0xFFFFFFFF);
  static Color get textSecondary     => const Color(0xFFFFFFFF).withOpacity(0.6);
  static Color get textHint          => const Color(0xFFFFFFFF).withOpacity(0.3);
  static Color get glassCardBg       => const Color(0xFFFFFFFF).withOpacity(0.06);
  static Color get glassCardBorder   => const Color(0xFFFFFFFF).withOpacity(0.12);
}

class AuroraTheme {
  static ThemeData get theme {
    final base = ThemeData.dark(useMaterial3: true);
    final textTheme = GoogleFonts.interTextTheme(base.textTheme).copyWith(
      displayLarge:  GoogleFonts.inter(color: AuroraColors.textPrimary, fontWeight: FontWeight.w700),
      displayMedium: GoogleFonts.inter(color: AuroraColors.textPrimary, fontWeight: FontWeight.w700),
      headlineLarge: GoogleFonts.inter(color: AuroraColors.textPrimary, fontWeight: FontWeight.w600),
      headlineMedium:GoogleFonts.inter(color: AuroraColors.textPrimary, fontWeight: FontWeight.w600),
      headlineSmall: GoogleFonts.inter(color: AuroraColors.textPrimary, fontWeight: FontWeight.w600),
      titleLarge:    GoogleFonts.inter(color: AuroraColors.textPrimary, fontWeight: FontWeight.w600),
      titleMedium:   GoogleFonts.inter(color: AuroraColors.textPrimary, fontWeight: FontWeight.w500),
      titleSmall:    GoogleFonts.inter(color: AuroraColors.textPrimary, fontWeight: FontWeight.w500),
      bodyLarge:     GoogleFonts.inter(color: AuroraColors.textPrimary),
      bodyMedium:    GoogleFonts.inter(color: AuroraColors.textSecondary),
      bodySmall:     GoogleFonts.inter(color: AuroraColors.textSecondary),
      labelLarge:    GoogleFonts.inter(color: AuroraColors.textPrimary, fontWeight: FontWeight.w500),
    );

    return base.copyWith(
      splashColor: Colors.white.withOpacity(0.9),
      highlightColor: const Color(0xFFF472B6).withOpacity(0.4),
      splashFactory: InkSparkle.splashFactory,
      textTheme: textTheme,
      scaffoldBackgroundColor: AuroraColors.backgroundDark,
      colorScheme: const ColorScheme.dark(
        primary:   Color(0xFFF472B6),
        secondary: Color(0xFF818CF8),
        tertiary:  Color(0xFF34D399),
        surface:   Color(0xFF1A0A2E),
        error:     Color(0xFFFF6B6B),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.inter(
          color: AuroraColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: AuroraColors.textPrimary),
      ),
      cardTheme: CardThemeData(
        color: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AuroraColors.glassCardBorder, width: 0.5),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AuroraColors.glassCardBg,
        hintStyle: GoogleFonts.inter(
            color: const Color(0xFFFFFFFF).withOpacity(0.4), fontSize: 14),
        labelStyle: GoogleFonts.inter(color: AuroraColors.textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AuroraColors.glassCardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: const Color(0xFFFFFFFF).withOpacity(0.15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFF472B6), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFFF6B6B)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFFF6B6B), width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF472B6),
          foregroundColor: Colors.white,
          elevation: 0,
          splashFactory: InkSparkle.splashFactory,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          minimumSize: const Size(double.infinity, 52),
          textStyle: GoogleFonts.inter(
              fontSize: 15, fontWeight: FontWeight.w500),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AuroraColors.pink,
          splashFactory: InkSparkle.splashFactory,
          textStyle:
              GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AuroraColors.pink,
          splashFactory: InkSparkle.splashFactory,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: AuroraColors.textPrimary,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          splashFactory: InkSparkle.splashFactory,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: Color(0xFFF472B6),
        unselectedItemColor: Color(0x99FFFFFF),
        type: BottomNavigationBarType.fixed,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFFFFFFFF).withOpacity(0.05),
        indicatorColor: const Color(0xFFF472B6).withOpacity(0.2),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.inter(
                color: AuroraColors.pink,
                fontSize: 12,
                fontWeight: FontWeight.w600);
          }
          return GoogleFonts.inter(
              color: AuroraColors.textSecondary, fontSize: 12);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: Color(0xFFF472B6));
          }
          return IconThemeData(
              color: const Color(0xFFFFFFFF).withOpacity(0.6));
        }),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xFF1A0A2E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AuroraColors.glassCardBorder),
        ),
        titleTextStyle: GoogleFonts.inter(
            color: AuroraColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600),
        contentTextStyle:
            GoogleFonts.inter(color: AuroraColors.textSecondary, fontSize: 14),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF1A0A2E),
        contentTextStyle:
            GoogleFonts.inter(color: AuroraColors.textPrimary, fontSize: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: AuroraColors.glassCardBorder),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      dividerTheme: DividerThemeData(
        color: const Color(0xFFFFFFFF).withOpacity(0.08),
        thickness: 0.5,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Color(0xFFF472B6),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
    );
  }
}
