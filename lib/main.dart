import 'package:flutter/material.dart';
import 'package:sliding_puzzle/game_screen.dart';

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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
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
      backgroundColor: Colors.indigo[50],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '🧩 Sliding Puzzle',
              style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Elegí una dificultad',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 40),
            _BotonDificultad(
              label: 'Fácil',
              descripcion: 'Tablero 3x3',
              color: Colors.green,
              onTap: () => _navegarAJuego(context, 3),
            ),
            const SizedBox(height: 16),
            _BotonDificultad(
              label: 'Medio',
              descripcion: 'Tablero 4x4',
              color: Colors.orange,
              onTap: () => _navegarAJuego(context, 4),
            ),
            const SizedBox(height: 16),
            _BotonDificultad(
              label: 'Difícil',
              descripcion: 'Tablero 5x5',
              color: Colors.red,
              onTap: () => _navegarAJuego(context, 5),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget reutilizable para cada botón de dificultad
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
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        minimumSize: const Size(220, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: onTap,
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(descripcion, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
