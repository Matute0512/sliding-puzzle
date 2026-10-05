import 'package:flutter_test/flutter_test.dart';
import 'package:sliding_puzzle/logic/dificultad.dart';

void main() {
  group('Dificultad', () {
    test('cada dificultad mapea a su tamaño de tablero', () {
      expect(Dificultad.facil.tamano, 3);
      expect(Dificultad.medio.tamano, 4);
      expect(Dificultad.dificil.tamano, 5);
      expect(Dificultad.experto.tamano, 6);
    });

    test('no hay dos dificultades con el mismo tablero', () {
      // Un tamaño repetido rompería los récords y el Top 5: dos entradas
      // distintas escribirían en la misma colección `leaderboard_NxN`.
      final tamanos = Dificultad.values.map((d) => d.tamano).toList();
      expect(tamanos.toSet().length, tamanos.length);
    });

    test('el menú solo ofrece las dificultades habilitadas', () {
      // `experto` está declarada pero sin botón: el tablero 6×6 todavía no
      // tiene entrada en la pantalla de récords ni colección en Firestore. Ver
      // el doc-comment del enum.
      expect(Dificultad.jugables, [
        Dificultad.facil,
        Dificultad.medio,
        Dificultad.dificil,
      ]);
      expect(Dificultad.jugables, isNot(contains(Dificultad.experto)));
    });
  });
}
