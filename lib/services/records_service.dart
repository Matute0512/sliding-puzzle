import 'package:shared_preferences/shared_preferences.dart';
import 'package:sliding_puzzle/models/record_game.dart';

/// Servicio para guardar y leer el historial de récords locales.
///
/// Almacena hasta [_maxRecords] partidas por dificultad,
/// ordenadas por tiempo ascendente.
class RecordsService {
  static const int _maxRecords = 5;
  static const String _prefijo = 'historial_records_';

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
}
