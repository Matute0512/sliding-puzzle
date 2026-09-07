import 'package:flutter_test/flutter_test.dart';
import 'package:sliding_puzzle/services/firebase_service.dart';

PuntajeGlobal p({String? id, required int mov, required int tiempo}) =>
    PuntajeGlobal(
      id: id,
      alias: 'X',
      movimientos: mov,
      tiempoSegundos: tiempo,
      fecha: DateTime(0),
    );

void main() {
  group('posicionEnTop (orden: menos movimientos, luego menos tiempo)', () {
    test('entra a un top vacío como #1', () {
      final candidato = p(mov: 5, tiempo: 10);
      expect(FirebaseService.posicionEnTop(const [], candidato), 1);
    });

    test('con menos de 5 jugadores entra aunque sea el peor', () {
      final actuales = [
        p(mov: 4, tiempo: 9),
        p(mov: 6, tiempo: 3),
      ];
      final candidato = p(mov: 8, tiempo: 20);
      expect(FirebaseService.posicionEnTop(actuales, candidato), 3);
    });

    test('no entra si es peor que el 5º actual', () {
      final actuales = [
        p(mov: 3, tiempo: 5),
        p(mov: 4, tiempo: 6),
        p(mov: 5, tiempo: 7),
        p(mov: 6, tiempo: 8),
        p(mov: 9, tiempo: 1),
      ];
      final candidato = p(mov: 10, tiempo: 1);
      expect(FirebaseService.posicionEnTop(actuales, candidato), isNull);
    });

    test('entra en el medio con el puesto correcto', () {
      final actuales = [
        p(mov: 3, tiempo: 5),
        p(mov: 5, tiempo: 7),
        p(mov: 7, tiempo: 9),
        p(mov: 8, tiempo: 1),
        p(mov: 9, tiempo: 1),
      ];
      // Orden esperado: 3, 5, 6, 7, 8, 9 → posición 3.
      final candidato = p(mov: 6, tiempo: 1);
      expect(FirebaseService.posicionEnTop(actuales, candidato), 3);
    });

    test('desempata por tiempo cuando hay iguales movimientos', () {
      final actuales = [
        p(mov: 4, tiempo: 9),
        p(mov: 5, tiempo: 7),
      ];

      // Peor tiempo con mismos movimientos → detrás del igual.
      expect(
        FirebaseService.posicionEnTop(actuales, p(mov: 4, tiempo: 12)),
        2,
      );
      // Mejor tiempo con mismos movimientos → delante del igual (quedaría #2,
      // detrás del jugador con 4 movimientos).
      expect(
        FirebaseService.posicionEnTop(actuales, p(mov: 5, tiempo: 5)),
        2,
      );
    });

    test('descarta el puntaje previo del mismo id (se actualiza en su lugar)', () {
      final actuales = [
        p(id: 'u1', mov: 3, tiempo: 5),
        p(id: 'u2', mov: 5, tiempo: 7),
        p(id: 'u3', mov: 7, tiempo: 9),
        p(id: 'u4', mov: 8, tiempo: 1),
        p(id: 'u5', mov: 9, tiempo: 1),
      ];
      // u1 mejora a 2 movimientos.
      final candidato = p(id: 'u1', mov: 2, tiempo: 3);
      expect(FirebaseService.posicionEnTop(actuales, candidato), 1);
    });
  });

  group('PuntajeGlobal.compareTo / esMejorQue', () {
    test('compara por movimientos y luego por tiempo', () {
      expect(p(mov: 4, tiempo: 9).compareTo(p(mov: 4, tiempo: 9)), 0);
      expect(p(mov: 3, tiempo: 99).esMejorQue(p(mov: 4, tiempo: 1)), isTrue);
      expect(p(mov: 5, tiempo: 10).esMejorQue(p(mov: 5, tiempo: 8)), isFalse);
    });
  });
}
