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
    test('la ruta es daily/YYYYMMDD.webp', () {
      // El nombre es la fecha, así subir la foto del día es solo dejar el
      // archivo con el nombre correcto: sin índice ni configuración.
      expect(DailyChallengeService.rutaImagen(20260919), 'daily/20260919.webp');
      expect(DailyChallengeService.rutaImagen(20260105), 'daily/20260105.webp');
    });

    test('la extensión es la que produce el script de optimización', () {
      // Storage no negocia formatos: no falla al resolver la URL, devuelve
      // `object-not-found` y el tablero cae al respaldo en silencio. Un
      // desajuste acá ya costó un hotfix (era `.jpg` y las fotos son `.webp`),
      // así que la extensión queda clavada por test.
      expect(
        DailyChallengeService.rutaImagen(20260919),
        endsWith('.webp'),
        reason: 'tiene que coincidir con lo que sube el script de optimización',
      );
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

  group('racha diaria y escudo protector', () {
    tearDown(() => DailyChallengeService.reloj = DateTime.now);

    test('diasEntreSemillas calcula días exactos cruzando fin de mes y bisiesto', () {
      expect(DailyChallengeService.diasEntreSemillas(20260919, 20260919), 0);
      expect(DailyChallengeService.diasEntreSemillas(20260919, 20260920), 1);
      expect(DailyChallengeService.diasEntreSemillas(20260930, 20261001), 1);
      expect(DailyChallengeService.diasEntreSemillas(20261231, 20270101), 1);
      // 2028 es bisiesto (febrero tiene 29 días)
      expect(DailyChallengeService.diasEntreSemillas(20280228, 20280301), 2);
    });

    test('arranca en 0 y sube con victorias en días consecutivos', () async {
      final inicial = await DailyChallengeService.estadoRacha(
        ahora: DateTime.utc(2026, 9, 19),
      );
      expect(inicial.rachaActual, 0);
      expect(inicial.mejorRacha, 0);
      expect(inicial.enRiesgo, isFalse);

      // Día 1
      await DailyChallengeService.marcarJugado(20260919);
      final dia1 = await DailyChallengeService.estadoRacha(
        ahora: DateTime.utc(2026, 9, 19),
      );
      expect(dia1.rachaActual, 1);
      expect(dia1.mejorRacha, 1);
      expect(dia1.enRiesgo, isFalse);

      // Al día siguiente antes de jugar, la racha de 1 sigue vigente
      final mananaAntes = await DailyChallengeService.estadoRacha(
        ahora: DateTime.utc(2026, 9, 20),
      );
      expect(mananaAntes.rachaActual, 1);
      expect(mananaAntes.enRiesgo, isFalse);

      // Día 2
      await DailyChallengeService.marcarJugado(20260920);
      final dia2 = await DailyChallengeService.estadoRacha(
        ahora: DateTime.utc(2026, 9, 20),
      );
      expect(dia2.rachaActual, 2);
      expect(dia2.mejorRacha, 2);

      // Marcar el mismo día otra vez es idempotente
      await DailyChallengeService.marcarJugado(20260920);
      final repetido = await DailyChallengeService.estadoRacha(
        ahora: DateTime.utc(2026, 9, 20),
      );
      expect(repetido.rachaActual, 2);
    });

    test('detecta racha en riesgo al saltear 1 día y permite repararla', () async {
      await DailyChallengeService.marcarJugado(20260918);
      await DailyChallengeService.marcarJugado(20260919);
      await DailyChallengeService.marcarJugado(20260920);

      // Saltea el 21 y abre el 22 (distancia = 2 días)
      final enRiesgo = await DailyChallengeService.estadoRacha(
        ahora: DateTime.utc(2026, 9, 22),
      );
      expect(enRiesgo.rachaActual, 0);
      expect(enRiesgo.rachaSalvable, 3);
      expect(enRiesgo.enRiesgo, isTrue);
      expect(enRiesgo.mejorRacha, 3);

      // Repara la racha el día 22
      final reparada = await DailyChallengeService.repararRacha(
        ahora: DateTime.utc(2026, 9, 22),
      );
      expect(reparada, isTrue);

      final trasReparar = await DailyChallengeService.estadoRacha(
        ahora: DateTime.utc(2026, 9, 22),
      );
      expect(trasReparar.rachaActual, 3);
      expect(trasReparar.enRiesgo, isFalse);

      // Al ganar hoy (día 22), la racha sube a 4
      await DailyChallengeService.marcarJugado(20260922);
      final trasGanar = await DailyChallengeService.estadoRacha(
        ahora: DateTime.utc(2026, 9, 22),
      );
      expect(trasGanar.rachaActual, 4);
      expect(trasGanar.mejorRacha, 4);
    });

    test('si no repara y juega con racha en riesgo, se reinicia a 1 conservando mejorRacha', () async {
      await DailyChallengeService.marcarJugado(20260918);
      await DailyChallengeService.marcarJugado(20260919);

      // Saltea el 20 y gana el 21 sin reparar
      await DailyChallengeService.marcarJugado(20260921);
      final estado = await DailyChallengeService.estadoRacha(
        ahora: DateTime.utc(2026, 9, 21),
      );
      expect(estado.rachaActual, 1);
      expect(estado.mejorRacha, 2);
      expect(estado.enRiesgo, isFalse);
    });

    test('si saltea 2 o más días seguidos, la racha expira y no es reparable', () async {
      await DailyChallengeService.marcarJugado(20260918);
      await DailyChallengeService.marcarJugado(20260919);

      // Abre el 22 (faltó 20 y 21 -> distancia = 3 días)
      final expirada = await DailyChallengeService.estadoRacha(
        ahora: DateTime.utc(2026, 9, 22),
      );
      expect(expirada.rachaActual, 0);
      expect(expirada.rachaSalvable, 0);
      expect(expirada.enRiesgo, isFalse);
      expect(expirada.mejorRacha, 2);

      expect(
        await DailyChallengeService.repararRacha(
          ahora: DateTime.utc(2026, 9, 22),
        ),
        isFalse,
      );
    });

    test('retrocompatibilidad v25: infiere racha 1 si existe ultimo_dia sin clave de racha', () async {
      SharedPreferences.setMockInitialValues({
        'desafio_diario_ultimo_dia': 20260919,
      });

      final estadoAyer = await DailyChallengeService.estadoRacha(
        ahora: DateTime.utc(2026, 9, 20),
      );
      expect(estadoAyer.rachaActual, 1);
      expect(estadoAyer.mejorRacha, 1);

      await DailyChallengeService.marcarJugado(20260920);
      final estadoHoy = await DailyChallengeService.estadoRacha(
        ahora: DateTime.utc(2026, 9, 20),
      );
      expect(estadoHoy.rachaActual, 2);
      expect(estadoHoy.mejorRacha, 2);
    });
  });
}
