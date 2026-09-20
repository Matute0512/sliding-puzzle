import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sliding_puzzle/l10n/app_localizations_en.dart';
import 'package:sliding_puzzle/l10n/app_localizations_es.dart';
import 'package:sliding_puzzle/main.dart';
import 'package:sliding_puzzle/providers/app_settings_provider.dart';
import 'package:sliding_puzzle/screens/home_screen.dart';

import 'helpers/localized_app.dart';

/// Estos tests sostienen el contrato de la i18n: que los catálogos estén
/// completos en ambos idiomas y que los mensajes con placeholders interpolen.
/// Sin ellos, un cambio en un `.arb` que rompa el formato de un mensaje solo se
/// notaría jugando.
void main() {
  group('catálogos', () {
    final es = AppLocalizationsEs();
    final en = AppLocalizationsEn();

    test('interpolan los placeholders de tiempo y objetivo', () {
      expect(es.secondsShort(45), '45s');
      expect(en.secondsShort(45), '45s');
      expect(es.goalMoves(20), '20 movs');
      expect(en.goalMoves(20), '20 moves');
    });

    test('interpolan la descripción de la dificultad', () {
      expect(es.boardSize(4), 'Tablero 4×4');
      expect(en.boardSize(4), 'Board 4×4');
    });

    test('interpolan el detalle de una partida guardada', () {
      // El mismo valor se reusa dos veces en el tamaño del tablero.
      expect(es.continueFreeDetail(4, 30, 45), 'Tablero 4×4 · 30 movs · 45s');
      expect(en.continueFreeDetail(4, 30, 45), 'Board 4×4 · 30 moves · 45s');
      expect(es.continueChallengeDetail(7, 12), 'Desafío · Nivel 7 · 12 movs');
      expect(en.continueChallengeDetail(7, 12), 'Challenge · Level 7 · 12 moves');
    });

    test('interpolan los mensajes de victoria y progreso', () {
      expect(es.levelPassed(5), '⭐ ¡Nivel 5 superado!');
      expect(en.levelPassed(5), '⭐ Level 5 cleared!');
      expect(es.top5Entered(3), '¡Entraste al Top 5 global! Puesto #3');
      expect(en.top5Entered(3), 'You made the Global Top 5! Rank #3');
      expect(es.levelProgress(4), '4 / 20');
      expect(es.starsProgress(9), '9 / 60');
      expect(es.levelStarsSemantics(4, 2), 'Nivel 4, 2 de 3 estrellas');
      expect(en.levelStarsSemantics(4, 2), 'Level 4, 2 of 3 stars');
    });
  });

  group('renderizado por locale', () {
    setUp(() {
      // `app_has_rated` evita que el menú abra el modal de calificación al
      // arrancar y se coma los `find.text` de abajo.
      SharedPreferences.setMockInitialValues(const {'app_has_rated': true});
    });

    testWidgets('el menú usa español con locale es', (tester) async {
      await tester.pumpWidget(appLocalizada(home: const HomeScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Elegí una dificultad'), findsOneWidget);
      expect(find.text('Modo Desafío'), findsOneWidget);
      expect(find.text('Tablero 3×3'), findsOneWidget);
      expect(find.text('Ver récords'), findsOneWidget);
    });

    testWidgets('el menú usa inglés con locale en', (tester) async {
      await tester.pumpWidget(
        appLocalizada(home: const HomeScreen(), locale: const Locale('en')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pick a difficulty'), findsOneWidget);
      expect(find.text('Challenge Mode'), findsOneWidget);
      expect(find.text('Board 3×3'), findsOneWidget);
      expect(find.text('View records'), findsOneWidget);

      // Y no se filtró texto en español.
      expect(find.text('Elegí una dificultad'), findsNothing);
    });
  });

  /// Estos montan el `SlidingPuzzleApp` real —no el helper— y mueven el locale
  /// de *plataforma* en vez del `locale:` del `MaterialApp`. Es la única forma
  /// de ejercitar la resolución de idioma: pasar `locale:` la saltea por
  /// completo, así que un test así pasaría sin validar el orden de respaldo.
  group('configuración de producción', () {
    Future<void> montarApp(WidgetTester tester, List<Locale> plataforma) async {
      tester.platformDispatcher.localesTestValue = plataforma;
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);

      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => AppSettingsProvider(),
          child: const SlidingPuzzleApp(),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('sigue el idioma del sistema cuando está soportado',
        (tester) async {
      await montarApp(tester, const [Locale('en')]);

      expect(find.text('Pick a difficulty'), findsOneWidget);
    });

    testWidgets('un idioma no soportado cae a español, no a inglés',
        (tester) async {
      // Acá es donde se prueba el ORDEN de `supportedLocales`: gen-l10n emite
      // `[en, es]` alfabético, y con esa lista los tres casos de abajo
      // renderizarían inglés.
      for (final idioma in ['fr', 'pt', 'ja']) {
        await montarApp(tester, [Locale(idioma)]);

        expect(
          find.text('Elegí una dificultad'),
          findsOneWidget,
          reason: 'el respaldo para "$idioma" debe ser español',
        );
      }
    });
  });
}
