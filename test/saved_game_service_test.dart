import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sliding_puzzle/services/saved_game_service.dart';

/// Tablero 3x3 válido con el hueco (0) en el índice 7.
const List<int> _tablero3x3 = [1, 2, 3, 4, 5, 6, 7, 0, 8];

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(const {}));

  group('SavedGameService', () {
    test('sin partida guardada devuelve null', () async {
      expect(await SavedGameService.obtener(), isNull);
    });

    test('guarda y recupera una partida libre', () async {
      const partida = PartidaGuardada(
        esDesafio: false,
        size: 3,
        nivel: null,
        tablero: _tablero3x3,
        movimientos: 12,
        segundos: 45,
      );
      await SavedGameService.guardar(partida);

      final leida = await SavedGameService.obtener();
      expect(leida, isNotNull);
      expect(leida!.esDesafio, isFalse);
      expect(leida.size, 3);
      expect(leida.nivel, isNull);
      expect(leida.tablero, _tablero3x3);
      expect(leida.movimientos, 12);
      expect(leida.segundos, 45);
    });

    test('guarda y recupera una partida del Modo Desafío', () async {
      // Nivel 1 → tablero 3x3.
      const partida = PartidaGuardada(
        esDesafio: true,
        size: 3,
        nivel: 1,
        tablero: _tablero3x3,
        movimientos: 2,
        segundos: 7,
      );
      await SavedGameService.guardar(partida);

      final leida = await SavedGameService.obtener();
      expect(leida, isNotNull);
      expect(leida!.esDesafio, isTrue);
      expect(leida.nivel, 1);
      expect(leida.size, 3);
    });

    test('guardar dos veces reemplaza la partida anterior', () async {
      await SavedGameService.guardar(
        const PartidaGuardada(
          esDesafio: false,
          size: 3,
          nivel: null,
          tablero: _tablero3x3,
          movimientos: 1,
          segundos: 1,
        ),
      );
      await SavedGameService.guardar(
        const PartidaGuardada(
          esDesafio: false,
          size: 4,
          nivel: null,
          tablero: [
            1, 2, 3, 4, //
            5, 6, 7, 8, //
            9, 10, 11, 12, //
            13, 14, 0, 15,
          ],
          movimientos: 9,
          segundos: 99,
        ),
      );

      final leida = await SavedGameService.obtener();
      expect(leida!.size, 4);
      expect(leida.movimientos, 9);
    });

    test('borrar elimina la partida guardada', () async {
      await SavedGameService.guardar(
        const PartidaGuardada(
          esDesafio: false,
          size: 3,
          nivel: null,
          tablero: _tablero3x3,
          movimientos: 3,
          segundos: 3,
        ),
      );
      await SavedGameService.borrar();

      expect(await SavedGameService.obtener(), isNull);
    });

    test('los datos corruptos se descartan y se limpian de prefs', () async {
      SharedPreferences.setMockInitialValues({
        'partida_guardada': 'esto no es JSON {{{',
      });

      expect(await SavedGameService.obtener(), isNull);

      // La clave inválida se borra: si no, quedaría basura imborrable que
      // nadie puede leer ni limpiar desde la UI.
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('partida_guardada'), isNull);
    });
  });

  group('PartidaGuardada.desdeJson rechaza datos inválidos', () {
    Map<String, dynamic> jsonValido() => {
      'es_desafio': false,
      'size': 3,
      'nivel': null,
      'tablero': _tablero3x3,
      'movimientos': 0,
      'segundos': 0,
    };

    test('acepta el JSON válido', () {
      expect(PartidaGuardada.desdeJson(jsonValido()), isNotNull);
    });

    test('rechaza un tablero con fichas repetidas', () {
      final json = jsonValido()..['tablero'] = [1, 2, 3, 4, 5, 6, 7, 0, 0];
      expect(PartidaGuardada.desdeJson(json), isNull);
    });

    test('rechaza un tablero con el tamaño equivocado', () {
      final json = jsonValido()..['tablero'] = [1, 2, 3, 0];
      expect(PartidaGuardada.desdeJson(json), isNull);
    });

    test('rechaza un tablero que no es una lista de enteros', () {
      final json = jsonValido()..['tablero'] = 'no soy un tablero';
      expect(PartidaGuardada.desdeJson(json), isNull);
    });

    test('rechaza movimientos o segundos negativos', () {
      expect(
        PartidaGuardada.desdeJson(jsonValido()..['movimientos'] = -1),
        isNull,
      );
      expect(PartidaGuardada.desdeJson(jsonValido()..['segundos'] = -5), isNull);
    });

    test('rechaza un tamaño fuera de rango', () {
      expect(PartidaGuardada.desdeJson(jsonValido()..['size'] = 1), isNull);
      expect(PartidaGuardada.desdeJson(jsonValido()..['size'] = 99), isNull);
    });

    test('una partida libre no puede traer nivel', () {
      final json = jsonValido()..['nivel'] = 3;
      expect(PartidaGuardada.desdeJson(json), isNull);
    });

    test('el Desafío rechaza un nivel fuera de 1..20', () {
      for (final nivel in [0, 21]) {
        final json = jsonValido()
          ..['es_desafio'] = true
          ..['nivel'] = nivel;
        expect(PartidaGuardada.desdeJson(json), isNull, reason: 'nivel $nivel');
      }
    });

    test('el nivel del Desafío debe corresponder al tamaño del tablero', () {
      // Del 11 al 20 el tablero es 4x4; un 3x3 con nivel 15 está mal formado.
      final json = jsonValido()
        ..['es_desafio'] = true
        ..['nivel'] = 15;
      expect(PartidaGuardada.desdeJson(json), isNull);
    });
  });
}
