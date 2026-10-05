import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sliding_puzzle/widgets/mode_switch.dart';

import '../helpers/localized_app.dart';

void main() {
  Future<void> montar(WidgetTester tester, VoidCallback onDesafio) async {
    await tester.pumpWidget(
      appLocalizada(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: ModeSwitch(onDesafio: onDesafio),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('muestra los dos modos', (tester) async {
    await montar(tester, () {});

    expect(find.text('CLÁSICO'), findsOneWidget);
    expect(find.text('DESAFÍO'), findsOneWidget);
  });

  testWidgets('tocar Desafío avisa, y Clásico no hace nada', (tester) async {
    var veces = 0;
    await montar(tester, () => veces++);

    // Clásico es la pantalla en la que ya estamos: no es un control, es un
    // cartel. Tocarlo no puede disparar nada.
    await tester.tap(find.text('CLÁSICO'));
    await tester.pumpAndSettle();
    expect(veces, 0);

    await tester.tap(find.text('DESAFÍO'));
    await tester.pumpAndSettle();
    expect(veces, 1);
  });
}
