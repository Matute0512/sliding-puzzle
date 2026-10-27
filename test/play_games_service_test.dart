import 'package:flutter_test/flutter_test.dart';
import 'package:sliding_puzzle/services/play_games_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PlayGamesService — resiliencia y evaluación de logros', () {
    test('iniciarSesionSilenciosa no lanza excepción en entorno no-Android/test', () async {
      await expectLater(
        PlayGamesService.iniciarSesionSilenciosa(),
        completes,
      );
    });

    test('desbloquearLogro maneja IDs vacíos o nulos de forma segura', () async {
      await expectLater(
        PlayGamesService.desbloquearLogro(''),
        completes,
      );
      await expectLater(
        PlayGamesService.desbloquearLogro('   '),
        completes,
      );
    });

    test('mostrarLogros no lanza excepción en entorno de test', () async {
      await expectLater(
        PlayGamesService.mostrarLogros(),
        completes,
      );
    });

    test('verificarLogrosVictoria evalúa las condiciones de los 5 logros sin errores', () {
      // 1. Tablero 3x3
      expect(
        () => PlayGamesService.verificarLogrosVictoria(
          size: 3,
          segundos: 120,
        ),
        returnsNormally,
      );

      // 2. Desafío Diario
      expect(
        () => PlayGamesService.verificarLogrosVictoria(
          size: 4,
          segundos: 200,
          esDiario: true,
        ),
        returnsNormally,
      );

      // 3. Mente ágil (4x4 en < 180s)
      expect(
        () => PlayGamesService.verificarLogrosVictoria(
          size: 4,
          segundos: 150,
        ),
        returnsNormally,
      );

      // 4. Perfeccionista (Modo Desafío con 3 estrellas)
      expect(
        () => PlayGamesService.verificarLogrosVictoria(
          size: 3,
          segundos: 45,
          estrellas: 3,
        ),
        returnsNormally,
      );

      // 5. Gran Maestro (Tablero 5x5)
      expect(
        () => PlayGamesService.verificarLogrosVictoria(
          size: 5,
          segundos: 300,
        ),
        returnsNormally,
      );
    });
  });
}

