import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart'; // Import esencial para AppLifecycleState
import 'package:shared_preferences/shared_preferences.dart';

/// Servicio centralizado para efectos de sonido y música de fondo.
///
/// Mantiene un AudioPlayer dedicado para la música y genera canales efímeros
/// para los efectos cortos, garantizando reproducción simultánea.
class SoundService {
  static const String _claveSonido = 'sonido_activado';
  static const String _claveMusica = 'musica_activada';

  // Solo mantenemos el de la música de forma persistente.
  static final AudioPlayer _musica = AudioPlayer();

  static bool sonidoActivado = true;
  static bool musicaActivada = true;

  // Flag interno para saber si pausamos la música al minimizar la app.
  static bool _pausadoPorCicloDeVida = false;

  /// Carga preferencias de usuario y configura la música de fondo.
  /// Llamar una sola vez antes de runApp().
  static Future<void> inicializar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      sonidoActivado = prefs.getBool(_claveSonido) ?? true;
      musicaActivada = prefs.getBool(_claveMusica) ?? true;

      // Configuración base para el loop continuo del fondo
      await _musica.setReleaseMode(ReleaseMode.loop);
      await _musica.setVolume(0.35);
    } catch (e) {
      debugPrint('Error inicializando SoundService: $e');
    }
  }

  /// Helper genérico: Instancia un canal independiente en baja latencia,
  /// lo reproduce y destruye su objeto en memoria al finalizar el clip.
  static Future<void> _reproducirEfectoCorto(
    String rutaAsset,
    double volumen,
  ) async {
    if (!sonidoActivado) return;

    AudioPlayer? reproductorTemporal;
    try {
      reproductorTemporal = AudioPlayer();
      await reproductorTemporal.setPlayerMode(PlayerMode.lowLatency);
      await reproductorTemporal.setVolume(volumen);

      // Escuchamos cuando el audio termine para liberar la memoria inmediatamente
      reproductorTemporal.onPlayerComplete.listen((_) {
        reproductorTemporal?.dispose();
      });

      await reproductorTemporal.play(AssetSource(rutaAsset));
    } catch (e) {
      debugPrint('Error reproduciendo efecto ($rutaAsset): $e');
      // Limpieza preventiva si el hilo nativo falla
      reproductorTemporal?.dispose();
    }
  }

  /// Reproduce el sonido de click al mover una ficha de forma independiente.
  static Future<void> reproducirClick() async {
    await _reproducirEfectoCorto('sounds/click.mp3', 0.6);
  }

  /// Reproduce el sonido de victoria de forma independiente.
  static Future<void> reproducirVictoria() async {
    await _reproducirEfectoCorto('sounds/victory.mp3', 0.8);
  }

  /// Inicia o reanuda la música de fondo en loop de forma segura.
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
      await _musica.pause();
    } catch (e) {
      debugPrint('Error al pausar música: $e');
    }
  }

  static Future<void> reanudarMusica() async {
    if (!musicaActivada) return;
    try {
      await _musica.resume();
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

  /// Maneja los cambios de estado de la aplicación (minimizar/maximizar).
  /// Debes llamarlo desde el AppLifecycleListener de tu widget principal.
  static void manejarCicloDeVida(AppLifecycleState estado) {
    if (estado == AppLifecycleState.paused ||
        estado == AppLifecycleState.inactive) {
      // Si la app se va a segundo plano y la música estaba sonando, la pausamos
      if (musicaActivada && _musica.state == PlayerState.playing) {
        pausarMusica();
        _pausadoPorCicloDeVida = true;
      }
    } else if (estado == AppLifecycleState.resumed) {
      // Si el usuario regresa y nosotros habíamos pausado la música, la reanudamos
      if (_pausadoPorCicloDeVida) {
        reanudarMusica();
        _pausadoPorCicloDeVida = false;
      }
    }
  }

  /// Alterna sonido (clicks + victoria) y guarda la preferencia.
  static Future<void> alternarSonido() async {
    sonidoActivado = !sonidoActivado;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_claveSonido, sonidoActivado);
  }

  /// Alterna la música de fondo y guarda la preferencia.
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
