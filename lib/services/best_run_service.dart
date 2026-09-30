import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_service.dart';

/// La mejor marca del jugador en **un** tablero.
class MejorPartida {
  const MejorPartida({
    required this.tiempoSegundos,
    required this.movimientos,
    required this.tamano,
    required this.fecha,
  });

  final int tiempoSegundos;
  final int movimientos;

  /// Lado del tablero en el que se logró la marca (3, 4 o 5).
  final int tamano;

  final DateTime fecha;

  /// `true` si esta marca mejora a [otra], que es **del mismo tablero**.
  ///
  /// El orden es el del Top 5 —menos movimientos y, en empate, menos tiempo—
  /// (ver `PuntajeGlobal.compareTo`), para que la tarjeta y la pantalla de
  /// récords no puedan contradecirse.
  ///
  /// Antes acá se comparaba por tiempo primero. El motivo era que la tarjeta
  /// enfrentaba tableros de distinto tamaño, y ahí cualquier criterio absoluto
  /// favorece al más chico —un 3×3 se resuelve en menos movimientos *y* en menos
  /// tiempo que un 5×5, siempre—. Ahora que la tarjeta muestra el récord de un
  /// solo tablero, ese motivo desapareció y conviene alinearse con el ranking.
  bool esMejorQue(MejorPartida otra) {
    if (movimientos != otra.movimientos) return movimientos < otra.movimientos;
    return tiempoSegundos < otra.tiempoSegundos;
  }

  Map<String, dynamic> toJson() => {
        'tiempoSegundos': tiempoSegundos,
        'movimientos': movimientos,
        'tamano': tamano,
        'fecha': fecha.toIso8601String(),
      };

  /// Devuelve `null` si falta algún campo o está corrupto.
  ///
  /// El llamador trata eso como "todavía no hay récord", que es preferible a
  /// romper el menú por un dato que se puede volver a generar jugando.
  static MejorPartida? fromJson(Map<String, dynamic> json) {
    final tiempo = json['tiempoSegundos'];
    final movimientos = json['movimientos'];
    final tamano = json['tamano'];
    if (tiempo is! int || movimientos is! int || tamano is! int) return null;

    return MejorPartida(
      tiempoSegundos: tiempo,
      movimientos: movimientos,
      tamano: tamano,
      fecha: DateTime.tryParse(json['fecha'] as String? ?? '') ?? DateTime(0),
    );
  }
}

/// Todo lo que el servicio guarda: la mejor marca de cada tablero y cuál fue el
/// último que se completó.
class RecordsPersonales {
  const RecordsPersonales({
    this.porTablero = const {},
    this.ultimoTamano,
  });

  /// Mejor marca por lado de tablero.
  final Map<int, MejorPartida> porTablero;

  /// El último tablero que el jugador **completó** en modo libre.
  final int? ultimoTamano;

  /// La marca que muestra la tarjeta del menú: la del último tablero completado.
  ///
  /// Es `null` mientras no haya completado ninguna partida.
  MejorPartida? get vigente {
    final tamano = ultimoTamano;
    return tamano == null ? null : porTablero[tamano];
  }

  Map<String, dynamic> toJson() => {
        'ultimoTamano': ultimoTamano,
        'porTablero': {
          for (final entrada in porTablero.entries)
            entrada.key.toString(): entrada.value.toJson(),
        },
      };

  /// Tolerante a propósito: una entrada ilegible se descarta sola en vez de
  /// tirar abajo las demás.
  static RecordsPersonales fromJson(Map<String, dynamic> json) {
    final crudo = json['porTablero'];
    final porTablero = <int, MejorPartida>{};

    if (crudo is Map) {
      for (final entrada in crudo.entries) {
        final tamano = int.tryParse('${entrada.key}');
        final valor = entrada.value;
        if (tamano == null || valor is! Map) continue;

        final marca = MejorPartida.fromJson(Map<String, dynamic>.from(valor));
        // La marca tiene que ser del tablero en el que está indexada: si no,
        // la tarjeta mostraría un récord bajo el tamaño equivocado.
        if (marca != null && marca.tamano == tamano) {
          porTablero[tamano] = marca;
        }
      }
    }

    final ultimo = json['ultimoTamano'];
    return RecordsPersonales(
      porTablero: porTablero,
      // Si el último tablero apunta a una marca que se descartó, se ignora: la
      // tarjeta caerá al estado vacío en vez de mostrar un dato a medias.
      ultimoTamano: ultimo is int && porTablero.containsKey(ultimo)
          ? ultimo
          : null,
    );
  }
}

