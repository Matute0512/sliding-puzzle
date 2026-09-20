import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../logic/puzzle_logic.dart';

/// Resultado del Desafío Diario de un día concreto.
///
/// Se guarda en disco junto al candado porque el botón "Compartir" necesita el
/// tiempo y los movimientos del jugador, y el ranking de Firestore es de solo
/// lectura desde la app (no se consulta "mi puntaje" para no gastar una lectura
/// más). El dato es local y de un solo día: no hay historial.
class ResultadoDiario {
  /// Semilla (YYYYMMDD) del día jugado.
  final int semilla;
  final int movimientos;
  final int segundos;

  const ResultadoDiario({
    required this.semilla,
    required this.movimientos,
    required this.segundos,
  });

  Map<String, dynamic> toJson() => {
        'semilla': semilla,
        'movimientos': movimientos,
        'segundos': segundos,
      };

  static ResultadoDiario? fromJson(Map<String, dynamic> json) {
    final semilla = json['semilla'];
    final movimientos = json['movimientos'];
    final segundos = json['segundos'];
    if (semilla is! int || movimientos is! int || segundos is! int) return null;
    return ResultadoDiario(
      semilla: semilla,
      movimientos: movimientos,
      segundos: segundos,
    );
  }
}

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

  /// Último resultado guardado (JSON con semilla, movimientos y segundos).
  static const String _claveResultado = 'desafio_diario_resultado';

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

  /// Foto de respaldo, empaquetada en la app.
  ///
  /// Se usa cuando la foto del día no se puede traer: sin internet, si todavía
  /// no se subió la del día, o si Storage rechaza la lectura. El tablero nunca
  /// queda vacío ni crashea por una foto que falta.
  static const AssetImage imagenRespaldo = AssetImage(
    'assets/images/pexels-toni-clavel-62572784-38947608.jpg',
  );

  /// Ruta de la foto del día dentro del bucket de Cloud Storage.
  ///
  /// `daily/YYYYMMDD.jpg`. La fecha como nombre hace que subir la del día sea
  /// simplemente dejar un archivo con el nombre correcto: no hay índice que
  /// mantener ni configuración que tocar.
  static String rutaImagen(int semilla) => 'daily/$semilla.jpg';

  /// Imagen del tablero del día, lista para pasarle a `PuzzleBoard`.
  ///
  /// Resuelve la URL de descarga con el SDK de Storage (en vez de armar la URL
  /// a mano) porque así funciona sin depender de que las reglas permitan
  /// lectura anónima: el SDK manda el token de la sesión.
  ///
  /// **Nunca lanza y nunca devuelve `null`.** Si algo falla devuelve
  /// [imagenRespaldo], que es justo lo que se quiere: un día sin foto subida no
  /// puede dejar el desafío injugable.
  ///
  /// Ojo: que esto resuelva no garantiza que la imagen después *cargue*. Si la
  /// descarga falla, el `errorBuilder` de `ImageTile` vuelve a caer en
  /// [imagenRespaldo]. Los dos caminos están cubiertos a propósito.
  static Future<ImageProvider> imagenDe(int semilla) async {
    try {
      final url = await FirebaseStorage.instance
          .ref(rutaImagen(semilla))
          .getDownloadURL();
      return CachedNetworkImageProvider(url);
    } catch (e) {
      debugPrint(
        'Desafío Diario: no se pudo resolver la foto del día $semilla '
        '($e). Se usa la de respaldo.',
      );
      return imagenRespaldo;
    }
  }

  /// `true` si el jugador ya completó el desafío del día de [ahora].
  static Future<bool> yaJugoHoy({DateTime? ahora}) async {
    final prefs = await SharedPreferences.getInstance();
    final ultimo = prefs.getInt(_claveUltimoDia);
    return ultimo != null && ultimo == semillaDe(ahora ?? DateTime.now());
  }

  /// Marca como completado el desafío de [semilla].
  ///
  /// Recibe la semilla en vez de leer el reloj a propósito: quien jugó sabe qué
  /// día jugó. Si alguien arranca a las 23:59 UTC y termina después de la
  /// medianoche, lo que consumió es el desafío del día en que **empezó**, y
  /// marcar el día nuevo le regalaría el de hoy sin haberlo visto.
  static Future<void> marcarJugado(int semilla) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_claveUltimoDia, semilla);
  }

  /// Marca el desafío del día de [ahora] como completado.
  ///
  /// Se llama al resolver el tablero. Guardar la fecha (y no un booleano) es lo
  /// que hace que el candado se renueve solo: mañana la comparación da distinto
  /// sin que nadie tenga que limpiar nada.
  static Future<void> marcarJugadoHoy({DateTime? ahora}) =>
      marcarJugado(semillaDe(ahora ?? DateTime.now()));

  /// Guarda el resultado del jugador para el día [semilla].
  ///
  /// Reemplaza el anterior: solo interesa el último día jugado.
  static Future<void> guardarResultado(ResultadoDiario resultado) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_claveResultado, jsonEncode(resultado.toJson()));
  }

  /// Resultado del jugador en el día [semilla], o `null` si no hay ninguno
  /// guardado o si el guardado es de otro día.
  static Future<ResultadoDiario?> resultadoDe(int semilla) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_claveResultado);
    if (raw == null) return null;

    try {
      final json = jsonDecode(raw);
      if (json is! Map<String, dynamic>) return null;
      final resultado = ResultadoDiario.fromJson(json);
      // Un resultado de otro día no sirve para compartir el de hoy.
      return resultado?.semilla == semilla ? resultado : null;
    } catch (_) {
      // Datos corruptos: se ignoran.
      return null;
    }
  }

  /// Borra el candado y el resultado guardado. Pensado para tests y para un
  /// futuro "reiniciar progreso" desde Ajustes; la app no lo usa en el flujo
  /// normal.
  static Future<void> reiniciar() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_claveUltimoDia);
    await prefs.remove(_claveResultado);
  }
}
