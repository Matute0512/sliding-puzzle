import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sliding_puzzle/services/admob_service.dart';
import 'package:sliding_puzzle/widgets/ad_banner_widget.dart';

void main() {
  late DateTime ahora;
  late int vecesMostrado;

  setUp(() {
    AdMobService.reiniciarEstadoParaTests();
    ahora = DateTime.utc(2026, 10, 22, 12, 0, 0);
    vecesMostrado = 0;
    AdMobService.reloj = () => ahora;
    AdMobService.mostrarInterstitialOverride = () async {
      vecesMostrado++;
      return true;
    };
  });

  tearDown(AdMobService.reiniciarEstadoParaTests);

  group('AdMobService — política de frecuencia y cooldown', () {
    test('muestra interstitial cada 2 victorias y reinicia el contador',
        () async {
      expect(
        await AdMobService.registrarVictoriaYMostrarSiCorresponde(),
        isFalse,
      );
      expect(vecesMostrado, 0);

      expect(
        await AdMobService.registrarVictoriaYMostrarSiCorresponde(),
        isTrue,
      );
      expect(vecesMostrado, 1);

      // La 3.ª victoria vuelve a ser 1 de 2: no muestra aunque pase el cooldown.
      ahora = ahora.add(const Duration(minutes: 5));
      expect(
        await AdMobService.registrarVictoriaYMostrarSiCorresponde(),
        isFalse,
      );
      expect(vecesMostrado, 1);
    });

    test('respeta el cooldown mínimo de 90s entre interstitials', () async {
      // Primer anuncio al completar 2 victorias.
      await AdMobService.registrarVictoriaYMostrarSiCorresponde();
      expect(
        await AdMobService.registrarVictoriaYMostrarSiCorresponde(),
        isTrue,
      );
      expect(vecesMostrado, 1);

      // Gana otras 2 partidas en 45 segundos (< 90s): bloqueado por cooldown.
      ahora = ahora.add(const Duration(seconds: 45));
      await AdMobService.registrarVictoriaYMostrarSiCorresponde();
      expect(
        await AdMobService.registrarVictoriaYMostrarSiCorresponde(),
        isFalse,
      );
      expect(vecesMostrado, 1);

      // Cuando se cumplen los 90 segundos, la siguiente victoria ya puede mostrar.
      ahora = ahora.add(const Duration(seconds: 45));
      expect(
        await AdMobService.registrarVictoriaYMostrarSiCorresponde(),
        isTrue,
      );
      expect(vecesMostrado, 2);
    });

    test(
        'salidas/reinicios con menos de 12 movimientos no suman para mostrar anuncio',
        () async {
      for (var i = 0; i < 5; i++) {
        expect(
          await AdMobService.registrarSalidaYMostrarSiCorresponde(
            movimientos: 11,
          ),
          isFalse,
        );
      }
      expect(vecesMostrado, 0);

      // Con >= 12 movimientos sí cuenta: a la 2.ª salida muestra anuncio.
      expect(
        await AdMobService.registrarSalidaYMostrarSiCorresponde(
          movimientos: 12,
        ),
        isFalse,
      );
      expect(
        await AdMobService.registrarSalidaYMostrarSiCorresponde(
          movimientos: 18,
        ),
        isTrue,
      );
      expect(vecesMostrado, 1);
    });

    test('Ad Unit IDs de prueba son válidos y no vacíos en modo test/debug',
        () {
      expect(AdMobService.adUnitIdBanner, startsWith('ca-app-pub-3940256099942544/'));
      expect(
        AdMobService.adUnitIdInterstitial,
        startsWith('ca-app-pub-3940256099942544/'),
      );
    });
  });

  testWidgets(
      'AdBannerWidget colapsa a SizedBox.shrink cuando el SDK no fue inicializado',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          bottomNavigationBar: AdBannerWidget(),
          body: SizedBox.expand(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.getSize(find.byType(AdBannerWidget)).height, 0);
  });
}

