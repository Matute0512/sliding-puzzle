import 'dart:convert';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../logic/puzzle_logic.dart';

/// Estado actual de la Racha Diaria del jugador.
class EstadoRachaDiaria {
  /// Días consecutivos vigentes (jugó hoy o ayer). Vale `0` si nunca jugó o
  /// si pasó más de 1 día sin jugar.
  final int rachaActual;

  /// Mayor cantidad de días consecutivos alcanzada históricamente.
  final int mejorRacha;

  /// Racha acumulada que puede rescatarse hoy con el Escudo Protector cuando
  /// el jugador salteó exactamente 1 día (jugó anteayer pero no ayer).
  /// Vale `0` cuando no hay racha en riesgo.
  final int rachaSalvable;

  const EstadoRachaDiaria({
    required this.rachaActual,
    required this.mejorRacha,
    this.rachaSalvable = 0,
  });

  /// `true` cuando el jugador faltó ayer pero puede reparar su racha hoy.
  bool get enRiesgo => rachaSalvable > 0;
}

/// Resultado del Desafío Diario de un día concreto.
///
/// Se guarda en disco junto al candado porque el botón "Compartir" necesita el
/// tiempo, los movimientos y la racha del jugador, y el ranking de Firestore es
/// de solo lectura desde la app (no se consulta "mi puntaje" para no gastar una
/// lectura más). El dato es local y de un solo día: no hay historial.
class ResultadoDiario {
  /// Semilla (YYYYMMDD) del día jugado.
  final int semilla;
  final int movimientos;
  final int segundos;

  /// Días consecutivos de racha alcanzados al completar este desafío.
  final int racha;

  const ResultadoDiario({
    required this.semilla,
    required this.movimientos,
    required this.segundos,
    this.racha = 1,
  });

  Map<String, dynamic> toJson() => {
    'semilla': semilla,
    'movimientos': movimientos,
    'segundos': segundos,
    'racha': racha,
  };

