import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../screens/game_screen.dart';
import '../screens/records_screen.dart';
import '../widgets/difficulty_button.dart';

/// Pantalla de inicio con selección de dificultad.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _navegarAJuego(BuildContext context, int size) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => GameScreen(size: size)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
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
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Elegí una dificultad',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: const Color(0xFF64748B),
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
                    color: Color(0xFF4361EE),
                  ),
                  label: Text(
                    'Ver récords',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF4361EE),
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
