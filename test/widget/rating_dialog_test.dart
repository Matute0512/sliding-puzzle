import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sliding_puzzle/services/records_service.dart';
import 'package:sliding_puzzle/widgets/rating_dialog.dart';

import '../helpers/localized_app.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('RatingDialog renderiza 5 estrellas, textos y botones',
      (tester) async {
    await tester.pumpWidget(
      appLocalizada(
        home: Scaffold(
          body: RatingDialog(
            onCalificar: () {},
            onAhoraNo: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.star_rounded), findsNWidgets(6)); // 5 en cabecera + 1 en botón
    expect(find.text('¿Te gusta Sliding Puzzle?'), findsOneWidget);
    expect(find.text('CALIFICAR EN PLAY STORE'), findsOneWidget);
    expect(find.text('Ahora no'), findsOneWidget);
  });

  testWidgets('RatingDialog.mostrar registra solicitud al tocar Ahora no',
      (tester) async {
    // 3 victorias para cumplir condición inicial
    await RecordsService.incrementarVictoriasParaRating();
    await RecordsService.incrementarVictoriasParaRating();
    await RecordsService.incrementarVictoriasParaRating();
    expect(await RecordsService.debeSolicitarCalificacion(), isTrue);

    await tester.pumpWidget(
      appLocalizada(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => RatingDialog.mostrar(context),
            child: const Text('Mostrar'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Abrir diálogo
    await tester.tap(find.text('Mostrar'));
    await tester.pumpAndSettle();

    expect(find.text('¿Te gusta Sliding Puzzle?'), findsOneWidget);

    // Tocar Ahora no
    await tester.tap(find.text('Ahora no'));
    await tester.pumpAndSettle();

    // Debe quedar en cooldown para las próximas 3 partidas
    expect(await RecordsService.debeSolicitarCalificacion(), isFalse);
    expect(await RecordsService.yaCalificoApp(), isFalse);
  });
}
