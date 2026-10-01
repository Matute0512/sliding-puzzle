import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import '../logic/puzzle_logic.dart';
import '../services/records_service.dart';
import '../services/sound_service.dart';
import '../theme/app_theme.dart';
import '../theme/kenney_ui.dart';
import '../widgets/arcade_panel.dart';
import '../widgets/header_square_button.dart';
import 'game_screen.dart';
import 'records_screen.dart';

/// Pantalla del Modo Desafío: una campaña de 20 niveles (1 a 10 en 3x3,
/// 11 a 20 en 4x4) con un objetivo de movimientos y hasta 3 estrellas por
/// nivel. Muestra el progreso desbloqueado, las mejores estrellas por nivel
/// y candados en los niveles todavía bloqueados.
///
/// El layout sale del frame "Modo desafío" (nodo `4:2689`). Del frame **no** se
/// implementaron el status bar de iOS ni el home indicator: son *chrome* de
/// mockup, no parte de la app. El frame tampoco trae fondo propio —usa el
/// "Layered arcade background" que ya pinta `GameBackground` en toda la app—,
/// así que acá no hay nada que hacer por ese lado.
///
/// Dos diferencias con el frame, las dos deliberadas:
///
/// - La grilla del frame muestra 12 niveles en 3 filas; el Desafío tiene 20, así
///   que scrollea. El aviso del pie queda fuera del scroll, fijo abajo.
/// - Kenney Future es ~38% más ancha que la Inter con la que está medido el
///   frame, así que los cuerpos de texto bajan uno o dos puntos. Es el mismo
///   ajuste que se hizo en el resto de la app.
class ChallengeLevelsScreen extends StatefulWidget {
  const ChallengeLevelsScreen({super.key});

  @override
  State<ChallengeLevelsScreen> createState() => _ChallengeLevelsScreenState();
}

class _ChallengeLevelsScreenState extends State<ChallengeLevelsScreen> {
  static const int _cantidadNiveles = 20;

