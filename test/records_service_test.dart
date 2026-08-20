import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sliding_puzzle/services/records_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(const {});
  });

  group('guardarPartida', () {
    test('guarda correctamente la primera partida', () async {
      final esPrecord = await RecordsService.guardarPartida(
        size: 3,
        tiempo: 12,
        movimientos: 40,
      );
      expect(esPrecord, isTrue);

      final historial = await RecordsService.obtenerHistorial(3);
      expect(historial, hasLength(1));
      expect(historial.first.tiempo, 12);
      expect(historial.first.movimientos, 40);
    });

    test('mantiene el orden por tiempo ascendente', () async {
      await RecordsService.guardarPartida(size: 3, tiempo: 30, movimientos: 1);
      await RecordsService.guardarPartida(size: 3, tiempo: 10, movimientos: 2);
      await RecordsService.guardarPartida(size: 3, tiempo: 20, movimientos: 3);

      final historial = await RecordsService.obtenerHistorial(3);
      expect(
        historial.map((r) => r.tiempo).toList(),
        const [10, 20, 30],
      );
    });

    test('no supera el límite de 5 récords', () async {
      for (var i = 1; i <= 7; i++) {
        await RecordsService.guardarPartida(
          size: 3,
          tiempo: i * 10,
          movimientos: i,
        );
      }

      final historial = await RecordsService.obtenerHistorial(3);
      expect(historial, hasLength(5));
      expect(
        historial.map((r) => r.tiempo).toList(),
        const [10, 20, 30, 40, 50],
      );
    });

    test('retorna true solo cuando es el nuevo #1', () async {
      expect(
        await RecordsService.guardarPartida(size: 3, tiempo: 30, movimientos: 1),
        isTrue,
      );
      // Más lento que el #1 actual → no es récord.
      expect(
        await RecordsService.guardarPartida(size: 3, tiempo: 45, movimientos: 2),
        isFalse,
      );
      // Más rápido que el #1 actual → nuevo récord.
      expect(
        await RecordsService.guardarPartida(size: 3, tiempo: 15, movimientos: 3),
        isTrue,
      );
    });
  });

  group('obtenerHistorial', () {
    test('retorna lista vacía si no hay datos', () async {
      expect(await RecordsService.obtenerHistorial(3), isEmpty);
      expect(await RecordsService.obtenerHistorial(4), isEmpty);
      expect(await RecordsService.obtenerHistorial(5), isEmpty);
    });

    test('retorna lista vacía si los datos guardados están corruptos', () async {
      SharedPreferences.setMockInitialValues(
        const {'historial_records_3': 'no-json'},
      );

      expect(await RecordsService.obtenerHistorial(3), isEmpty);
    });
  });

  group('limpiarDatosViejos', () {
    test('elimina las claves del formato anterior', () async {
      SharedPreferences.setMockInitialValues(
        const {
          'record_tiempo_3': '90',
          'record_tiempo_4': '120',
          'record_movimientos_3': '30',
          'record_movimientos_5': '50',
        },
      );

      await RecordsService.limpiarDatosViejos();

      final prefs = await SharedPreferences.getInstance();
      const clavesViejas = [
        'record_tiempo_3',
        'record_tiempo_4',
        'record_tiempo_5',
        'record_movimientos_3',
        'record_movimientos_4',
        'record_movimientos_5',
      ];
      for (final clave in clavesViejas) {
        expect(
          prefs.containsKey(clave),
          isFalse,
          reason: '$clave debe eliminarse',
        );
      }
    });
  });
}
