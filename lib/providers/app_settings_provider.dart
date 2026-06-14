import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/sound_service.dart';

/// Maneja el estado global de configuración de la app:
/// tema, efectos de sonido y música de fondo.
///
/// Persiste todas las preferencias via shared_preferences.
class AppSettingsProvider extends ChangeNotifier {
  static const String _claveTema = 'theme_mode';
  static const String _claveSonido = 'sondido_activado';
  static const String _claveMusica = 'musica_activada';

  ThemeMode _themeMode = ThemeMode.system;
  bool _sonidoActivado = true;
  bool _musicaActivada = true;

  ThemeMode get themeMode => _themeMode;
  bool get sonidoActivado => _sonidoActivado;
  bool get musicaActivada => _musicaActivada;

  /// Cargar todas las preferencias guardadas.
  /// Llamar una sola vez antes de runApp().
  Future<void> inicializar() async {
    final prefs = await SharedPreferences.getInstance();

    final valorTema = prefs.getString(_claveTema);
    _themeMode = switch (valorTema) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };

    _sonidoActivado = prefs.getBool(_claveSonido) ?? true;
    _musicaActivada = prefs.getBool(_claveMusica) ?? true;

    // Sincronizamos SoundService con las preferecias cargadas.
    SoundService.sonidoActivado = _sonidoActivado;
    SoundService.musicaActivada = _musicaActivada;
  }

  Future<void> cambiarTema(ThemeMode modo) async {
    _themeMode = modo;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_claveTema, modo.name);
  }

  Future<void> alternarSonido() async {
    _sonidoActivado = !_sonidoActivado;
    SoundService.sonidoActivado = _sonidoActivado;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_claveSonido, _sonidoActivado);
  }

  Future<void> alternarMusica() async {
    _musicaActivada = !_musicaActivada;
    SoundService.musicaActivada = _musicaActivada;
    if (_musicaActivada) {
      await SoundService.iniciarMusica();
    } else {
      await SoundService.detenerMusica();
    }
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_claveMusica, _musicaActivada);
  }
}
