import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sliding_puzzle/screens/game_screen.dart';
import 'package:sliding_puzzle/screens/home_screen.dart';
import 'package:sliding_puzzle/services/saved_game_service.dart';
import 'package:sliding_puzzle/widgets/hud_card.dart';

import '../helpers/localized_app.dart';

/// Tablero 3x3 casi resuelto: sólo falta mover la ficha 8 al hueco (índice 7)
/// para ganar. Permite comprobar la victoria sin resolver un puzzle entero.
const List<int> _casiResuelto = [1, 2, 3, 4, 5, 6, 7, 0, 8];

/// Tablero 3x3 con un movimiento que NO gana: mover la ficha 7 deja el hueco
/// en su lugar y el tablero sigue desordenado. Necesario para probar el
/// autoguardado de una partida realmente en curso (con `_casiResuelto`,
/// cualquier movimiento la resolvería).
const List<int> _enCurso = [1, 2, 3, 4, 5, 6, 0, 7, 8];

/// Partida libre a medias sobre [_enCurso].
const PartidaGuardada _partidaEnCurso = PartidaGuardada(
  esDesafio: false,
  size: 3,
  nivel: null,
  tablero: _enCurso,
  movimientos: 5,
  segundos: 30,
);

const PartidaGuardada _partidaLibre = PartidaGuardada(
  esDesafio: false,
  size: 3,
  nivel: null,
  tablero: _casiResuelto,
  movimientos: 5,
  segundos: 30,
);

const PartidaGuardada _partidaDesafio = PartidaGuardada(
  esDesafio: true,
  size: 3,
  nivel: 1,
  tablero: _casiResuelto,
  movimientos: 2,
  segundos: 0,
);

/// Monta un menú con el juego encima, para poder disparar el "Atrás" del
/// sistema sobre la ruta del juego (que es lo que intercepta `PopScope`).
Future<void> _montarJuegoSobreMenu(
  WidgetTester tester,
  PartidaGuardada partida,
) async {
  await tester.pumpWidget(
    appLocalizada(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GameScreen(
                    size: partida.size,
                    nivelDesafio: partida.nivel,
                    partidaInicial: partida,
                  ),
                ),
              ),
              child: const Text('entrar'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('entrar'));
  await tester.pumpAndSettle();
}

