import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:sliding_puzzle/logic/puzzle_logic.dart';
import 'package:sliding_puzzle/models/record_game.dart';

/// Servicio para guardar y leer el historial de récords locales.
///
/// Almacena hasta [_maxRecords] partidas por dificultad,
/// ordenadas por tiempo ascendente.
class RecordsService {
  static const int _maxRecords = 5;
  static const String _prefijo = 'historial_records_';

  // Claves del progreso del Modo Desafío.
  static const String _claveNivelMaximo = 'desafio_nivel_maximo';
  static const String _claveEstrellas = 'desafio_estrellas';

  // Claves del formato viejo — se limpian al migrar.
  static const List<String> _clavesViejas = [
    'record_tiempo_3',
    'record_tiempo_4',
    'record_tiempo_5',
    'record_movimientos_3',
    'record_movimientos_4',
    'record_movimientos_5',
  ];

  /// Elimina datos del formato anterior si existen.
  static Future<void> limpiarDatosViejos() async {
    final prefs = await SharedPreferences.getInstance();
    for (final clave in _clavesViejas) {
      await prefs.remove(clave);
    }
  }

  /// Devuelve el historial de partidas para una dificultad (puede ser vacío).
  static Future<List<RecordGame>> obtenerHistorial(int size) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_prefijo$size');
    if (raw == null) return [];
    try {
      return RecordGame.decodeList(raw);
    } catch (_) {
      return [];
    }
  }

  /// Guarda la partida en el historial y retorna si es el nuevo #1.
  static Future<bool> guardarPartida({
    required int size,
    required int tiempo,
    required int movimientos,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final historial = await obtenerHistorial(size);

    final nueva = RecordGame(tiempo: tiempo, movimientos: movimientos);

    // Verificamos si es récord #1 antes de insertar
    final esPrimerPuesto = historial.isEmpty || tiempo < historial.first.tiempo;

    historial.add(nueva);

    // Ordenamos por tiempo ascendente y recortamos al límite
    historial.sort((a, b) => a.tiempo.compareTo(b.tiempo));
    final top = historial.take(_maxRecords).toList();

    await prefs.setString('$_prefijo$size', RecordGame.encodeList(top));

    return esPrimerPuesto;
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
      // Datos corruptos: se ignoran y se vuelve a empezar, como en obtenerHistorial.
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
}
