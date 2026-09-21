import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/panchang_terms.dart' show AppLanguage, appLanguageNotifier;

/// TithiNow Design System - Source of Truth
/// Enforces exact colors, typography, spacing, and radius tokens.

abstract class AppColors {
  /// Application background (#121414)
  static const Color background = Color(0xFF121414);

  /// Surface / elevated background (#FFFFFF at 5% opacity)
  static Color get surface => const Color(0xFFFFFFFF).withValues(alpha: 0.05);

  /// Alternate surface (#FFFFFF at 10% opacity)
  static Color get surfaceVariant => const Color(0xFFFFFFFF).withValues(alpha: 0.10);

  /// Borders and outlines (#FFFFFF at 15% opacity)
  static Color get outline => const Color(0xFFFFFFFF).withValues(alpha: 0.15);

  /// Primary brand color (#7FC9CE)
  static const Color primary = Color(0xFF7FC9CE);

  /// Secondary brand color (#A79BC4)
  static const Color secondary = Color(0xFFA79BC4);

  /// Tertiary brand color (#D9B686)
  static const Color tertiary = Color(0xFFD9B686);

  /// Primary content on surfaces (#BAC9CB)
  static const Color onSurface = Color(0xFFBAC9CB);

  /// Variant content on surfaces (#FFFFFF)
  static const Color onSurfaceVariant = Color(0xFFFFFFFF);

  /// Negative / bad state (#E20607)
  static const Color indicatorBad = Color(0xFFE20607);

  /// Positive / good state (#2BCF08)
  static const Color indicatorGood = Color(0xFF2BCF08);
}

abstract class AppSpacing {
  static const double spacing4 = 4.0;
  static const double spacing8 = 8.0;
  static const double spacing12 = 12.0;
  static const double spacing16 = 16.0;
  static const double spacing24 = 24.0;
  static const double spacing32 = 32.0;
  static const double spacing40 = 40.0;
  static const double spacing48 = 48.0;
  static const double spacing56 = 56.0;
  static const double spacing64 = 64.0;
  static const double spacing72 = 72.0;
}

abstract class AppRadius {
  static const double radius8 = 8.0;
  static const double radius12 = 12.0;
  static const double radius16 = 16.0;
  static const double radius24 = 24.0;
  static const double radius32 = 32.0;
  static const double radius999 = 999.0;

  static BorderRadius get border8 => BorderRadius.circular(radius8);
  static BorderRadius get border12 => BorderRadius.circular(radius12);
  static BorderRadius get border16 => BorderRadius.circular(radius16);
  static BorderRadius get border24 => BorderRadius.circular(radius24);
  static BorderRadius get border32 => BorderRadius.circular(radius32);
  static BorderRadius get border999 => BorderRadius.circular(radius999);
}

class AppTypography {
  final bool isDesktop;
  final AppLanguage language;

  AppTypography({
    this.isDesktop = false,
    this.language = AppLanguage.english,
  });

  /// Font Weights
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight semiBold = FontWeight.w600;

  /// Optical font scale factor for Indic scripts (Hindi and Gujarati).
  ///
  /// Indic scripts (Devanagari and Gujarati) have smaller base glyphs within the EM square
  /// due to upper and lower matra requirements. Scaling by +12% matches English visual weight.
  double get scriptScale => switch (language) {
    AppLanguage.hindi || AppLanguage.gujarati => 1.12,
    AppLanguage.english => 1.0,
  };

  /// Optical line height for Indic scripts to prevent matra clipping.
  double get scriptLineHeight => switch (language) {
    AppLanguage.hindi || AppLanguage.gujarati => 1.35,
    AppLanguage.english => 1.20,
  };

  /// Returns a heading TextStyle with the appropriate font family and optical scaling:
  /// - English: Sora
  /// - Hindi: Laila
  /// - Gujarati: Mukta Vaani
  static TextStyle headingStyle({
    AppLanguage? language,
    required double fontSize,
    FontWeight weight = regular,
    Color color = AppColors.onSurfaceVariant,
    double? height,
  }) {
    final effectiveLanguage = language ?? appLanguageNotifier.value;
    final scale = (effectiveLanguage == AppLanguage.hindi || effectiveLanguage == AppLanguage.gujarati) ? 1.12 : 1.0;
    final effectiveHeight = height ?? ((effectiveLanguage == AppLanguage.hindi || effectiveLanguage == AppLanguage.gujarati) ? 1.35 : null);
    final effectiveSize = fontSize * scale;

    return switch (effectiveLanguage) {
      AppLanguage.hindi => GoogleFonts.laila(
        fontSize: effectiveSize,
        fontWeight: weight,
        color: color,
        height: effectiveHeight,
      ),
      AppLanguage.gujarati => GoogleFonts.muktaVaani(
        fontSize: effectiveSize,
        fontWeight: weight,
        color: color,
        height: effectiveHeight,
      ),
      AppLanguage.english => GoogleFonts.sora(
        fontSize: fontSize,
        fontWeight: weight,
        color: color,
        height: height,
      ),
    };
  }

