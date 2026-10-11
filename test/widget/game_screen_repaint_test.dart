import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sliding_puzzle/logic/puzzle_logic.dart';
import 'package:sliding_puzzle/screens/game_screen.dart';
import 'package:sliding_puzzle/widgets/game_header.dart';
import 'package:sliding_puzzle/widgets/hud_card.dart';
import 'package:sliding_puzzle/widgets/puzzle_board.dart';

import '../helpers/localized_app.dart';
import '../helpers/puzzle_solver.dart';

/// Primera capa de repintado hacia arriba desde [nodo].
///
/// `markNeedsPaint` propaga hacia arriba y se frena en el primer ancestro que
/// sea capa de repintado, así que esto responde "¿qué capa se lleva el
/// repintado que origine [nodo]?".
RenderObject? _capaDeRepintado(RenderObject nodo) {
  RenderObject? capa = nodo.parent;
  while (capa != null && !capa.isRepaintBoundary) {
    final padre = capa.parent;
    capa = padre is RenderObject ? padre : null;
  }
  return capa;
}

/// Guardas de los tres invariantes de rendimiento del gameplay.
///
/// Los tres se rompen sin que ningún test funcional se entere: la pantalla se
/// sigue viendo igual, sólo se pinta de más. Ver `README.md`, sección de
/// rendimiento, y `AUDITORIA_TRANSICIONES_Y_GAMEPLAY.md`.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues(const {}));

  testWidgets(
    'el tablero se repinta en su propia capa, por dentro de PuzzleBoard',
    (tester) async {
      await tester.pumpWidget(appLocalizada(home: const GameScreen(size: 5)));
      await tester.pump();

      // El `Stack` que anima al deslizar una ficha.
      final stack = tester.renderObject(
        find
            .descendant(
              of: find.byType(PuzzleBoard),
              matching: find.byType(Stack),
            )
            .first,
      );

      final capa = _capaDeRepintado(stack);

      // Sin la capa del tablero, el boundary más cercano hacia arriba es el
      // viewport del `SingleChildScrollView` (`_RenderSingleChildViewport`),
      // que NO es un `RenderRepaintBoundary`. Con esa capa, cada frame de los
      // 160 ms del deslizamiento re-registra y re-rasteriza todo su contenido:
      // HUD, consigna, pozo con su halo y botonera.
      expect(
        capa,
        isA<RenderRepaintBoundary>(),
        reason: 'el boundary de repintado del tablero desapareció: el '
            'deslizamiento vuelve a repintar el HUD, el pozo y la botonera',
      );

      // Y es la del tablero, no una de más arriba: comparte el tamaño exacto
      // de la caja de `PuzzleBoard`. (El viewport del scroll mide el alto de
      // toda el área scrolleable, y la capa de la ruta, la pantalla entera.)
      expect(capa!.paintBounds.size, tester.getSize(find.byType(PuzzleBoard)));
    },
  );

  testWidgets(
    'mover una ficha no reconstruye el Chrome: sólo el tablero y el contador',
    (tester) async {
      await tester.pumpWidget(appLocalizada(home: const GameScreen(size: 3)));
      // `pumpAndSettle` para que termine de resolver el récord del tablero
      // (`_cargarRecord`), que publica con `setState`: si cayera en medio de la
      // aserción de identidad, la haría fallar por un motivo ajeno al test.
      await tester.pumpAndSettle();

      final headerAntes = tester.widget<GameHeader>(find.byType(GameHeader));
      final tableroAntes = leerTablero(tester, 3);

      final movible = PuzzleLogic.movibles(tableroAntes, 3).first;
      await tester.tap(
        find.byKey(ValueKey(tableroAntes[movible])),
        warnIfMissed: false,
      );
      await tester.pump();

      // Control de sensibilidad: el tablero se movió y el contador subió. Sin
      // esto, la aserción de abajo pasaría por no haber pasado nada.
      expect(leerTablero(tester, 3), isNot(equals(tableroAntes)));
      expect(
        find.descendant(of: find.byType(HudCard), matching: find.text('1')),
        findsOneWidget,
      );

      // El Chrome queda intacto: la misma instancia de widget sigue montada, es
      // decir que `_GameScreenState.build` no volvió a correr. Con el tablero y
      // el contador en `ValueNotifier`, los únicos que reaccionan son sus
      // builders; con un `setState` se reconstruía la pantalla entera (~1000
      // elementos en 5×5) en cada jugada.
      expect(
        identical(tester.widget<GameHeader>(find.byType(GameHeader)), headerAntes),
        isTrue,
        reason: 'mover una ficha volvió a reconstruir el Chrome',
      );

      // La pantalla se desmonta a mano para que `dispose` detenga el cronómetro
      // que arrancó el primer movimiento.
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'la capa del tablero queda por encima del LayoutBuilder: la invalidación '
    'no escapa al viewport del scroll',
    (tester) async {
      await tester.pumpWidget(appLocalizada(home: const GameScreen(size: 5)));
      await tester.pump();

      // El `LayoutBuilder` de `PuzzleBoard` es el boundary de *relayout* del
      // tablero, y el framework cierra todo layout con `markNeedsPaint()`
      // (`RenderObject.layout` y `_layoutWithoutResize`). Por eso la
      // invalidación que dispara mover una ficha **nace en el `LayoutBuilder`**,
      // no en el `Stack`, y sube hasta la primera capa de repintado que
      // encuentre. Si el `RepaintBoundary` volviera a quedar adentro, esa capa
      // sería el viewport del `SingleChildScrollView`
      // (`_RenderSingleChildViewport` es repaint boundary) y cada uno de los
      // ~10 frames de los 160 ms del deslizamiento volvería a registrar y
      // rasterizar el HUD, la consigna, el pozo con su halo y la botonera.
      final layoutBuilder = tester.renderObject(
        find
            .descendant(
              of: find.byType(PuzzleBoard),
              matching: find.byType(LayoutBuilder),
            )
            .first,
      );
      final capaDelRelayout = _capaDeRepintado(layoutBuilder);

      expect(
        capaDelRelayout,
        isA<RenderRepaintBoundary>(),
        reason: 'el RepaintBoundary volvió a quedar adentro del LayoutBuilder: '
            'la invalidación de relayout del tablero escapa hasta el viewport '
            'del scroll y el deslizamiento repinta el HUD, el pozo con su halo '
            'y la botonera',
      );

      // Y es **la misma** capa que la del `Stack`: el tablero entero comparte
      // una sola capa de repintado, así que la invalidación por relayout y la
      // de pintado caen juntas y no arrastran al resto de la pantalla.
      final stack = tester.renderObject(
        find
            .descendant(
              of: find.byType(PuzzleBoard),
              matching: find.byType(Stack),
            )
            .first,
      );
      expect(
        identical(capaDelRelayout, _capaDeRepintado(stack)),
        isTrue,
        reason: 'el relayout y el pintado del tablero están cayendo en capas '
            'distintas: hay más de un RepaintBoundary en el camino',
      );
      expect(
        capaDelRelayout!.paintBounds.size,
        stack.paintBounds.size,
        reason: 'la capa del tablero no mide lo que mide el tablero',
      );
    },
  );
}
