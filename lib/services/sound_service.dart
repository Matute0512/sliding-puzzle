import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SoundService {
  static const String _claveSonido = 'sonido_activado';
  static const String _claveMusica = 'musica_activada';

  static final AudioPlayer _musica = AudioPlayer();

  static bool sonidoActivado = true;
  static bool musicaActivada = true;
  static bool _pausadoPorCicloDeVida = false;

  static Future<void> inicializar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      sonidoActivado = prefs.getBool(_claveSonido) ?? true;
      musicaActivada = prefs.getBool(_claveMusica) ?? true;

      await _musica.setReleaseMode(ReleaseMode.loop);
      await _musica.setVolume(0.35);
      // Configuramos el AudioContext para que no interrumpa otros sonidos
      await _musica.setAudioContext(
        AudioContext(
          android: AudioContextAndroid(
            audioFocus: AndroidAudioFocus.gainTransientMayDuck,
            usageType: AndroidUsageType.game,
            contentType: AndroidContentType.music,
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error inicializando SoundService: $e');
    }
  }

  static void reproducirClick() {
    if (!sonidoActivado) return;
    unawaited(_reproducirEfecto('sounds/click.mp3', 0.6));
  }

  static void reproducirVictoria() {
    if (!sonidoActivado) return;
    unawaited(_reproducirEfecto('sounds/victory.mp3', 0.8));
  }

  static Future<void> _reproducirEfecto(String asset, double volumen) async {
    AudioPlayer? player;
    try {
      player = AudioPlayer();
      await player.setAudioContext(
        AudioContext(
          android: AudioContextAndroid(
            // gainTransientMayDuck: baja la música levemente en lugar
            // de cortar el foco completamente (evita la cascada AUDIOFOCUS_LOSS)
            audioFocus: AndroidAudioFocus.gainTransientMayDuck,
            usageType: AndroidUsageType.game,
            contentType: AndroidContentType.sonification,
          ),
        ),
      );
      await player.setPlayerMode(PlayerMode.lowLatency);
      await player.setVolume(volumen);
      await player.play(AssetSource(asset));
      await player.onPlayerComplete.first;
    } catch (e) {
      debugPrint('Error en efecto ($asset): $e');
    } finally {
      await player?.dispose();
    }
  }

  static Future<void> iniciarMusica() async {
    if (!musicaActivada) return;
    try {
      await _musica.play(AssetSource('sounds/background_music.mp3'));
    } catch (e) {
      debugPrint('Error al iniciar música: $e');
    }
  }

  static Future<void> pausarMusica() async {
    try {
      if (_musica.state == PlayerState.playing) {
        await _musica.pause();
      }
    } catch (e) {
      debugPrint('Error al pausar música: $e');
    }
  }

  static Future<void> reanudarMusica() async {
    if (!musicaActivada) return;
    try {
      if (_musica.state == PlayerState.paused) {
        await _musica.resume();
      }
    } catch (e) {
      debugPrint('Error al reanudar música: $e');
    }
  }

  static Future<void> detenerMusica() async {
    try {
      await _musica.stop();
    } catch (e) {
      debugPrint('Error al detener música: $e');
    }
  }

  static void manejarCicloDeVida(AppLifecycleState estado) {
    if (estado == AppLifecycleState.paused ||
        estado == AppLifecycleState.inactive) {
      if (musicaActivada && _musica.state == PlayerState.playing) {
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
