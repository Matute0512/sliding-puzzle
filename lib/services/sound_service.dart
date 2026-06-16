import 'package:flutter/widgets.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Servicio centralizado de audio usando SoLoud — motor de audio de baja
/// latencia diseñado para juegos. Reemplaza a audioplayers, que generaba
/// lag y crashes con taps rápidos y repetidos (clicks de fichas).
class SoundService {
  static const String _claveSonido = 'sonido_activado';
  static const String _claveMusica = 'musica_activada';

  static final SoLoud _soloud = SoLoud.instance;

  static AudioSource? _fuenteClick;
  static AudioSource? _fuenteVictoria;
  static AudioSource? _fuenteMusica;
  static SoundHandle? _handleMusica;

  static bool sonidoActivado = true;
  static bool musicaActivada = true;
  static bool _inicializado = false;
  static bool _pausadoPorCicloDeVida = false;

  static Future<void> inicializar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      sonidoActivado = prefs.getBool(_claveSonido) ?? true;
      musicaActivada = prefs.getBool(_claveMusica) ?? true;

      await _soloud.init();
      _inicializado = true;

      // Precargamos los 3 assets en memoria — quedan listos para
      // reproducirse instantáneamente sin recargar el archivo.
      _fuenteClick = await _soloud.loadAsset('assets/sounds/click.mp3');
      _fuenteVictoria = await _soloud.loadAsset('assets/sounds/victory.mp3');
      _fuenteMusica = await _soloud.loadAsset(
        'assets/sounds/background_music.mp3',
      );
    } catch (e) {
      debugPrint('Error inicializando SoundService: $e');
    }
  }

  /// Reproduce el click. SoLoud crea una nueva "voz" (instancia de
  /// reproducción) cada vez sin recargar el archivo ni bloquear el
  /// hilo principal — soporta clicks tan rápidos como el usuario tapee.
  static void reproducirClick() {
    if (!sonidoActivado || !_inicializado || _fuenteClick == null) return;
    _soloud.play(_fuenteClick!, volume: 0.6);
  }

  static void reproducirVictoria() {
    if (!sonidoActivado || !_inicializado || _fuenteVictoria == null) return;
    _soloud.play(_fuenteVictoria!, volume: 0.8);
  }

  static Future<void> iniciarMusica() async {
    if (!musicaActivada || !_inicializado || _fuenteMusica == null) return;
    try {
      // Si ya hay una instancia sonando, no abrimos otra encima.
      if (_handleMusica != null &&
          _soloud.getIsValidVoiceHandle(_handleMusica!)) {
        return;
      }
      _handleMusica = _soloud.play(_fuenteMusica!, volume: 0.35, looping: true);
    } catch (e) {
      debugPrint('Error al iniciar música: $e');
    }
  }

  static Future<void> pausarMusica() async {
    try {
      if (_handleMusica != null &&
          _soloud.getIsValidVoiceHandle(_handleMusica!)) {
        _soloud.setPause(_handleMusica!, true);
      }
    } catch (e) {
      debugPrint('Error al pausar música: $e');
    }
  }

  static Future<void> reanudarMusica() async {
    if (!musicaActivada) return;
    try {
      if (_handleMusica != null &&
          _soloud.getIsValidVoiceHandle(_handleMusica!)) {
        _soloud.setPause(_handleMusica!, false);
      } else {
        // El handle ya no es válido (se detuvo), arrancamos de nuevo.
        await iniciarMusica();
      }
    } catch (e) {
      debugPrint('Error al reanudar música: $e');
    }
  }

  static Future<void> detenerMusica() async {
    try {
      if (_handleMusica != null) {
        await _soloud.stop(_handleMusica!);
        _handleMusica = null;
      }
    } catch (e) {
      debugPrint('Error al detener música: $e');
    }
  }

  static void manejarCicloDeVida(AppLifecycleState estado) {
    if (estado == AppLifecycleState.paused ||
        estado == AppLifecycleState.inactive) {
      if (musicaActivada &&
          _handleMusica != null &&
          _soloud.getIsValidVoiceHandle(_handleMusica!)) {
        pausarMusica();
        _pausadoPorCicloDeVida = true;
      }
    } else if (estado == AppLifecycleState.resumed) {
      if (_pausadoPorCicloDeVida) {
        reanudarMusica();
        _pausadoPorCicloDeVida = false;
      }
    }
  }

  static Future<void> alternarSonido() async {
    sonidoActivado = !sonidoActivado;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_claveSonido, sonidoActivado);
    if (sonidoActivado) {
      reproducirClick();
    }
  }

  static Future<void> alternarMusica() async {
    musicaActivada = !musicaActivada;
    if (musicaActivada) {
      await iniciarMusica();
    } else {
      await detenerMusica();
      _pausadoPorCicloDeVida = false;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_claveMusica, musicaActivada);
  }
}
