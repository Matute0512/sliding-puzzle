import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:games_services/games_services.dart';

import 'logros_pendientes.dart';

/// Servicio centralizado de integración con **Google Play Games Services**.
///
/// ## Seguridad de IDs
/// Los IDs de logros y de proyecto **no** se versionan en Git: se inyectan en
/// tiempo de compilación mediante `--dart-define-from-file=dart_defines.json`
/// (ignorado en `.gitignore`) o desde GitHub Secrets en CI.
///
/// ## Resiliencia Offline
/// Todas las llamadas capturan errores y excepciones de forma silenciosa para
/// que el juego siga siendo 100% disfrutable offline o si el usuario no tiene
/// configurada una cuenta de Google Play Games.
///
/// ## Logros pendientes
/// Cada logro conseguido se guarda primero en [LogrosPendientes] y se envía
/// cuando hay sesión. Si la victoria ocurre sin sesión o sin red, el logro se
/// entrega en el próximo arranque o victoria en lugar de perderse.
///
/// ## Sin interrupciones
/// El popup de inicio de sesión se intenta **una sola vez** al arrancar. Si el
/// usuario lo cierra o falla, no se vuelve a mostrar durante las partidas: solo
/// el botón "Logros" ([mostrarLogros]) lo pide de nuevo de forma explícita.
class PlayGamesService {
  PlayGamesService._();

  // ─────────────────────────────────────────────────────────────────────
  // IDs de Logros inyectados por --dart-define-from-file=dart_defines.json
  // ─────────────────────────────────────────────────────────────────────

  static const String _logroPrimerDesliz = String.fromEnvironment(
    'ACHIEVEMENT_PRIMER_DESLIZ',
  );
  static const String _logroDesafioSuperado = String.fromEnvironment(
    'ACHIEVEMENT_DESAFIO_SUPERADO',
  );
  static const String _logroMenteAgil = String.fromEnvironment(
    'ACHIEVEMENT_MENTE_AGIL',
  );
  static const String _logroPerfeccionista = String.fromEnvironment(
    'ACHIEVEMENT_PERFECCIONISTA',
  );
  static const String _logroGranMaestro = String.fromEnvironment(
    'ACHIEVEMENT_GRAN_MAESTRO',
  );

  /// Tiempo máximo para consultar el estado de sesión al plugin.
  static const Duration _timeoutEstadoSesion = Duration(seconds: 5);

  static bool _autenticado = false;
  static bool _autenticando = false;

  /// `true` si el inicio de sesión automático ya falló o fue cancelado en esta
  /// ejecución: evita volver a abrir el popup en cada victoria.
  static bool _intentoAutomaticoHecho = false;

  static bool _sincronizando = false;
  static bool _resincronizar = false;
  static bool _avisoConfiguracionMostrado = false;

  /// Indica si el sistema actual soporta Google Play Games Services.
  /// Solo activo en dispositivos Android nativos en ejecución real (no web ni tests).
  static bool get _esPlataformaSoportada {
    if (kIsWeb) return false;
    if (defaultTargetPlatform != TargetPlatform.android) return false;
    try {
      if (Platform.environment.containsKey('FLUTTER_TEST')) return false;
    } catch (_) {
      // Platform.environment no está soportado en Android y lanza UnsupportedError.
    }
    return true;
  }

  /// `true` si el build trae los IDs de logros. Si faltan (por ejemplo, un
  /// secret de CI desactualizado), avisa una vez por log en lugar de fallar
  /// en silencio.
  static bool get _configurado {
    final completo = [
      _logroPrimerDesliz,
      _logroDesafioSuperado,
      _logroMenteAgil,
      _logroPerfeccionista,
      _logroGranMaestro,
    ].every((id) => id.isNotEmpty);
    if (!completo && !_avisoConfiguracionMostrado) {
      _avisoConfiguracionMostrado = true;
      debugPrint(
        'PlayGames: faltan IDs de logros en dart_defines '
        '(ACHIEVEMENT_*). Los logros no se enviarán en este build.',
      );
    }
    return completo;
  }

