import 'package:flutter/material.dart';

/// Colores personalizados que no forman parte del ColorScheme generado por
/// Material 3.
///
/// Hay una sola instancia ([game]) a propósito: el juego tiene un único aspecto
/// y no sigue el modo claro/oscuro del sistema. Los paneles de Kenney son
/// claros pase lo que pase, así que un segundo juego de colores para fondo
/// claro no tendría dónde aplicarse.
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

  /// Únicos colores de la app. Pensados sobre el azul marino de
  /// [AppTheme.gameBackground], que es el fondo de todas las pantallas.
  static const game = AppColors(
    background: AppTheme.gameBackground,
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

/// Define el único tema de la app.
///
/// Antes había tema claro y oscuro y la app seguía al sistema. Se sacó a
/// propósito: el rediseño usa sprites de Kenney, que tienen un solo aspecto y
/// son claros. Mantener un tema claro no aportaba nada (los paneles se veían
/// igual) y el fondo oscuro es lo que hace resaltar esos paneles y los botones
/// azules.
class AppTheme {
  static const Color seedColor = Color(0xFF4361EE);
  static const Color accentShadow = Color(0xFF3146B5);

  /// Azul marino profundo. Es el fondo de todas las pantallas y la fuente única
  /// de `scaffoldBackgroundColor` y de `AppColors.background`.
  static const Color gameBackground = Color(0xFF0F172A);

  // Colores del podio. Son para tintar la estrella del ranking (ver
  // `KenneyIcon.tint`): el pack de Kenney no trae bronce, así que el podio no
  // se puede armar con sprites ya coloreados.
  static const Color podiumGold = Color(0xFFF59E0B);
  static const Color podiumSilver = Color(0xFF94A3B8);
  static const Color podiumBronze = Color(0xFFB45309);

  /// Color de la estrella del podio, o `null` si el puesto no es 1º, 2º ni 3º.
  static Color? podiumColor(int puesto) => switch (puesto) {
        1 => podiumGold,
        2 => podiumSilver,
        3 => podiumBronze,
        _ => null,
      };

  static ThemeData get game {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
      scaffoldBackgroundColor: gameBackground,
      textTheme: ThemeData.dark().textTheme.apply(fontFamily: 'Poppins'),
      extensions: const [AppColors.game],
    );
  }
}