  /// Returns a body TextStyle with the appropriate font family and optical scaling:
  /// - English: Inter
  /// - Hindi: Baloo 2
  /// - Gujarati: Baloo Bhai 2
  static TextStyle bodyStyle({
    AppLanguage? language,
    required double fontSize,
    FontWeight weight = regular,
    Color color = AppColors.onSurface,
    double? height,
  }) {
    final effectiveLanguage = language ?? appLanguageNotifier.value;
    final scale = (effectiveLanguage == AppLanguage.hindi || effectiveLanguage == AppLanguage.gujarati) ? 1.12 : 1.0;
    final effectiveHeight = height ?? ((effectiveLanguage == AppLanguage.hindi || effectiveLanguage == AppLanguage.gujarati) ? 1.35 : null);
    final effectiveSize = fontSize * scale;

    return switch (effectiveLanguage) {
      AppLanguage.hindi => GoogleFonts.baloo2(
        fontSize: effectiveSize,
        fontWeight: weight,
        color: color,
        height: effectiveHeight,
      ),
      AppLanguage.gujarati => GoogleFonts.balooBhai2(
        fontSize: effectiveSize,
        fontWeight: weight,
        color: color,
        height: effectiveHeight,
      ),
      AppLanguage.english => GoogleFonts.inter(
        fontSize: fontSize,
        fontWeight: weight,
        color: color,
        height: height,
      ),
    };
  }

  /// Headings H1 - H4
  TextStyle h1({FontWeight weight = regular, Color color = AppColors.onSurfaceVariant}) {
    return headingStyle(
      language: language,
      fontSize: isDesktop ? 40.0 : 30.0,
      weight: weight,
      color: color,
    );
  }

  TextStyle h2({FontWeight weight = regular, Color color = AppColors.onSurfaceVariant}) {
    return headingStyle(
      language: language,
      fontSize: isDesktop ? 32.0 : 26.0,
      weight: weight,
      color: color,
    );
  }

  TextStyle h3({FontWeight weight = regular, Color color = AppColors.onSurfaceVariant}) {
    return headingStyle(
      language: language,
      fontSize: isDesktop ? 26.0 : 22.0,
      weight: weight,
      color: color,
    );
  }

  TextStyle h4({FontWeight weight = regular, Color color = AppColors.onSurfaceVariant}) {
    return headingStyle(
      language: language,
      fontSize: isDesktop ? 22.0 : 19.0,
      weight: weight,
      color: color,
    );
  }

  /// BodyLG, BodyMD, BodySM, Caption
  TextStyle bodyLG({FontWeight weight = regular, Color color = AppColors.onSurface}) {
    return bodyStyle(
      language: language,
      fontSize: isDesktop ? 18.0 : 17.0,
      weight: weight,
      color: color,
    );
  }

  TextStyle bodyMD({FontWeight weight = regular, Color color = AppColors.onSurface}) {
    return bodyStyle(
      language: language,
      fontSize: isDesktop ? 16.0 : 15.0,
      weight: weight,
      color: color,
    );
  }

  TextStyle bodySM({FontWeight weight = regular, Color color = AppColors.onSurface}) {
    return bodyStyle(
      language: language,
      fontSize: isDesktop ? 14.0 : 13.0,
      weight: weight,
      color: color,
    );
  }

  TextStyle caption({FontWeight weight = regular, Color color = AppColors.onSurface}) {
    return bodyStyle(
      language: language,
      fontSize: 11.0,
      weight: weight,
      color: color,
    );
  }
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.dark(
        brightness: Brightness.dark,
        surface: AppColors.background,
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        tertiary: AppColors.tertiary,
        onSurface: AppColors.onSurface,
        onPrimary: AppColors.background,
        outline: AppColors.outline,
        error: AppColors.indicatorBad,
      ),
      textTheme: TextTheme(
        headlineLarge: GoogleFonts.sora(fontSize: 30, fontWeight: FontWeight.w600, color: AppColors.onSurfaceVariant),
        headlineMedium: GoogleFonts.sora(fontSize: 26, fontWeight: FontWeight.w600, color: AppColors.onSurfaceVariant),
        headlineSmall: GoogleFonts.sora(fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.onSurfaceVariant),
        titleLarge: GoogleFonts.sora(fontSize: 19, fontWeight: FontWeight.w600, color: AppColors.onSurfaceVariant),
        bodyLarge: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w400, color: AppColors.onSurface),
        bodyMedium: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w400, color: AppColors.onSurface),
        bodySmall: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w400, color: AppColors.onSurface),
        labelSmall: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w400, color: AppColors.onSurface),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.onSurfaceVariant,
        elevation: 0,
        titleTextStyle: GoogleFonts.sora(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: AppColors.onSurfaceVariant,
        ),
      ),
    );
  }
}

extension DesignSystemContext on BuildContext {
  /// True if running on desktop (macOS, Windows, Linux) OR if screen width >= 720.
  /// In tests, uses screen width to allow testing responsive layouts.
  bool get isDesktop {
    if (!kIsWeb && Platform.environment.containsKey('FLUTTER_TEST')) {
      return MediaQuery.sizeOf(this).width >= 720;
    }
    if (!kIsWeb && (Platform.isMacOS || Platform.isWindows || Platform.isLinux)) {
      return true;
    }
    return MediaQuery.sizeOf(this).width >= 720;
  }

  /// Resolves [AppTypography] with the current language from [appLanguageNotifier].
  AppTypography get appTypography => AppTypography(
    isDesktop: isDesktop,
    language: appLanguageNotifier.value,
  );

  /// Resolves [AppTypography] for an explicit [language] override.
  AppTypography appTypographyFor(AppLanguage language) => AppTypography(
    isDesktop: isDesktop,
    language: language,
  );
}

