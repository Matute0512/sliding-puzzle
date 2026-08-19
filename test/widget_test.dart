import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sliding_puzzle/screens/game_screen.dart';
import 'package:sliding_puzzle/theme/app_theme.dart';

void main() {
  testWidgets(
    'el GridView no recorta las sombras de las fichas (Clip.none) '
    'para los 3 tamaños de tablero',
    (tester) async {
      for (final size in [3, 4, 5]) {
        await tester.pumpWidget(
          MaterialApp(theme: AppTheme.light, home: GameScreen(size: size)),
        );
        await tester.pump();

        final grid = tester.widget<GridView>(find.byType(GridView));
        expect(
          grid.clipBehavior,
          Clip.none,
          reason:
              'el grid debe dejar visible la sombra de la fila inferior '
              '(size=$size)',
        );

        await tester.pumpWidget(const SizedBox.shrink());
      }
    },
  );

  testWidgets(
    'el tablero completo con todas las sombras cabe en pantalla sin scroll '
    'en 380px y en Pixel 7',
    (tester) async {
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      for (final logicalSize in [const Size(380, 740), const Size(412, 915)]) {
        tester.view.physicalSize = logicalSize;

        for (final size in [3, 4, 5]) {
          await tester.pumpWidget(
            MaterialApp(theme: AppTheme.light, home: GameScreen(size: size)),
          );
          await tester.pump();

          final grid = tester.widget<GridView>(find.byType(GridView));
          expect(grid.clipBehavior, Clip.none);

          // Extensión máxima de sombra hacia abajo entre todas las fichas
          // (offset.dy + blurRadius), tomada de la decoración real.
          final tiles = tester.widgetList<AnimatedContainer>(
            find.descendant(
              of: find.byType(GridView),
              matching: find.byType(AnimatedContainer),
            ),
          );
          var maxShadow = 0.0;
          for (final tile in tiles) {
            final sombras = (tile.decoration as BoxDecoration).boxShadow!;
            for (final s in sombras) {
              maxShadow = math.max(maxShadow, s.offset.dy + s.blurRadius);
            }
          }

          // La sombra de la fila inferior debe quedar dentro del viewport
          // visible (no cortada por el SingleChildScrollView).
          final scrollViewRect = tester.getRect(
            find.byType(SingleChildScrollView),
          );
          final gridBottom = tester.getBottomLeft(find.byType(GridView)).dy;
          expect(
            gridBottom + maxShadow,
            lessThanOrEqualTo(scrollViewRect.bottom),
            reason:
                'la sombra inferior debe ser visible sin scroll '
                '(size=$size, pantalla=$logicalSize)',
          );

          // No se necesita scroll: el contenido entra completo.
          final scrollable = tester.state<ScrollableState>(
            find
                .descendant(
                  of: find.byType(SingleChildScrollView),
                  matching: find.byType(Scrollable),
                )
                .first,
          );
          expect(
            scrollable.position.maxScrollExtent,
            0,
            reason:
                'no debe requerir scroll (size=$size, pantalla=$logicalSize)',
          );

          await tester.pumpWidget(const SizedBox.shrink());
        }
      }
    },
  );
}
