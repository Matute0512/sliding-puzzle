import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sliding_puzzle/services/sound_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'sonido_activado': true,
      'musica_activada': true,
    });
  });

  tearDown(() async {
    await SoundService.dispose();
  });

  group('SoundService — Preferencias y alternado', () {
    test('alternarSonido conmuta el valor y persiste en SharedPreferences', () async {
      SoundService.sonidoActivado = true;
      await SoundService.alternarSonido();
      expect(SoundService.sonidoActivado, isFalse);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('sonido_activado'), isFalse);

      await SoundService.alternarSonido();
      expect(SoundService.sonidoActivado, isTrue);
      expect(prefs.getBool('sonido_activado'), isTrue);
    });

    test('alternarMusica conmuta el valor y persiste en SharedPreferences', () async {
      SoundService.musicaActivada = true;
      await SoundService.alternarMusica();
      expect(SoundService.musicaActivada, isFalse);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('musica_activada'), isFalse);

      await SoundService.alternarMusica();
      expect(SoundService.musicaActivada, isTrue);
      expect(prefs.getBool('musica_activada'), isTrue);
    });
  });

  group('SoundService — Ciclo de vida y robustez ante fallos nativos', () {
    test('manejarCicloDeVida con detached ejecuta dispose seguro sin lanzar', () {
      expect(
        () => SoundService.manejarCicloDeVida(AppLifecycleState.detached),
        returnsNormally,
      );
    });

    test('manejarCicloDeVida con paused y hidden no arroja excepciones sin SoLoud inicializado', () {
      expect(
        () => SoundService.manejarCicloDeVida(AppLifecycleState.paused),
        returnsNormally,
      );
      expect(
        () => SoundService.manejarCicloDeVida(AppLifecycleState.hidden),
        returnsNormally,
      );
    });

    test('reproducirClick y reproducirVictoria son seguras sin SoLoud activo', () {
      expect(SoundService.reproducirClick, returnsNormally);
      expect(SoundService.reproducirVictoria, returnsNormally);
    });

    test('dispose limpia de forma idempotente y segura', () async {
      await expectLater(SoundService.dispose(), completes);
      await expectLater(SoundService.dispose(), completes);
    });
  });
}

