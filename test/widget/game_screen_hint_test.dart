import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sliding_puzzle/screens/game_screen.dart';
import 'package:sliding_puzzle/services/admob_service.dart';
import 'package:sliding_puzzle/services/coins_service.dart';
import 'package:sliding_puzzle/services/saved_game_service.dart';
import 'package:sliding_puzzle/services/skin_service.dart';
import 'package:sliding_puzzle/widgets/puzzle_tile.dart';

import '../helpers/localized_app.dart';

/// Tablero 3x3 no resuelto con 1 movimiento para ganar:
/// [1, 2, 3,
///  4, 5, 6,
///  7, 0, 8]
/// Ficha 8 (índice 8) al hueco (índice 7) resuelve el juego.
const PartidaGuardada _partidaUnPaso = PartidaGuardada(
  esDesafio: false,
  size: 3,
  nivel: null,
  tablero: [1, 2, 3, 4, 5, 6, 7, 0, 8],
  movimientos: 0,
  segundos: 0,
);

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    SkinService.reiniciarParaTests();
    await SkinService.inicializar();
    CoinsService.reiniciarEstadoParaTests(30);
    AdMobService.reiniciarEstadoParaTests();
  });

  tearDown(() {
    SkinService.reiniciarParaTests();
    CoinsService.reiniciarEstadoParaTests(0);
    AdMobService.reiniciarEstadoParaTests();
  });

  testWidgets('Botón de pista aparece en partida clásica con costo de 15 monedas',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      appLocalizada(
        home: const GameScreen(
          size: 3,
          partidaInicial: _partidaUnPaso,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.lightbulb_rounded), findsOneWidget);
    expect(find.text('15'), findsOneWidget);
  });

  testWidgets('Tocar pista con saldo suficiente descuenta 15 monedas y resalta la ficha',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      appLocalizada(
        home: const GameScreen(
          size: 3,
          partidaInicial: _partidaUnPaso,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(CoinsService.saldo, equals(30));

    // Tocar botón de pista
    await tester.tap(find.byIcon(Icons.lightbulb_rounded));
    await tester.pump();

    // Se descuentan 15 monedas (30 - 15 = 15)
    expect(CoinsService.saldo, equals(15));

    // La ficha 8 es la sugerida inmediata para ganar y debe tener esSugerida = true
    final tileFinder = find.byWidgetPredicate(
      (widget) => widget is PuzzleTile && widget.numero == 8 && widget.esSugerida,
    );
    expect(tileFinder, findsOneWidget);
  });

  testWidgets('Con saldo insuficiente ofrece ver anuncio y otorga la pista tras el ad',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    CoinsService.reiniciarEstadoParaTests(5); // Menos de 15 monedas
    AdMobService.mostrarRewardedOverride = () async => true;

    await tester.pumpWidget(
      appLocalizada(
        home: const GameScreen(
          size: 3,
          partidaInicial: _partidaUnPaso,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tocar botón de pista
    await tester.tap(find.byIcon(Icons.lightbulb_rounded));
    await tester.pumpAndSettle();

    // Muestra diálogo de anuncio para pista
    expect(find.text('¿Usar Pista Inteligente?'), findsOneWidget);

    // Confirmar ver anuncio
    await tester.tap(find.text('Ver anuncio'));
    await tester.pumpAndSettle();

    // No descuenta monedas (sigue en 5)
    expect(CoinsService.saldo, equals(5));

    // Ficha 8 quedó resaltada
    final tileFinder = find.byWidgetPredicate(
      (widget) => widget is PuzzleTile && widget.numero == 8 && widget.esSugerida,
    );
    expect(tileFinder, findsOneWidget);
  });

  testWidgets('Hacer un movimiento limpia la sugerencia de pista',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      appLocalizada(
        home: const GameScreen(
          size: 3,
          partidaInicial: _partidaUnPaso,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Activar pista
    await tester.tap(find.byIcon(Icons.lightbulb_rounded));
    await tester.pump();

    expect(
      find.byWidgetPredicate(
        (widget) => widget is PuzzleTile && widget.numero == 8 && widget.esSugerida,
      ),
      findsOneWidget,
    );

    // Mover la ficha 7
    await tester.tap(find.byKey(const ValueKey(7)), warnIfMissed: false);
    await tester.pump();

    // Ya ninguna ficha tiene esSugerida = true
    expect(
      find.byWidgetPredicate(
        (widget) => widget is PuzzleTile && widget.esSugerida,
      ),
      findsNothing,
    );
  });
}
