import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:sliding_puzzle/logic/puzzle_logic.dart';

/// Servicio de persistencia local (SharedPreferences) para:
/// - Progreso del Modo Desafío (nivel desbloqueado + mejores estrellas).
/// - Alias del jugador (Top 5 Global).
/// - Aviso de calificación de la app.
///
/// El historial de récords de las partidas libres ya no se guarda en local:
/// pasó a un Top 5 Global en Firestore (ver `FirebaseService`).
class RecordsService {
  // Claves del formato viejo de récords — se limpian al migrar.
  static const List<String> _clavesViejas = [
    'record_tiempo_3',
    'record_tiempo_4',
    'record_tiempo_5',
    'record_movimientos_3',
    'record_movimientos_4',
    'record_movimientos_5',
  ];

  // Historial local de partidas libres (pre-Top 5 global) que ya no se usa.
  static const List<String> _clavesHistorialLibre = [
    'historial_records_3',
    'historial_records_4',
    'historial_records_5',
  ];

  // Claves del progreso del Modo Desafío.
  static const String _claveNivelMaximo = 'desafio_nivel_maximo';
  static const String _claveEstrellas = 'desafio_estrellas';

  // Clave del aviso de calificación en Google Play.
  static const String _claveAppCalificada = 'app_has_rated';

  // Clave del alias del jugador para el Top 5 Global.
  static const String _claveAlias = 'alias_usuario';

  /// Elimina datos de formatos anteriores que ya no se usan, incluidas las
  /// claves del historial local de partidas libres (sustituido por Firestore).
  static Future<void> limpiarDatosViejos() async {
    final prefs = await SharedPreferences.getInstance();
    for (final clave in [..._clavesViejas, ..._clavesHistorialLibre]) {
      await prefs.remove(clave);
    }
  }

  /// Devuelve el nivel más alto desbloqueado del Modo Desafío.
  /// Inicia en 1: el primer nivel siempre está disponible.
  static Future<int> obtenerNivelMaximo() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_claveNivelMaximo) ?? 1;
  }

  /// Devuelve las mejores estrellas obtenidas por nivel (nivel -> 1..3).
  /// Puede estar vacío si todavía no se completó ningún nivel.
  static Future<Map<int, int>> obtenerEstrellas() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_claveEstrellas);
    if (raw == null) return {};

    try {
      final datos = jsonDecode(raw) as Map<String, dynamic>;
      final estrellas = <int, int>{};
      for (final entrada in datos.entries) {
        final nivel = int.tryParse(entrada.key);
        final valor = entrada.value;
        if (nivel != null && valor is int && valor >= 1 && valor <= 3) {
          estrellas[nivel] = valor;
        }
      }
      return estrellas;
    } catch (_) {
      // Datos corruptos: se ignoran y se vuelve a empezar.
      return {};
    }
  }

  /// Registra la victoria de un nivel del Modo Desafío.
  ///
  /// Calcula las estrellas según [movimientos] y [objetivo], conserva la mejor
  /// marca por nivel y desbloquea el siguiente nivel (hasta el 20). Devuelve
  /// las estrellas obtenidas en esta partida.
  static Future<int> registrarVictoriaDesafio({
    required int nivel,
    required int movimientos,
    required int objetivo,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final estrellas = PuzzleLogic.estrellasPara(movimientos, objetivo);

    final mejores = await obtenerEstrellas();
    final anteriores = mejores[nivel] ?? 0;
    if (estrellas > anteriores) {
      mejores[nivel] = estrellas;
      await prefs.setString(
        _claveEstrellas,
        jsonEncode({
          for (final e in mejores.entries) e.key.toString(): e.value,
        }),
      );
    }

    final nivelMaximo = await obtenerNivelMaximo();
    final siguiente = nivel < 20 ? nivel + 1 : nivel;
    if (siguiente > nivelMaximo) {
      await prefs.setInt(_claveNivelMaximo, siguiente);
    }

    return estrellas;
  }

  /// Retorna si el usuario ya calificó la app en Google Play.
  /// `false` por defecto: todavía no se lo preguntamos.
  static Future<bool> yaCalificoApp() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_claveAppCalificada) ?? false;
  }

  /// Marca que el usuario ya calificó la app, para no volver a mostrar el aviso.
  static Future<void> marcarAppCalificada() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_claveAppCalificada, true);
  }

  /// Devuelve el alias guardado del jugador (ya normalizado, máx. 5 letras)
  /// o `null` si todavía no eligió uno.
  static Future<String?> obtenerAlias() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_claveAlias);
  }

  /// Guarda (o reemplaza) el alias del jugador.
  ///
  /// Normaliza el valor: recorta espacios y pasa a mayúsculas, limitando a
  /// 5 letras por seguridad (la UI ya restringe el largo del campo).
  static Future<void> guardarAlias(String alias) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_claveAlias, _normalizarAlias(alias));
  }

  static String _normalizarAlias(String alias) {
    final limpio = alias.trim().toUpperCase();
    return limpio.length <= 5 ? limpio : limpio.substring(0, 5);
  }
}
