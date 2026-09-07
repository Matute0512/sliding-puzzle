import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sliding_puzzle/services/records_service.dart';

import 'firebase_options.dart';
import 'providers/app_settings_provider.dart';
import 'screens/home_screen.dart';
import 'services/sound_service.dart';
import 'theme/app_theme.dart';

Future<void> _inicializarFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
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
  final settings = AppSettingsProvider();
  await settings.inicializar();
  await SoundService.inicializar();

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
    final themeMode = context.watch<AppSettingsProvider>().themeMode;

    return MaterialApp(
      title: 'Sliding Puzzle',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      home: const HomeScreen(),
    );
  }
}
