import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sliding_puzzle/services/best_run_service.dart';
import 'package:sliding_puzzle/widgets/best_run_card.dart';

import '../helpers/localized_app.dart';

void main() {
  Future<void> montar(WidgetTester tester, MejorPartida? marca) async {
    await tester.pumpWidget(
      appLocalizada(
        home: Scaffold(
          body: Center(child: BestRunCard(marca: marca)),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  MejorPartida marca({
    int tiempoSegundos = 37,
    int movimientos = 45,
    int tamano = 4,
  }) => MejorPartida(
    tiempoSegundos: tiempoSegundos,
    movimientos: movimientos,
    tamano: tamano,
    fecha: DateTime(2026, 9, 30),
  );

  testWidgets('con marca muestra tiempo, movimientos y tablero', (tester) async {
    await montar(tester, marca());

    expect(find.text('MEJOR PARTIDA'), findsOneWidget);
    expect(find.text('00:37'), findsOneWidget);
    expect(find.text('45 MOVS'), findsOneWidget);
    // El tablero va como "Récord en NxN" y no como "Tablero NxN": la tarjeta
    // muestra la marca de un tablero concreto y el jugador tiene que saber cuál
    // está intentando romper.
    expect(find.text('RÉCORD EN 4×4'), findsOneWidget);
  });

  testWidgets('formatea el tiempo como cronómetro, con minutos', (tester) async {
    // El resto de la app muestra "125s"; esta tarjeta usa mm:ss porque es el
    // formato del frame. Sin el acarreo de minutos daría "00:125".
    await montar(tester, marca(tiempoSegundos: 125));

    expect(find.text('02:05'), findsOneWidget);
  });

  testWidgets('sin marca muestra el estado vacío, no un cero', (tester) async {
    await montar(tester, null);

    expect(find.text('MEJOR PARTIDA'), findsOneWidget);
    expect(find.text('--:--'), findsOneWidget);
    expect(find.text('Todavía no terminaste ninguna partida'), findsOneWidget);

    // Un "00:00" se leería como un récord real de cero segundos.
    expect(find.text('00:00'), findsNothing);
  });
}
