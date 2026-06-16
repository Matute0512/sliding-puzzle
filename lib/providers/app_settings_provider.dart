import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/sound_service.dart';

/// Maneja el estado global de configuración de la app:
/// tema, efectos de sonido y música de fondo.
///
/// Persiste todas las preferencias via shared_preferences.
class AppSettingsProvider extends ChangeNotifier {
  static const String _claveTema = 'theme_mode';
  static const String _claveSonido =
      'sonido_activado'; // Arreglado el typo 'sondido'
  static const String _claveMusica = 'musica_activada';

  ThemeMode _themeMode = ThemeMode.system;
  bool _sonidoActivado = true;
  bool _musicaActivada = true;

  ThemeMode get themeMode => _themeMode;
  bool get sonidoActivado => _sonidoActivado;
  bool get musicaActivada => _musicaActivada;

  /// Cargar todas las preferencias guardadas.
  /// Llamar una sola vez antes de runApp() o al iniciar el widget raíz.
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

    // Sincronizamos SoundService con las preferencias cargadas.
    SoundService.sonidoActivado = _sonidoActivado;
    SoundService.musicaActivada = _musicaActivada;

    // ¡CRÍTICO!: Notificar a la UI para que aplique el tema y configuraciones reales guardadas
    notifyListeners();
  }

  Future<void> cambiarTema(ThemeMode modo) async {
    _themeMode = modo;
    notifyListeners(); // Notificación inmediata a la UI

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_claveTema, modo.name);
  }

  Future<void> alternarSonido() async {
    _sonidoActivado = !_sonidoActivado;
    SoundService.sonidoActivado = _sonidoActivado;
    notifyListeners(); // La UI cambia el icono de forma instantánea

    // Si se activa, podemos reproducir opcionalmente un "click" de prueba aquí
    if (_sonidoActivado) {
      SoundService.reproducirClick(); // Asegúrate de tener este método o similar en tu servicio
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_claveSonido, _sonidoActivado);
  }

  Future<void> alternarMusica() async {
    _musicaActivada = !_musicaActivada;
    SoundService.musicaActivada = _musicaActivada;

    // Cambiamos el estado asíncrono del reproductor de música
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
