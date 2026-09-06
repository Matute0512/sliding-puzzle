import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sliding_puzzle/screens/challenge_levels_screen.dart';
import 'package:sliding_puzzle/screens/game_screen.dart';
import 'package:sliding_puzzle/screens/home_screen.dart';
import 'package:sliding_puzzle/theme/app_theme.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(const {});
  });

  testWidgets('Home ofrece un botón para entrar al Modo Desafío', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const HomeScreen()),
    );
    await tester.pump();

    expect(find.text('Modo Desafío'), findsOneWidget);
  });

  testWidgets('ChallengeLevelsScreen muestra el resumen y niveles bloqueados',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const ChallengeLevelsScreen()),
    );
    await tester.pumpAndSettle();

    // Sin progreso: nivel alcanzado 1 y estrellas 0.
    expect(find.text('Nivel alcanzado'), findsOneWidget);
    expect(find.text('1 / 20'), findsOneWidget);
    expect(find.text('0 / 60'), findsOneWidget);

    // Los niveles posteriores al 1 están bloqueados.
    expect(find.text('Bloqueado'), findsWidgets);
  });

  testWidgets('GameScreen en desafío muestra el HUD Objetivo y no el Tiempo',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const GameScreen(size: 3, nivelDesafio: 1),
      ),
    );
    await tester.pump();

    // Nivel 1 → tablero 3x3 con objetivo de 3 movimientos.
    expect(find.text('Objetivo'), findsOneWidget);
    expect(find.text('3 movs'), findsOneWidget);
    expect(find.text('Tiempo'), findsNothing);
  });
}
