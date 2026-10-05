import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sliding_puzzle/providers/app_settings_provider.dart';
import 'package:sliding_puzzle/screens/settings_screen.dart';

import '../helpers/localized_app.dart';

void main() {
  testWidgets(
    'la pantalla no desborda en ancho angosto ni con fuente grande',
    (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(320, 700);
      addTearDown(tester.view.reset);

      // Fuente grande del sistema: el caso que recortaba textos en el ancho
      // mínimo soportado.
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => AppSettingsProvider(),
          child: appLocalizada(home: const SettingsScreen()),
        ),
      );
      await tester.pump();

      // Si algo desbordara, pumpWidget habría lanzado una excepción de
      // RenderFlex overflow.
      expect(find.text('Sonido'), findsOneWidget);
      expect(find.text('Efectos de sonido'), findsOneWidget);
      expect(find.text('Música de fondo'), findsOneWidget);
      expect(find.byType(Switch), findsNWidgets(2));
    },
  );

  testWidgets('ya no hay selector de tema: el juego tiene un solo aspecto', (
    tester,
  ) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppSettingsProvider(),
        child: appLocalizada(home: const SettingsScreen()),
      ),
    );
    await tester.pump();

    // El selector se sacó junto con el tema claro/oscuro. Si alguien lo
    // reintroduce sin devolverle un efecto real, este test lo marca: un control
    // de tema que no cambia nada es peor que no tenerlo.
    expect(find.byType(SegmentedButton<ThemeMode>), findsNothing);
    expect(find.text('Apariencia'), findsNothing);
  });
}
