import 'package:flutter_test/flutter_test.dart';
import 'package:sliding_puzzle/logic/puzzle_logic.dart';

void main() {
  group('generarTablero', () {
    test('produce un tablero resoluble, no resuelto y sin duplicados', () {
      for (final size in [3, 4, 5]) {
        for (var i = 0; i < 100; i++) {
          final t = PuzzleLogic.generarTablero(size);
          expect(t.length, size * size);
          expect(PuzzleLogic.tieneSolucion(t, size), isTrue);
          expect(PuzzleLogic.estaResuelto(t), isFalse);
          expect(
            t.toSet().length,
            size * size,
            reason: 'sin duplicados ni faltantes',
          );
        }
      }
    });
  });

  group('tieneSolucion', () {
    test('retorna true/false para casos conocidos en 3x3 y 4x4', () {
      // 3x3 (impar): paridad par de inversiones es resoluble.
      const resuelto3 = [1, 2, 3, 4, 5, 6, 7, 8, 0];
      const unaInversion3 = [2, 1, 3, 4, 5, 6, 7, 8, 0];
      const dosInversiones3 = [2, 3, 1, 4, 5, 6, 7, 8, 0];
      expect(PuzzleLogic.tieneSolucion(resuelto3, 3), isTrue);
      expect(PuzzleLogic.tieneSolucion(unaInversion3, 3), isFalse);
      expect(PuzzleLogic.tieneSolucion(dosInversiones3, 3), isTrue);

      // 4x4 (par): además de la paridad importa la fila del vacío.
      const resuelto4 = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 0];
      const unaInversion4 = [2, 1, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 0];
      expect(PuzzleLogic.tieneSolucion(resuelto4, 4), isTrue);
      expect(PuzzleLogic.tieneSolucion(unaInversion4, 4), isFalse);
    });
  });

  group('mover', () {
    test('solo permite mover fichas adyacentes al vacío', () {
      const t = [1, 2, 3, 4, 5, 6, 7, 8, 0];
      expect(PuzzleLogic.puedeMover(t, 5, 3), isTrue);
      expect(PuzzleLogic.puedeMover(t, 0, 3), isFalse);

      final nuevo = PuzzleLogic.mover(t, 5, 3);
      expect(nuevo, [1, 2, 3, 4, 5, 0, 7, 8, 6]);
      expect(t, [1, 2, 3, 4, 5, 6, 7, 8, 0], reason: 'entrada inmutable');
    });

    test('es inmutable: no modifica el tablero original y devuelve uno nuevo', () {
      final t = List<int>.generate(9, (i) => i == 8 ? 0 : i + 1);

      final resultado = PuzzleLogic.mover(t, 5, 3);

      expect(resultado, [1, 2, 3, 4, 5, 0, 7, 8, 6]);
      expect(t, [1, 2, 3, 4, 5, 6, 7, 8, 0], reason: 'el original no cambia');
      expect(identical(resultado, t), isFalse, reason: 'retorna una lista nueva');
    });
  });

  group('puedeMover', () {
    test('cubre los 4 casos: arriba, abajo, izquierda y derecha', () {
      // Vacío en el centro (índice 4) de un 3x3.
      const t = [1, 2, 3, 4, 0, 5, 6, 7, 8];

      // Ficha arriba del vacío → el vacío se mueve hacia arriba.
      expect(PuzzleLogic.puedeMover(t, 1, 3), isTrue);
      // Ficha abajo del vacío → el vacío se mueve hacia abajo.
      expect(PuzzleLogic.puedeMover(t, 7, 3), isTrue);
      // Ficha a la izquierda del vacío → el vacío se mueve a la izquierda.
      expect(PuzzleLogic.puedeMover(t, 3, 3), isTrue);
      // Ficha a la derecha del vacío → el vacío se mueve a la derecha.
      expect(PuzzleLogic.puedeMover(t, 5, 3), isTrue);
    });

    test('rechaza movimientos diagonales y no adyacentes', () {
      const t = [1, 2, 3, 4, 0, 5, 6, 7, 8];

      // Diagonales del vacío central.
      for (final indice in [0, 2, 6, 8]) {
        expect(
          PuzzleLogic.puedeMover(t, indice, 3),
          isFalse,
          reason: 'la diagonal $indice no debe poder moverse',
        );
      }
      // La propia posición vacía no es un movimiento válido.
      expect(PuzzleLogic.puedeMover(t, 4, 3), isFalse);
    });
  });

  group('estaResuelto', () {
    test('detecta tableros resueltos y no resueltos', () {
      const resuelto3 = [1, 2, 3, 4, 5, 6, 7, 8, 0];
      const resuelto4 = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 0];
      const vacioEnElMedio = [1, 2, 3, 4, 5, 6, 7, 0, 8];
      const invertido = [8, 7, 6, 5, 4, 3, 2, 1, 0];

      expect(PuzzleLogic.estaResuelto(resuelto3), isTrue);
      expect(PuzzleLogic.estaResuelto(resuelto4), isTrue);
      // El vacío no está en la última posición.
      expect(PuzzleLogic.estaResuelto(vacioEnElMedio), isFalse);
      // Fichas desordenadas.
      expect(PuzzleLogic.estaResuelto(invertido), isFalse);
    });
  });
}
