import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'game_screen.dart';
import 'records_screen.dart';

void main() {
  runApp(const SlidingPuzzleApp());
}

class SlidingPuzzleApp extends StatelessWidget {
  const SlidingPuzzleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sliding Puzzle',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4361EE)),
        useMaterial3: true,
        // Poppins como fuente global
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
      home: const HomeScreen(),
    );
  }
}

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
                // Logo / título
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
                _BotonDificultad(
                  label: '😊  Fácil',
                  descripcion: 'Tablero 3x3',
                  color: const Color(0xFF10B981),
                  onTap: () => _navegarAJuego(context, 3),
                ),
                const SizedBox(height: 16),
                _BotonDificultad(
                  label: '😤  Medio',
                  descripcion: 'Tablero 4x4',
                  color: const Color(0xFFF59E0B),
                  onTap: () => _navegarAJuego(context, 4),
                ),
                const SizedBox(height: 16),
                _BotonDificultad(
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

class _BotonDificultad extends StatelessWidget {
  final String label;
  final String descripcion;
  final Color color;
  final VoidCallback onTap;

  const _BotonDificultad({
    required this.label,
    required this.descripcion,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 3,
        ),
        onPressed: onTap,
        child: Column(
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(descripcion, style: GoogleFonts.poppins(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
