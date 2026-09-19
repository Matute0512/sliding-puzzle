import 'package:shared_preferences/shared_preferences.dart';

import '../logic/puzzle_logic.dart';

/// Motor del Desafío Diario: un tablero por día, igual para todo el mundo, con
/// un solo intento.
///
/// ## Por qué UTC y no hora local
///
/// La semilla sale de la fecha **UTC**, no de la local. Con fecha local, un
/// jugador en Nueva Zelanda estaría resolviendo el tablero del día siguiente
/// mientras en México siguen con el de hoy: el ranking del día compararía
/// tableros distintos y dejaría de tener sentido. UTC es lo que hace que "el
/// desafío de hoy" sea *el mismo* para todos.
///
/// El costo es que el día cambia a una hora incómoda según la región (en
/// Argentina, a las 21:00). Es el precio de que el tablero sea compartido.
///
/// ## El candado
///
/// Se guarda la fecha (YYYYMMDD) del último día completado. No hace falta
/// ningún job que "resetee" nada: alcanza con comparar contra la fecha de hoy,
/// así que el candado se destraba solo al cruzar la medianoche UTC, incluso si
/// la app estuvo cerrada semanas.
///
/// ## Reloj inyectable
///
/// Todos los métodos que dependen de "ahora" aceptan un [DateTime] opcional.
/// Sin él usan `DateTime.now()`. Es lo que permite testear el cruce de medianoche
/// sin tocar el reloj del sistema ni esperar.
class DailyChallengeService {
  DailyChallengeService._();

  /// Fecha (YYYYMMDD) del último día que el jugador completó.
  static const String _claveUltimoDia = 'desafio_diario_ultimo_dia';

  /// Convierte un instante a la fecha UTC en formato `YYYYMMDD`.
  ///
  /// Es una función pura: no lee el reloj ni el disco. Todo lo demás se apoya
  /// en ella, así que es donde conviene mirar si algo no cuadra.
  ///
  /// ```dart
  /// semillaDe(DateTime.utc(2026, 9, 19)) // 20260919
  /// ```
  static int semillaDe(DateTime ahora) {
    final utc = ahora.toUtc();
    // year * 10000 + month * 100 + day deja los dígitos alineados, así que el
    // número ordena igual que la fecha: 20260919 < 20260920. Eso hace que
    // comparar semillas sea comparar días.
    return utc.year * 10000 + utc.month * 100 + utc.day;
  }

  /// Semilla del día de hoy (UTC).
  static int get semillaHoy => semillaDe(DateTime.now());

  /// Tablero del Desafío Diario para el día de [ahora] (hoy si se omite).
  ///
  /// No toca el disco: el tablero se deriva de la fecha, así que dos
  /// dispositivos cualesquiera obtienen el mismo sin sincronizar nada.
  static List<int> tableroDe(DateTime ahora) =>
      PuzzleLogic.generarTableroDiario(semillaDe(ahora));

  /// Tablero del Desafío Diario de hoy.
  static List<int> tableroHoy() => tableroDe(DateTime.now());

  /// `true` si el jugador ya completó el desafío del día de [ahora].
  static Future<bool> yaJugoHoy({DateTime? ahora}) async {
    final prefs = await SharedPreferences.getInstance();
    final ultimo = prefs.getInt(_claveUltimoDia);
    return ultimo != null && ultimo == semillaDe(ahora ?? DateTime.now());
  }

  /// Marca el desafío del día de [ahora] como completado.
  ///
  /// Se llama al resolver el tablero. Guardar la fecha (y no un booleano) es lo
  /// que hace que el candado se renueve solo: mañana la comparación da distinto
  /// sin que nadie tenga que limpiar nada.
  static Future<void> marcarJugadoHoy({DateTime? ahora}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_claveUltimoDia, semillaDe(ahora ?? DateTime.now()));
  }

  /// Borra el candado. Pensado para tests y para un futuro "reiniciar progreso"
  /// desde Ajustes; la app no lo usa en el flujo normal.
  static Future<void> reiniciar() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_claveUltimoDia);
  }
}
