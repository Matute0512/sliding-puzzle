import 'package:flutter/material.dart';
import 'puzzle_logic.dart';

/// Pantalla principal del juego donde se muestra el tablero.
class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

/// StatefulWidget porque el tablero cambia cada vez
/// que el usuario mueve una ficha.
class _GameScreenState extends State<GameScreen> {
  static const int size = 3; // tablero 3x3
  late List<int> _tablero;
  int _movimientos = 0;

  @override
  void initState() {
    super.initState();
    // Generamos el tablero mezclado al iniciar la pantalla
    _tablero = PuzzleLogic.generarTablero(size);
  }

  /// Maneja el tap en una ficha
  void _onTapFicha(int indice) {
    if (!PuzzleLogic.puedeMover(_tablero, indice, size)) return;

    setState(() {
      _tablero = PuzzleLogic.mover(_tablero, indice);
      _movimientos++;
    });

    if (PuzzleLogic.estaResuelto(_tablero)) {
      _mostrarVictoria();
    }
  }

  /// Muestra el diálogo de victoria
  void _mostrarVictoria() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('🎉 ¡Ganaste!'),
        content: Text('Lo resolviste en $_movimientos movimientos.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _reiniciar();
            },
            child: const Text('Jugar de nuevo'),
          ),
        ],
      ),
    );
  }

  /// Reinicia el tablero
  void _reiniciar() {
    setState(() {
      _tablero = PuzzleLogic.generarTablero(size);
      _movimientos = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo[50],
      appBar: AppBar(
        backgroundColor: Colors.indigo,
        title: const Text(
          'Sliding Puzzle',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          // Botón para reiniciar desde el appbar
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _reiniciar,
          ),
        ],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Contador de movimientos
          Text(
            'Movimientos: $_movimientos',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          // Tablero
          Center(
            child: SizedBox(
              width: 300,
              height: 300,
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: size,
                  crossAxisSpacing: 6,
                  mainAxisSpacing: 6,
                ),
                itemCount: size * size,
                itemBuilder: (context, indice) {
                  final numero = _tablero[indice];
                  final esVacio = numero == 0;

                  return GestureDetector(
                    onTap: () => _onTapFicha(indice),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      decoration: BoxDecoration(
                        color: esVacio ? Colors.transparent : Colors.indigo,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: esVacio
                            ? null
                            : Text(
                                '$numero',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
