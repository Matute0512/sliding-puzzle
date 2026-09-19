import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sliding_puzzle/widgets/image_tile.dart';
import 'package:sliding_puzzle/widgets/puzzle_board.dart';
import 'package:sliding_puzzle/widgets/puzzle_tile.dart';

import '../helpers/localized_app.dart';

/// PNG de 1x1 transparente. Se usa en vez de un asset real para que el test no
/// dependa de que `flutter test` resuelva el bundle de assets.
final _png1x1 = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAE'
  'hQGAhKmMIQAAAABJRU5ErkJggg==',
);

final _imagenPrueba = MemoryImage(_png1x1);

void main() {
  group('posicionDe', () {
    test('mapea cada ficha a su celda en el tablero resuelto 3x3', () {
      const n = 3;
      // Orden de lectura: 1 2 3 / 4 5 6 / 7 8 9
      expect(ImageTile.posicionDe(1, n), (fila: 0, col: 0));
      expect(ImageTile.posicionDe(2, n), (fila: 0, col: 1));
      expect(ImageTile.posicionDe(3, n), (fila: 0, col: 2));
      expect(ImageTile.posicionDe(4, n), (fila: 1, col: 0));
      expect(ImageTile.posicionDe(5, n), (fila: 1, col: 1));
      expect(ImageTile.posicionDe(6, n), (fila: 1, col: 2));
      expect(ImageTile.posicionDe(7, n), (fila: 2, col: 0));
      expect(ImageTile.posicionDe(8, n), (fila: 2, col: 1));
      expect(ImageTile.posicionDe(9, n), (fila: 2, col: 2));
    });

    test('mapea correctamente en 4x4 (el otro tamaño real del juego)', () {
      const n = 4;
      expect(ImageTile.posicionDe(1, n), (fila: 0, col: 0));
      expect(ImageTile.posicionDe(4, n), (fila: 0, col: 3));
      expect(ImageTile.posicionDe(5, n), (fila: 1, col: 0));
      expect(ImageTile.posicionDe(11, n), (fila: 2, col: 2));
      expect(ImageTile.posicionDe(16, n), (fila: 3, col: 3));
    });
  });

  group('alineacionDe', () {
    test('la primera ficha va arriba a la izquierda y la última abajo a la '
        'derecha', () {
      expect(ImageTile.alineacionDe(1, 3), FractionalOffset.topLeft);
      expect(ImageTile.alineacionDe(9, 3), FractionalOffset.bottomRight);
      expect(ImageTile.alineacionDe(1, 4), FractionalOffset.topLeft);
      expect(ImageTile.alineacionDe(16, 4), FractionalOffset.bottomRight);
    });

    test('las intermedias caen en la fracción exacta de su celda', () {
      // 3x3 -> columnas 0, 1/2, 1
      expect(ImageTile.alineacionDe(2, 3), const FractionalOffset(1 / 2, 0));
      expect(ImageTile.alineacionDe(4, 3), const FractionalOffset(0, 1 / 2));
      expect(ImageTile.alineacionDe(5, 3), const FractionalOffset(1 / 2, 1 / 2));
      // 4x4 -> columnas 0, 1/3, 2/3, 1
      expect(ImageTile.alineacionDe(2, 4), const FractionalOffset(1 / 3, 0));
      expect(ImageTile.alineacionDe(3, 4), const FractionalOffset(2 / 3, 0));
      expect(ImageTile.alineacionDe(6, 4), const FractionalOffset(1 / 3, 1 / 3));
    });

    test('la alineación depende solo del número, no de dónde esté la ficha',
        () {
      // Es la propiedad que hace que el puzzle funcione: la pieza lleva su
      // recorte consigo. Si esto cambiara, la imagen se armaría mal.
      for (final n in [3, 4, 5]) {
        for (var k = 1; k < n * n; k++) {
          final a = ImageTile.alineacionDe(k, n);
          expect(a.dx, inInclusiveRange(0, 1), reason: 'dx fuera de rango (k=$k, n=$n)');
          expect(a.dy, inInclusiveRange(0, 1), reason: 'dy fuera de rango (k=$k, n=$n)');
        }
      }
    });
  });

  group('ImageTile renderizado', () {
    Widget montar(Widget child) => appLocalizada(
          home: Scaffold(body: Center(child: child)),
        );

    testWidgets('la ficha vacía no dibuja nada', (tester) async {
      await tester.pumpWidget(
        montar(
          SizedBox(
            width: 100,
            height: 100,
            child: ImageTile(imagen: _imagenPrueba, numero: 0, size: 3),
          ),
        ),
      );

      expect(find.byType(Image), findsNothing);
    });
  });

  group('PuzzleBoard con imagen', () {
    testWidgets(
      'cada ficha recibe la alineación de SU número, no la de su posición',
      (tester) async {
        // Tablero desordenado a propósito: si el widget usara la posición
        // actual en vez del número, las alineaciones no coincidirían.
        const n = 3;
        const tablero = [4, 1, 0, 2, 8, 5, 3, 6, 7];

        await tester.pumpWidget(
          appLocalizada(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 300,
                  height: 300,
                  child: PuzzleBoard(
                    tablero: tablero,
                    size: n,
                    onTileTap: (_) {},
                    imagen: _imagenPrueba,
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        for (var k = 1; k < n * n; k++) {
          final ficha = find.byWidgetPredicate(
            (w) => w is PuzzleTile && w.numero == k,
          );
          expect(ficha, findsOneWidget, reason: 'falta la ficha $k');

          final caja = tester.widget<OverflowBox>(
            find.descendant(of: ficha, matching: find.byType(OverflowBox)),
          );
          expect(
            caja.alignment,
            ImageTile.alineacionDe(k, n),
            reason: 'la ficha $k muestra la porción equivocada',
          );
        }
      },
    );

    testWidgets(
      'la imagen queda desplazada exactamente -col*lado y -fila*lado',
      (tester) async {
        // Verificación geométrica de verdad: mide dónde terminó la imagen en
        // pantalla. El test de arriba solo comprueba que el código coincide con
        // la fórmula de `alineacionDe`; si esa fórmula estuviera mal, pasaría
        // igual. Este mide el layout que Flutter realmente calculó.
        const n = 3;
        const ladoTablero = 300.0;
        const espaciado = 4.0;
        const tablero = [4, 1, 0, 2, 8, 5, 3, 6, 7];

        await tester.pumpWidget(
          appLocalizada(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: ladoTablero,
                  height: ladoTablero,
                  child: PuzzleBoard(
                    tablero: tablero,
                    size: n,
                    onTileTap: (_) {},
                    imagen: _imagenPrueba,
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        final ladoCelda = (ladoTablero - (n - 1) * espaciado) / n;

        for (var k = 1; k < n * n; k++) {
          final (:fila, :col) = ImageTile.posicionDe(k, n);
          final ficha = find.byWidgetPredicate(
            (w) => w is PuzzleTile && w.numero == k,
          );

          final rectFicha = tester.getRect(ficha);
          final rectImagen = tester.getRect(
            find.descendant(of: ficha, matching: find.byType(Image)),
          );

          // La celda mide `ladoCelda`; la imagen entera mide n veces eso y está
          // corrida hacia arriba/izquierda justo lo necesario para que la
          // porción visible caiga sobre la celda (fila, col).
          expect(
            rectImagen.width,
            moreOrLessEquals(ladoCelda * n, epsilon: 0.01),
            reason: 'la imagen debería medir n celdas (ficha $k)',
          );
          expect(
            rectImagen.left,
            moreOrLessEquals(rectFicha.left - col * ladoCelda, epsilon: 0.01),
            reason: 'corrimiento horizontal incorrecto en la ficha $k',
          );
          expect(
            rectImagen.top,
            moreOrLessEquals(rectFicha.top - fila * ladoCelda, epsilon: 0.01),
            reason: 'corrimiento vertical incorrecto en la ficha $k',
          );
        }
      },
    );

    testWidgets('el hueco no dibuja imagen', (tester) async {
      const tablero = [1, 2, 3, 4, 5, 6, 7, 0, 8]; // hueco en el índice 7

      await tester.pumpWidget(
        appLocalizada(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                height: 300,
                child: PuzzleBoard(
                  tablero: tablero,
                  size: 3,
                  onTileTap: (_) {},
                  imagen: _imagenPrueba,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // 8 fichas con imagen (el 0 no se dibuja como ficha) + 9 sockets.
      expect(find.byType(ImageTile), findsNWidgets(8));
    });

    testWidgets('sin imagen sigue renderizando los números de siempre', (
      tester,
    ) async {
      const tablero = [1, 2, 3, 4, 5, 6, 7, 8, 0];

      await tester.pumpWidget(
        appLocalizada(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                height: 300,
                child: PuzzleBoard(
                  tablero: tablero,
                  size: 3,
                  onTileTap: (_) {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(ImageTile), findsNothing);
      expect(find.text('5'), findsOneWidget);
    });
  });
}