  static ResultadoDiario? fromJson(Map<String, dynamic> json) {
    final semilla = json['semilla'];
    final movimientos = json['movimientos'];
    final segundos = json['segundos'];
    final racha = json['racha'];
    if (semilla is! int || movimientos is! int || segundos is! int) return null;
    return ResultadoDiario(
      semilla: semilla,
      movimientos: movimientos,
      segundos: segundos,
      racha: racha is int && racha > 0 ? racha : 1,
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
/// Los métodos que dependen de "ahora" —[yaJugoHoy], [marcarJugadoHoy]— aceptan
/// un [DateTime] opcional y, sin él, leen [reloj]. Es lo que permite testear el
/// cruce de medianoche sin tocar el reloj del sistema ni esperar.
///
/// [reloj] existe porque los getters sin parámetros ([semillaHoy], [tableroHoy])
/// no tienen dónde recibir un [DateTime], y son justamente los que usa la UI.
/// Los tests lo reemplazan para hacer que "hoy" sea el día que les conviene:
/// sin esa costura, el cruce de medianoche al volver del segundo plano no se
/// podría ejercitar desde un widget test.
class DailyChallengeService {
  DailyChallengeService._();

  /// Fecha (YYYYMMDD) del último día que el jugador completó.
  static const String _claveUltimoDia = 'desafio_diario_ultimo_dia';

  /// Racha de días consecutivos acumulada hasta `_claveUltimoDia`.
  static const String _claveRachaActual = 'desafio_diario_racha_actual';

  /// Mejor racha histórica de días consecutivos.
  static const String _claveMejorRacha = 'desafio_diario_mejor_racha';

  /// Último resultado guardado (JSON con semilla, movimientos, segundos y racha).
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

  /// Reconstruye la fecha UTC (`00:00:00Z`) correspondiente a una [semilla] `YYYYMMDD`.
  static DateTime fechaDeSemilla(int semilla) {
    final year = semilla ~/ 10000;
    final month = (semilla % 10000) ~/ 100;
    final day = semilla % 100;
    return DateTime.utc(year, month, day);
  }

  /// Calcula la cantidad exacta de días calendario UTC entre [semillaAnterior]
  /// y [semillaPosterior].
  static int diasEntreSemillas(int semillaAnterior, int semillaPosterior) {
    final inicio = fechaDeSemilla(semillaAnterior);
    final fin = fechaDeSemilla(semillaPosterior);
    return fin.difference(inicio).inDays;
  }

  /// Reloj del que sale "hoy" cuando no se pasa uno explícito.
  ///
  /// Es `DateTime.now` en producción. Los tests lo reemplazan para poder cruzar
  /// la medianoche UTC sin tocar el reloj de la máquina ni esperar: es la única
  /// forma de ejercitar la recarga del desafío al volver del segundo plano.
  /// Los métodos que ya aceptan un `DateTime` opcional no lo miran — ese
  /// parámetro sigue mandando.
  @visibleForTesting
  static DateTime Function() reloj = DateTime.now;

  /// Semilla del día de hoy (UTC).
  static int get semillaHoy => semillaDe(reloj());

  /// Tablero del Desafío Diario para el día de [ahora] (hoy si se omite).
  ///
  /// No toca el disco: el tablero se deriva de la fecha, así que dos
  /// dispositivos cualesquiera obtienen el mismo sin sincronizar nada.
  static List<int> tableroDe(DateTime ahora) =>
      PuzzleLogic.generarTableroDiario(semillaDe(ahora));

  /// Tablero del Desafío Diario de hoy.
  static List<int> tableroHoy() => tableroDe(reloj());

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
  /// `daily/YYYYMMDD.webp`. La fecha como nombre hace que subir la del día sea
  /// simplemente dejar un archivo con el nombre correcto: no hay índice que
  /// mantener ni configuración que tocar.
  ///
  /// La extensión es `.webp` porque es la que produce el script que optimiza las
  /// fotos antes de subirlas. Tiene que coincidir **exactamente**: Storage no
  /// negocia formatos ni redirige, así que un desajuste acá no falla al resolver
  /// la URL —`getDownloadURL()` anda igual— sino que devuelve
  /// `object-not-found` y manda el tablero al respaldo. Fue justo lo que pasó
  /// con `.jpg`.
  static String rutaImagen(int semilla) => 'daily/$semilla.webp';

  /// Clave de caché de la foto del día.
  ///
  /// Lleva la **semilla adelante** para que la relación "un día, una foto" quede
  /// explícita: ninguna imagen puede servirse desde el caché de otro día, ni
  /// siquiera si Storage llegara a devolver la misma URL para dos fechas
  /// distintas (un CDN o un proxy por delante bastarían para que pasara).
  ///
  /// Lleva **también la URL** porque el token de Storage cambia cuando se
  /// reemplaza el archivo, y quedarse solo con la semilla rompería esa
  /// actualización de una forma difícil de ver: `CachedNetworkImageProvider`
  /// define su igualdad como `cacheKey ?? url` (ver
  /// `cached_network_image_provider.dart`), así que con la clave fija en la
  /// semilla dos providers de la misma fecha pero distinto contenido serían
  /// **iguales**, y el `Image` ni siquiera volvería a pedir la imagen: seguiría
  /// mostrando la vieja desde el `ImageCache` en memoria.
  static String claveCacheImagen(int semilla, String url) =>
      'daily-$semilla-$url';

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
      // Se decodifica a un máximo de 1024 px de lado (~340 dp a DPR 3) para no
      // subir a GPU una textura a resolución nativa de cámara. `ResizeImage`
      // compone su clave sobre la del `CachedNetworkImageProvider`, así que
      // `claveCacheImagen(semilla, url)` sigue gobernando el caché.
      return ResizeImage(
        CachedNetworkImageProvider(
          url,
          cacheKey: claveCacheImagen(semilla, url),
        ),
        width: 1024,
        policy: ResizeImagePolicy.fit,
      );
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
    return ultimo != null && ultimo == semillaDe(ahora ?? reloj());
  }

  /// Lee la racha guardada manteniendo retrocompatibilidad con `v25` (donde
  /// solo se guardaba `_claveUltimoDia` sin `_claveRachaActual`).
  static int _leerRachaGuardada(SharedPreferences prefs, int? ultimoDia) {
    if (ultimoDia == null) return 0;
    final guardada = prefs.getInt(_claveRachaActual);
    if (guardada != null && guardada > 0) return guardada;
    return 1;
  }

  /// Consulta el estado de la racha diaria para el día de [ahora] (o [reloj]).
  static Future<EstadoRachaDiaria> estadoRacha({DateTime? ahora}) async {
    final prefs = await SharedPreferences.getInstance();
    final ultimoDia = prefs.getInt(_claveUltimoDia);
    final rachaGuardada = _leerRachaGuardada(prefs, ultimoDia);
    final mejorGuardada = math.max(
      prefs.getInt(_claveMejorRacha) ?? 0,
      rachaGuardada,
    );

    if (ultimoDia == null) {
      return EstadoRachaDiaria(rachaActual: 0, mejorRacha: mejorGuardada);
    }

    final hoy = semillaDe(ahora ?? reloj());
    final dias = diasEntreSemillas(ultimoDia, hoy);

    if (dias == 0 || dias == 1) {
      return EstadoRachaDiaria(
        rachaActual: rachaGuardada,
        mejorRacha: mejorGuardada,
      );
    }

    if (dias == 2) {
      return EstadoRachaDiaria(
        rachaActual: 0,
        mejorRacha: mejorGuardada,
        rachaSalvable: rachaGuardada,
      );
    }

    return EstadoRachaDiaria(rachaActual: 0, mejorRacha: mejorGuardada);
  }

  /// Repara una racha en riesgo (cuando el jugador faltó exactamente 1 día, ayer)
  /// puenteando `_claveUltimoDia` al día de ayer para que la racha continúe
  /// intacta. Devuelve `true` si la racha estaba en riesgo y fue reparada.
  static Future<bool> repararRacha({DateTime? ahora}) async {
    final prefs = await SharedPreferences.getInstance();
    final ultimoDia = prefs.getInt(_claveUltimoDia);
    if (ultimoDia == null) return false;

    final fechaHoy = fechaDeSemilla(semillaDe(ahora ?? reloj()));
    final hoy = semillaDe(fechaHoy);
    final dias = diasEntreSemillas(ultimoDia, hoy);
    if (dias != 2) return false;

    final rachaGuardada = _leerRachaGuardada(prefs, ultimoDia);
    final semillaAyer = semillaDe(fechaHoy.subtract(const Duration(days: 1)));

    await prefs.setInt(_claveUltimoDia, semillaAyer);
    await prefs.setInt(_claveRachaActual, rachaGuardada);
    return true;
  }

  /// Marca como completado el desafío de [semilla] y actualiza la racha diaria.
  ///
  /// Recibe la semilla en vez de leer el reloj a propósito: quien jugó sabe qué
  /// día jugó. Si alguien arranca a las 23:59 UTC y termina después de la
  /// medianoche, lo que consumió es el desafío del día en que **empezó**, y
  /// marcar el día nuevo le regalaría el de hoy sin haberlo visto.
  ///
  /// Devuelve la racha actualizada tras registrar la victoria.
  static Future<int> marcarJugado(int semilla) async {
    final prefs = await SharedPreferences.getInstance();
    final ultimoDia = prefs.getInt(_claveUltimoDia);
    final rachaPrevia = _leerRachaGuardada(prefs, ultimoDia);
    final mejorPrevia = math.max(
      prefs.getInt(_claveMejorRacha) ?? 0,
      rachaPrevia,
    );

    int nuevaRacha;
    if (ultimoDia == null) {
      nuevaRacha = 1;
    } else {
      final dias = diasEntreSemillas(ultimoDia, semilla);
      if (dias == 0) {
        nuevaRacha = rachaPrevia;
      } else if (dias == 1) {
        nuevaRacha = rachaPrevia + 1;
      } else {
        nuevaRacha = 1;
      }
    }

    final nuevaMejor = math.max(mejorPrevia, nuevaRacha);
    await prefs.setInt(_claveUltimoDia, semilla);
    await prefs.setInt(_claveRachaActual, nuevaRacha);
    await prefs.setInt(_claveMejorRacha, nuevaMejor);
    return nuevaRacha;
  }

  /// Marca el desafío del día de [ahora] como completado.
  ///
  /// Se llama al resolver el tablero. Guardar la fecha (y no un booleano) es lo
  /// que hace que el candado se renueve solo: mañana la comparación da distinto
  /// sin que nadie tenga que limpiar nada.
  static Future<int> marcarJugadoHoy({DateTime? ahora}) =>
      marcarJugado(semillaDe(ahora ?? reloj()));

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

  /// Borra el candado, la racha y el resultado guardado. Pensado para tests y
  /// para un futuro "reiniciar progreso" desde Ajustes; la app no lo usa en el
  /// flujo normal.
  static Future<void> reiniciar() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_claveUltimoDia);
    await prefs.remove(_claveRachaActual);
    await prefs.remove(_claveMejorRacha);
    await prefs.remove(_claveResultado);
  }
}
