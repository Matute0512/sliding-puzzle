import 'package:flutter/material.dart';

import '../logic/puzzle_logic.dart';
import '../services/daily_challenge_service.dart';
import '../theme/app_theme.dart';
import '../widgets/puzzle_board.dart';

/// ⚠️ PANTALLA TEMPORAL DE PRUEBA — borrar cuando el puzzle con fotos del
/// Desafío Diario tenga su pantalla real.
///
/// Sirve para ver y jugar el rompecabezas con una imagen, y comprobar que el
/// recorte por ficha, el deslizamiento y los huecos se comportan igual que con
/// las fichas numéricas.
///
/// Es **autocontenida** a propósito: usa `PuzzleBoard` directo en vez de
/// `GameScreen`, así no arrastra timer, confeti, récords ni escrituras a
/// Firestore. Probar acá no puede ensuciar el Top 5 global.
///
/// No pasa por el sistema de i18n: es una pantalla de desarrollo que no se
/// publica, y agregar claves a los `.arb` para algo que se va a borrar sería
/// ruido. Los textos van en duro a conciencia.
class ImagePuzzleTestScreen extends StatefulWidget {
  const ImagePuzzleTestScreen({super.key, this.size = 3});

  /// Lado del tablero. 3 y 4 son los tamaños reales del juego.
  final int size;

  @override
  State<ImagePuzzleTestScreen> createState() => _ImagePuzzleTestScreenState();
}

class _ImagePuzzleTestScreenState extends State<ImagePuzzleTestScreen> {
  late List<int> _tablero;
  int _movimientos = 0;

  @override
  void initState() {
    super.initState();
    _tablero = PuzzleLogic.generarTablero(widget.size);
  }

  void _reiniciar() {
    setState(() {
      _tablero = PuzzleLogic.generarTablero(widget.size);
      _movimientos = 0;
    });
  }

  /// Arma el tablero resuelto de una. Sirve para verificar de un vistazo que
  /// las piezas reconstruyen bien la imagen: si el recorte estuviera mal, acá
  /// se nota al instante sin tener que resolver el puzzle.
  void _resolver() {
    setState(() {
      final total = widget.size * widget.size;
      _tablero = List.generate(total, (i) => (i + 1) % total);
    });
  }

  void _onTapFicha(int indice) {
    if (!PuzzleLogic.puedeMover(_tablero, indice, widget.size)) return;
    setState(() {
      _tablero = PuzzleLogic.mover(_tablero, indice, widget.size);
      _movimientos++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: colors.textPrimary),
        title: Text(
          'Prueba: puzzle con imagen',
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(
                  'Tablero ${widget.size}×${widget.size} · $_movimientos movs',
                  style: TextStyle(color: colors.textSecondary),
                ),
                const SizedBox(height: 16),
                AspectRatio(
                  aspectRatio: 1,
                  child: PuzzleBoard(
                    tablero: _tablero,
                    size: widget.size,
                    onTileTap: _onTapFicha,
                    imagen: DailyChallengeService.imagenDiaria,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _reiniciar,
                      icon: const Icon(Icons.shuffle),
                      label: const Text('Mezclar'),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: _resolver,
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Resolver'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Cambiar de tablero: modificar `size` en '
                  'ImagePuzzleTestScreen.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: colors.textSecondary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
