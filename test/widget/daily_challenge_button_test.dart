import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sliding_puzzle/screens/home_screen.dart';
import 'package:sliding_puzzle/services/daily_challenge_service.dart';

import '../helpers/localized_app.dart';

void main() {
  /// `app_has_rated: true` evita que el modal de calificación aparezca encima
  /// y ensucie los finders.
  void montarHome() {
    SharedPreferences.setMockInitialValues(const {'app_has_rated': true});
  }

  Future<void> renderHome(WidgetTester tester) async {
    await tester.pumpWidget(appLocalizada(home: const HomeScreen()));
    // Dos frames: el primero monta, el segundo aplica el `setState` que llega
    // cuando termina de leerse el candado desde disco.
    await tester.pump();
    await tester.pump();
  }

  testWidgets('sin jugar hoy, el botón invita a jugar el Desafío Diario', (
    tester,
  ) async {
    montarHome();
    await renderHome(tester);

    expect(find.text('Desafío Diario'), findsOneWidget);
    expect(find.text('Un tablero por día · todos juegan el mismo'), findsOneWidget);
    expect(find.text('Ver Resultados del Día'), findsNothing);
  });

  testWidgets('si ya jugó hoy, el botón pasa a Ver Resultados del Día', (
    tester,
  ) async {
    montarHome();
    await DailyChallengeService.marcarJugadoHoy();

    await renderHome(tester);

    expect(find.text('Ver Resultados del Día'), findsOneWidget);
    expect(find.text('Ya jugaste el de hoy · volvé mañana'), findsOneWidget);
    expect(find.text('Desafío Diario'), findsNothing);
  });

  testWidgets('al cruzarse la medianoche UTC el botón vuelve a habilitarse', (
    tester,
  ) async {
    montarHome();

    // Se completó el desafío de ayer...
    await DailyChallengeService.marcarJugadoHoy(
      ahora: DateTime.now().toUtc().subtract(const Duration(days: 1)),
    );

    // ...así que hoy el botón tiene que ofrecer jugar de nuevo. Es el caso que
    // más fácil se rompe: basta con guardar un booleano en vez de la fecha.
    await renderHome(tester);

    expect(find.text('Desafío Diario'), findsOneWidget);
    expect(find.text('Ver Resultados del Día'), findsNothing);
  });

  testWidgets('tocar el botón avisa que la pantalla todavía no existe', (
    tester,
  ) async {
    montarHome();
    await DailyChallengeService.marcarJugadoHoy();
    await renderHome(tester);

    // El Home es scrolleable y el botón queda debajo del fold en el viewport
    // por defecto (800x600): sin esto el tap no acierta y no pasa nada.
    final boton = find.text('Ver Resultados del Día');
    await tester.ensureVisible(boton);
    await tester.pumpAndSettle();

    await tester.tap(boton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.widgetWithText(SnackBar, 'Próximamente'), findsOneWidget);
  });
}
