import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show debugPrint;

/// Un puntaje del ranking del Desafío Diario.
///
/// Se guarda un documento por usuario por día (doc id = uid anónimo), así que
/// [id] coincide con el uid y no puede haber spam de un mismo jugador.
class PuntajeDiario {
  final String? id;
  final String alias;
  final int movimientos;
  final int tiempoSegundos;
  final DateTime fecha;

  const PuntajeDiario({
    this.id,
    required this.alias,
    required this.movimientos,
    required this.tiempoSegundos,
    required this.fecha,
  });

  /// Orden del diario: **menos tiempo primero**; en empate, menos movimientos.
  ///
  /// Al revés que el Top 5 clásico (que ordena por movimientos y después por
  /// tiempo), y es a propósito: acá el tablero es el mismo para todos, así que
  /// la cantidad de movimientos óptima es prácticamente la misma y lo que
  /// realmente distingue a los jugadores es la velocidad.
  int compareTo(PuntajeDiario otro) {
    final porTiempo = tiempoSegundos.compareTo(otro.tiempoSegundos);
    if (porTiempo != 0) return porTiempo;
    return movimientos.compareTo(otro.movimientos);
  }

  bool esMejorQue(PuntajeDiario otro) => compareTo(otro) < 0;

  factory PuntajeDiario.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const <String, dynamic>{};
    return PuntajeDiario(
      id: doc.id,
      alias: (data['alias'] as String?) ?? '???',
      movimientos: (data['movimientos'] as num?)?.toInt() ?? 0,
      tiempoSegundos: (data['tiempoSegundos'] as num?)?.toInt() ?? 0,
      fecha: (data['fecha'] as Timestamp?)?.toDate() ?? DateTime(0),
    );
  }
}

/// Acceso al ranking del Desafío Diario en Firestore.
///
/// Ruta: `daily_leaderboards/{semilla}/scores`, donde `semilla` es la fecha UTC
/// en formato YYYYMMDD (`20260919`). Un documento por participante.
///
/// Está **separado** de `FirebaseService` (el Top 5 de las partidas clásicas)
/// en las tres cosas que importan: la ruta, el orden de los puntajes, y el
/// hecho de que acá se escribe siempre. Mezclarlos en una sola colección
/// arruinaría las dos tablas.
///
/// La semilla se pasa **explícitamente** en cada llamada en vez de calcularse
/// acá adentro. Es deliberado: quien jugó sabe qué día jugó, y si la partida
/// empezó antes de la medianoche UTC y terminó después, la respuesta correcta
/// es el día en que se generó el tablero, no el día en que se terminó.
class DailyLeaderboardService {
  static const int _limiteConsulta = 200;

  static const String _coleccion = 'daily_leaderboards';
  static const String _subcoleccion = 'scores';

  /// `daily_leaderboards/{semilla}/scores`
  static CollectionReference<Map<String, dynamic>> _scores(int semilla) =>
      FirebaseFirestore.instance
          .collection(_coleccion)
          .doc('$semilla')
          .collection(_subcoleccion);

  /// Devuelve el Top 5 del día [semilla], ordenado por tiempo y luego
  /// movimientos.
  ///
  /// No captura errores a propósito: la pantalla de resultados decide cómo
  /// mostrar el estado de error. Devuelve vacío si todavía no jugó nadie.
  static Future<List<PuntajeDiario>> obtenerTopDia(int semilla) async {
    final snap = await _scores(semilla).limit(_limiteConsulta).get();

    final lista = snap.docs.map(PuntajeDiario.fromDocument).toList()
      ..sort((a, b) => a.compareTo(b));
    return lista.take(5).toList();
  }

  /// Registra el resultado del día [semilla].
  ///
  /// A diferencia del Top 5 clásico, **escribe siempre**: no filtra por si
  /// entra al Top 5. El diario es un evento colectivo y la tabla se arma con
  /// todos los que jugaron; filtrar dejaría afuera a la mayoría y el ranking
  /// del día no diría nada.
  ///
  /// Un documento por usuario (doc id = uid), con `set` merge: si el mismo uid
  /// vuelve a subir, conserva la mejor marca en vez de pisarla con una peor.
  ///
  /// Devuelve `true` si quedó registrado. Nunca lanza: sin red o sin sesión se
  /// pierde el registro del día, pero el juego no se interrumpe.
  static Future<bool> registrarPuntaje({
    required int semilla,
    required String alias,
    required int movimientos,
    required int tiempoSegundos,
  }) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return false;

      final candidato = PuntajeDiario(
        id: uid,
        alias: alias,
        movimientos: movimientos,
        tiempoSegundos: tiempoSegundos,
        fecha: DateTime.now(),
      );

      final doc = _scores(semilla).doc(uid);

      // Leer antes de escribir cuesta una lectura, pero evita que un reintento
      // con peor marca borre la buena. En el uso normal no puede pasar (el
      // candado es de un intento), pero el costo es bajo y la garantía es real.
      final previo = await doc.get();
      if (previo.exists && !candidato.esMejorQue(PuntajeDiario.fromDocument(previo))) {
        return true;
      }

      await doc.set(
        {
          'alias': alias,
          'movimientos': movimientos,
          'tiempoSegundos': tiempoSegundos,
          'fecha': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      return true;
    } catch (e) {
      // Sin red, sin sesión o error de reglas: se ignora silenciosamente.
      debugPrint('No se pudo registrar el puntaje diario: $e');
      return false;
    }
  }

  /// Posición (1..5) que ocuparía [candidato] dentro de [actuales] (ya
  /// ordenados asc), descartando un eventual documento previo del mismo id.
  /// `null` si no entra al Top 5.
  ///
  /// Función pura: se puede testear sin Firestore.
  static int? posicionEnTop(
    List<PuntajeDiario> actuales,
    PuntajeDiario candidato,
  ) {
    final sinElMismo = actuales
        .where((p) => p.id == null || p.id != candidato.id)
        .toList();
    final peor = sinElMismo.length >= 5 ? sinElMismo[4] : null;
    if (peor != null && !candidato.esMejorQue(peor)) return null;

    final todos = [...sinElMismo, candidato]
      ..sort((a, b) => a.compareTo(b));
    return todos.indexWhere((p) => identical(p, candidato)) + 1;
  }
}
