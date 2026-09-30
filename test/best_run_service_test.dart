import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sliding_puzzle/services/best_run_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(const {});
  });

  MejorPartida marca({
    int segundos = 60,
    int movs = 40,
    int tamano = 4,
  }) => MejorPartida(
    tiempoSegundos: segundos,
    movimientos: movs,
    tamano: tamano,
    fecha: DateTime(2026, 9, 30),
  );

  group('MejorPartida', () {
    test('ordena por movimientos y desempata por tiempo', () {
      // Es el orden del Top 5: la tarjeta y la pantalla de récords no pueden
      // contradecirse sobre cuál marca es mejor.
      expect(marca(movs: 30).esMejorQue(marca(movs: 40)), isTrue);
      expect(marca(movs: 40).esMejorQue(marca(movs: 30)), isFalse);

      // A igual cantidad de movimientos gana el más rápido.
      expect(
        marca(movs: 40, segundos: 50).esMejorQue(marca(movs: 40, segundos: 60)),
        isTrue,
      );

      // Una marca idéntica no mejora a sí misma: sin esto, cada partida
      // reescribiría el disco al pedo.
      expect(marca().esMejorQue(marca()), isFalse);
    });

    test('sobrevive al viaje por JSON', () {
      final original = marca();
      final copia = MejorPartida.fromJson(original.toJson())!;

      expect(copia.tiempoSegundos, original.tiempoSegundos);
      expect(copia.movimientos, original.movimientos);
      expect(copia.tamano, original.tamano);
      expect(copia.fecha, original.fecha);
    });

    test('un JSON incompleto se descarta en vez de romper', () {
      expect(MejorPartida.fromJson(const {'movimientos': 40}), isNull);
      expect(MejorPartida.fromJson(const {}), isNull);
    });
  });

  group('RecordsPersonales', () {
    test('sin último tablero no hay marca vigente', () {
      const records = RecordsPersonales();
      expect(records.vigente, isNull);
    });

    test('descarta una marca guardada bajo el tamaño equivocado', () {
      // Si no se validara, la tarjeta podría mostrar el tiempo de un 3×3 bajo
      // la etiqueta "Récord en 5×5".
      final records = RecordsPersonales.fromJson({
        'ultimoTamano': 5,
        'porTablero': {
          '5': marca(tamano: 3).toJson(),
        },
      });

      expect(records.porTablero, isEmpty);
      expect(records.vigente, isNull);
    });

    test('ignora un último tablero que no tiene marca', () {
      final records = RecordsPersonales.fromJson({
        'ultimoTamano': 5,
        'porTablero': <String, dynamic>{},
      });

      expect(records.ultimoTamano, isNull);
      expect(records.vigente, isNull);
    });
  });

  group('BestRunService', () {
    test('sin nada guardado devuelve null', () async {
      expect(await BestRunService.obtenerVigente(), isNull);
    });

    test('el tablero vigente es el último completado, no el de mejor marca', () async {
      // El caso que motivó el cambio: un 3×3 casi siempre tiene menos
      // movimientos que un 5×5. Si la tarjeta eligiera el mejor absoluto,
      // mostraría el 3×3 para siempre y el jugador de 5×5 nunca vería lo suyo.
      await BestRunService.registrarPartida(marca(movs: 15, tamano: 3));
      await BestRunService.registrarPartida(marca(movs: 200, tamano: 5));

      expect((await BestRunService.obtenerVigente())!.tamano, 5);
    });

    test('conserva la marca de cada tablero por separado', () async {
      await BestRunService.registrarPartida(marca(movs: 40, segundos: 60, tamano: 3));
      await BestRunService.registrarPartida(marca(movs: 80, segundos: 90, tamano: 5));

      // Vuelve al 3×3 con una partida mala: tiene que encontrar su marca
      // intacta, no la del 5×5 ni la recién jugada.
      await BestRunService.registrarPartida(marca(movs: 999, segundos: 999, tamano: 3));

      final vigente = (await BestRunService.obtenerVigente())!;
      expect(vigente.tamano, 3);
      expect(vigente.movimientos, 40);
      expect(vigente.tiempoSegundos, 60);
    });

    test('dentro del mismo tablero solo reemplaza si mejora', () async {
      await BestRunService.registrarPartida(marca(movs: 40, tamano: 4));

      // Peor: no reemplaza.
      await BestRunService.registrarPartida(marca(movs: 55, tamano: 4));
      expect((await BestRunService.obtenerVigente())!.movimientos, 40);

      // Mejor: reemplaza.
      await BestRunService.registrarPartida(marca(movs: 35, tamano: 4));
      expect((await BestRunService.obtenerVigente())!.movimientos, 35);
    });

    test('un caché corrupto se trata como "todavía no hay récord"', () async {
      // Es preferible perder las marcas —se vuelven a generar jugando— a que el
      // menú no abra.
      SharedPreferences.setMockInitialValues(
        const {'records_personales': 'esto no es json'},
      );

      expect(await BestRunService.obtenerVigente(), isNull);
    });

    test('refrescar sin Firebase conserva lo local y no rompe', () async {
      // Sin `Firebase.initializeApp`, esto es el caso offline: `obtenerMejorPropio`
      // atrapa la excepción y devuelve null, así que el refresco no puede tirar
      // abajo el menú ni borrar la marca que ya estaba en disco.
      await BestRunService.registrarPartida(marca(movs: 40, tamano: 4));

      final resultado = await BestRunService.refrescarDesdeFirestore();

      expect(resultado?.movimientos, 40);
      expect((await BestRunService.obtenerVigente())?.movimientos, 40);
    });

    test('refrescar sin partidas no consulta nada y devuelve null', () async {
      expect(await BestRunService.refrescarDesdeFirestore(), isNull);
    });
  });
}
