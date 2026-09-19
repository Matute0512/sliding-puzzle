import 'package:flutter/material.dart';

/// Ficha que muestra **una porción** de una imagen: la que le corresponde a su
/// posición en el tablero resuelto.
///
/// Es la pieza clave del rompecabezas con fotos. La ficha con [numero] `k`
/// muestra siempre el mismo recorte —el del orden de lectura del tablero
/// resuelto— sin importar dónde esté ubicada hoy. Al deslizarse, las piezas se
/// reacomodan solas y armar el puzzle reconstruye la imagen completa.
///
/// ## Cómo recorta
///
/// La idea: dibujar la imagen entera `n` veces más grande que la celda y
/// correrla hacia arriba/izquierda lo justo para que la porción visible caiga
/// sobre la celda que le toca. Con `OverflowBox` + `FractionalOffset`:
///
/// Flutter resuelve el corrimiento como `alignment * (tamañoCelda - tamañoImagen)`,
/// y con `a = col / (n - 1)` eso da exactamente `-col * ladoCelda`:
///
///   * `col = 0`     -> `a = 0` -> se ve el borde izquierdo de la imagen
///   * `col = n - 1` -> `a = 1` -> se ve el borde derecho
///
/// El `ClipRect` recorta lo que sobra.
///
/// **Por qué `OverflowBox` y no `Align`.** La receta más difundida usa
/// `Align` + `FractionalOffset`, pero no sirve acá: `RenderPositionedBox`
/// (la clase detrás de `Align`) mide a su hijo con `constraints.loosen()`
/// —ver `shifted_box.dart`—, que **conserva el máximo** y por lo tanto recorta
/// el hijo al tamaño de la celda. `Align` está pensado para *encajar* al hijo,
/// no para dejarlo desbordar, así que el recorte por ficha no ocurre: la imagen
/// entera termina aplastada dentro de cada celda. `OverflowBox` existe
/// justamente para darle al hijo restricciones distintas de las que recibió.
///
/// Requiere restricciones **acotadas**, porque necesita el lado de la celda para
/// escalar la imagen a `n` veces ese tamaño. En `PuzzleBoard` siempre las tiene
/// (`AnimatedPositioned` fija ancho y alto).
class ImageTile extends StatelessWidget {
  /// Imagen completa del rompecabezas.
  final ImageProvider imagen;

  /// Número de ficha (1..n²-1). Determina qué porción se muestra.
  final int numero;

  /// Lado del tablero (3, 4, 5...).
  final int size;

  /// Radio de las esquinas. Se pasa desde afuera para que coincida con el del
  /// contenedor de la ficha y no queden dos valores que se puedan desincronizar.
  final BorderRadius borderRadius;

  const ImageTile({
    super.key,
    required this.imagen,
    required this.numero,
    required this.size,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
  });

  /// Posición (fila, col) que le toca a [numero] en el tablero resuelto.
  ///
  /// En el tablero resuelto la ficha `k` vive en el índice `k - 1` (ver
  /// `PuzzleLogic.estaResuelto`), así que fila y columna salen de ese índice en
  /// orden de lectura.
  static ({int fila, int col}) posicionDe(int numero, int size) =>
      (fila: (numero - 1) ~/ size, col: (numero - 1) % size);

  /// Alineación que hay que darle al `Align` para que se vea la porción de
  /// [numero]. Ver el comentario de la clase para la deducción.
  static FractionalOffset alineacionDe(int numero, int size) {
    final (:fila, :col) = posicionDe(numero, size);
    // El divisor es `size - 1` porque FractionalOffset va de 0 a 1: la última
    // ficha tiene que caer exactamente en 1. Con los tableros reales (3x3 o
    // más) nunca es 0.
    final divisor = size - 1;
    return FractionalOffset(col / divisor, fila / divisor);
  }

  @override
  Widget build(BuildContext context) {
    // Ficha vacía o tablero degenerado: no hay porción que mostrar.
    // `PuzzleBoard` no llega acá con numero 0 (los huecos son sockets), pero el
    // guardado evita que un uso manual calcule un recorte sin sentido.
    if (numero <= 0 || size < 2) return const SizedBox.shrink();

    return ClipRRect(
      borderRadius: borderRadius,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final lado = constraints.maxWidth;

          // Sin restricciones acotadas no se puede saber el lado de la celda.
          // En `PuzzleBoard` nunca pasa; se degrada a la imagen entera para no
          // romper con un error de layout difícil de rastrear.
          if (!lado.isFinite) {
            return Image(image: imagen, fit: BoxFit.contain);
          }

          return ClipRect(
            child: OverflowBox(
              // La imagen entera, n veces más grande que la celda: así cada
              // celda es exactamente 1/n de la imagen.
              maxWidth: lado * size,
              maxHeight: lado * size,
              alignment: alineacionDe(numero, size),
              // El SizedBox es necesario porque `Image` no se estira hasta el
              // máximo de las restricciones por sí solo: sin él, la imagen
              // quedaría de su tamaño intrínseco y el recorte no cerraría.
              child: SizedBox(
                width: lado * size,
                height: lado * size,
                // `cover` recorta a cuadrado si la imagen no lo es, sin
                // deformarla. Con una imagen ya cuadrada no recorta nada.
                child: Image(image: imagen, fit: BoxFit.cover),
              ),
            ),
          );
        },
      ),
    );
  }
}
