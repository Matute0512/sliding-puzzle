import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/app_settings_provider.dart';
import 'screens/home_screen.dart';
import 'services/sound_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
