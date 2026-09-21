import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sliding_puzzle/logic/puzzle_logic.dart';
import 'package:sliding_puzzle/screens/game_screen.dart';
import 'package:sliding_puzzle/services/daily_challenge_service.dart';
import 'package:sliding_puzzle/services/saved_game_service.dart';
import 'package:sliding_puzzle/widgets/daily_preview_dialog.dart';
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

  setUp(() {
    SharedPreferences.setMockInitialValues(const {});
    // El reloj es global y estático: si un test lo mueve y no lo devuelve, el
    // siguiente arranca en el día equivocado.
    DailyChallengeService.reloj = DateTime.now;
  });

  /// Cierra la vista previa de la foto del día, si está abierta.
  ///
  /// El diario la abre al entrar, y mientras esté arriba se queda con los
  /// toques: sin cerrarla ningún test llega al tablero.
  Future<void> cerrarPreviewDiario(WidgetTester tester) async {
    final boton = find.text('¡Empezar!');
    if (boton.evaluate().isEmpty) return;
    await tester.tap(boton);
    await tester.pump();
  }

  Future<void> montarDiario(WidgetTester tester) async {
    await tester.pumpWidget(
      appLocalizada(home: const GameScreen(size: n, esDiario: true)),
    );
    await tester.pump();
    await tester.pump();
    await cerrarPreviewDiario(tester);
  }

  /// Manda la app a segundo plano.
  ///
  /// Van los estados intermedios porque `AppLifecycleListener` no reacciona a
  /// un salto directo: hay que recorrerlos igual que el sistema.
  Future<void> aSegundoPlano(WidgetTester tester) async {
    for (final estado in [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(estado);
      await tester.pump();
    }
  }

  /// Trae la app de vuelta a primer plano.
  Future<void> aPrimerPlano(WidgetTester tester) async {
    for (final estado in [
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(estado);
      await tester.pump();
    }
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

  group('vista previa de la foto del día', () {
    testWidgets('se muestra al entrar, antes de dejar jugar', (tester) async {
      await tester.pumpWidget(
        appLocalizada(home: const GameScreen(size: n, esDiario: true)),
      );
      await tester.pump();
      await tester.pump();

      expect(
        find.byType(DailyPreviewDialog),
        findsOneWidget,
        reason: 'armar el tablero sin haber visto la foto es adivinanza',
      );
      expect(find.text('La foto de hoy'), findsOneWidget);
      expect(find.text('¡Empezar!'), findsOneWidget);
    });

    testWidgets('el botón la cierra y deja mover las fichas', (tester) async {
      await tester.pumpWidget(
        appLocalizada(home: const GameScreen(size: n, esDiario: true)),
      );
      await tester.pump();
      await tester.pump();

      await tester.tap(find.text('¡Empezar!'));
      await tester.pump();

      expect(find.byType(DailyPreviewDialog), findsNothing);

      // El tablero quedó jugable: la primera jugada de la solución entra.
      final jugadas = resolverTablero(leerTablero(tester, n), n);
      await tester.tap(find.byKey(ValueKey(jugadas[0])), warnIfMissed: false);
      await tester.pump();

      expect(
        leerTablero(tester, n),
        isNot(equals(DailyChallengeService.tableroHoy())),
        reason: 'el toque tenía que llegar al tablero, no al diálogo',
      );
    });

    testWidgets('una partida libre NO la muestra', (tester) async {
      // La vista previa es del diario: en los otros modos las fichas son
      // números y no hay ninguna foto que anticipar.
      await tester.pumpWidget(appLocalizada(home: const GameScreen(size: 3)));
      await tester.pump();
      await tester.pump();

      expect(find.byType(DailyPreviewDialog), findsNothing);
    });

    testWidgets('sin Firebase muestra la foto de respaldo, no un hueco', (
      tester,
    ) async {
      // En tests no hay Firebase, así que `imagenDe` cae al respaldo. El
      // diálogo tiene que dibujar esa foto igual: quedarse en blanco sería
      // exactamente el problema que el diálogo viene a resolver.
      await tester.pumpWidget(
        appLocalizada(home: const GameScreen(size: n, esDiario: true)),
      );
      await tester.pump();
      await tester.pump();

      final imagen = tester.widget<Image>(
        find.descendant(
          of: find.byType(DailyPreviewDialog),
          matching: find.byType(Image),
        ),
      );

      expect(
        imagen.image,
        same(DailyChallengeService.imagenRespaldo),
        reason: 'la vista previa nunca puede quedar vacía',
      );
    });
  });

  group('cruce de la medianoche UTC en segundo plano', () {
    testWidgets('sin haber movido, pasa al desafío del día nuevo', (
      tester,
    ) async {
      final dia19 = DateTime.utc(2026, 9, 19, 23, 30);
      final dia20 = DateTime.utc(2026, 9, 20, 0, 30);
      DailyChallengeService.reloj = () => dia19;

      await montarDiario(tester);
      expect(
        leerTablero(tester, n),
        equals(DailyChallengeService.tableroDe(dia19)),
      );

      // La app queda fuera de foco y el día UTC cambia mientras tanto.
      await aSegundoPlano(tester);
      DailyChallengeService.reloj = () => dia20;
      await aPrimerPlano(tester);
      await tester.pump();

      expect(
        leerTablero(tester, n),
        equals(DailyChallengeService.tableroDe(dia20)),
        reason:
            'sin una sola ficha movida no hay puntaje que proteger, y quedarse '
            'en el tablero de ayer dejaría al jugador sin el desafío de hoy',
      );
    });

    testWidgets('con la partida ya empezada, NO cambia el tablero', (
      tester,
    ) async {
      // Es el invariante que sostiene el ranking: el tablero y el puntaje son
      // los del día en que se empezó a jugar.
      final dia19 = DateTime.utc(2026, 9, 19, 23, 30);
      final dia20 = DateTime.utc(2026, 9, 20, 0, 30);
      DailyChallengeService.reloj = () => dia19;

      await montarDiario(tester);
      final tableroDel19 = leerTablero(tester, n);

      final jugadas = resolverTablero(tableroDel19, n);
      await tester.tap(find.byKey(ValueKey(jugadas[0])), warnIfMissed: false);
      await tester.pump();
      final trasLaJugada = leerTablero(tester, n);

      await aSegundoPlano(tester);
      DailyChallengeService.reloj = () => dia20;
      await aPrimerPlano(tester);
      await tester.pump();

      expect(
        leerTablero(tester, n),
        equals(trasLaJugada),
        reason:
            'cambiar el tablero a mitad de camino le daría un puntaje del día '
            'nuevo a una partida del viejo',
      );
    });

    testWidgets('el día nuevo vuelve a mostrar la vista previa', (
      tester,
    ) async {
      // La foto es otra: el jugador tiene que verla antes de mover, igual que
      // al entrar.
      final dia19 = DateTime.utc(2026, 9, 19, 23, 30);
      DailyChallengeService.reloj = () => dia19;

      await montarDiario(tester);
      expect(find.byType(DailyPreviewDialog), findsNothing);

      await aSegundoPlano(tester);
      DailyChallengeService.reloj = () => DateTime.utc(2026, 9, 20, 0, 30);
      await aPrimerPlano(tester);
      await tester.pump();

      expect(find.byType(DailyPreviewDialog), findsOneWidget);
    });
  });
}
