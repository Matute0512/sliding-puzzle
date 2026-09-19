import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sliding_puzzle/logic/puzzle_logic.dart';
import 'package:sliding_puzzle/screens/game_screen.dart';
import 'package:sliding_puzzle/services/daily_challenge_service.dart';
import 'package:sliding_puzzle/services/saved_game_service.dart';
import 'package:sliding_puzzle/widgets/image_tile.dart';

import '../helpers/localized_app.dart';
import '../helpers/puzzle_solver.dart';

/// Aislamiento del Desafío Diario dentro de `GameScreen`.
///
/// ## Qué se puede verificar acá y qué no
///
/// Buena parte del aislamiento es **estructural** y no deja rastro observable:
/// `FirebaseService` traga todos sus errores (`catch (_) { return null; }`), así
/// que en un test sin Firebase el camino al Top 5 global no imprime nada ni
/// cambia ningún resultado. No hay forma de distinguir "no lo llamé" de "lo llamé
/// y falló en silencio" sin mockear el plugin nativo.
///
/// Lo que sí se verifica: que en modo diario la victoria toma la rama del diario
/// y **no** la de partida libre. Esa rama es la única que pasa por
/// `_registrarPuntajeGlobal` (lectura y escritura del ranking), así que probar
/// que no se toma prueba que el ranking no se toca.
void main() {
  const n = PuzzleLogic.diarioSize;

  setUp(() => SharedPreferences.setMockInitialValues(const {}));

  Future<void> montarDiario(WidgetTester tester) async {
    await tester.pumpWidget(
      appLocalizada(home: const GameScreen(size: n, esDiario: true)),
    );
    await tester.pump();
  }

  /// Resuelve el tablero y deja correr la victoria (que es asíncrona: marca el
  /// candado antes de mostrar el diálogo). Nada de `pumpAndSettle`: el confeti
  /// anima 4 segundos y lo haría esperar de más.
  Future<void> resolverYEsperarVictoria(WidgetTester tester) async {
    final jugadas = resolverTablero(leerTablero(tester, n), n);
    expect(jugadas, isNotEmpty, reason: 'no se pudo resolver el tablero');
    await jugarSecuencia(tester, jugadas);
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  testWidgets('el tablero es el determinista del día, no uno al azar', (
    tester,
  ) async {
    await montarDiario(tester);

    expect(
      leerTablero(tester, n),
      equals(DailyChallengeService.tableroHoy()),
      reason: 'el diario tiene que ser el mismo tablero para todo el mundo',
    );
  });

  testWidgets('se arma con la imagen, no con números', (tester) async {
    await montarDiario(tester);

    // 8 fichas con imagen en 3x3: el hueco no dibuja nada.
    expect(find.byType(ImageTile), findsNWidgets(n * n - 1));
  });

  testWidgets('resolverlo cierra el candado de hoy', (tester) async {
    expect(await DailyChallengeService.yaJugoHoy(), isFalse);

    await montarDiario(tester);
    await resolverYEsperarVictoria(tester);

    expect(
      await DailyChallengeService.yaJugoHoy(),
      isTrue,
      reason: 'el intento del día tiene que quedar consumido',
    );
  });

  testWidgets('la victoria es la del diario, no la de partida libre', (
    tester,
  ) async {
    await montarDiario(tester);
    await resolverYEsperarVictoria(tester);

    expect(find.text('¡Desafío de hoy completado!'), findsOneWidget);

    // El diálogo de partida libre es la puerta de entrada al Top 5 global:
    // `_resolverPuestoGlobal` solo se llama desde esa rama. Que no aparezca
    // prueba que el ranking no se tocó.
    expect(
      find.text('🎉 ¡Ganaste!'),
      findsNothing,
      reason: 'el diario no debe pasar por el ranking global',
    );
    expect(find.text('Jugar de nuevo'), findsNothing);
  });

  testWidgets('no guarda la partida como "en curso"', (tester) async {
    await montarDiario(tester);

    // Una jugada para que la partida arranque y deje de ser un tablero intacto.
    final jugadas = resolverTablero(leerTablero(tester, n), n);
    await tester.tap(find.byKey(ValueKey(jugadas[0])), warnIfMissed: false);
    await tester.pump();

    // Ir a segundo plano es cuando el juego guarda para poder retomarse.
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();

    expect(
      await SavedGameService.obtener(),
      isNull,
      reason:
          'guardar el diario permitiría retomarlo desde "Continuar Partida" '
          'como partida libre, y ahí sí escribiría en el ranking global',
    );
  });

  testWidgets(
    'control: una partida libre SÍ se guarda al ir a segundo plano',
    (tester) async {
      // Sin este control, el test de arriba pasaría también si el ciclo de vida
      // no llegara a dispararse nunca y no se guardara nada en ningún modo.
      await tester.pumpWidget(appLocalizada(home: const GameScreen(size: 3)));
      await tester.pump();

      final jugadas = resolverTablero(leerTablero(tester, 3), 3);
      await tester.tap(find.byKey(ValueKey(jugadas[0])), warnIfMissed: false);
      await tester.pump();

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();

      expect(await SavedGameService.obtener(), isNotNull);
    },
  );
}
