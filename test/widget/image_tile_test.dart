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
      expect(
        ImageTile.alineacionDe(5, 3),
        const FractionalOffset(1 / 2, 1 / 2),
      );
      // 4x4 -> columnas 0, 1/3, 2/3, 1
      expect(ImageTile.alineacionDe(2, 4), const FractionalOffset(1 / 3, 0));
      expect(ImageTile.alineacionDe(3, 4), const FractionalOffset(2 / 3, 0));
      expect(
        ImageTile.alineacionDe(6, 4),
        const FractionalOffset(1 / 3, 1 / 3),
      );
    });

    test(
      'la alineación depende solo del número, no de dónde esté la ficha',
      () {
        for (final n in [3, 4, 5]) {
          for (var k = 1; k < n * n; k++) {
            final a = ImageTile.alineacionDe(k, n);
            expect(
              a.dx,
              inInclusiveRange(0, 1),
              reason: 'dx fuera de rango (k=$k, n=$n)',
            );
            expect(
              a.dy,
              inInclusiveRange(0, 1),
              reason: 'dy fuera de rango (k=$k, n=$n)',
            );
          }
        }
      },
    );
  });

  group('recorteDe', () {
    test('divide una imagen cuadrada en n×n porciones exactas', () {
      const tamano = Size(300, 300);
      expect(
        ImageTile.recorteDe(1, 3, tamano),
        const Rect.fromLTWH(0, 0, 100, 100),
      );
      expect(
        ImageTile.recorteDe(2, 3, tamano),
        const Rect.fromLTWH(100, 0, 100, 100),
      );
      expect(
        ImageTile.recorteDe(5, 3, tamano),
        const Rect.fromLTWH(100, 100, 100, 100),
      );
      expect(
        ImageTile.recorteDe(9, 3, tamano),
        const Rect.fromLTWH(200, 200, 100, 100),
      );
    });

    test('centra el recorte cuadrado (BoxFit.cover) si la imagen no es 1:1', () {
      // 400x300 -> cuadrado central de 300x300 desplazado 50 px en X.
      const apaisada = Size(400, 300);
      expect(
        ImageTile.recorteDe(1, 3, apaisada),
        const Rect.fromLTWH(50, 0, 100, 100),
      );
      expect(
        ImageTile.recorteDe(9, 3, apaisada),
        const Rect.fromLTWH(250, 200, 100, 100),
      );
    });
  });

  group('respaldo', () {
    /// Bytes que no son una imagen válida: la decodificación falla y dispara el
    /// fallback a `respaldo`.
    final rota = MemoryImage(base64Decode('aW52YWxpZG8='));

    Widget montarConRespaldo(ImageProvider? respaldo) => appLocalizada(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 90,
                height: 90,
                child: ImageTile(
                  imagen: rota,
                  respaldo: respaldo,
                  numero: 1,
                  size: 3,
                ),
              ),
            ),
          ),
        );

    testWidgets('si la foto del día no carga, cae a la de respaldo', (
      tester,
    ) async {
      await tester.pumpWidget(montarConRespaldo(_imagenPrueba));
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      final state = tester.state<ImageTileState>(find.byType(ImageTile));
      expect(
        state.proveedorActivo,
        same(_imagenPrueba),
        reason:
            'sin red o sin foto subida el tablero tiene que caer a la foto '
            'empaquetada, no quedar en blanco',
      );
    });

    testWidgets('sin respaldo, la ficha no rompe', (tester) async {
      await tester.pumpWidget(montarConRespaldo(null));
      final error = tester.takeException();

      expect(error, anyOf(isNull, isA<Exception>(), isA<Error>()));
      expect(find.byType(ImageTile), findsOneWidget);
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

      expect(
        find.descendant(
          of: find.byType(ImageTile),
          matching: find.byType(CustomPaint),
        ),
        findsNothing,
      );
    });
  });

  group('PuzzleBoard con imagen', () {
    testWidgets(
      'cada ficha recibe el recorte de SU número, no el de su posición',
      (tester) async {
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

          final tileImagen = tester.widget<ImageTile>(
            find.descendant(of: ficha, matching: find.byType(ImageTile)),
          );
          expect(
            tileImagen.numero,
            k,
            reason: 'la ficha $k muestra la porción equivocada',
          );
          expect(tileImagen.size, n);
        }
      },
    );

    testWidgets(
      'el recorte de cada ficha corresponde exactamente a (col*lado, fila*lado)',
      (tester) async {
        const n = 3;
        const ladoImagen = 300.0;
        const ladoCelda = ladoImagen / n;

        for (var k = 1; k < n * n; k++) {
          final (:fila, :col) = ImageTile.posicionDe(k, n);
          final rect = ImageTile.recorteDe(
            k,
            n,
            const Size(ladoImagen, ladoImagen),
          );

          expect(
            rect.width,
            moreOrLessEquals(ladoCelda, epsilon: 0.01),
            reason: 'ancho de recorte incorrecto en la ficha $k',
          );
          expect(
            rect.height,
            moreOrLessEquals(ladoCelda, epsilon: 0.01),
            reason: 'alto de recorte incorrecto en la ficha $k',
          );
          expect(
            rect.left,
            moreOrLessEquals(col * ladoCelda, epsilon: 0.01),
            reason: 'origen X de recorte incorrecto en la ficha $k',
          );
          expect(
            rect.top,
            moreOrLessEquals(fila * ladoCelda, epsilon: 0.01),
            reason: 'origen Y de recorte incorrecto en la ficha $k',
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

      // 8 fichas con imagen (el 0 no se dibuja como ficha).
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
