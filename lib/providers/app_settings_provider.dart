import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/sound_service.dart';

/// Maneja el estado global de configuración de la app:
/// efectos de sonido y música de fondo.
///
/// Persiste todas las preferencias via shared_preferences.
///
/// Ya no maneja el tema: el juego tiene un único aspecto (`AppTheme.game`) y no
/// sigue el modo claro/oscuro del sistema. La clave `theme_mode` que quedó
/// guardada en instalaciones viejas se ignora; no se borra porque no molesta y
/// así no hay que tocarla en la migración.
class AppSettingsProvider extends ChangeNotifier {
  static const String _claveSonido = 'sonido_activado';
  static const String _claveMusica = 'musica_activada';

  bool _sonidoActivado = true;
  bool _musicaActivada = true;

  bool get sonidoActivado => _sonidoActivado;
  bool get musicaActivada => _musicaActivada;

  /// Cargar todas las preferencias guardadas.
  /// Llamar una sola vez antes de runApp() o al iniciar el widget raíz.
  Future<void> inicializar() async {
    final prefs = await SharedPreferences.getInstance();

    _sonidoActivado = prefs.getBool(_claveSonido) ?? true;
    _musicaActivada = prefs.getBool(_claveMusica) ?? true;

    // Sincronizamos SoundService con las preferencias cargadas.
    SoundService.sonidoActivado = _sonidoActivado;
    SoundService.musicaActivada = _musicaActivada;

    // ¡CRÍTICO!: Notificar a la UI para que aplique el tema y configuraciones reales guardadas
    notifyListeners();
  }

  Future<void> alternarSonido() async {
    _sonidoActivado = !_sonidoActivado;
    SoundService.sonidoActivado = _sonidoActivado;
    notifyListeners(); // La UI cambia el icono de forma instantánea

    // Si se activa, podemos reproducir opcionalmente un "click" de prueba aquí
    if (_sonidoActivado) {
      SoundService.reproducirClick();
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
