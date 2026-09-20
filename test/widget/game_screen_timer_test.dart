import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sliding_puzzle/screens/game_screen.dart';
import 'package:sliding_puzzle/widgets/hud_card.dart';

import '../helpers/localized_app.dart';
import '../helpers/puzzle_solver.dart';

/// Segundos que muestra el HUD del tiempo (el modal muestra una foto fija, así
/// que solo el HUD sirve para observar si el reloj sigue vivo).
int _segundosHud(WidgetTester tester) {
  final textos = tester.widgetList<Text>(
    find.descendant(of: find.byType(HudCard), matching: find.byType(Text)),
  );
  for (final texto in textos) {
    final coincidencia =
        RegExp(r'^(\d+)s$').firstMatch(texto.data ?? '');
    if (coincidencia != null) {
      return int.parse(coincidencia.group(1)!);
    }
  }
  return -1;
}

/// Avanza tiempo REAL y deja latir el refresco del HUD.
///
/// Ojo: el cronómetro de la partida es un `Stopwatch`, que mide el reloj real,
/// mientras que `tester.pump(duración)` solo avanza el reloj *falso* que mueve
/// los `Timer`. Para que el HUD llegue a volcar un valor nuevo hay que hacer las
/// dos cosas: esperar de verdad (`runAsync`) y después bombear el reloj falso.
Future<void> _avanzarRelojReal(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 1100)),
  );
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(const {}));

  testWidgets('el cronómetro se congela al ganar y no lo revive el ciclo de vida',
      (tester) async {
    await tester.pumpWidget(
      appLocalizada(home: const GameScreen(size: 3)),
    );
    await tester.pump();

    final jugadas = resolverTablero(leerTablero(tester, 3), 3);
    expect(jugadas, isNotEmpty, reason: 'no se pudo resolver el tablero inicial');

    // Primera jugada: arranca el reloj.
    await tester.tap(find.byKey(ValueKey(jugadas[0])), warnIfMissed: false);
    await tester.pump();

    // Control de sensibilidad: con la partida en curso el reloj SÍ avanza. Sin
    // esto, las aserciones de abajo podrían pasar por no medir nada.
    final antesDeJugar = _segundosHud(tester);
    await _avanzarRelojReal(tester);
    expect(_segundosHud(tester), greaterThan(antesDeJugar),
        reason: 'el reloj debería avanzar mientras se juega (control del test)');

    // Se termina la partida.
    for (var i = 1; i < jugadas.length; i++) {
      await tester.tap(find.byKey(ValueKey(jugadas[i])), warnIfMissed: false);
      await tester.pump();
    }
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('🎉 ¡Ganaste!'), findsOneWidget);

    final alGanar = _segundosHud(tester);
    expect(alGanar, greaterThanOrEqualTo(0),
        reason: 'no se pudo leer el tiempo del HUD, las aserciones de abajo '
            'no probarían nada');

    // 1) Con el reloj detenido, el tiempo real que pase no lo mueve.
    await _avanzarRelojReal(tester);
    expect(_segundosHud(tester), alGanar,
        reason: 'el reloj siguió corriendo después de ganar');

    // 2) Ciclo de vida: la app se va a background y vuelve (con los estados
    // intermedios, porque Flutter rechaza saltos directos).
    for (final estado in [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(estado);
      await tester.pump();
    }
    for (final estado in [
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(estado);
      await tester.pump();
    }

    await _avanzarRelojReal(tester);
    expect(_segundosHud(tester), alGanar,
        reason: 'volver de background revivió el cronómetro de una partida ya '
            'ganada (regresión: faltaba el flag de partida terminada)');
  });
}
