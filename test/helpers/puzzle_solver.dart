import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sliding_puzzle/widgets/puzzle_board.dart';

/// Utilidades para los tests que necesitan **jugar** un tablero de verdad, en
/// vez de solo renderizarlo: leer el estado desde el árbol de widgets y calcular
/// la secuencia de toques que lo resuelve.

/// Lee el tablero real desde el árbol de widgets: cada ficha es un
/// `AnimatedPositioned` con `key: ValueKey(numero)`, y su left/top dan el índice.
List<int> leerTablero(WidgetTester tester, int n) {
  final ancho = tester.getSize(find.byType(PuzzleBoard)).width;
  final paso = (ancho - (n - 1) * 4) / n + 4;
  final tablero = List<int>.filled(n * n, 0);

  final fichas = tester.widgetList<AnimatedPositioned>(
    find.byType(AnimatedPositioned),
  );
  for (final ficha in fichas) {
    final clave = ficha.key;
    if (clave is! ValueKey<int>) continue;
    final fila = ((ficha.top ?? 0) / paso).round();
    final columna = ((ficha.left ?? 0) / paso).round();
    tablero[fila * n + columna] = clave.value;
  }
  return tablero;
}

/// Números de ficha a tocar, en orden, para resolver el tablero (BFS).
///
/// Devuelve la lista vacía si no encontró solución, que en la práctica
/// significaría que el tablero de entrada nunca fue resoluble.
List<int> resolverTablero(List<int> inicio, int n) {
  final meta = <int>[...List.generate(n * n - 1, (i) => i + 1), 0].join(',');
  final cola = <List<int>>[List<int>.from(inicio)];
  final caminos = <String, List<int>>{inicio.join(','): const []};
  final visitados = <String>{inicio.join(',')};
  var cabeza = 0;

  while (cabeza < cola.length) {
    final b = cola[cabeza++];
    final clave = b.join(',');
    final camino = caminos[clave]!;
    if (clave == meta) return camino;

    final hueco = b.indexOf(0);
    for (final delta in [-n, n, -1, 1]) {
      final destino = hueco + delta;
      if (destino < 0 || destino >= n * n) continue;
      if (delta.abs() == 1 && (hueco ~/ n) != (destino ~/ n)) continue;

      final siguiente = List<int>.from(b);
      siguiente[hueco] = siguiente[destino];
      siguiente[destino] = 0;

      final claveSiguiente = siguiente.join(',');
      if (visitados.add(claveSiguiente)) {
        caminos[claveSiguiente] = [...camino, b[destino]];
        cola.add(siguiente);
      }
    }
  }
  return const [];
}

/// Toca las fichas de [jugadas] en orden, con un `pump` entre cada una.
///
/// `warnIfMissed: false` porque las fichas se mueven mientras se resuelve y el
/// punto medio de una puede quedar tapado por otra; el toque igual llega al
/// gesto correcto.
Future<void> jugarSecuencia(WidgetTester tester, List<int> jugadas) async {
  for (final numero in jugadas) {
    await tester.tap(find.byKey(ValueKey(numero)), warnIfMissed: false);
    await tester.pump();
  }
}