  /// Inicia sesión de manera silenciosa en Google Play Games al arrancar la app.
  ///
  /// Si el usuario ya está logueado en el dispositivo, Play Games mostrará el
  /// saludo nativo en pantalla ("Conectado como..."). Si falla o no hay red,
  /// falla de forma silenciosa sin interrumpir la experiencia.
  ///
  /// Primero consulta si Play Games ya autenticó al jugador (auto-login de
  /// Play Games v2). Solo si no, intenta un único `signIn()`. Al terminar,
  /// envía los logros pendientes.
  static Future<void> iniciarSesionSilenciosa() async {
    if (!_esPlataformaSoportada) {
      debugPrint('PlayGames: plataforma no soportada para signIn.');
      return;
    }
    _configurado; // Solo para dejar el aviso en el log si faltan IDs.

    if (!_autenticado && !_intentoAutomaticoHecho) {
      _intentoAutomaticoHecho = true;
      if (await _consultarSesion()) {
        _autenticado = true;
        debugPrint('PlayGames: sesión existente detectada.');
      } else {
        debugPrint(
          'PlayGames: no hay sesión activa previa. Se mantiene modo local/invitado.',
        );
      }
    }
    await _sincronizarPendientes();
  }

  /// Desbloquea un logro por su ID alfanumérico en Google Play Games.
  ///
  /// El logro se guarda en la cola de pendientes y se envía si hay sesión; si
  /// no la hay, queda guardado para el próximo intento. Nunca abre el popup
  /// de inicio de sesión.
  static Future<void> desbloquearLogro(String androidId) async {
    if (!_esPlataformaSoportada) {
      debugPrint('PlayGames: plataforma no soportada para desbloquearLogro.');
      return;
    }
    if (androidId.trim().isEmpty) {
      debugPrint('PlayGames: ID de logro vacío, omitiendo.');
      return;
    }

    try {
      debugPrint(
        'PlayGames: encolando logro $androidId (autenticado: $_autenticado)',
      );
      await LogrosPendientes.encolar(androidId);
      await _sincronizarPendientes();
    } catch (e, stack) {
      debugPrint(
        'PlayGames: error al desbloquear logro $androidId: $e\n$stack',
      );
    }
  }

  /// Abre la interfaz visual nativa de logros de Google Play Games.
  ///
  /// Es la única acción que vuelve a pedir el inicio de sesión de forma
  /// explícita si el automático falló o fue cancelado.
  static Future<void> mostrarLogros() async {
    if (!_esPlataformaSoportada) {
      debugPrint('PlayGames: plataforma no soportada para mostrarLogros.');
      return;
    }

    try {
      debugPrint(
        'PlayGames: abriendo vista de logros (autenticado: $_autenticado)...',
      );
      if (!_autenticado) {
        await _iniciarSesionInteractiva();
      }
      if (!_autenticado) return;
      await _sincronizarPendientes();
      final res = await Achievements.showAchievements();
      debugPrint('PlayGames: showAchievements() retorno: $res');
    } catch (e, stack) {
      debugPrint(
        'PlayGames: no se pudo abrir la pantalla de logros: $e\n$stack',
      );
    }
  }

  /// Evalúa las condiciones de la partida ganada y dispara los logros correspondientes.
  ///
  /// - [size]: Tamaño del tablero (3, 4 o 5).
  /// - [segundos]: Tiempo total empleado en segundos.
  /// - [esDiario]: `true` si la victoria corresponde al Desafío Diario.
  /// - [estrellas]: Estrellas obtenidas en el Modo Desafío (1 a 3), si aplica.
  static void verificarLogrosVictoria({
    required int size,
    required int segundos,
    bool esDiario = false,
    int? estrellas,
  }) {
    if (!_esPlataformaSoportada) return;
    if (!_configurado) return;

    debugPrint(
      'PlayGames: evaluando victoria: size=$size, s=$segundos, diario=$esDiario, estrellas=$estrellas',
    );

    unawaited(
      _encolarYSincronizar(
        logrosParaVictoria(
          size: size,
          segundos: segundos,
          esDiario: esDiario,
          estrellas: estrellas,
        ),
      ),
    );
  }

