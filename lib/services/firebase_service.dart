import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show debugPrint;

/// Un puntaje del Top 5 Global (partidas libres).
///
/// Se guarda un documento por usuario por tamaño (doc id = uid anónimo), por
/// eso [id] coincide con el uid y no puede haber spam de un mismo jugador.
class PuntajeGlobal {
  final String? id;
  final String alias;
  final int movimientos;
  final int tiempoSegundos;
  final DateTime fecha;

  const PuntajeGlobal({
    this.id,
    required this.alias,
    required this.movimientos,
    required this.tiempoSegundos,
    required this.fecha,
  });

  /// Orden: primero menos movimientos; en empate, menos tiempo.
  int compareTo(PuntajeGlobal otro) {
    final porMovimientos = movimientos.compareTo(otro.movimientos);
    if (porMovimientos != 0) return porMovimientos;
    return tiempoSegundos.compareTo(otro.tiempoSegundos);
  }

  bool esMejorQue(PuntajeGlobal otro) => compareTo(otro) < 0;

  factory PuntajeGlobal.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const <String, dynamic>{};
    return PuntajeGlobal(
      id: doc.id,
      alias: (data['alias'] as String?) ?? '???',
      movimientos: (data['movimientos'] as num?)?.toInt() ?? 0,
      tiempoSegundos: (data['tiempoSegundos'] as num?)?.toInt() ?? 0,
      fecha: (data['fecha'] as Timestamp?)?.toDate() ?? DateTime(0),
    );
  }
}

/// Acceso al Top 5 Global de partidas libres en Firestore.
///
/// Colecciones: `leaderboard_3x3`, `leaderboard_4x4`, `leaderboard_5x5`.
/// Cada documento representa un puntaje de un usuario anónimo.
class FirebaseService {
  static const int _limiteConsulta = 200;

  static String nombreColeccion(int size) => 'leaderboard_${size}x$size';

  /// Devuelve el Top 5 (ordenado: menos movimientos, luego menos tiempo).
  ///
  /// No captura errores a propósito: el llamador (pantalla de récords) decide
  /// cómo mostrar el estado de error. Devuelve vacío si no hay puntajes.
  static Future<List<PuntajeGlobal>> obtenerTop(int size) async {
    final snap = await FirebaseFirestore.instance
        .collection(nombreColeccion(size))
        .limit(_limiteConsulta)
        .get();

    final lista = snap.docs.map(PuntajeGlobal.fromDocument).toList()
      ..sort((a, b) => a.compareTo(b));
    return lista.take(5).toList();
  }

  /// Registra la partida libre en Firestore **solo si entra al Top 5** del
  /// tamaño indicado. Un documento por usuario (doc id = uid anónimo), con
  /// `set` merge: conserva la mejor marca del jugador.
  ///
  /// Devuelve el puesto obtenido (1..5) o `null` si no clasificó o si la
  /// operación falló (offline / sin sesión). Nunca lanza: la experiencia
  /// offline no se interrumpe.
  static Future<int?> registrarSiClasifica({
    required int size,
    required String alias,
    required int movimientos,
    required int tiempoSegundos,
  }) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return null;

      final coleccion =
          FirebaseFirestore.instance.collection(nombreColeccion(size));

      // Leemos el estado actual (hasta 200 jugadores) para decidir en cliente.
      final snap = await coleccion.limit(_limiteConsulta).get();
      final actuales = snap.docs.map(PuntajeGlobal.fromDocument).toList()
        ..sort((a, b) => a.compareTo(b));

      // Puntaje previo de ESTE usuario (doc id = uid), si existe.
      PuntajeGlobal? propio;
      for (final p in actuales) {
        if (p.id == uid) {
          propio = p;
          break;
        }
      }

      final candidato = PuntajeGlobal(
        id: uid,
        alias: alias,
        movimientos: movimientos,
        tiempoSegundos: tiempoSegundos,
        fecha: DateTime.now(),
      );

      // No se degrada la propia marca: si el usuario ya tiene un puntaje mejor
      // o igual, no escribimos nada.
      if (propio != null && !candidato.esMejorQue(propio)) return null;

      // Entra al Top 5 si hay lugar o si supera al 5º actual.
      final peor = actuales.length >= 5 ? actuales[4] : null;
      final entra =
          actuales.length < 5 || (peor != null && candidato.esMejorQue(peor));
      if (!entra) return null;

      await coleccion.doc(uid).set(
        {
          'alias': alias,
          'movimientos': movimientos,
          'tiempoSegundos': tiempoSegundos,
          'fecha': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      return posicionEnTop(actuales, candidato);
    } catch (e) {
      // Sin red, sin sesión o error de reglas: se ignora silenciosamente.
      debugPrint('No se pudo registrar el puntaje global: $e');
      return null;
    }
  }

  /// Consulta el puesto que ocuparía (1..5) la partida actual del usuario en
  /// el Top 5 de [size], **sin escribir nada**. Descuenta un eventual puntaje
  /// previo del mismo usuario (doc id = uid).
  ///
  /// Devuelve `null` si no clasifica, si no hay sesión o si falla la red
  /// (nunca lanza).
  static Future<int?> posicionActualPuntaje({
    required int size,
    required int movimientos,
    required int tiempoSegundos,
  }) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return null;
      final top = await obtenerTop(size);
      return posicionEnTop(
        top,
        PuntajeGlobal(
          id: uid,
          alias: '',
          movimientos: movimientos,
          tiempoSegundos: tiempoSegundos,
          fecha: DateTime.now(),
        ),
      );
    } catch (_) {
      return null;
    }
  }

  /// Devuelve la posición (1..5) que ocuparía [candidato] dentro de [actuales]
  /// (ya ordenados asc), descartando un eventual documento previo del mismo id.
  /// `null` si no entra al Top 5.
  ///
  /// Función pura: se puede testear sin Firestore.
  static int? posicionEnTop(
    List<PuntajeGlobal> actuales,
    PuntajeGlobal candidato,
  ) {
    // Se descarta únicamente el documento previo del mismo id (si el candidato
    // tiene id). Las entradas sin id (tests / externas) se conservan siempre.
    final sinElMismo =
        actuales.where((p) => p.id == null || p.id != candidato.id).toList();
    final peor = sinElMismo.length >= 5 ? sinElMismo[4] : null;
    if (peor != null && !candidato.esMejorQue(peor)) return null;

    final todos = [...sinElMismo, candidato]
      ..sort((a, b) => a.compareTo(b));
    return todos.indexWhere((p) => identical(p, candidato)) + 1;
  }
}
