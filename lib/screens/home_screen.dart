import 'package:flutter/material.dart';

import '../screens/game_screen.dart';
import '../screens/records_screen.dart';
import '../screens/settings_screen.dart';
import '../services/sound_service.dart';
import '../theme/app_theme.dart';
import '../widgets/difficulty_button.dart';

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
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    SoundService.detenerMusica();
    super.dispose();
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
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🧩', style: TextStyle(fontSize: 64)),
                const SizedBox(height: 16),
                Text(
                  'Sliding Puzzle',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Elegí una dificultad',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 48),
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
                const SizedBox(height: 32),
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RecordsScreen()),
                    );
                  },
                  icon: const Icon(
                    Icons.emoji_events,
                    color: AppTheme.seedColor,
                  ),
                  label: const Text(
                    'Ver récords',
                    style: TextStyle(
                      fontFamily: 'Poppins',
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
    );
  }
}
