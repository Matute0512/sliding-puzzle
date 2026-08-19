import 'package:flutter_test/flutter_test.dart';
import 'package:sliding_puzzle/models/record_game.dart';

void main() {
  group('toJson / fromJson', () {
    test('son inversos entre sí', () {
      const partida = RecordGame(tiempo: 10, movimientos: 5);

      final json = partida.toJson();
      expect(json, const {'tiempo': 10, 'movimientos': 5});

      final recuperada = RecordGame.fromJson(json);
      expect(recuperada.tiempo, partida.tiempo);
      expect(recuperada.movimientos, partida.movimientos);
    });
  });

  group('encodeList / decodeList', () {
    test('son inversos entre sí', () {
      const lista = [
        RecordGame(tiempo: 10, movimientos: 5),
        RecordGame(tiempo: 20, movimientos: 7),
      ];

      final raw = RecordGame.encodeList(lista);
      final decodificada = RecordGame.decodeList(raw);

      expect(decodificada, hasLength(2));
      expect(decodificada[0].tiempo, 10);
      expect(decodificada[0].movimientos, 5);
      expect(decodificada[1].tiempo, 20);
      expect(decodificada[1].movimientos, 7);
    });
  });

  group('decodeList', () {
    test('con string vacío o malformado lanza FormatException (no otro error)', () {
      expect(() => RecordGame.decodeList(''), throwsA(isA<FormatException>()));
      expect(
        () => RecordGame.decodeList('esto no es json'),
        throwsA(isA<FormatException>()),
      );
    });

    test('con "[]" retorna una lista vacía', () {
      expect(RecordGame.decodeList('[]'), isEmpty);
    });
  });
}