/// Récord personal de partida libre que muestra el menú.
///
/// El historial de partidas libres vive en Firestore (Top 5 por tablero), pero
/// esta tarjeta necesita un dato **instantáneo y sin red**: es lo primero que se
/// ve al abrir la app, y hacerla esperar un round-trip dejaría el menú con un
/// hueco o con un spinner en cada arranque.
///
/// Por eso las marcas se cachean en disco al ganar y la tarjeta se dibuja
/// siempre desde ahí. [refrescarDesdeFirestore] es un extra best-effort.
///
/// **La tarjeta muestra el récord del último tablero completado, no el mejor
/// entre todos.** Si mostrara el mejor absoluto, el 3×3 ganaría siempre —se
/// resuelve en menos movimientos y en menos tiempo que cualquier tablero más
/// grande—, y el jugador que juega 5×5 nunca vería reflejado su esfuerzo. Con el
/// tablero como referencia, la marca que se muestra es una que el jugador puede
/// efectivamente intentar romper.
class BestRunService {
  static const String _clave = 'records_personales';

  static Future<RecordsPersonales> _leer() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_clave);
    if (raw == null) return const RecordsPersonales();

    try {
      return RecordsPersonales.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      // JSON corrupto: se ignora y se vuelve a empezar, igual que hace
      // `RecordsService.obtenerEstrellas` con las estrellas del Desafío.
      return const RecordsPersonales();
    }
  }

  static Future<void> _escribir(RecordsPersonales records) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_clave, jsonEncode(records.toJson()));
  }

  /// La marca que muestra la tarjeta, o `null` si no completó ninguna partida.
  static Future<MejorPartida?> obtenerVigente() async =>
      (await _leer()).vigente;

  /// Registra una partida libre terminada.
  ///
  /// Corre en el camino caliente de la victoria: nunca lanza.
  ///
  /// El tablero de [partida] pasa a ser el vigente **siempre**, aunque su marca
  /// sea peor que la del tablero anterior: lo que el jugador acaba de completar
  /// es lo que quiere ver. La marca en sí solo se reemplaza si mejora a la que
  /// ya había para ese mismo tablero.
  static Future<void> registrarPartida(MejorPartida partida) async {
    final actual = await _leer();
    final previa = actual.porTablero[partida.tamano];

    final mejora = previa == null || partida.esMejorQue(previa);
    // Nada que escribir: mismo tablero vigente y la marca no mejoró.
    if (!mejora && actual.ultimoTamano == partida.tamano) return;

    final porTablero = Map<int, MejorPartida>.from(actual.porTablero);
    if (mejora) porTablero[partida.tamano] = partida;

    await _escribir(
      RecordsPersonales(
        porTablero: porTablero,
        ultimoTamano: partida.tamano,
      ),
    );
  }

  /// Intenta mejorar la marca del tablero vigente con lo que haya en Firestore.
  ///
  /// **Es best-effort, y conviene saber por qué no es la fuente de verdad.** La
  /// sesión es anónima, así que cada instalación tiene su propio uid: el único
  /// caso en que esto recupera algo es que el caché local se haya perdido con el
  /// uid intacto. En el uso normal, la marca local —que se reescribe en cada
  /// victoria— ya es más completa que lo que Firestore puede contar.
  ///
  /// Se consulta **solo el tablero vigente**, no los tres: es el único que la
  /// tarjeta muestra, y así esto sigue siendo una sola lectura.
  ///
  /// Devuelve la marca vigente resultante, o `null` si no hay ninguna.
  static Future<MejorPartida?> refrescarDesdeFirestore() async {
    final actual = await _leer();
    final tamano = actual.ultimoTamano;
    if (tamano == null) return null;

    final remoto = await FirebaseService.obtenerMejorPropio(tamano);
    final previa = actual.porTablero[tamano];
    if (remoto == null || previa == null) return previa;

    final candidata = MejorPartida(
      tiempoSegundos: remoto.tiempoSegundos,
      movimientos: remoto.movimientos,
      tamano: tamano,
      fecha: remoto.fecha,
    );
    if (!candidata.esMejorQue(previa)) return previa;

    final porTablero = Map<int, MejorPartida>.from(actual.porTablero)
      ..[tamano] = candidata;
    await _escribir(
      RecordsPersonales(porTablero: porTablero, ultimoTamano: tamano),
    );
    return candidata;
  }
}
