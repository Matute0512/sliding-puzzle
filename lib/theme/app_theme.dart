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

  /// Tercera jerarquía de texto: subtítulos y metadatos que acompañan a un
  /// valor sin competir con él (el "Tablero 4×4" debajo de un tiempo).
  ///
  /// Es más apagado que [textSecondary] a propósito. En el rediseño las
  /// etiquetas en mayúsculas quedaron con [textSecondary] y los subtítulos
  /// corrieron un escalón más abajo; con un solo secundario los dos niveles se
  /// leían iguales y la tarjeta perdía jerarquía.
  final Color textMuted;

  final Color emptyTile;

  const AppColors({
    required this.background,
    required this.cardBackground,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.emptyTile,
  });

  /// Únicos colores de la app. Pensados sobre el navy de
  /// [AppTheme.gameBackground], que es el fondo de todas las pantallas.
  static const game = AppColors(
    background: AppTheme.gameBackground,
    cardBackground: Color(0xFF1E293B),
    textPrimary: Color(0xFFF1F5F9),
    textSecondary: Color(0xFF94A3B8),
    textMuted: Color(0xFF63759D),
    emptyTile: Color(0xFF334155),
  );

  @override
  AppColors copyWith({
    Color? background,
    Color? cardBackground,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? emptyTile,
  }) {
    return AppColors(
      background: background ?? this.background,
      cardBackground: cardBackground ?? this.cardBackground,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
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
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      emptyTile: Color.lerp(emptyTile, other.emptyTile, t)!,
    );
  }
}

/// Define el único tema de la app.
///
/// Antes había tema claro y oscuro y la app seguía al sistema. Se sacó a
/// propósito: el rediseño tiene un solo aspecto. Mantener un tema claro no
/// aportaba nada y el fondo oscuro es lo que hace resaltar los paneles y los
/// botones.
class AppTheme {
  static const Color seedColor = Color(0xFF4361EE);
  static const Color accentShadow = Color(0xFF3146B5);

  /// Familia por defecto de toda la app. Es la tipografía arcade de Kenney.
  ///
  /// Es **+38% más ancha** que Poppins (medido sobre las tablas `hmtx` de los
  /// dos .ttf, no estimado). Por eso los `fontSize` de la app se redujeron ~15%
  /// en el mismo cambio: compensa parte del ancho sin que el texto quede chico,
  /// y al ser un factor uniforme mantiene la jerarquía entre tamaños. Si hay
  /// que ajustar más, el número a mover es el factor, no cada `fontSize`.
  ///
  /// La variante "Narrow" del pack no ayuda a esto: da el mismo ancho promedio.
  static const String fontFamily = 'Kenney Future';

  // --- Fondo -----------------------------------------------------------------
  //
  // Estos valores salen del rediseño (frame "Inicio y dificultad"), no del UI
  // Pack de Kenney: el rediseño combina las superficies navy del diseño con la
  // forma y la tipografía del pack.

  /// Base del fondo de todas las pantallas: el color raíz del frame.
  ///
  /// Es lo que se ve por detrás del degradado y el respaldo mientras pinta, y
  /// también `AppColors.background`, que la pausa usa como velo sobre el
  /// tablero. El degradado y la grilla los dibuja `GameBackground`.
  static const Color gameBackground = Color(0xFF05091C);

  /// Paradas del degradado vertical del fondo, de arriba hacia abajo.
  ///
  /// El punto medio va al 52% y no al 50%: así el azul se sostiene un poco más
  /// arriba del centro, que es como está en el frame.
  static const Color backdropTop = Color(0xFF08102C);
  static const Color backdropMiddle = Color(0xFF071328);
  static const Color backdropBottom = Color(0xFF030617);

  /// Paso de la grilla modular del fondo, en píxeles lógicos.
  static const double gridStep = 50;

  /// Líneas de la grilla. [gridLineAccent] marca una de cada cuatro: la grilla
  /// pareja se lee como una textura muerta y el acento le da un pulso cada
  /// 200 px, que es lo que la hace parecer un tablero y no un papel milimetrado.
  static const Color gridLine = Color(0x1754B8FF);
  static const Color gridLineAccent = Color(0x2E65D6FF);

  /// Colores de los dos glows del fondo (los "atmosphere" del frame).
  ///
  /// El frame los trae como dos SVG difusos; acá se reproducen con un
  /// `RadialGradient`, que es exactamente lo que esos SVG son. Los tonos están
  /// leídos del render del frame y no de un token de diseño, así que son lo
  /// primero a revisar si el fondo no coincide.
  static const Color backdropGlowUpper = Color(0xFF3D6BFF);
  static const Color backdropGlowLower = Color(0xFF1E7FA8);

  /// Velo de legibilidad: oscurece los extremos del fondo y deja limpio el
  /// centro. Sin él los glows y la grilla compiten con el texto y los botones.
  static const Color veilTop = Color(0x12020619);
  static const Color veilBottom = Color(0x66020619);

  // --- Superficies "arcade" --------------------------------------------------
  //
  // Las tarjetas y el switch del rediseño son **planos**, no sprites de Kenney.
  // El motivo está en `kenney_ui.dart`: los sprites del pack son mapas de
  // sombreado claros, y multiplicarlos por un navy tan oscuro como estos
  // aplasta el bisel hasta dejarlo en un bloque liso. El sprite se reserva para
  // lo que sí se tinta con un color vivo: los botones.

  /// Fondo de las tarjetas navy (tarjeta de mejor partida).
  static const Color arcadeSurface = Color(0xE8101B3D);

  /// Borde de esas tarjetas. Un azul claro con alfa muy bajo: no busca
  /// separarse del fondo, solo insinuar el canto.
  static const Color arcadeBorder = Color(0x336EA8FF);

