import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../screens/challenge_levels_screen.dart';
import '../screens/game_screen.dart';
import '../screens/records_screen.dart';
import '../screens/settings_screen.dart';
import '../services/records_service.dart';
import '../services/saved_game_service.dart';
import '../services/sound_service.dart';
import '../theme/app_theme.dart';
import '../widgets/difficulty_button.dart';

/// URL de la ficha de la app en Google Play.
const String _urlPlayStore =
    'https://play.google.com/store/apps/details?id=dev.matute.slidingpuzzle';

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

  @override
  void initState() {
    super.initState();
    SoundService.iniciarMusica();

    _lifecycleListener = AppLifecycleListener(
      onResume: SoundService.reanudarMusica,
      onHide: SoundService.pausarMusica,
      onPause: SoundService.pausarMusica,
    );

    _cargarPartidaGuardada();

    // Esperamos la primera frame para no mostrar el modal durante el arranque.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _verificarCalificacion();
    });
  }

  /// Relee la partida guardada. Se llama al arrancar y cada vez que se vuelve
  /// del juego, porque salir con el botón Atrás deja una partida pendiente.
  Future<void> _cargarPartidaGuardada() async {
    final partida = await SavedGameService.obtener();
    if (!mounted) return;
    setState(() => _partidaGuardada = partida);
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
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            '¿Te gusta Sliding Puzzle?',
            style: TextStyle(fontWeight: FontWeight.bold),
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
                'Tu opinión nos ayuda a seguir mejorando el juego. '
                '¿Nos dejarías una calificación en Google Play?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
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
                    child: const Text(
                      'Calificar en Play Store',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(
                    'Ahora no',
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

    final uri = Uri.parse(_urlPlayStore);
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
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('No se pudo abrir Google Play'),
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
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          icon: const Icon(
            Icons.privacy_tip_rounded,
            size: 48,
            color: AppTheme.seedColor,
          ),
          title: const Text(
            'Privacidad y Datos',
            style: TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          content: Text(
            'Para el Top 5 Global, el juego guarda únicamente tu Alias y tu '
            'mejor puntuación de forma anónima.\n\n'
            'No solicitamos correos, contraseñas ni datos de tu dispositivo. '
            'Podés participar con total tranquilidad.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
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
                child: const Text(
                  'Entendido',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        );
      },
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
    // aparecer como "Continuar Partida".
    SoundService.reanudarMusica();
    await _cargarPartidaGuardada();
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

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Privacidad y datos',
            icon: Icon(Icons.privacy_tip_outlined, color: colors.textPrimary),
            onPressed: _mostrarPrivacidad,
          ),
          IconButton(
            tooltip: 'Configuración',
            icon: Icon(Icons.settings_outlined, color: colors.textPrimary),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      // Scroll + minHeight: mantiene el contenido centrado cuando entra en
      // pantalla y permite scrollear en pantallas cortas / landscape.
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 24,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.extension_rounded,
                          size: 64,
                          color: AppTheme.seedColor,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Sliding Puzzle',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Partida pendiente: se ofrece retomarla antes de las
                        // dificultades, que arrancan una partida nueva.
                        if (_partidaGuardada case final partida?) ...[
                          const SizedBox(height: 8),
                          _BotonContinuar(
                            partida: partida,
                            onTap: () => _continuarPartida(partida),
                            onDescartar: _descartarPartidaGuardada,
                          ),
                          const SizedBox(height: 24),
                        ],
                        Text(
                          'Elegí una dificultad',
                          style: TextStyle(
                            fontSize: 16,
                            color: colors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        DifficultyButton(
                          label: 'Fácil',
                          descripcion: 'Tablero 3x3',
                          color: const Color(0xFF10B981),
                          onTap: () => _navegarAJuego(context, 3),
                        ),
                        const SizedBox(height: 16),
                        DifficultyButton(
                          label: 'Medio',
                          descripcion: 'Tablero 4x4',
                          color: const Color(0xFFF59E0B),
                          onTap: () => _navegarAJuego(context, 4),
                        ),
                        const SizedBox(height: 16),
                        DifficultyButton(
                          label: 'Difícil',
                          descripcion: 'Tablero 5x5',
                          color: const Color(0xFFEF4444),
                          onTap: () => _navegarAJuego(context, 5),
                        ),
                        const SizedBox(height: 48),
                        DifficultyButton(
                          label: 'Modo Desafío',
                          descripcion: '20 niveles · ganá 3 estrellas',
                          color: AppTheme.seedColor,
                          foregroundColor: Colors.white,
                          onTap: () => _navegarADesafio(context),
                        ),
                        const SizedBox(height: 32),
                        TextButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const RecordsScreen(),
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.emoji_events,
                            color: AppTheme.seedColor,
                          ),
                          label: const Text(
                            'Ver récords',
                            style: TextStyle(
                              color: AppTheme.seedColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
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
    // En el Modo Desafío no hay cronómetro, así que el tiempo no se muestra.
    final detalle = partida.esDesafio
        ? 'Desafío · Nivel ${partida.nivel} · ${partida.movimientos} movs'
        : 'Tablero ${partida.size}x${partida.size} · '
            '${partida.movimientos} movs · ${partida.segundos}s';

    return Semantics(
      button: true,
      label: 'Continuar partida. $detalle',
      child: Material(
        color: AppTheme.seedColor,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
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
                      const Text(
                        'Continuar Partida',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        detalle,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onDescartar,
                  tooltip: 'Descartar partida',
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
    );
  }
}
