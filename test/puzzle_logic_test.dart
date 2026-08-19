import 'package:flutter_test/flutter_test.dart';
import 'package:sliding_puzzle/logic/puzzle_logic.dart';

void main() {
  test('generarTablero produce un tablero resoluble y no resuelto', () {
    for (final size in [3, 4, 5]) {
      for (var i = 0; i < 100; i++) {
        final t = PuzzleLogic.generarTablero(size);
        expect(t.length, size * size);
        expect(PuzzleLogic.tieneSolucion(t, size), isTrue);
        expect(PuzzleLogic.estaResuelto(t), isFalse);
        expect(t.toSet().length, size * size, reason: 'sin duplicados/faltantes');
      }
    }
  });

  test('mover solo permite fichas adyacentes al vacío', () {
    const t = [1, 2, 3, 4, 5, 6, 7, 8, 0];
    expect(PuzzleLogic.puedeMover(t, 5, 3), isTrue);
    expect(PuzzleLogic.puedeMover(t, 0, 3), isFalse);
    final nuevo = PuzzleLogic.mover(t, 5, 3);
    expect(nuevo, [1, 2, 3, 4, 5, 0, 7, 8, 6]);
    expect(t, [1, 2, 3, 4, 5, 6, 7, 8, 0], reason: 'entrada inmutable');
  });
}
