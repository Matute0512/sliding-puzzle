import 'package:flutter/material.dart';
import 'package:sliding_puzzle/logic/puzzle_logic.dart';
import 'puzzle_tile.dart';

/// Tablero del puzzle con fichas que se deslizan hacia el hueco.
///
/// Reemplaza al `GridView`: un `Stack` con `clipBehavior: Clip.none` (para que
/// las sombras de la última fila no se recorten) donde cada ficha es un
/// `AnimatedPositioned` keyed por su número. Al reordenarse el tablero, la
/// ficha anima su posición y se ve el deslizamiento real.
class PuzzleBoard extends StatelessWidget {
  final List<int> tablero;
  final int size;
  final void Function(int indice) onTileTap;

  const PuzzleBoard({
    super.key,
    required this.tablero,
    required this.size,
    required this.onTileTap,
  });

  /// Mueve la ficha [indice] únicamente si el deslizamiento va en dirección
  /// al espacio vacío. Los swipes en cualquier otra dirección se ignoran.
  void _deslizarFicha(int indice, Direccion direccion) {
    if (PuzzleLogic.direccionHaciaVacio(tablero, indice, size) != direccion) {
      return;
    }
    onTileTap(indice);
  }

  @override
  Widget build(BuildContext context) {
    const espaciado = 4.0;
    final n = size;
    final movibles = PuzzleLogic.movibles(tablero, size).toSet();

    return LayoutBuilder(
      builder: (context, constraints) {
        final ladoCelda = (constraints.maxWidth - (n - 1) * espaciado) / n;
        double left(int i) => (i % n) * (ladoCelda + espaciado);
        double top(int i) => (i ~/ n) * (ladoCelda + espaciado);

        return Stack(
          clipBehavior: Clip.none,
          children: [
            // Sockets: el fondo de todas las celdas. Muestran el estilo de
            // ficha vacía (visible el hueco) y dan una base estable sobre
            // la que las fichas deslizan.
            for (var i = 0; i < n * n; i++)
              Positioned(
                left: left(i),
                top: top(i),
                width: ladoCelda,
                height: ladoCelda,
                child: PuzzleTile(
                  numero: 0,
                  size: n,
                  onTap: () {},
                  esSocket: true,
                ),
              ),
            // Fichas numeradas: al cambiar su índice, AnimatedPositioned
            // las desliza desde su posición anterior.
            for (var i = 0; i < tablero.length; i++)
              if (tablero[i] != 0)
                AnimatedPositioned(
                  key: ValueKey(tablero[i]),
                  duration: const Duration(milliseconds: 160),
                  curve: Curves.easeOutCubic,
                  left: left(i),
                  top: top(i),
                  width: ladoCelda,
                  height: ladoCelda,
                  child: PuzzleTile(
                    numero: tablero[i],
                    size: n,
                    activa: movibles.contains(i),
                    onTap: () => onTileTap(i),
                    onSwipe: (direccion) => _deslizarFicha(i, direccion),
                  ),
                ),
          ],
        );
      },
    );
  }
}
