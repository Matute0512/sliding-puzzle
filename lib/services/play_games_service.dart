import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:games_services/games_services.dart';

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

  static bool _autenticado = false;
  static bool _autenticando = false;

  /// Indica si el sistema actual soporta Google Play Games Services.
  /// Solo activo en dispositivos Android nativos en ejecución real (no web ni tests).
  static bool get _esPlataformaSoportada =>
      !kIsWeb &&
      defaultTargetPlatform == TargetPlatform.android &&
      !Platform.environment.containsKey('FLUTTER_TEST');

  /// Inicia sesión de manera silenciosa en Google Play Games al arrancar la app.
  ///
  /// Si el usuario ya está logueado en el dispositivo, Play Games mostrará el
  /// saludo nativo en pantalla ("Conectado como..."). Si falla o no hay red,
  /// falla de forma silenciosa sin interrumpir la experiencia.
  static Future<void> iniciarSesionSilenciosa() async {
    if (!_esPlataformaSoportada || _autenticado || _autenticando) return;

    _autenticando = true;
    try {
      final resultado = await GameAuth.signIn();
      _autenticado = resultado != null;
      debugPrint('PlayGames: inicio de sesión completado (auth: $_autenticado)');
    } catch (e) {
      debugPrint('PlayGames: inicio de sesión no disponible o cancelado: $e');
    } finally {
      _autenticando = false;
    }
  }

  /// Desbloquea un logro por su ID alfanumérico en Google Play Games.
  static Future<void> desbloquearLogro(String androidId) async {
    if (!_esPlataformaSoportada || androidId.trim().isEmpty) return;

    try {
      if (!_autenticado) {
        await iniciarSesionSilenciosa();
      }
      final respuesta = await Achievements.unlock(
        achievement: Achievement(androidID: androidId),
      );
      debugPrint('PlayGames: logro $androidId desbloqueado: $respuesta');
    } catch (e) {
      debugPrint('PlayGames: error al desbloquear logro $androidId: $e');
    }
  }

  /// Abre la interfaz visual nativa de logros de Google Play Games.
  static Future<void> mostrarLogros() async {
    if (!_esPlataformaSoportada) return;

    try {
      if (!_autenticado) {
        await iniciarSesionSilenciosa();
      }
      await Achievements.showAchievements();
    } catch (e) {
      debugPrint('PlayGames: no se pudo abrir la pantalla de logros: $e');
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

    // 1. Primer desliz: Resuelve tu primer tablero 3x3
    if (size == 3 && _logroPrimerDesliz.isNotEmpty) {
      unawaited(desbloquearLogro(_logroPrimerDesliz));
    }

    // 2. Desafío superado: Resuelve un Desafío Diario por primera vez
    if (esDiario && _logroDesafioSuperado.isNotEmpty) {
      unawaited(desbloquearLogro(_logroDesafioSuperado));
    }

    // 3. Mente ágil: Resuelve un tablero 4x4 en menos de 3 minutos (< 180s)
    if (size == 4 && segundos < 180 && _logroMenteAgil.isNotEmpty) {
      unawaited(desbloquearLogro(_logroMenteAgil));
    }

    // 4. Perfeccionista: Consigue 3 estrellas en cualquier nivel
    if (estrellas != null && estrellas >= 3 && _logroPerfeccionista.isNotEmpty) {
      unawaited(desbloquearLogro(_logroPerfeccionista));
    }

    // 5. Gran Maestro: Resuelve un tablero 5x5
    if (size == 5 && _logroGranMaestro.isNotEmpty) {
      unawaited(desbloquearLogro(_logroGranMaestro));
    }
  }
}

