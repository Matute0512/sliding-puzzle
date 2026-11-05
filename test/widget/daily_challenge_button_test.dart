import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sliding_puzzle/screens/home_screen.dart';
import 'package:sliding_puzzle/services/admob_service.dart';
import 'package:sliding_puzzle/services/coins_service.dart';
import 'package:sliding_puzzle/services/daily_challenge_service.dart';

import '../helpers/localized_app.dart';

void main() {
  setUp(() {
    DailyChallengeService.reloj = DateTime.now;
    CoinsService.reiniciarEstadoParaTests(0);
    AdMobService.reiniciarEstadoParaTests();
  });

  /// `app_has_rated: true` evita que el modal de calificación aparezca encima
  /// y ensucie los finders.
  void montarHome([Map<String, Object> extraPrefs = const {}]) {
    SharedPreferences.setMockInitialValues({
      'app_has_rated': true,
      'monedas_bienvenida_entregada': true,
      ...extraPrefs,
    });
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

    // El botón del diario es un `ArcadeButton`, que pinta su título en
    // versalitas; el subtítulo va tal cual.
    expect(find.text('DESAFÍO DIARIO'), findsOneWidget);
    expect(find.text('Un tablero por día · todos juegan el mismo'), findsOneWidget);
    expect(find.text('VER RESULTADOS DEL DÍA'), findsNothing);
  });

  testWidgets('si ya jugó hoy, el botón pasa a Ver Resultados del Día', (
    tester,
  ) async {
    montarHome();
    await DailyChallengeService.marcarJugadoHoy();

    await renderHome(tester);

    expect(find.text('VER RESULTADOS DEL DÍA'), findsOneWidget);
    expect(find.text('Ya jugaste el de hoy · volvé mañana'), findsOneWidget);
    expect(find.text('DESAFÍO DIARIO'), findsNothing);
  });

  testWidgets('al cruzarse la medianoche UTC el botón vuelve a habilitarse y muestra la racha activa', (
    tester,
  ) async {
    montarHome();

    // Se completó el desafío de ayer...
    await DailyChallengeService.marcarJugadoHoy(
      ahora: DateTime.now().toUtc().subtract(const Duration(days: 1)),
    );

    // ...así que hoy el botón tiene que ofrecer jugar de nuevo mostrando la racha.
    await renderHome(tester);

    expect(find.text('DESAFÍO DIARIO'), findsOneWidget);
    expect(find.text('🔥 Racha de 1d · ¡mantenela hoy!'), findsOneWidget);
    expect(find.text('VER RESULTADOS DEL DÍA'), findsNothing);
  });

  testWidgets('si ya jugó hoy con racha de 2 o más días, muestra la racha en el subtítulo', (
    tester,
  ) async {
    montarHome();
    DailyChallengeService.reloj = () => DateTime.utc(2026, 9, 20, 12);
    await DailyChallengeService.marcarJugado(20260919);
    await DailyChallengeService.marcarJugado(20260920);

    await renderHome(tester);

    expect(find.text('VER RESULTADOS DEL DÍA'), findsOneWidget);
    expect(find.text('Ya jugaste hoy · 🔥 Racha de 2d'), findsOneWidget);
  });

  testWidgets('si salteó ayer muestra racha en riesgo y permite salvarla con 50 monedas', (
    tester,
  ) async {
    montarHome({'monedas_saldo': 60});
    await CoinsService.inicializar();
    DailyChallengeService.reloj = () => DateTime.utc(2026, 9, 22, 12);
    await DailyChallengeService.marcarJugado(20260919);
    await DailyChallengeService.marcarJugado(20260920);

    await renderHome(tester);

    expect(find.text('⚠️ Racha de 2d en riesgo · ¡salvala hoy!'), findsOneWidget);

    final boton = find.text('DESAFÍO DIARIO');
    await tester.ensureVisible(boton);
    await tester.pumpAndSettle();
    await tester.tap(boton);
    await tester.pumpAndSettle();

    expect(find.text('🛡️ ¡Racha de 2d en riesgo!'), findsOneWidget);
    expect(find.text('Salvar con 50 monedas'), findsOneWidget);

    await tester.tap(find.text('Salvar con 50 monedas'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(CoinsService.saldo, equals(10));
    final estado = await DailyChallengeService.estadoRacha(
      ahora: DateTime.utc(2026, 9, 22, 12),
    );
    expect(estado.enRiesgo, isFalse);
    expect(estado.rachaActual, equals(2));
  });

  testWidgets('permite salvar la racha en riesgo viendo un anuncio bonificado', (
    tester,
  ) async {
    montarHome({'monedas_saldo': 10});
    await CoinsService.inicializar();
    AdMobService.mostrarRewardedOverride = () async => true;
    DailyChallengeService.reloj = () => DateTime.utc(2026, 9, 22, 12);
    await DailyChallengeService.marcarJugado(20260918);
    await DailyChallengeService.marcarJugado(20260919);
    await DailyChallengeService.marcarJugado(20260920);

    await renderHome(tester);

    expect(find.text('⚠️ Racha de 3d en riesgo · ¡salvala hoy!'), findsOneWidget);

    final boton = find.text('DESAFÍO DIARIO');
    await tester.ensureVisible(boton);
    await tester.pumpAndSettle();
    await tester.tap(boton);
    await tester.pumpAndSettle();

    expect(find.text('🛡️ ¡Racha de 3d en riesgo!'), findsOneWidget);
    expect(find.text('Salvar viendo anuncio'), findsOneWidget);

    await tester.tap(find.text('Salvar viendo anuncio'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final estado = await DailyChallengeService.estadoRacha(
      ahora: DateTime.utc(2026, 9, 22, 12),
    );
    expect(estado.enRiesgo, isFalse);
    expect(estado.rachaActual, equals(3));
  });

  testWidgets('tocar el botón abre los resultados del día', (tester) async {
    montarHome();
    await DailyChallengeService.marcarJugadoHoy();
    await renderHome(tester);

    // El Home es scrolleable y el botón queda debajo del fold en el viewport
    // por defecto (800x600): sin esto el tap no acierta y no pasa nada.
    final boton = find.text('VER RESULTADOS DEL DÍA');
    await tester.ensureVisible(boton);
    await tester.pumpAndSettle();

    await tester.tap(boton);
    // Sin `pumpAndSettle`: mientras la consulta está en vuelo hay un spinner
    // girando y no settlea nunca.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

    expect(find.text('Resultados del Día'), findsOneWidget);
  });
}
