import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sliding_puzzle/theme/app_theme.dart';
import 'package:sliding_puzzle/widgets/puzzle_tile.dart';

void main() {
  Widget construir({int numero = 5, int size = 3, VoidCallback? onTap}) {
    return MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: Center(
          child: PuzzleTile(
            numero: numero,
            size: size,
            onTap: onTap ?? () {},
          ),
        ),
      ),
    );
  }

  testWidgets('no renderiza texto cuando numero == 0 (ficha vacía)', (tester) async {
    await tester.pumpWidget(construir(numero: 0));

    expect(find.byType(Text), findsNothing);
  });

  testWidgets('renderiza el número correcto cuando numero > 0', (tester) async {
    await tester.pumpWidget(construir(numero: 5));

    expect(find.text('5'), findsOneWidget);
  });

  testWidgets('llama onTap cuando se toca la ficha', (tester) async {
    var toques = 0;
    await tester.pumpWidget(construir(numero: 5, onTap: () => toques++));

    await tester.tap(find.byType(PuzzleTile));
    expect(toques, 1);
  });
}
