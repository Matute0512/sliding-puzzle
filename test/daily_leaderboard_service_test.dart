import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sliding_puzzle/l10n/app_localizations_en.dart';
import 'package:sliding_puzzle/l10n/app_localizations_es.dart';
import 'package:sliding_puzzle/services/daily_challenge_service.dart';
import 'package:sliding_puzzle/services/daily_leaderboard_service.dart';

PuntajeDiario _p({
  String? id,
  String alias = 'AAA',
  required int segundos,
  required int movimientos,
}) =>
    PuntajeDiario(
      id: id,
      alias: alias,
      movimientos: movimientos,
      tiempoSegundos: segundos,
      fecha: DateTime(2026, 9, 19),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues(const {}));

  group('orden del ranking diario', () {
    test('manda el tiempo, no los movimientos', () {
      // Es la diferencia clave con el Top 5 clásico, que ordena por
      // movimientos primero. Acá el tablero es el mismo para todos, así que
      // quien hizo menos movimientos no es "mejor": el óptimo es casi el mismo.
      final rapido = _p(segundos: 30, movimientos: 40);
      final lento = _p(segundos: 90, movimientos: 12);

      expect(rapido.esMejorQue(lento), isTrue);
      expect(lento.esMejorQue(rapido), isFalse);
    });

    test('en empate de tiempo desempata por movimientos', () {
      final eficiente = _p(segundos: 45, movimientos: 18);
      final desprolijo = _p(segundos: 45, movimientos: 33);

      expect(eficiente.esMejorQue(desprolijo), isTrue);
      expect(desprolijo.esMejorQue(eficiente), isFalse);
      expect(eficiente.compareTo(desprolijo), lessThan(0));
    });

    test('dos puntajes idénticos empatan', () {
      expect(
        _p(segundos: 45, movimientos: 20).compareTo(
          _p(segundos: 45, movimientos: 20),
        ),
        0,
      );
    });
  });

  group('posicionEnTop', () {
    final top = [
      _p(id: 'a', segundos: 30, movimientos: 20),
      _p(id: 'b', segundos: 40, movimientos: 25),
      _p(id: 'c', segundos: 50, movimientos: 30),
      _p(id: 'd', segundos: 60, movimientos: 35),
      _p(id: 'e', segundos: 70, movimientos: 40),
    ];

    test('entra primero si es el más rápido', () {
      expect(
        DailyLeaderboardService.posicionEnTop(
          top,
          _p(id: 'nuevo', segundos: 10, movimientos: 99),
        ),
        1,
      );
    });

    test('entra en el medio según su tiempo', () {
      expect(
        DailyLeaderboardService.posicionEnTop(
          top,
          _p(id: 'nuevo', segundos: 45, movimientos: 28),
        ),
        3,
      );
    });

    test('no entra si es más lento que el quinto', () {
      expect(
        DailyLeaderboardService.posicionEnTop(
          top,
          _p(id: 'nuevo', segundos: 80, movimientos: 10),
        ),
        isNull,
      );
    });

    test('entra con la tabla incompleta', () {
      expect(
        DailyLeaderboardService.posicionEnTop(
          [top.first],
          _p(id: 'nuevo', segundos: 999, movimientos: 99),
        ),
        2,
        reason: 'con menos de 5 puntajes siempre hay lugar',
      );
    });

    test('descarta el puntaje previo del mismo uid', () {
      // Si el mismo jugador vuelve a subir, su marca vieja no debe competir
      // contra él mismo: si no, aparecería dos veces en la tabla y la posición
      // saldría corrida.
      expect(
        DailyLeaderboardService.posicionEnTop(
          top,
          _p(id: 'a', segundos: 65, movimientos: 40),
        ),
        4,
        reason: 'con el previo de "a" descartado, 65s cae entre 60s y 70s',
      );
    });
  });

  group('resultado local del día', () {
    test('sin nada guardado no hay resultado', () async {
      expect(await DailyChallengeService.resultadoDe(20260919), isNull);
    });

    test('guarda y devuelve el resultado del día', () async {
      await DailyChallengeService.guardarResultado(
        const ResultadoDiario(
          semilla: 20260919,
          movimientos: 24,
          segundos: 71,
        ),
      );

      final resultado = await DailyChallengeService.resultadoDe(20260919);
      expect(resultado, isNotNull);
      expect(resultado!.movimientos, 24);
      expect(resultado.segundos, 71);
    });

    test('un resultado de otro día no cuenta como el de hoy', () async {
      // Es lo que evita que el botón de compartir muestre el tiempo de ayer.
      await DailyChallengeService.guardarResultado(
        const ResultadoDiario(
          semilla: 20260918,
          movimientos: 24,
          segundos: 71,
        ),
      );

      expect(await DailyChallengeService.resultadoDe(20260919), isNull);
      expect(await DailyChallengeService.resultadoDe(20260918), isNotNull);
    });

    test('datos corruptos no rompen la lectura', () async {
      SharedPreferences.setMockInitialValues(
        const {'desafio_diario_resultado': 'esto no es json'},
      );

      expect(await DailyChallengeService.resultadoDe(20260919), isNull);
    });

    test('reiniciar borra también el resultado guardado', () async {
      await DailyChallengeService.guardarResultado(
        const ResultadoDiario(
          semilla: 20260919,
          movimientos: 24,
          segundos: 71,
        ),
      );

      await DailyChallengeService.reiniciar();

      expect(await DailyChallengeService.resultadoDe(20260919), isNull);
    });
  });

  group('candado con semilla explícita', () {
    test('marcarJugado consume el día que se le pasa, no el de hoy', () async {
      // Es el caso de la partida que cruza la medianoche UTC: empezó el 19 y
      // terminó el 20. Lo consumido tiene que ser el 19, que es el tablero que
      // el jugador realmente vio.
      await DailyChallengeService.marcarJugado(20260919);

      expect(
        await DailyChallengeService.yaJugoHoy(ahora: DateTime.utc(2026, 9, 19)),
        isTrue,
      );
      expect(
        await DailyChallengeService.yaJugoHoy(ahora: DateTime.utc(2026, 9, 20)),
        isFalse,
        reason: 'el desafío del 20 sigue disponible: nunca lo jugó',
      );
    });
  });

  group('texto para compartir', () {
    test('incluye semilla, tiempo, movimientos y link', () {
      final texto = AppLocalizationsEs().dailyShareText(
        '20260919',
        '1m 11s',
        24,
        'https://ejemplo.test/app',
      );

      expect(texto, contains('#20260919'));
      expect(texto, contains('1m 11s'));
      expect(texto, contains('24'));
      expect(texto, contains('https://ejemplo.test/app'));
    });

    test('la semilla no lleva separador de miles', () {
      // Por esto la semilla viaja como String: como `int`, ICU la formatearía
      // y el texto compartido diría "20.260.919" en vez de "20260919".
      final texto = AppLocalizationsEs().dailyShareText(
        '20260919',
        '45s',
        20,
        'https://ejemplo.test/app',
      );

      expect(texto, contains('20260919'));
      expect(texto, isNot(contains('20.260.919')));
      expect(texto, isNot(contains('20,260,919')));
    });

    test('el inglés usa su propio texto pero los mismos datos', () {
      final texto = AppLocalizationsEn().dailyShareText(
        '20260919',
        '45s',
        20,
        'https://ejemplo.test/app',
      );

      expect(texto, contains('#20260919'));
      expect(texto, contains('45s'));
      expect(texto, contains('https://ejemplo.test/app'));
    });
  });
}
