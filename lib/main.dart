import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'services/sound_service.dart';
import 'services/theme_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SoundService.inicializar();
  runApp(const SlidingPuzzleApp());
}

class SlidingPuzzleApp extends StatefulWidget {
  const SlidingPuzzleApp({super.key});

  @override
  State<SlidingPuzzleApp> createState() => _SlidingPuzzleAppState();
}

class _SlidingPuzzleAppState extends State<SlidingPuzzleApp> {
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _cargarTema();
  }

  Future<void> _cargarTema() async {
    final mode = await ThemeService.cargarThemeMode();
    if (!mounted) return;
    setState(() => _themeMode = mode);
  }

  void cambiarTema(ThemeMode mode) {
    setState(() => _themeMode = mode);
    ThemeService.guardarThemeMode(mode);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sliding Puzzle',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: _themeMode,
      home: HomeScreen(themeMode: _themeMode, onThemeChanged: cambiarTema),
    );
  }
}
