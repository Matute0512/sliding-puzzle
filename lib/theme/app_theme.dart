import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Colores personalizados que cambian entre tema claro y oscuro,
/// pero no forman parte del ColorScheme generado por Material 3.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  final Color background;
  final Color cardBackground;
  final Color textPrimary;
  final Color textSecondary;
  final Color emptyTile;

  const AppColors({
    required this.background,
    required this.cardBackground,
    required this.textPrimary,
    required this.textSecondary,
    required this.emptyTile,
  });

  static const light = AppColors(
    background: Color(0xFFF4F6F9),
    cardBackground: Colors.white,
    textPrimary: Color(0xFF1E293B),
    textSecondary: Color(0xFF64748B),
    emptyTile: Color(0xFFE2E8F0),
  );

  static const dark = AppColors(
    background: Color(0xFF0F172A),
    cardBackground: Color(0xFF1E293B),
    textPrimary: Color(0xFFF1F5F9),
    textSecondary: Color(0xFF94A3B8),
    emptyTile: Color(0xFF334155),
  );

  @override
  AppColors copyWith({
    Color? background,
    Color? cardBackground,
    Color? textPrimary,
    Color? textSecondary,
    Color? emptyTile,
  }) {
    return AppColors(
      background: background ?? this.background,
      cardBackground: cardBackground ?? this.cardBackground,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      emptyTile: emptyTile ?? this.emptyTile,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      background: Color.lerp(background, other.background, t)!,
      cardBackground: Color.lerp(cardBackground, other.cardBackground, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      emptyTile: Color.lerp(emptyTile, other.emptyTile, t)!,
    );
  }
}

/// Define los temas claro y oscuro de la app,
/// ambos basados en el mismo seed color (#4361EE).
class AppTheme {
  static const Color seedColor = Color(0xFF4361EE);
  static const Color accentShadow = Color(0xFF3146B5);

  static ThemeData get light {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: Brightness.light,
      ),
      useMaterial3: true,
      textTheme: GoogleFonts.poppinsTextTheme(ThemeData.light().textTheme),
      extensions: const [AppColors.light],
    );
  }

  static ThemeData get dark {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
      textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
      extensions: const [AppColors.dark],
    );
  }
}
