import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sliding_puzzle/logic/puzzle_logic.dart';
import 'package:sliding_puzzle/services/daily_challenge_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(const {});
  });

  group('semillaDe', () {
    test('formatea la fecha UTC como YYYYMMDD', () {
      expect(
        DailyChallengeService.semillaDe(DateTime.utc(2026, 9, 19)),
        20260919,
      );
    });

    test('rellena mes y día de un solo dígito', () {
      // Sin el relleno, enero daría 202615 en vez de 20260105 y las semillas
      // dejarían de ordenar como las fechas.
      expect(
        DailyChallengeService.semillaDe(DateTime.utc(2026, 1, 5)),
        20260105,
      );
    });

    test('normaliza a UTC antes de formatear', () {
      // 2026-09-18 23:00 en UTC-3 son las 02:00 UTC del 19: ya es otro día.
      // Se construye con offset explícito para que el test no dependa del huso
      // horario de la máquina que lo corre.
      final conOffset = DateTime.parse('2026-09-18T23:00:00-03:00');
      expect(DailyChallengeService.semillaDe(conOffset), 20260919);
    });

    test('las semillas ordenan igual que las fechas', () {
      final diecinueve = DailyChallengeService.semillaDe(
        DateTime.utc(2026, 9, 19),
      );
      final veinte = DailyChallengeService.semillaDe(DateTime.utc(2026, 9, 20));
      final finDeMes = DailyChallengeService.semillaDe(
        DateTime.utc(2026, 9, 30),
      );
      final mesSiguiente = DailyChallengeService.semillaDe(
        DateTime.utc(2026, 10, 1),
      );

      expect(diecinueve, lessThan(veinte));
      expect(veinte, lessThan(finDeMes));
      // El salto de mes es el caso que rompería un formato mal armado.
      expect(finDeMes, lessThan(mesSiguiente));
    });
  });

  group('candado de un intento por día', () {
    test('sin haber jugado nunca, no jugó hoy', () async {
      expect(
        await DailyChallengeService.yaJugoHoy(ahora: DateTime.utc(2026, 9, 19)),
        isFalse,
      );
    });

    test('después de marcar, ya jugó ese mismo día a cualquier hora', () async {
      await DailyChallengeService.marcarJugadoHoy(
        ahora: DateTime.utc(2026, 9, 19, 12),
      );

      expect(
        await DailyChallengeService.yaJugoHoy(
          ahora: DateTime.utc(2026, 9, 19, 12),
        ),
        isTrue,
      );
      expect(
        await DailyChallengeService.yaJugoHoy(
          ahora: DateTime.utc(2026, 9, 19, 23, 59, 59),
        ),
        isTrue,
      );
    });

    test('al cruzar la medianoche UTC el candado se reinicia', () async {
      final antes = DateTime.utc(2026, 9, 19, 23, 59, 59);
      final despues = DateTime.utc(2026, 9, 20, 0, 0, 1);

      await DailyChallengeService.marcarJugadoHoy(ahora: antes);
      expect(await DailyChallengeService.yaJugoHoy(ahora: antes), isTrue);

      expect(
        await DailyChallengeService.yaJugoHoy(ahora: despues),
        isFalse,
        reason: 'un segundo después de la medianoche UTC ya es otro desafío',
      );
    });

    test('la semilla también cambia al cruzar la medianoche', () {
      final antes = DateTime.utc(2026, 9, 19, 23, 59, 59);
      final despues = DateTime.utc(2026, 9, 20, 0, 0, 1);

      expect(DailyChallengeService.semillaDe(antes), 20260919);
      expect(DailyChallengeService.semillaDe(despues), 20260920);
    });

    test('el candado es por día exacto, no acumulativo', () async {
      await DailyChallengeService.marcarJugadoHoy(
        ahora: DateTime.utc(2026, 9, 19),
      );

      expect(
        await DailyChallengeService.yaJugoHoy(ahora: DateTime.utc(2026, 9, 18)),
        isFalse,
      );
      expect(
        await DailyChallengeService.yaJugoHoy(ahora: DateTime.utc(2026, 9, 20)),
        isFalse,
      );
    });

    test('sobrevive a un salto largo de días sin quedar pegado', () async {
      // Alguien que jugó y volvió tres semanas después tiene que poder jugar.
      await DailyChallengeService.marcarJugadoHoy(
        ahora: DateTime.utc(2026, 9, 19),
      );

      expect(
        await DailyChallengeService.yaJugoHoy(ahora: DateTime.utc(2026, 10, 9)),
        isFalse,
      );
    });

    test('reiniciar borra el candado', () async {
      final hoy = DateTime.utc(2026, 9, 19);
      await DailyChallengeService.marcarJugadoHoy(ahora: hoy);
      expect(await DailyChallengeService.yaJugoHoy(ahora: hoy), isTrue);

      await DailyChallengeService.reiniciar();
      expect(await DailyChallengeService.yaJugoHoy(ahora: hoy), isFalse);
    });
  });

  group('foto del día en Cloud Storage', () {
    test('la ruta es daily/YYYYMMDD.jpg', () {
      // El nombre es la fecha, así subir la foto del día es solo dejar el
      // archivo con el nombre correcto: sin índice ni configuración.
      expect(DailyChallengeService.rutaImagen(20260919), 'daily/20260919.jpg');
      expect(DailyChallengeService.rutaImagen(20260105), 'daily/20260105.jpg');
    });

    test('cada día apunta a un archivo distinto', () {
      expect(
        DailyChallengeService.rutaImagen(20260919),
        isNot(DailyChallengeService.rutaImagen(20260920)),
      );
    });

    test('sin Firebase disponible cae a la foto de respaldo', () async {
      // Es el caso que importa: sin red, sin Storage configurado, o si la foto
      // del día todavía no se subió. El desafío tiene que seguir jugándose.
      final imagen = await DailyChallengeService.imagenDe(20260919);

      expect(imagen, same(DailyChallengeService.imagenRespaldo));
    });
  });

  group('clave de caché de la foto del día', () {
    const url = 'https://storage.example/v0/b/x/o/daily.jpg?alt=media&token=a';

    test('cada día tiene su propia entrada de caché', () {
      // Aunque Storage devolviera la misma URL para dos fechas —con un CDN o un
      // proxy por delante dejaría de ser imposible— la clave no se puede
      // compartir: el tablero de hoy mostraría la foto de ayer.
      expect(
        DailyChallengeService.claveCacheImagen(20260919, url),
        isNot(DailyChallengeService.claveCacheImagen(20260920, url)),
      );
    });

    test('la misma foto da siempre la misma clave', () {
      expect(
        DailyChallengeService.claveCacheImagen(20260919, url),
        DailyChallengeService.claveCacheImagen(20260919, url),
      );
    });

    test('reemplazar la foto del día renueva la clave', () {
      // Al reemplazar el archivo, Storage emite un token nuevo. Si la clave
      // quedara fija en la semilla, `CachedNetworkImageProvider` compararía los
      // dos providers como iguales (`cacheKey ?? url`) y el `Image` ni siquiera
      // volvería a pedir la imagen: seguiría sirviendo la vieja.
      expect(
        DailyChallengeService.claveCacheImagen(20260919, 'url-vieja'),
        isNot(DailyChallengeService.claveCacheImagen(20260919, 'url-nueva')),
      );
    });
  });

  group('reloj inyectable', () {
    tearDown(() => DailyChallengeService.reloj = DateTime.now);

    test('semillaHoy sale del reloj', () {
      DailyChallengeService.reloj = () => DateTime.utc(2026, 9, 19, 23, 30);
      expect(DailyChallengeService.semillaHoy, 20260919);
    });

    test('tableroHoy sigue al reloj', () {
      DailyChallengeService.reloj = () => DateTime.utc(2026, 9, 19);
      final del19 = DailyChallengeService.tableroHoy();

      DailyChallengeService.reloj = () => DateTime.utc(2026, 9, 20);
      expect(DailyChallengeService.tableroHoy(), isNot(equals(del19)));
    });

    test('yaJugoHoy sin argumento lee el reloj', () async {
      DailyChallengeService.reloj = () => DateTime.utc(2026, 9, 19);
      await DailyChallengeService.marcarJugadoHoy();
      expect(await DailyChallengeService.yaJugoHoy(), isTrue);

      // Un segundo después de la medianoche UTC ya es otro desafío: el candado
      // tiene que destrabarse solo, sin que nadie limpie nada.
      DailyChallengeService.reloj = () => DateTime.utc(2026, 9, 20, 0, 0, 1);
      expect(await DailyChallengeService.yaJugoHoy(), isFalse);
    });

    test('un DateTime explícito le gana al reloj', () async {
      DailyChallengeService.reloj = () => DateTime.utc(2026, 9, 20);
      await DailyChallengeService.marcarJugadoHoy(
        ahora: DateTime.utc(2026, 9, 19),
      );

      expect(
        await DailyChallengeService.yaJugoHoy(ahora: DateTime.utc(2026, 9, 19)),
        isTrue,
      );
      expect(
        await DailyChallengeService.yaJugoHoy(),
        isFalse,
        reason: 'sin argumento manda el reloj, que acá apunta al día siguiente',
      );
    });
  });

  group('tablero determinista', () {
    test('la misma fecha da siempre el mismo tablero', () {
      // Es la garantía que hace que todos jueguen lo mismo sin sincronizar
      // nada: el tablero se deriva de la fecha, no se guarda.
      final manana = DailyChallengeService.tableroDe(DateTime.utc(2026, 9, 19));
      final noche = DailyChallengeService.tableroDe(
        DateTime.utc(2026, 9, 19, 23),
      );
      expect(manana, equals(noche), reason: 'la hora del día no debe influir');
    });

    test('fechas distintas dan tableros distintos', () {
      final hoy = DailyChallengeService.tableroDe(DateTime.utc(2026, 9, 19));
      final manana = DailyChallengeService.tableroDe(DateTime.utc(2026, 9, 20));
      expect(hoy, isNot(equals(manana)));
    });

    test('el tablero tiene el tamaño del diario, sin fichas repetidas', () {
      final tablero = DailyChallengeService.tableroDe(
        DateTime.utc(2026, 9, 19),
      );
      final total = PuzzleLogic.diarioSize * PuzzleLogic.diarioSize;

      expect(tablero.length, total);
      expect(tablero.where((n) => n == 0).length, 1, reason: 'un solo hueco');
      expect(tablero.toSet().length, total, reason: 'sin repetidas');
    });

    test('un mes entero de tableros es resoluble y no arranca resuelto', () {
      // La garantía que da el scramble inverso. Sin esto, un día podría
      // amanecer con un tablero imposible y el desafío sería injugable para
      // todo el mundo a la vez, sin forma de saltearlo.
      for (var dia = 1; dia <= 30; dia++) {
        final tablero = PuzzleLogic.generarTableroDiario(20260900 + dia);
        expect(
          PuzzleLogic.tieneSolucion(tablero, PuzzleLogic.diarioSize),
          isTrue,
          reason: 'el tablero del día $dia no tiene solución',
        );
        expect(
          PuzzleLogic.estaResuelto(tablero),
          isFalse,
          reason: 'el tablero del día $dia arranca resuelto',
        );
      }
    });

    test('el tablero no depende del candado ni de nada en disco', () {
      // `tableroDe` es puro: mismo resultado con el candado marcado o no.
      final antes = DailyChallengeService.tableroDe(DateTime.utc(2026, 9, 19));
      return DailyChallengeService.marcarJugadoHoy(
        ahora: DateTime.utc(2026, 9, 19),
      ).then((_) {
        final despues = DailyChallengeService.tableroDe(
          DateTime.utc(2026, 9, 19),
        );
        expect(despues, equals(antes));
      });
    });
  });
}