  /// Devuelve los IDs de logros que corresponden a una victoria. Es pura (sin
  /// plataforma) para poder testear las condiciones.
  @visibleForTesting
  static List<String> logrosParaVictoria({
    required int size,
    required int segundos,
    bool esDiario = false,
    int? estrellas,
  }) {
    return [
      // 1. Primer desliz: Resuelve tu primer tablero 3x3
      if (size == 3) _logroPrimerDesliz,

      // 2. Desafío superado: Resuelve un Desafío Diario por primera vez
      if (esDiario) _logroDesafioSuperado,

      // 3. Mente ágil: Resuelve un tablero 4x4 en menos de 3 minutos (< 180s)
      if (size == 4 && segundos < 180) _logroMenteAgil,

      // 4. Perfeccionista: Consigue 3 estrellas en cualquier nivel
      if (estrellas != null && estrellas >= 3) _logroPerfeccionista,

      // 5. Gran Maestro: Resuelve un tablero 5x5
      if (size == 5) _logroGranMaestro,
    ].where((id) => id.isNotEmpty).toList();
  }

  // ─────────────────────────────────────────────────────────────────────
  // Internos
  // ─────────────────────────────────────────────────────────────────────

  /// Encola los logros de forma secuencial y luego sincroniza una sola vez.
  static Future<void> _encolarYSincronizar(List<String> ids) async {
    if (ids.isEmpty) return;
    try {
      for (final id in ids) {
        await LogrosPendientes.encolar(id);
      }
      await _sincronizarPendientes();
    } catch (e, stack) {
      debugPrint('PlayGames: error al encolar logros: $e\n$stack');
    }
  }

  /// Consulta al plugin si hay un jugador autenticado, con timeout para no
  /// quedar colgado si el stream no emite.
  static Future<bool> _consultarSesion() async {
    try {
      return await GameAuth.isSignedIn.timeout(
        _timeoutEstadoSesion,
        onTimeout: () => false,
      );
    } catch (e) {
      debugPrint('PlayGames: no se pudo consultar la sesión: $e');
      return false;
    }
  }

  /// Llama a `GameAuth.signIn()` (puede mostrar el popup de Play Games).
  static Future<void> _iniciarSesionInteractiva() async {
    if (_autenticando) {
      debugPrint('PlayGames: autenticación en progreso...');
      return;
    }
    _autenticando = true;
    try {
      debugPrint('PlayGames: llamando a GameAuth.signIn()...');
      final resultado = await GameAuth.signIn();
      _autenticado = resultado != null;
      debugPrint(
        'PlayGames: GameAuth.signIn() retorno: "$resultado" (autenticado: $_autenticado)',
      );
    } catch (e, stack) {
      _autenticado = false;
      debugPrint('PlayGames: error en GameAuth.signIn(): $e\n$stack');
    } finally {
      _autenticando = false;
    }
  }

  /// Envía los logros pendientes si hay sesión. Nunca abre el popup y nunca
  /// lanza. Si ya hay una sincronización en curso, la repite al terminar.
  static Future<void> _sincronizarPendientes() async {
    if (!_autenticado) return;
    if (_sincronizando) {
      _resincronizar = true;
      return;
    }
    _sincronizando = true;
    try {
      do {
        _resincronizar = false;
        var primerEnvio = true;
        final enviados = await LogrosPendientes.sincronizar((id) async {
          if (!primerEnvio) {
            // Espaciado para evitar saturación del canal IPC nativo de Play Games
            // (evita el código 26502: CLIENT_RECONNECT_REQUIRED).
            await Future.delayed(const Duration(milliseconds: 250));
          }
          primerEnvio = false;

          try {
            final respuesta = await Achievements.unlock(
              achievement: Achievement(androidID: id),
            );
            debugPrint('PlayGames: logro $id respuesta: $respuesta');
          } on PlatformException catch (e) {
            final mensaje = e.message ?? '';
            if (e.code.contains('26502') || mensaje.contains('26502')) {
              debugPrint(
                'PlayGames: CLIENT_RECONNECT_REQUIRED en $id, reintentando tras espera...',
              );
              await Future.delayed(const Duration(milliseconds: 500));
              final reintento = await Achievements.unlock(
                achievement: Achievement(androidID: id),
              );
              debugPrint(
                'PlayGames: logro $id reintento respuesta: $reintento',
              );
              return;
            }
            rethrow;
          }
        });
        if (enviados > 0) {
          debugPrint('PlayGames: $enviados logro(s) pendiente(s) enviado(s).');
        }
      } while (_resincronizar);
    } catch (e, stack) {
      debugPrint('PlayGames: error al sincronizar logros: $e\n$stack');
    } finally {
      _sincronizando = false;
    }
  }
}
