import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sliding_puzzle/theme/app_theme.dart';
import 'package:sliding_puzzle/widgets/hud_card.dart';

void main() {
  Widget construir({
    required IconData icono,
    required String label,
    required String valor,
  }) {
    return MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: Center(
          child: HudCard(icono: icono, label: label, valor: valor),
        ),
      ),
    );
  }

  testWidgets('renderiza el label y el valor correctamente', (tester) async {
    await tester.pumpWidget(
      construir(icono: Icons.timer, label: 'Tiempo', valor: '12s'),
    );

    expect(find.text('Tiempo'), findsOneWidget);
    expect(find.text('12s'), findsOneWidget);
  });

  testWidgets('renderiza el ícono correcto', (tester) async {
    await tester.pumpWidget(
      construir(icono: Icons.sports_esports, label: 'Movimientos', valor: '0'),
    );

    expect(find.byIcon(Icons.sports_esports), findsOneWidget);
  });
}