  /// Radio de las tarjetas navy.
  static const double arcadeRadius = 22;

  /// Tinte de las tarjetas del HUD (Tiempo, Movimientos) y del pozo del
  /// tablero.
  ///
  /// Es el mismo navy que [arcadeSurface], pero **opaco**: `arcadeSurface` lleva
  /// alfa porque va como tarjeta sobre el degradado, mientras que el HUD tinta
  /// un sprite de Kenney y necesita un color sólido para que el `modulate` no
  /// deje traslucir la grilla de abajo.
  ///
  /// Se movió junto con el fondo: el valor viejo (#152B45) estaba elegido contra
  /// el patrón de baldosas, y sobre el navy nuevo se leía como un parche más
  /// claro pegado arriba de la escena.
  static const Color hudTint = Color(0xFF101B3D);

  /// Fondo y borde del track del switch de modo.
  static const Color switchTrack = Color(0xDE09132C);
  static const Color switchBorder = Color(0x2B5B7DFF);

  /// Píldora del modo activo en el switch.
  static const Color switchActive = Color(0xFF526BFF);

  /// Radio del track del switch y de su píldora.
  static const double switchRadius = 14;
  static const double switchPillRadius = 10;

  /// Botones cuadrados del header (menú y récords).
  static const Color headerButtonSurface = Color(0xB80D1836);
  static const Color headerButtonBorder = Color(0x306EA8FF);
  static const double headerButtonSize = 40;

  /// Acento cian del rediseño. Lo usan el "edición arcade" del header y el
  /// contador de movimientos de la tarjeta de récord.
  static const Color accentCyan = Color(0xFF60DEFF);

  // --- Modo Desafío ----------------------------------------------------------
  //
  // Los valores salen del frame "Modo desafío" (nodo `4:2689`). El fondo de esa
  // pantalla ya estaba: el frame "Layered arcade background" es el mismo que usa
  // el resto de la app, así que ahí no hay nada nuevo (ver `GameBackground`).

  /// Etiqueta azul apagada del frame: "TU PROGRESO", "SELECCIONÁ UN NIVEL" y el
  /// aviso de desbloqueo del pie.
  ///
  /// No se reusa `AppColors.textSecondary` (#94A3B8) aunque estén cerca: este es
  /// más azul, y sobre el navy del fondo la diferencia se ve.
  static const Color labelBlue = Color(0xFF94A8D4);

  /// Pastilla del ícono de bandera dentro de la tarjeta de progreso.
  static const Color challengeBadgeSurface = Color(0x2E536CFF);
  static const Color challengeBadgeBorder = Color(0x526F87FF);

  /// Track y valor de la barra de progreso.
  static const Color challengeTrack = Color(0xFF07112A);
  static const Color challengeValue = Color(0xFF6F75FF);

  /// Tarjetas de nivel. Son **claras** en los dos temas, así que el texto que va
  /// encima sale de los tokens `levelTileInk*` y no de `AppColors`.
  static const Color levelTile = Color(0xFFDDE4F2);

  /// La del nivel que se está jugando: un pelo más clara, con borde cian y halo.
  static const Color levelTileCurrent = Color(0xFFE7ECF8);
  static const double levelTileRadius = 10;

  /// Tinta del número del nivel y del "BLOQUEADO" sobre la tarjeta clara.
  static const Color levelTileInk = Color(0xFF17243B);
  static const Color levelTileLockedInk = Color(0xFF40536E);

  /// Número del nivel actual. Es el mismo violeta que [switchActive] por
  /// coincidencia de los frames, no por compartir rol: si el switch cambia de
  /// color, este no tiene por qué seguirlo.
  static const Color levelTileCurrentInk = Color(0xFF526BFF);

  /// Halo del nivel actual: `0 5 16 rgba(79,224,255,0.4)`.
  static const Color levelTileGlow = Color(0x664FE0FF);

  /// Barra de aviso de desbloqueo, al pie de la grilla.
  static const Color challengeHintSurface = Color(0xD90A1531);
  static const Color challengeHintBorder = Color(0x2154D7FF);

  /// Alto de las tarjetas de la grilla de niveles y proporción del frame
  /// (82,5 × 112 en el iPhone de 400). Se mantiene la proporción y no el alto:
  /// el ancho lo reparte la grilla según la pantalla.
  static const double levelTileAspectRatio = 82.5 / 112;

  // --- Colores de dificultad -------------------------------------------------
  //
  // Son los del frame. Tintan el sprite gris del botón por `BlendMode.modulate`
  // (ver `KenneySlice.decoration`), así que un solo sprite cubre los tres.
  // El texto que va encima es oscuro: el blanco sobre estos fondos falla WCAG
  // AA (el verde da ~2.5:1).

  static const Color difficultyEasy = Color(0xFF0FCB9A);
  static const Color difficultyMedium = Color(0xFFF0A10A);
  static const Color difficultyHard = Color(0xFFEE4B57);

  /// Color del tablero 6×6, que todavía no tiene botón (ver
  /// `lib/logic/dificultad.dart`). **Es provisional**: el frame solo define tres
  /// dificultades, así que este violeta es una extrapolación y hay que revisarlo
  /// contra un diseño antes de habilitar el botón.
  static const Color difficultyExpert = Color(0xFFA855F7);

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
      fontFamily: fontFamily,
      // Transparente a propósito: el fondo lo pinta `GameBackground`, que
      // envuelve la app entera desde `MaterialApp.builder` (ver main.dart). Si
      // el Scaffold pintara un color sólido, lo taparía en todas las pantallas.
      scaffoldBackgroundColor: Colors.transparent,
      textTheme: ThemeData.dark().textTheme.apply(fontFamily: fontFamily),
      extensions: const [AppColors.game],
    );
  }
}
