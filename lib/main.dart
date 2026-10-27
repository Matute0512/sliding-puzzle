import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sliding_puzzle/services/coins_service.dart';
import 'package:sliding_puzzle/services/records_service.dart';

import 'firebase_options.dart';
import 'l10n/app_localizations.dart';
import 'l10n/supported_locales.dart';
import 'providers/app_settings_provider.dart';
import 'screens/home_screen.dart';
import 'services/admob_service.dart';
import 'services/play_games_service.dart';
import 'services/sound_service.dart';
import 'theme/app_theme.dart';
import 'theme/kenney_ui.dart';
import 'widgets/ad_banner_widget.dart';

Future<void> _inicializarFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);
    // Sesión anónima: necesaria para escribir en Firestore (1 doc por uid).
    if (FirebaseAuth.instance.currentUser == null) {
      await FirebaseAuth.instance.signInAnonymously();
    }
  } catch (e) {
    // Sin red o plataforma sin configurar: la app arranca igual. El Top 5
    // mostrará su estado de error y la escritura del puntaje se omite.
    debugPrint('Firebase no disponible: $e');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _inicializarFirebase();
  await RecordsService.limpiarDatosViejos();
  await CoinsService.inicializar();
  final settings = AppSettingsProvider();
  await settings.inicializar();
  await SoundService.inicializar();
  unawaited(AdMobService.init());
  unawaited(PlayGamesService.iniciarSesionSilenciosa());

  runApp(
    ChangeNotifierProvider.value(
      value: settings,
      child: const SlidingPuzzleApp(),
    ),
  );
}

class SlidingPuzzleApp extends StatelessWidget {
  const SlidingPuzzleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // El título es el nombre comercial de la app, no texto traducible.
      title: 'Sliding Puzzle',
      debugShowCheckedModeBanner: false,
      // Sin `locale` explícito: la app sigue el idioma del sistema.
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      // `localesSoportados` fija el orden del respaldo (español primero). Ver el
      // comentario en lib/l10n/supported_locales.dart: el orden generado por
      // gen-l10n dejaría el inglés como respaldo.
      supportedLocales: localesSoportados,
      // Un solo tema, y sin `darkTheme` ni `themeMode`: el juego no sigue el
      // modo claro/oscuro del sistema. Como `theme` es lo único que hay,
      // MaterialApp lo usa siempre, sin importar lo que diga el dispositivo.
      theme: AppTheme.game,
      // El fondo del juego y el banner inferior se montan acá, una sola vez,
      // por fuera del Navigator: así el patrón de fondo es continuo y el
      // banner permanece cargado al cambiar entre Home, Niveles y los tableros
      // sin retraso ni recargas en cada navegación.
      builder: (context, child) => GameBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: child ?? const SizedBox.shrink(),
          bottomNavigationBar: const AdBannerWidget(),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
