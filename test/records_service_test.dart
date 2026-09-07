import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sliding_puzzle/services/records_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(const {});
  });

  group('limpiarDatosViejos', () {
    test('elimina claves del formato viejo y el historial local de partidas libres',
        () async {
      SharedPreferences.setMockInitialValues(
        const {
          'record_tiempo_3': '90',
          'record_movimientos_5': '50',
          'historial_records_3': '[]',
          'historial_records_4': '[]',
          'historial_records_5': '[]',
        },
      );

      await RecordsService.limpiarDatosViejos();

      final prefs = await SharedPreferences.getInstance();
      const claves = [
        'record_tiempo_3',
        'record_tiempo_4',
        'record_tiempo_5',
        'record_movimientos_3',
        'record_movimientos_4',
        'record_movimientos_5',
        'historial_records_3',
        'historial_records_4',
        'historial_records_5',
      ];
      for (final clave in claves) {
        expect(prefs.containsKey(clave), isFalse, reason: '$clave debe eliminarse');
      }
    });
  });

  group('desafío', () {
    test('el nivel máximo desbloqueado inicia en 1 y sin estrellas', () async {
      expect(await RecordsService.obtenerNivelMaximo(), 1);
      expect(await RecordsService.obtenerEstrellas(), isEmpty);
    });

    test('registrarVictoriaDesafio guarda estrellas y desbloquea el siguiente',
        () async {
      final estrellas = await RecordsService.registrarVictoriaDesafio(
        nivel: 1,
        movimientos: 3, // objetivo del nivel 1 = 3 → 3 estrellas
        objetivo: 3,
      );
      expect(estrellas, 3);
      expect(await RecordsService.obtenerNivelMaximo(), 2);
      expect(await RecordsService.obtenerEstrellas(), {1: 3});
    });

    test('conserva la mejor marca: un peor resultado no degrada', () async {
      await RecordsService.registrarVictoriaDesafio(
        nivel: 2,
        movimientos: 4, // objetivo del nivel 2 = 4 → 3 estrellas
        objetivo: 4,
      );
      await RecordsService.registrarVictoriaDesafio(
        nivel: 2,
        movimientos: 10, // supera el +50% → 1 estrella
        objetivo: 4,
      );
      expect(await RecordsService.obtenerEstrellas(), {2: 3});
    });

    test('nunca desbloquea más allá del nivel 20', () async {
      await RecordsService.registrarVictoriaDesafio(
        nivel: 19,
        movimientos: 10,
        objetivo: 10,
      );
      expect(await RecordsService.obtenerNivelMaximo(), 20);

      await RecordsService.registrarVictoriaDesafio(
        nivel: 20,
        movimientos: 20,
        objetivo: 20,
      );
      expect(await RecordsService.obtenerNivelMaximo(), 20);
    });

    test('obtenerEstrellas ignora datos corruptos', () async {
      SharedPreferences.setMockInitialValues(
        const {'desafio_estrellas': 'no-json'},
      );
      expect(await RecordsService.obtenerEstrellas(), isEmpty);
    });
  });

  group('calificación', () {
    test('por defecto el usuario todavía no calificó la app', () async {
      expect(await RecordsService.yaCalificoApp(), isFalse);
    });

    test('marcarAppCalificada persiste y yaCalificoApp lo refleja', () async {
      expect(await RecordsService.yaCalificoApp(), isFalse);

      await RecordsService.marcarAppCalificada();

      expect(await RecordsService.yaCalificoApp(), isTrue);
    });
  });

  group('alias', () {
    test('por defecto no hay alias guardado', () async {
      expect(await RecordsService.obtenerAlias(), isNull);
    });

    test('guardarAlias normaliza (mayúsculas y sin espacios) y persiste', () async {
      await RecordsService.guardarAlias('  mate ');
      expect(await RecordsService.obtenerAlias(), 'MATE');

      await RecordsService.guardarAlias('LuCaS');
      expect(await RecordsService.obtenerAlias(), 'LUCAS');
    });

    test('guardarAlias limita a 5 letras', () async {
      await RecordsService.guardarAlias('abcdefgh');
      expect(await RecordsService.obtenerAlias(), 'ABCDE');
    });
  });
}
