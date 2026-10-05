import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sliding_puzzle/logic/dificultad.dart';
import 'package:sliding_puzzle/widgets/arcade_button.dart';
import 'package:sliding_puzzle/widgets/difficulty_button.dart';

import '../helpers/localized_app.dart';

void main() {
  Future<void> montar(
    WidgetTester tester,
    Dificultad dificultad,
    VoidCallback onTap,
  ) async {
    await tester.pumpWidget(
      appLocalizada(
        home: Scaffold(
          body: Center(
            child: DifficultyButton(dificultad: dificultad, onTap: onTap),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('informa la dificultad que se tocó', (tester) async {
    // Es lo que pidió el rediseño: el botón no sabe de tamaños, entrega la
    // `Dificultad` y la pantalla la resuelve a un `size`. Si esto se rompiera,
    // tocar "Fácil" abriría el tablero de otra dificultad.
    for (final dificultad in Dificultad.jugables) {
      Dificultad? tocada;
      await montar(tester, dificultad, () => tocada = dificultad);

      await tester.tap(find.byType(ArcadeButton));
      expect(tocada, dificultad);
    }
  });

  testWidgets('muestra el nombre y el tablero', (tester) async {
    await montar(tester, Dificultad.medio, () {});

    // El título va en versalitas por estilo (ver `ArcadeButton`); el subtítulo
    // sale tal cual del catálogo.
    expect(find.text('MEDIO'), findsOneWidget);
    expect(find.text('Tablero 4×4'), findsOneWidget);
  });
}
