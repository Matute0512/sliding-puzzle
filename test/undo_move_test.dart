import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sliding_puzzle/screens/game_screen.dart';
import 'package:sliding_puzzle/services/admob_service.dart';
import 'package:sliding_puzzle/services/coins_service.dart';
import 'package:sliding_puzzle/services/saved_game_service.dart';
import 'package:sliding_puzzle/widgets/hud_card.dart';

import 'helpers/localized_app.dart';

/// Tablero 3x3 no resuelto: el hueco está en el índice 6 (abajo a la izquierda).
/// [1, 2, 3,
///  4, 5, 6,
///  0, 7, 8]
/// Fichas adyacentes al hueco: 4 (arriba, índice 3) y 7 (derecha, índice 7).
const PartidaGuardada _partidaPrueba = PartidaGuardada(
  esDesafio: false,
  size: 3,
  nivel: null,
  tablero: [1, 2, 3, 4, 5, 6, 0, 7, 8],
  movimientos: 0,
  segundos: 0,
);

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    CoinsService.reiniciarEstadoParaTests(20);
    AdMobService.reiniciarEstadoParaTests();
  });

  tearDown(() {
    CoinsService.reiniciarEstadoParaTests(0);
    AdMobService.reiniciarEstadoParaTests();
  });

  group('Funcionalidad Deshacer movimiento (Undo)', () {
    testWidgets('botón Deshacer inicia deshabilitado sin movimientos previos',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        appLocalizada(
          home: const GameScreen(
            size: 3,
            partidaInicial: _partidaPrueba,
          ),
        ),
      );
      await tester.pump();

      // Botón Deshacer visible con ícono de undo
      expect(find.byIcon(Icons.undo_rounded), findsOneWidget);

      // Tocar Deshacer no hace nada porque no hay movimientos
      await tester.tap(find.byIcon(Icons.undo_rounded));
      await tester.pump();

      expect(
        find.descendant(of: find.byType(HudCard), matching: find.text('0')),
        findsOneWidget,
      );
      expect(CoinsService.saldo, equals(20));
    });

    testWidgets('deshace un movimiento con monedas, revierte tablero y restaura contador',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        appLocalizada(
          home: const GameScreen(
            size: 3,
            partidaInicial: _partidaPrueba,
          ),
        ),
      );
      await tester.pump();

      // Mover ficha 7 hacia el hueco
      await tester.tap(find.byKey(const ValueKey(7)), warnIfMissed: false);
      await tester.pump();

      // Movimientos ahora es 1
      expect(
        find.descendant(of: find.byType(HudCard), matching: find.text('1')),
        findsOneWidget,
      );

      // Tocar Deshacer
      await tester.tap(find.byIcon(Icons.undo_rounded));
      await tester.pumpAndSettle();

      // Se descuentan 10 monedas (20 - 10 = 10)
      expect(CoinsService.saldo, equals(10));

      // Movimientos vuelve a 0
      expect(
        find.descendant(of: find.byType(HudCard), matching: find.text('0')),
        findsOneWidget,
      );
    });

    testWidgets('con saldo insuficiente ofrece ver anuncio y si cancela no deshace',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      CoinsService.reiniciarEstadoParaTests(5); // Menos de 10 monedas

      await tester.pumpWidget(
        appLocalizada(
          home: const GameScreen(
            size: 3,
            partidaInicial: _partidaPrueba,
          ),
        ),
      );
      await tester.pump();

      // Ficha 7 se mueve
      await tester.tap(find.byKey(const ValueKey(7)), warnIfMissed: false);
      await tester.pump();
      expect(
        find.descendant(of: find.byType(HudCard), matching: find.text('1')),
        findsOneWidget,
      );

      // Al tener < 10 monedas, el botón muestra el ícono de anuncio
      expect(find.byIcon(Icons.smart_display_rounded), findsWidgets);

      // Tocar Deshacer abre el diálogo de confirmación
      await tester.tap(find.byIcon(Icons.undo_rounded));
      await tester.pumpAndSettle();

      expect(find.text('¿Deshacer movimiento?'), findsOneWidget);

      // Cancelar
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      // Sigue en 1 movimiento y 5 monedas
      expect(
        find.descendant(of: find.byType(HudCard), matching: find.text('1')),
        findsOneWidget,
      );
      expect(CoinsService.saldo, equals(5));
    });

    testWidgets('con saldo insuficiente y viendo anuncio recompensado deshace gratis',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      CoinsService.reiniciarEstadoParaTests(5);

      var anuncioVisto = false;
      AdMobService.mostrarRewardedOverride = () async {
        anuncioVisto = true;
        return true;
      };

      await tester.pumpWidget(
        appLocalizada(
          home: const GameScreen(
            size: 3,
            partidaInicial: _partidaPrueba,
          ),
        ),
      );
      await tester.pump();

      // Mover ficha 7
      await tester.tap(find.byKey(const ValueKey(7)), warnIfMissed: false);
      await tester.pump();
      expect(
        find.descendant(of: find.byType(HudCard), matching: find.text('1')),
        findsOneWidget,
      );

      // Tocar Deshacer abre el diálogo
      await tester.tap(find.byIcon(Icons.undo_rounded));
      await tester.pumpAndSettle();

      // Aceptar ver anuncio
      await tester.tap(find.text('Ver anuncio'));
      await tester.pumpAndSettle();

      expect(anuncioVisto, isTrue);

      // Movimiento deshecho
      expect(
        find.descendant(of: find.byType(HudCard), matching: find.text('0')),
        findsOneWidget,
      );
      // Saldo de monedas intacto
      expect(CoinsService.saldo, equals(5));
    });
  });
}

