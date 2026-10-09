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

  /// Si no es `null`, las fichas muestran porciones de esta imagen en vez de
  /// números. No afecta en nada la mecánica: el deslizamiento, los huecos y las
  /// pistas de "movible" dependen del [tablero], no de cómo se dibuje la ficha.
  final ImageProvider? imagen;

  /// Imagen a la que caer si [imagen] no carga. Ver `ImageTile.respaldo`.
  final ImageProvider? imagenRespaldo;

  const PuzzleBoard({
    super.key,
    required this.tablero,
    required this.size,
    required this.onTileTap,
    this.imagen,
    this.imagenRespaldo,
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

        // El `RepaintBoundary` va **por fuera** del `Stack`, y ésa es la pieza
        // que faltaba: los boundaries de las fichas y de los sockets son
        // *hijos* del `Stack`, así que cuando `AnimatedPositioned` cambia
        // `left`/`top` la invalidación de pintado sube igual hasta el ancestro
        // más cercano. Sin esta capa, ese ancestro es el viewport del
        // `SingleChildScrollView` de `GameScreen` (`_RenderSingleChildViewport`
        // es repaint boundary), que envuelve el HUD, la consigna, el pozo con
        // su halo y la botonera: todo eso se volvía a registrar y a rasterizar
        // en cada frame de los 160 ms del deslizamiento. Con la capa acá, la
        // propagación se corta en el borde del tablero y el resto de la
        // pantalla no se entera. El pozo y su halo quedan afuera a propósito
        // (su decoración vive en `GameScreen`), así que tampoco se re-rasterizan.
        //
        // `RenderRepaintBoundary` es un `RenderProxyBox`: no recorta ni cambia
        // el layout, así que la sombra de la fila inferior sigue desbordando
        // (`Clip.none`) y la geometría que lee `test/helpers/puzzle_solver.dart`
        // no se corre.
        return RepaintBoundary(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Sockets: el fondo de todas las celdas. Muestran el estilo de
              // ficha vacía (visible el hueco) y dan una base estable sobre
              // la que las fichas deslizan.
              //
              // Van todos dentro de un mismo `RepaintBoundary` porque no
              // cambian nunca: al animarse una ficha el `Stack` se relayouta y
              // se repinta, y sin esta capa los n² sockets se volverían a
              // dibujar en cada frame de los 160 ms del deslizamiento.
              Positioned.fill(
                child: RepaintBoundary(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
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
                    ],
                  ),
                ),
              ),
              // Fichas numeradas: al cambiar su índice, `AnimatedPositioned`
              // las desliza desde su posición anterior.
              //
              // Cada ficha lleva su propio `RepaintBoundary`: mientras el
              // `Stack` se repinta por el cambio de `left`/`top`, las demás
              // fichas se recomponen desde su capa cacheada en vez de volver a
              // dibujar el sprite 9-slice con su borde y sus sombras en cada
              // frame. El `key` queda en el `AnimatedPositioned`, que es de
              // donde `test/helpers/puzzle_solver.dart` lee el tablero.
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
                    child: RepaintBoundary(
                      child: PuzzleTile(
                        numero: tablero[i],
                        size: n,
                        imagen: imagen,
                        imagenRespaldo: imagenRespaldo,
                        activa: movibles.contains(i),
                        onTap: () => onTileTap(i),
                        onSwipe: (direccion) => _deslizarFicha(i, direccion),
                      ),
                    ),
                  ),
            ],
          ),
        );
      },
    );
  }
}
