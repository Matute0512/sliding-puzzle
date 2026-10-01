import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sliding_puzzle/screens/challenge_levels_screen.dart';
import 'package:sliding_puzzle/screens/game_screen.dart';
import 'package:sliding_puzzle/screens/home_screen.dart';

import '../helpers/localized_app.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(const {});
  });

  testWidgets('Home ofrece un botón para entrar al Modo Desafío', (tester) async {
    await tester.pumpWidget(
      appLocalizada(home: const HomeScreen()),
    );
    await tester.pump();

    // El modo Desafío ya no es un botón propio: es el segmento derecho del
    // switch del menú, que renderiza su etiqueta en versalitas.
    expect(find.text('DESAFÍO'), findsOneWidget);
  });

  testWidgets('ChallengeLevelsScreen muestra el resumen y niveles bloqueados',
      (tester) async {
    await tester.pumpWidget(
      appLocalizada(home: const ChallengeLevelsScreen()),
    );
    await tester.pumpAndSettle();

    // El header es el del frame: título y bajada propios del Modo Desafío, en
    // vez del nombre genérico que ponía el AppBar.
    expect(find.text('DESAFÍO'), findsOneWidget);
    expect(find.text('CIRCUITO ARCADE'), findsOneWidget);

    // Sin progreso: nivel alcanzado 1 y 0 estrellas. El rótulo y el total son
    // los del frame — "TU PROGRESO" y el número pelado, sin "/ 60".
    expect(find.text('TU PROGRESO'), findsOneWidget);
    expect(find.text('1 / 20'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);

    // Los niveles posteriores al 1 están bloqueados.
    expect(find.text('BLOQUEADO'), findsWidgets);

    // El aviso del pie nombra el nivel que hay que completar para avanzar.
    expect(
      find.text('Completá el nivel 1 para desbloquear el siguiente.'),
      findsOneWidget,
    );
  });

  testWidgets('GameScreen en desafío muestra el HUD Objetivo y no el Tiempo',
      (tester) async {
    await tester.pumpWidget(
      appLocalizada(home: const GameScreen(size: 3, nivelDesafio: 1)),
    );
    await tester.pump();

    // Nivel 1 → tablero 3x3 con objetivo de 3 movimientos.
    expect(find.text('Objetivo'), findsOneWidget);
    expect(find.text('3 movs'), findsOneWidget);
    expect(find.text('Tiempo'), findsNothing);
  });
}
