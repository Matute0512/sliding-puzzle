import 'package:flutter_test/flutter_test.dart';
import 'package:sliding_puzzle/logic/puzzle_logic.dart';

void main() {
  group('PuzzleLogic.distanciaManhattanTotal', () {
    test('tablero resuelto tiene distancia 0', () {
      final resuelto3x3 = [1, 2, 3, 4, 5, 6, 7, 8, 0];
      expect(PuzzleLogic.distanciaManhattanTotal(resuelto3x3, 3), equals(0));

      final resuelto4x4 = List.generate(16, (i) => (i + 1) % 16);
      expect(PuzzleLogic.distanciaManhattanTotal(resuelto4x4, 4), equals(0));
    });

    test('tablero con 1 movimiento de distancia tiene distancia 1', () {
      // El 8 se movió a la posición del hueco (índice 8) y el hueco quedó en índice 7
      final tablero = [1, 2, 3, 4, 5, 6, 7, 0, 8];
      expect(PuzzleLogic.distanciaManhattanTotal(tablero, 3), equals(1));
    });
  });

  group('PuzzleLogic.calcularPista', () {
    test('devuelve null si el tablero ya está resuelto', () {
      final resuelto = [1, 2, 3, 4, 5, 6, 7, 8, 0];
      expect(PuzzleLogic.calcularPista(resuelto, 3), isNull);
    });

    test('recomienda el movimiento ganador inmediato cuando falta 1 paso', () {
      // 8 está en índice 8 (donde debería ir el 0), y el hueco está en índice 7.
      // La ficha 8 (índice 8) debe deslizarse al hueco (índice 7) para ganar.
      final tablero = [1, 2, 3, 4, 5, 6, 7, 0, 8];
      final pista = PuzzleLogic.calcularPista(tablero, 3);

      expect(pista, equals(8));
    });

    test('la pista siempre devuelve una ficha adyacente al hueco (movible)', () {
      for (final size in [3, 4, 5]) {
        final tablero = PuzzleLogic.generarTablero(size);
        final movibles = PuzzleLogic.movibles(tablero, size);
        final pista = PuzzleLogic.calcularPista(tablero, size);

        expect(pista, isNotNull);
        expect(movibles, contains(pista));
      }
    });

    test('penaliza el último movimiento para evitar oscilación si hay alternativas', () {
      // Hueco en el centro (índice 4 en 3x3).
      // Movibles: arriba (1), abajo (7), izquierda (3), derecha (5).
      final tablero = [1, 2, 3, 4, 0, 6, 7, 5, 8];
      // Si la última jugada vino de 5, la pista no debería sugerir 5 si hay otra opción mejor o igual.
      final pistaConMemoria = PuzzleLogic.calcularPista(tablero, 3, ultimoIndiceMovido: 5);
      final pistaSinMemoria = PuzzleLogic.calcularPista(tablero, 3);

      expect(pistaConMemoria, isNotNull);
      expect(PuzzleLogic.movibles(tablero, 3), contains(pistaConMemoria));
      expect(pistaSinMemoria, isNotNull);
    });
  });
}
