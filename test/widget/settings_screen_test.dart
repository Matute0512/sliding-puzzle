import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sliding_puzzle/providers/app_settings_provider.dart';
import 'package:sliding_puzzle/screens/settings_screen.dart';
import 'package:sliding_puzzle/theme/app_theme.dart';

void main() {
  testWidgets(
    'el SegmentedButton del tema no desborda en ancho angosto ni con fuente grande',
    (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(320, 700);
      addTearDown(tester.view.reset);

      // Fuente grande del sistema: el caso que recortaba 'Sistema'.
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => AppSettingsProvider(),
          child: MaterialApp(
            theme: AppTheme.light,
            home: const SettingsScreen(),
          ),
        ),
      );
      await tester.pump();

      // Si un segmento desbordara, pumpWidget habría lanzado una excepción
      // de RenderFlex overflow. Además, los 3 labels deben estar presentes.
      expect(find.byType(SegmentedButton<ThemeMode>), findsOneWidget);
      expect(find.text('Claro'), findsOneWidget);
      expect(find.text('Oscuro'), findsOneWidget);
      expect(find.text('Sistema'), findsOneWidget);
    },
  );
}