  int _nivelMaximo = 1;
  Map<int, int> _estrellas = const {};
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarProgreso();
  }

  Future<void> _cargarProgreso() async {
    // Cargamos ambos en paralelo y refrescamos la grilla.
    final futuroNivel = RecordsService.obtenerNivelMaximo();
    final futuroEstrellas = RecordsService.obtenerEstrellas();
    final nivel = await futuroNivel;
    final estrellas = await futuroEstrellas;
    if (!mounted) return;
    setState(() {
      _nivelMaximo = nivel;
      _estrellas = estrellas;
      _cargando = false;
    });
  }

  /// Encadena niveles desde [nivelInicial] jugando con una pausa de música por
  /// partida. El GameScreen informa con `true` cuando el jugador pidió "Siguiente
  /// Nivel"; la grilla avanza sola hasta que el jugador vuelve (y recarga).
  Future<void> _jugarNiveles(int nivelInicial) async {
    var nivel = nivelInicial;
    await SoundService.pausarMusica();
    if (!mounted) return;
    // Capturamos el navigator una vez para no usar el BuildContext a través de
    // las pausas asíncronas del bucle (lint use_build_context_synchronously).
    final navigator = Navigator.of(context);
    while (mounted) {
      final config = PuzzleLogic.configuracionNivel(nivel);
      final avanzar = await navigator.push<bool>(
        MaterialPageRoute(
          builder: (_) => GameScreen(size: config.size, nivelDesafio: nivel),
        ),
      );
      if (!mounted) return;
      // Al volver de una partida, refrescamos progreso y música del menú.
      if (avanzar != true || nivel >= _cantidadNiveles) break;
      nivel++;
    }
    SoundService.reanudarMusica();
    await _cargarProgreso();
  }

  void _tocarNivel(int nivel) {
    if (nivel <= _nivelMaximo) {
      _jugarNiveles(nivel);
      return;
    }
    // Nivel bloqueado: feedback táctil + aviso.
    HapticFeedback.vibrate();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.levelLocked),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
  }

  void _abrirRecords() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RecordsScreen()),
    );
  }

  /// Si el nivel 20 ya tiene estrellas, la campaña terminó. No alcanza con
  /// `_nivelMaximo == _cantidadNiveles`: eso solo dice que el 20 está
  /// **desbloqueado**, no ganado, y en esa ventana el aviso del pie mentiría.
  bool get _campanaCompleta => (_estrellas[_cantidadNiveles] ?? 0) > 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      // Sin `backgroundColor`: el fondo lo pinta `GameBackground`
      // desde `MaterialApp.builder`. Ver `AppTheme.game`.
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              children: [
                _CabeceraDesafio(
                  onVolver: () => Navigator.of(context).pop(),
                  onRecords: _abrirRecords,
                ),
                Expanded(
                  // La cabecera se pinta siempre: mientras carga, lo único que
                  // falta es la grilla, y dejar el header evita el salto de
                  // layout cuando llega el progreso.
                  child: _cargando
                      ? const Center(child: CircularProgressIndicator())
                      : Padding(
                          padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
                          child: Column(
                            children: [
                              _TarjetaProgreso(
                                nivelMaximo: _nivelMaximo,
                                totalNiveles: _cantidadNiveles,
                                totalEstrellas: _estrellas.values.fold(
                                  0,
                                  (a, b) => a + b,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                l10n.selectLevel.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.labelBlue,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Expanded(
                                child: GridView.builder(
                                  padding: EdgeInsets.zero,
                                  // 4 columnas fijas, como el frame, en vez del
                                  // `maxCrossAxisExtent` de antes: con el ancho
                                  // del frame caían 4, pero en una pantalla más
                                  // ancha entraban 5 y la grilla dejaba de
                                  // parecerse al diseño.
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 4,
                                    mainAxisSpacing: 10,
                                    crossAxisSpacing: 10,
                                    childAspectRatio:
                                        AppTheme.levelTileAspectRatio,
                                  ),
                                  itemCount: _cantidadNiveles,
                                  itemBuilder: (context, i) {
                                    final nivel = i + 1;
                                    final bloqueado = nivel > _nivelMaximo;
                                    return _CeldaNivel(
                                      nivel: nivel,
                                      estrellas: _estrellas[nivel] ?? 0,
                                      bloqueado: bloqueado,
                                      esActual:
                                          !bloqueado && nivel == _nivelMaximo,
                                      onTap: () => _tocarNivel(nivel),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 16),
                              _AvisoDesbloqueo(
                                texto: _campanaCompleta
                                    ? l10n.challengeComplete
                                    : _nivelMaximo >= _cantidadNiveles
                                        ? l10n.challengeFinalLevel
                                        : l10n.unlockNextLevel(_nivelMaximo),
                              ),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Header del Modo Desafío: volver, título y récords.
///
/// Reemplaza al `AppBar` que tenía la pantalla. El `AppBar` sumaba una altura y
/// traía un `leading` y un `actions` con su propio layout, cuando el frame ya
/// define los dos cuadrados y el título centrado —los mismos de `HomeHeader`.
class _CabeceraDesafio extends StatelessWidget {
  const _CabeceraDesafio({required this.onVolver, required this.onRecords});

  final VoidCallback onVolver;
  final VoidCallback onRecords;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        height: 56,
        child: Row(
          children: [
            HeaderSquareButton(
              // El tooltip de volver ya viene traducido por Material.
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              onTap: onVolver,
              child: KenneyIcon(
                KenneySlices.arrowWest,
                size: 19,
                tint: colors.textPrimary,
              ),
            ),
            // `Expanded` en el medio y botones del mismo ancho a los costados:
            // así el título queda centrado en la pantalla y no en el espacio
            // libre. Mismo criterio que `HomeHeader`.
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    // El título del frame es "DESAFÍO" a secas, no "Modo
                    // Desafío": el "Desafío Diario" es otra cosa y conviene no
                    // confundirlos en el header.
                    l10n.challengeTab.toUpperCase(),
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 17,
                      height: 1.2,
                      fontWeight: FontWeight.w800,
                      color: colors.textPrimary,
                    ),
                  ),
                  Text(
                    l10n.challengeCircuit.toUpperCase(),
                    maxLines: 1,
                    style: const TextStyle(
                      fontSize: 9,
                      height: 1.2,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.accentCyan,
                    ),
                  ),
                ],
              ),
            ),
            HeaderSquareButton(
              tooltip: l10n.viewRecords,
              onTap: onRecords,
              child: Icon(
                Icons.emoji_events_rounded,
                size: 18,
                color: colors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tarjeta de progreso: bandera, "tu progreso" con la barra, y estrellas.
///
/// Va sobre [ArcadePanel] y no sobre un sprite de Kenney: la superficie es navy
/// oscura y el pack se aplasta con ese tinte (ver `ArcadePanel`). Por lo mismo,
/// el texto de adentro sale de `AppColors` y no de `KenneyInk`.
class _TarjetaProgreso extends StatelessWidget {
  const _TarjetaProgreso({
    required this.nivelMaximo,
    required this.totalNiveles,
    required this.totalEstrellas,
  });

  final int nivelMaximo;
  final int totalNiveles;
  final int totalEstrellas;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final l10n = AppLocalizations.of(context)!;

    return ArcadePanel(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      radius: 18,
      child: SizedBox(
        height: 72,
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppTheme.challengeBadgeSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.challengeBadgeBorder),
              ),
              child: const Center(
                child: Icon(
                  Icons.flag_rounded,
                  size: 19,
                  color: AppTheme.accentCyan,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        l10n.challengeProgressLabel.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.labelBlue,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        l10n.levelProgress(nivelMaximo),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.accentCyan,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  _BarraProgreso(
                    // Sobre los niveles y no sobre las estrellas: el número que
                    // tiene al lado es `nivelMaximo / 20`, y una barra que
                    // midiera otra cosa se leería como un error.
                    //
                    // El frame la dibuja a 116 px de un track de ~218 (53%) con
                    // "8 / 20" al lado (40%), así que el mockup no es
                    // internamente consistente; manda la etiqueta.
                    progreso: nivelMaximo / totalNiveles,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Row(
              children: [
                // El sprite de la estrella es la máscara gris, así que el ámbar
                // va por tinte.
                const KenneyIcon(
                  KenneySlices.star,
                  size: 15,
                  tint: AppTheme.podiumGold,
                ),
                const SizedBox(width: 5),
                Text(
                  '$totalEstrellas',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: colors.textPrimary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Track y valor de la barra de progreso del frame.
class _BarraProgreso extends StatelessWidget {
  const _BarraProgreso({required this.progreso});

  final double progreso;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: SizedBox(
        height: 6,
        child: ColoredBox(
          color: AppTheme.challengeTrack,
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progreso.clamp(0.0, 1.0),
            child: const ColoredBox(color: AppTheme.challengeValue),
          ),
        ),
      ),
    );
  }
}

/// Celda de un nivel de la grilla: número, candado si está bloqueado y las
/// estrellas obtenidas (ámbar las ganadas, contorno las pendientes).
class _CeldaNivel extends StatelessWidget {
  final int nivel;
  final int estrellas;
  final bool bloqueado;
  final bool esActual;
  final VoidCallback onTap;

  const _CeldaNivel({
    required this.nivel,
    required this.estrellas,
    required this.bloqueado,
    required this.esActual,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Semantics(
      button: true,
      label: bloqueado
          ? l10n.levelLockedSemantics(nivel)
          : l10n.levelStarsSemantics(nivel, estrellas),
      // La celda es un sprite cuadrado de Kenney **claro** en los dos temas, así
      // que la tinta de adentro sale de los tokens `levelTileInk*` y no de
      // `AppColors`.
      //
      // El nivel bloqueado se atenúa entero con `Opacity` en vez de cambiar el
      // color de fondo: el sprite no se recolorea por tema, y así se lee
      // "apagado" sin tener que mantener un segundo sprite solo para el estado
      // bloqueado.
      //
      // El `Material` transparente por dentro del sprite es para que la tinta
      // del `InkWell` se pinte encima del fondo en vez de taparlo.
      child: Opacity(
        opacity: bloqueado ? 0.55 : 1,
        child: DecoratedBox(
          // El halo va en un `DecoratedBox` por fuera del sprite porque
          // `KenneySurface` no proyecta sombra, y el resplandor cian es la única
          // señal de "estás acá" que el frame le da al nivel actual.
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.levelTileRadius),
            boxShadow: esActual
                ? const [
                    BoxShadow(
                      color: AppTheme.levelTileGlow,
                      blurRadius: 16,
                      offset: Offset(0, 5),
                    ),
                  ]
                : null,
          ),
          child: KenneySurface(
            slice: KenneySlices.flatSquare,
            tint: esActual ? AppTheme.levelTileCurrent : AppTheme.levelTile,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius:
                        BorderRadius.circular(AppTheme.levelTileRadius),
                    border: esActual
                        ? Border.all(color: AppTheme.accentCyan, width: 2)
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (bloqueado)
                        const Icon(
                          Icons.lock_outline_rounded,
                          color: AppTheme.levelTileLockedInk,
                          size: 21,
                        )
                      else
                        Text(
                          '$nivel',
                          style: TextStyle(
                            // 18 y no los 20 del frame, por el ancho de Kenney
                            // Future. Ver `HomeHeader`.
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: esActual
                                ? AppTheme.levelTileCurrentInk
                                : AppTheme.levelTileInk,
                          ),
                        ),
                      const SizedBox(height: 10),
                      if (bloqueado)
                        Text(
                          l10n.locked.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.levelTileLockedInk,
                          ),
                        )
                      else
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Estrella ámbar la ganada, contorno gris la
                            // pendiente. La estrella del pack es la máscara
                            // gris, así que el ámbar va por tinte; el contorno
                            // ya es gris de fábrica.
                            for (var i = 0; i < 3; i++)
                              KenneyIcon(
                                i < estrellas
                                    ? KenneySlices.star
                                    : KenneySlices.starOutline,
                                size: 15,
                                tint:
                                    i < estrellas ? AppTheme.podiumGold : null,
                              ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Aviso del pie: qué falta para desbloquear el nivel siguiente.
///
/// Queda fijo abajo mientras la grilla scrollea: con 20 niveles la grilla no
/// entra, y el aviso es lo último que conviene perder de vista.
class _AvisoDesbloqueo extends StatelessWidget {
  const _AvisoDesbloqueo({required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    return ArcadePanel(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      color: AppTheme.challengeHintSurface,
      borderColor: AppTheme.challengeHintBorder,
      radius: 14,
      // El aviso está apoyado sobre el contenido, no flotando: misma razón por
      // la que el switch de modo apaga la sombra.
      shadow: false,
      child: SizedBox(
        height: 52,
        child: Row(
          children: [
            const Icon(
              Icons.lock_open_rounded,
              size: 17,
              color: AppTheme.labelBlue,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                texto,
                style: const TextStyle(
                  fontSize: 10,
                  height: 1.4,
                  color: AppTheme.labelBlue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
