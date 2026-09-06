import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../screens/challenge_levels_screen.dart';
import '../screens/game_screen.dart';
import '../screens/records_screen.dart';
import '../screens/settings_screen.dart';
import '../services/records_service.dart';
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

  @override
  void initState() {
    super.initState();
    SoundService.iniciarMusica();

    _lifecycleListener = AppLifecycleListener(
      onResume: SoundService.reanudarMusica,
      onHide: SoundService.pausarMusica,
      onPause: SoundService.pausarMusica,
    );

    // Esperamos la primera frame para no mostrar el modal durante el arranque.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _verificarCalificacion();
    });
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

  void _navegarAJuego(BuildContext context, int size) async {
    // Pausamos la música del menú antes de entrar al juego.
    await SoundService.pausarMusica();
    if (!context.mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => GameScreen(size: size)),
    );
    // Al volver del juego, reanudamos la música del menú.
    SoundService.reanudarMusica();
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
