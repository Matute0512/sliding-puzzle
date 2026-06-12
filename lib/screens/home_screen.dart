import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../screens/game_screen.dart';
import '../screens/records_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/difficulty_button.dart';

/// Pantalla de inicio con selección de dificultad.
class HomeScreen extends StatelessWidget {
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeChanged;

  const HomeScreen({
    super.key,
    required this.themeMode,
    required this.onThemeChanged,
  });

  void _navegarAJuego(BuildContext context, int size) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => GameScreen(size: size)),
    );
  }

  ThemeMode _siguienteModo(ThemeMode actual) {
    switch (actual) {
      case ThemeMode.light:
        return ThemeMode.dark;
      case ThemeMode.dark:
        return ThemeMode.system;
      case ThemeMode.system:
        return ThemeMode.light;
    }
  }

  IconData _iconoParaModo(ThemeMode modo) {
    switch (modo) {
      case ThemeMode.light:
        return Icons.light_mode;
      case ThemeMode.dark:
        return Icons.dark_mode;
      case ThemeMode.system:
        return Icons.brightness_auto;
    }
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
            tooltip: 'Cambiar tema',
            icon: Icon(_iconoParaModo(themeMode), color: colors.textPrimary),
            onPressed: () => onThemeChanged(_siguienteModo(themeMode)),
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
                  style: GoogleFonts.poppins(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Elegí una dificultad',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 48),
                DifficultyButton(
                  label: '😊  Fácil',
                  descripcion: 'Tablero 3x3',
                  color: const Color(0xFF10B981),
                  onTap: () => _navegarAJuego(context, 3),
                ),
                const SizedBox(height: 16),
                DifficultyButton(
                  label: '😤  Medio',
                  descripcion: 'Tablero 4x4',
                  color: const Color(0xFFF59E0B),
                  onTap: () => _navegarAJuego(context, 4),
                ),
                const SizedBox(height: 16),
                DifficultyButton(
                  label: '💀  Difícil',
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
                  label: Text(
                    'Ver récords',
                    style: GoogleFonts.poppins(
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
