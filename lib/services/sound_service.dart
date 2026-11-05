import 'dart:ui';

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
  static AppLifecycleListener? _lifecycleListener;

  static Future<void> inicializar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      sonidoActivado = prefs.getBool(_claveSonido) ?? true;
      musicaActivada = prefs.getBool(_claveMusica) ?? true;

      // Registra el listener global del ciclo de vida para sincronizar
      // segundo plano y destrucción limpia del motor nativo.
      _lifecycleListener ??= AppLifecycleListener(
        onStateChange: manejarCicloDeVida,
        onExitRequested: () async {
          await dispose();
          return AppExitResponse.exit;
        },
      );

      if (!_soloud.isInitialized) {
        await _soloud.init();
      }
      _inicializado = true;

      // Precargamos los 3 assets en memoria — quedan listos para
      // reproducirse instantáneamente sin recargar el archivo.
      final fuentes = await Future.wait([
        _soloud.loadAsset('assets/sounds/click.mp3'),
        _soloud.loadAsset('assets/sounds/victory.mp3'),
        _soloud.loadAsset('assets/sounds/background_music.mp3'),
      ]);
      _fuenteClick = fuentes[0];
      _fuenteVictoria = fuentes[1];
      _fuenteMusica = fuentes[2];
    } catch (e) {
      debugPrint('Error inicializando SoundService: $e');
    }
  }

  /// Reproduce el click. SoLoud crea una nueva "voz" (instancia de
  /// reproducción) cada vez sin recargar el archivo ni bloquear el
  /// hilo principal — soporta clicks tan rápidos como el usuario tapee.
  static void reproducirClick() {
    if (!sonidoActivado || !_inicializado || _fuenteClick == null) return;
    if (!_soloud.isInitialized) return;
    try {
      _soloud.play(_fuenteClick!, volume: 0.6);
    } catch (e) {
      debugPrint('Error reproduciendo click: $e');
    }
  }

  static void reproducirVictoria() {
    if (!sonidoActivado || !_inicializado || _fuenteVictoria == null) return;
    if (!_soloud.isInitialized) return;
    try {
      _soloud.play(_fuenteVictoria!, volume: 0.8);
    } catch (e) {
      debugPrint('Error reproduciendo victoria: $e');
    }
  }

  static Future<void> iniciarMusica() async {
    if (!musicaActivada || !_inicializado || _fuenteMusica == null) return;
    if (!_soloud.isInitialized) return;
    try {
      // Si ya hay una instancia válida, la reanudamos en vez de abrir otra
      // encima. "Iniciar" siempre deja la música sonando (por ejemplo al
      // entrar al juego, donde la del menú quedó pausada).
      if (_handleMusica != null &&
          _soloud.getIsValidVoiceHandle(_handleMusica!)) {
        _soloud.setPause(_handleMusica!, false);
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
          _soloud.isInitialized &&
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
          _soloud.isInitialized &&
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
      if (_handleMusica != null && _soloud.isInitialized) {
        await _soloud.stop(_handleMusica!);
        _handleMusica = null;
      }
    } catch (e) {
      debugPrint('Error al detener música: $e');
    }
  }

  /// Libera los recursos nativos del motor SoLoud y detiene todos los hilos
  /// de audio de fondo (miniaudio). Crítico para evitar que llamadas FFI
  /// pendientes aterricen sobre trampolines destruidos al terminar la app.
  static Future<void> dispose() async {
    try {
      if (_soloud.isInitialized) {
        await _soloud.deinitAsync();
      }
    } catch (e) {
      debugPrint('Error cerrando SoLoud: $e');
    } finally {
      _fuenteClick = null;
      _fuenteVictoria = null;
      _fuenteMusica = null;
      _handleMusica = null;
      _inicializado = false;
      _pausadoPorCicloDeVida = false;
    }
  }

  static void manejarCicloDeVida(AppLifecycleState estado) {
    if (estado == AppLifecycleState.paused ||
        estado == AppLifecycleState.inactive ||
        estado == AppLifecycleState.hidden) {
      if (musicaActivada &&
          _handleMusica != null &&
          _soloud.isInitialized &&
          _soloud.getIsValidVoiceHandle(_handleMusica!)) {
        pausarMusica();
        _pausadoPorCicloDeVida = true;
      }
    } else if (estado == AppLifecycleState.detached) {
      // El motor de la app se está destruyendo: liberar recursos nativos y
      // detener worker threads de miniaudio para evitar que SoLoud dispare callbacks
      // FFI hacia trampolines ya liberados (crash DLRT_GetFfiCallbackMetadata / SIGABRT).
      try {
        if (_soloud.isInitialized) {
          _soloud.deinit();
        }
      } catch (e) {
        debugPrint('Error en deinit sincrónico de SoLoud: $e');
      } finally {
        _fuenteClick = null;
        _fuenteVictoria = null;
        _fuenteMusica = null;
        _handleMusica = null;
        _inicializado = false;
        _pausadoPorCicloDeVida = false;
      }
    } else if (estado == AppLifecycleState.resumed) {
      if (!_inicializado || !_soloud.isInitialized) {
        inicializar().then((_) {
          if (musicaActivada) iniciarMusica();
        });
      } else if (_pausadoPorCicloDeVida) {
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