/// Avanza tras ganar SIN `pumpAndSettle`: el confeti de la victoria mantiene
/// frames programados y la espera no se estabiliza nunca (mismo motivo por el
/// que el test del cronómetro bombea duraciones fijas).
Future<void> _bombearVictoria(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Dispara el "Atrás" del sistema y deja correr la salida asíncrona que hace
/// `PopScope`: primero guarda la partida (await) y sólo después navega, así que
/// un único `pumpAndSettle` no alcanza a ver la pantalla anterior.
Future<void> _pulsarAtras(WidgetTester tester) async {
  await tester.binding.handlePopRoute();
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    // `app_has_rated` evita que el menú abra el modal de calificación al
    // arrancar: su barrera modal se come los toques sobre la tarjeta de
    // "Continuar Partida" y haría pasar los tests por el motivo equivocado.
    SharedPreferences.setMockInitialValues(const {'app_has_rated': true});
  });

  group('botón "Continuar Partida" en el menú', () {
    testWidgets('no aparece si no hay partida guardada', (tester) async {
      await tester.pumpWidget(
        appLocalizada(home: const HomeScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Continuar Partida'), findsNothing);
    });

    testWidgets('aparece si hay una partida guardada', (tester) async {
      await SavedGameService.guardar(_partidaLibre);

      await tester.pumpWidget(
        appLocalizada(home: const HomeScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Continuar Partida'), findsOneWidget);
      // El detalle muestra modo, movimientos y tiempo de la partida pendiente.
      expect(
        find.textContaining('Tablero 3×3 · 5 movs · 30s'),
        findsOneWidget,
      );
    });

    testWidgets('describe el nivel cuando la partida es del Desafío',
        (tester) async {
      await SavedGameService.guardar(_partidaDesafio);

      await tester.pumpWidget(
        appLocalizada(home: const HomeScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Continuar Partida'), findsOneWidget);
      expect(find.textContaining('Desafío · Nivel 1'), findsOneWidget);
    });

    testWidgets('desaparece si la partida guardada era basura', (tester) async {
      SharedPreferences.setMockInitialValues({
        'app_has_rated': true,
        'partida_guardada': '{"size": 3, "tablero": [1,2,3]}',
      });

      await tester.pumpWidget(
        appLocalizada(home: const HomeScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Continuar Partida'), findsNothing);
    });

    testWidgets('descartar oculta la tarjeta y borra el guardado', (tester) async {
      await SavedGameService.guardar(_partidaLibre);

      await tester.pumpWidget(
        appLocalizada(home: const HomeScreen()),
      );
      await tester.pumpAndSettle();
      expect(find.text('Continuar Partida'), findsOneWidget);

      // Se busca por el ícono: `byTooltip` devuelve el proxy del tooltip, que no
      // recibe el hit-test (el toque caería en el InkWell de la tarjeta).
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Continuar Partida'), findsNothing);
      expect(await SavedGameService.obtener(), isNull);
    });

    testWidgets('descartar no entra al juego', (tester) async {
      await SavedGameService.guardar(_partidaLibre);

      await tester.pumpWidget(
        appLocalizada(home: const HomeScreen()),
      );
      await tester.pumpAndSettle();

      // Se busca por el ícono: `byTooltip` devuelve el proxy del tooltip, que no
      // recibe el hit-test (el toque caería en el InkWell de la tarjeta).
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      // Seguimos en el menú y no se abrió ninguna partida.
      expect(find.byType(GameScreen), findsNothing);
      expect(find.text('Elegí una dificultad'), findsOneWidget);
    });

    testWidgets('descartar borra en disco, no sólo en pantalla', (tester) async {
      await SavedGameService.guardar(_partidaDesafio);

      await tester.pumpWidget(
        appLocalizada(home: const HomeScreen()),
      );
      await tester.pumpAndSettle();

      // Se busca por el ícono: `byTooltip` devuelve el proxy del tooltip, que no
      // recibe el hit-test (el toque caería en el InkWell de la tarjeta).
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      // Se desmonta el menú y se vuelve a montar desde cero: si el borrado sólo
      // hubiera sido un setState, la tarjeta reaparecería al releer prefs.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(
        appLocalizada(home: const HomeScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Continuar Partida'), findsNothing);
    });
  });

  group('restaurar una partida', () {
    testWidgets('el tablero, los movimientos y el tiempo vuelven del guardado',
        (tester) async {
      await tester.pumpWidget(
        appLocalizada(
          home:const GameScreen(size: 3, partidaInicial: _partidaLibre),
        ),
      );
      await tester.pump();

      // El tiempo no arranca en 0: se conserva lo ya jugado. Los contadores se
      // buscan dentro de las tarjetas del HUD: el tablero también dibuja un
      // "5" (la ficha), y buscarlo suelto daría dos coincidencias.
      expect(
        find.descendant(of: find.byType(HudCard), matching: find.text('30s')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: find.byType(HudCard), matching: find.text('5')),
        findsOneWidget,
      );

      // El tablero es el guardado, no uno nuevo: la ficha 8 sigue en la
      // esquina con el hueco a su izquierda.
      expect(find.byKey(const ValueKey(8)), findsOneWidget);
    });

    testWidgets('una partida nueva arranca en cero', (tester) async {
      await tester.pumpWidget(
        appLocalizada(
          home:const GameScreen(size: 3),
        ),
      );
      await tester.pump();

      expect(find.text('0s'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);
    });
  });

  group('autoguardado', () {
    testWidgets('el botón Atrás guarda la partida en curso y sale',
        (tester) async {
      await _montarJuegoSobreMenu(tester, _partidaEnCurso);

      // Un movimiento más para que lo guardado sea el estado actual y no el
      // que se restauró. La ficha 7 no resuelve el tablero.
      await tester.tap(find.byKey(const ValueKey(7)), warnIfMissed: false);
      await tester.pump();

      await _pulsarAtras(tester);

      // Volvimos al menú...
      expect(find.text('entrar'), findsOneWidget);
      // ...y la partida quedó guardada con el movimiento extra.
      final guardada = await SavedGameService.obtener();
      expect(guardada, isNotNull);
      expect(guardada!.movimientos, 6);
      expect(guardada.segundos, greaterThanOrEqualTo(30));
    });

    testWidgets('pausar guarda la partida', (tester) async {
      await tester.pumpWidget(
        appLocalizada(
          home:const GameScreen(size: 3, partidaInicial: _partidaLibre),
        ),
      );
      await tester.pump();

      await tester.tap(find.byIcon(Icons.pause));
      await tester.pumpAndSettle();

      final guardada = await SavedGameService.obtener();
      expect(guardada, isNotNull);
      expect(guardada!.movimientos, 5);
    });

    testWidgets('ganar borra la partida guardada', (tester) async {
      await SavedGameService.guardar(_partidaLibre);
      expect(await SavedGameService.obtener(), isNotNull);

      await tester.pumpWidget(
        appLocalizada(
          home:const GameScreen(size: 3, partidaInicial: _partidaLibre),
        ),
      );
      await tester.pump();

      // Mover la ficha 8 al hueco resuelve el tablero.
      await tester.tap(find.byKey(const ValueKey(8)), warnIfMissed: false);
      await _bombearVictoria(tester);

      expect(find.text('🎉 ¡Ganaste!'), findsOneWidget);
      expect(await SavedGameService.obtener(), isNull);
    });

    testWidgets('reiniciar borra la partida guardada', (tester) async {
      await SavedGameService.guardar(_partidaLibre);

      await tester.pumpWidget(
        appLocalizada(
          home:const GameScreen(size: 3, partidaInicial: _partidaLibre),
        ),
      );
      await tester.pump();

      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pumpAndSettle();

      expect(await SavedGameService.obtener(), isNull);
    });

    testWidgets('una partida sin empezar no se guarda al salir', (tester) async {
      await tester.pumpWidget(
        appLocalizada(
          home:Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const GameScreen(size: 3),
                    ),
                  ),
                  child: const Text('entrar'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('entrar'));
      await tester.pumpAndSettle();

      // Sin ningún movimiento: el tablero está intacto, no hay nada que retomar.
      await _pulsarAtras(tester);

      expect(await SavedGameService.obtener(), isNull);
    });
  });

  group('botón "Volver al Menú" en la victoria', () {
    testWidgets('cierra la partida y vuelve al menú limpiando la pila',
        (tester) async {
      await _montarJuegoSobreMenu(tester, _partidaLibre);

      await tester.tap(find.byKey(const ValueKey(8)), warnIfMissed: false);
      await _bombearVictoria(tester);
      expect(find.text('🎉 ¡Ganaste!'), findsOneWidget);

      await tester.tap(find.text('Volver al Menú'));
      await tester.pumpAndSettle();

      expect(find.text('entrar'), findsOneWidget);
      expect(find.text('🎉 ¡Ganaste!'), findsNothing);
    });
  });
}
