import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:sliding_puzzle/logic/puzzle_logic.dart';

/// Partida en curso guardada localmente, para poder retomarla desde el menú.
///
/// El tiempo se guarda como segundos ya acumulados: al retomar, el cronómetro
/// de `GameScreen` vuelve a arrancar de cero y suma este valor como
/// desplazamiento, porque un `Stopwatch` no puede iniciarse en un valor
/// distinto de cero.
class PartidaGuardada {
  /// `true` si la partida pertenece al Modo Desafío.
  final bool esDesafio;

  /// Tamaño del tablero: 3, 4 o 5.
  final int size;

  /// Nivel del Modo Desafío (1 a 20). `null` en las partidas libres.
  final int? nivel;

  /// Fichas en su posición actual, incluido el hueco (0).
  final List<int> tablero;

  final int movimientos;

  /// Segundos ya jugados antes de guardar.
  final int segundos;

  const PartidaGuardada({
    required this.esDesafio,
    required this.size,
    required this.nivel,
    required this.tablero,
    required this.movimientos,
    required this.segundos,
  });

  Map<String, dynamic> toJson() => {
    'es_desafio': esDesafio,
    'size': size,
    'nivel': nivel,
    'tablero': tablero,
    'movimientos': movimientos,
    'segundos': segundos,
  };

  /// Reconstruye una partida desde JSON, o `null` si los datos no son válidos.
  ///
  /// La validación es estricta a propósito: SharedPreferences es persistencia
  /// sin esquema, y un tablero corrupto (fichas de más, de menos o repetidas)
  /// rompería el juego al tocar "Continuar". Ante la duda, se descarta.
  static PartidaGuardada? desdeJson(Map<String, dynamic> json) {
    final size = json['size'];
    final esDesafio = json['es_desafio'];
    final nivel = json['nivel'];
    final movimientos = json['movimientos'];
    final segundos = json['segundos'];
    final tableroCrudo = json['tablero'];

    if (size is! int || size < 2 || size > 8) return null;
    if (esDesafio is! bool) return null;
    if (movimientos is! int || movimientos < 0) return null;
    if (segundos is! int || segundos < 0) return null;
    if (tableroCrudo is! List) return null;

    final tablero = tableroCrudo.whereType<int>().toList();
    if (tablero.length != size * size) return null;
    // Debe ser exactamente la permutación 0..size²-1: si falta o sobra una
    // ficha, o hay repetidas, el tablero no es jugable.
    final ordenado = List<int>.from(tablero)..sort();
    for (var i = 0; i < ordenado.length; i++) {
      if (ordenado[i] != i) return null;
    }

    final int? nivelValido;
    if (esDesafio) {
      if (nivel is! int || nivel < 1 || nivel > 20) return null;
      // El tablero debe ser del tamaño que le corresponde a ese nivel.
      if (PuzzleLogic.configuracionNivel(nivel).size != size) return null;
      nivelValido = nivel;
    } else {
      if (nivel != null) return null;
      nivelValido = null;
    }

    return PartidaGuardada(
      esDesafio: esDesafio,
      size: size,
      nivel: nivelValido,
      tablero: tablero,
      movimientos: movimientos,
      segundos: segundos,
    );
  }
}

/// Persistencia local de la partida en curso (un único slot).
///
/// Guarda el estado mínimo para retomar donde quedó: modo, nivel, tablero,
/// movimientos y segundos. Se escribe al pausar y al salir con el botón Atrás,
/// y se borra al ganar, al reiniciar y al empezar una partida nueva.
class SavedGameService {
  static const String _clave = 'partida_guardada';

  /// Guarda (o reemplaza) la partida en curso.
  static Future<void> guardar(PartidaGuardada partida) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_clave, jsonEncode(partida.toJson()));
  }

  /// Devuelve la partida guardada, o `null` si no hay ninguna.
  ///
  /// Si el contenido está corrupto se descarta y se borra la clave: así no
  /// queda un registro inválido que nadie puede leer ni limpiar.
  static Future<PartidaGuardada?> obtener() async {
    final prefs = await SharedPreferences.getInstance();
    final crudo = prefs.getString(_clave);
    if (crudo == null) return null;

    PartidaGuardada? partida;
    try {
      final json = jsonDecode(crudo);
      if (json is Map<String, dynamic>) {
        partida = PartidaGuardada.desdeJson(json);
      }
    } catch (_) {
      partida = null;
    }

    if (partida == null) await prefs.remove(_clave);
    return partida;
  }

  /// Elimina la partida guardada.
  static Future<void> borrar() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_clave);
  }
}
