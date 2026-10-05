import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_info.dart';
import '../l10n/app_localizations.dart';
import '../logic/dificultad.dart';
import '../logic/puzzle_logic.dart';
import '../screens/challenge_levels_screen.dart';
import '../screens/game_screen.dart';
import '../screens/records_screen.dart';
import '../screens/settings_screen.dart';
import '../services/best_run_service.dart';
import '../services/daily_challenge_service.dart';
import '../services/records_service.dart';
import '../services/saved_game_service.dart';
import '../services/sound_service.dart';
import '../theme/app_theme.dart';
import '../theme/kenney_ui.dart';
import '../widgets/arcade_button.dart';
import '../widgets/best_run_card.dart';
import '../widgets/daily_results_dialog.dart';
import '../widgets/difficulty_button.dart';
import '../widgets/home_header.dart';
import '../widgets/mode_switch.dart';

/// Violeta del Desafío Diario. Está acá y no en `AppTheme` porque es el único
/// lugar que lo usa; el frame no incluye este botón, así que el color es el que
/// ya tenía la pantalla.
const Color _tinteDiario = Color(0xFF8B5CF6);

/// Pantalla de inicio con selección de dificultad.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final AppLifecycleListener _lifecycleListener;

  /// Partida en curso pendiente de retomar, o `null` si no hay ninguna.
  PartidaGuardada? _partidaGuardada;

  /// Si el jugador ya completó el Desafío Diario de hoy (según la fecha UTC).
  /// Arranca en `false` y se corrige apenas se lee el disco.
  bool _jugoDiarioHoy = false;

  /// La mejor partida del tablero vigente, para la tarjeta del menú. `null`
  /// mientras el jugador no haya completado ninguna partida libre.
  MejorPartida? _mejorPartida;

  @override
  void initState() {
    super.initState();
    SoundService.iniciarMusica();

    _lifecycleListener = AppLifecycleListener(
      // Al volver del segundo plano se relee el candado del diario: si la app
      // quedó abierta toda la noche, el día UTC pudo cambiar mientras tanto y
      // el botón tiene que reflejarlo sin reiniciar la app.
      onResume: () {
        SoundService.reanudarMusica();
        _cargarEstadoDiario();
      },
      onHide: SoundService.pausarMusica,
      onPause: SoundService.pausarMusica,
    );

    _cargarPartidaGuardada();
    _cargarEstadoDiario();
    _cargarMejorPartida();
    _refrescarMejorPartidaDesdeFirestore();

    // Esperamos la primera frame para no mostrar el modal durante el arranque.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _verificarCalificacion();
    });
  }

  /// Relee si el Desafío Diario de hoy ya fue completado.
  Future<void> _cargarEstadoDiario() async {
    final jugo = await DailyChallengeService.yaJugoHoy();
    if (!mounted) return;
    setState(() => _jugoDiarioHoy = jugo);
  }

  /// Relee la partida guardada. Se llama al arrancar y cada vez que se vuelve
  /// del juego, porque salir con el botón Atrás deja una partida pendiente.
  Future<void> _cargarPartidaGuardada() async {
    final partida = await SavedGameService.obtener();
    if (!mounted) return;
    setState(() => _partidaGuardada = partida);
  }

  /// Relee la marca local del menú. Igual que la partida guardada, se refresca
  /// al volver del juego porque ahí es donde pudo haberse superado —o donde pudo
  /// haber cambiado el tablero vigente, que es lo que decide cuál se muestra.
  Future<void> _cargarMejorPartida() async {
    final marca = await BestRunService.obtenerVigente();
    if (!mounted) return;
    setState(() => _mejorPartida = marca);
  }

  /// Pide a Firestore una marca mejor que la local.
  ///
  /// Corre por detrás y sin bloquear el primer pintado: la tarjeta se dibuja ya
  /// con lo que haya en disco, y si la red trae algo mejor se actualiza sola.
  /// Nunca lanza, así que no hace falta proteger la llamada.
  Future<void> _refrescarMejorPartidaDesdeFirestore() async {
    final marca = await BestRunService.refrescarDesdeFirestore();
    if (!mounted || marca == null) return;
    setState(() => _mejorPartida = marca);
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    SoundService.detenerMusica();
    super.dispose();
  }

  /// Si el usuario todavía no calificó la app, muestra el modal de calificación.
  Future<void> _verificarCalificacion() async {
    final yaCalifico = await RecordsService.yaCalificoApp();
    if (!mounted || yaCalifico) return;
    _mostrarCalificacion();
  }

  /// Modal que invita a calificar la app en Google Play.
  void _mostrarCalificacion() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final colors = Theme.of(dialogContext).extension<AppColors>()!;
        final l10n = AppLocalizations.of(dialogContext)!;
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            l10n.rateTitle,
            style: const TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.star_rounded,
                size: 56,
                color: Color(0xFFF59E0B),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.rateBody,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
          actions: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.seedColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(dialogContext);
                      _marcarYAbirTienda();
                    },
                    child: Text(
                      l10n.rateButton,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(
                    l10n.notNow,
                    style: TextStyle(color: colors.textSecondary),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  /// Marca que el usuario ya calificó (aunque el launch falle, no volvemos a
  /// preguntar) y abre la tienda fuera de la app.
  Future<void> _marcarYAbirTienda() async {
    await RecordsService.marcarAppCalificada();

    final uri = Uri.parse(urlPlayStore);
    try {
      final abierto = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!abierto && mounted) {
        _avisarFalloTienda();
      }
    } catch (_) {
      if (mounted) _avisarFalloTienda();
    }
  }

  void _avisarFalloTienda() {
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(l10n.playStoreError),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  /// Muestra el aviso simplificado de privacidad del Top 5 Global.
  void _mostrarPrivacidad() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final colors = Theme.of(dialogContext).extension<AppColors>()!;
        final l10n = AppLocalizations.of(dialogContext)!;
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          icon: const Icon(
            Icons.privacy_tip_rounded,
            size: 48,
            color: AppTheme.seedColor,
          ),
          title: Text(
            l10n.privacyTitle,
            style: const TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          content: Text(
            l10n.privacyBody,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: colors.textSecondary,
            ),
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.seedColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(
                  l10n.understood,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _abrirAjustes() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
  }

  void _abrirRecords() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RecordsScreen()),
    );
  }

  void _navegarAJuego(BuildContext context, int size) async {
    // Pausamos la música del menú antes de entrar al juego.
    await SoundService.pausarMusica();
    if (!context.mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => GameScreen(size: size)),
    );
    // Al volver del juego, reanudamos la música del menú y releemos la partida
    // guardada: salir con el botón Atrás deja una partida pendiente que debe
    // aparecer como "Continuar Partida". La marca del menú también se relee,
    // porque ganar la acaba de actualizar en disco.
    SoundService.reanudarMusica();
    await _cargarPartidaGuardada();
    await _cargarMejorPartida();
  }

  /// Retoma la partida guardada donde quedó.
  Future<void> _continuarPartida(PartidaGuardada partida) async {
    // Pausamos la música del menú antes de entrar al juego, igual que al
    // arrancar una partida nueva.
    await SoundService.pausarMusica();
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GameScreen(
          size: partida.size,
          nivelDesafio: partida.nivel,
          partidaInicial: partida,
        ),
      ),
    );
    SoundService.reanudarMusica();
    await _cargarPartidaGuardada();
    await _cargarMejorPartida();
  }

  /// Descarta la partida guardada sin entrar al juego.
  ///
  /// Se borra primero de disco y recién después se actualiza la UI: si se
  /// ocultara la tarjeta antes y el borrado fallara, la partida reaparecería al
  /// volver al menú.
  Future<void> _descartarPartidaGuardada() async {
    await SavedGameService.borrar();
    if (!mounted) return;
    setState(() => _partidaGuardada = null);
  }

  void _navegarADesafio(BuildContext context) async {
    // No pausamos la música: HomeScreen sigue montada y la grilla comparte la
    // música del menú. La pausa ocurre recién al entrar a una partida, dentro
    // de ChallengeLevelsScreen (mismo patrón que _navegarAJuego).
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ChallengeLevelsScreen()),
    );
  }

  /// Acción del botón del Desafío Diario.
  ///
  /// Si el jugador todavía no jugó hoy, entra al tablero del día. El modo
  /// diario de `GameScreen` está aislado del Top 5 global de Firestore, así que
  /// resolverlo no ensucia el ranking de las partidas clásicas.
  Future<void> _onTapDiario() async {
    if (_jugoDiarioHoy) {
      // El candado cerrado significa que jugó HOY (así lo compara
      // `yaJugoHoy`), así que el día a mostrar es el de hoy.
      await DailyResultsDialog.mostrar(
        context,
        semilla: DailyChallengeService.semillaHoy,
      );
      return;
    }

    // Pausamos la música del menú antes de entrar, igual que en los otros
    // modos; GameScreen la reanuda al arrancar su propia partida.
    await SoundService.pausarMusica();
    if (!mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const GameScreen(
          size: PuzzleLogic.diarioSize,
          esDiario: true,
        ),
      ),
    );

    // Al volver se reanuda la música y se relee el candado: si el jugador
    // completó el desafío, el botón tiene que decir ya mismo "Ver Resultados
    // del Día" y no esperar a que se reinicie la app.
    SoundService.reanudarMusica();
    await _cargarEstadoDiario();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      // Sin `backgroundColor`: el fondo lo pinta `GameBackground`
      // desde `MaterialApp.builder`. Ver `AppTheme.game`.
      body: SafeArea(
        // El `AppBar` se fue con el rediseño: el header lo dibuja la pantalla y
        // el `SafeArea` es lo que evita que se meta bajo la barra de estado.
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: Padding(
                      // Los márgenes del frame: 20 a los costados y 30 abajo.
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
                      child: Column(
                        // Arriba, como el frame: el contenido no se centra en la
                        // pantalla, así queda a la vista la grilla del fondo.
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          HomeHeader(
                            onAjustes: _abrirAjustes,
                            onPrivacidad: _mostrarPrivacidad,
                            onRecords: _abrirRecords,
                          ),
                          const SizedBox(height: 18),
                          // La partida pendiente va primero: retomar es lo más
                          // probable para alguien que vuelve al menú.
                          if (_partidaGuardada case final partida?) ...[
                            _BotonContinuar(
                              partida: partida,
                              onTap: () => _continuarPartida(partida),
                              onDescartar: _descartarPartidaGuardada,
                            ),
                            const SizedBox(height: 12),
                          ],
                          BestRunCard(marca: _mejorPartida),
                          const SizedBox(height: 18),
                          _IntroDificultad(l10n: l10n),
                          const SizedBox(height: 12),
                          for (final dificultad in Dificultad.jugables) ...[
                            DifficultyButton(
                              dificultad: dificultad,
                              onTap: () =>
                                  _navegarAJuego(context, dificultad.tamano),
                            ),
                            const SizedBox(height: 12),
                          ],
                          const SizedBox(height: 6),
                          ModeSwitch(
                            onDesafio: () => _navegarADesafio(context),
                          ),
                          const SizedBox(height: 12),
                          ArcadeButton(
                            onTap: _onTapDiario,
                            tint: _tinteDiario,
                            icono: Icons.calendar_month_rounded,
                            titulo: _jugoDiarioHoy
                                ? l10n.dailyChallengePlayed
                                : l10n.dailyChallenge,
                            subtitulo: _jugoDiarioHoy
                                ? l10n.dailyChallengePlayedSubtitle
                                : l10n.dailyChallengeSubtitle,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Título y bajada de la selección de dificultad.
class _IntroDificultad extends StatelessWidget {
  const _IntroDificultad({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Column(
      children: [
        Text(
          l10n.chooseDifficulty.toUpperCase(),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          l10n.difficultyIntro,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: colors.textMuted),
        ),
      ],
    );
  }
}

/// Botón destacado del menú para retomar la partida que quedó a medias.
///
/// Toda la tarjeta retoma la partida; la "X" de la derecha la descarta. El
/// `IconButton` anidado gana el gesto sobre el `InkWell` exterior, así que
/// descartar nunca dispara también el "continuar".
class _BotonContinuar extends StatelessWidget {
  final PartidaGuardada partida;
  final VoidCallback onTap;
  final VoidCallback onDescartar;

  const _BotonContinuar({
    required this.partida,
    required this.onTap,
    required this.onDescartar,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // En el Modo Desafío no hay cronómetro, así que el tiempo no se muestra.
    final detalle = partida.esDesafio
        ? l10n.continueChallengeDetail(partida.nivel!, partida.movimientos)
        : l10n.continueFreeDetail(
            partida.size,
            partida.movimientos,
            partida.segundos,
          );

    return Semantics(
      button: true,
      label: l10n.continueGameSemantics(detalle),
      // El `Material` va transparente y por dentro del sprite: así la tinta del
      // `InkWell` se pinta arriba del fondo en vez de taparlo.
      child: KenneySurface(
        slice: KenneySlices.primaryButton,
        tint: AppTheme.seedColor,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 16),
              child: Row(
                children: [
                const Icon(
                  Icons.play_circle_fill_rounded,
                  color: Colors.white,
                  size: 38,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.continueGame.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        detalle,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onDescartar,
                  tooltip: l10n.discardGameTooltip,
                  icon: Icon(
                    Icons.close_rounded,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
