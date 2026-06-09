import 'package:shared_preferences/shared_preferences.dart';

/// Servicio para guardar y leer récords locales por dificultad.
class RecordsService {
  static Future<int?> obtenerMejorTiempo(int size) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('record_tiempo_$size');
  }

  static Future<int?> obtenerMejorMovimientos(int size) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('record_movimientos_$size');
  }

  static Future<bool> guardarSiEsMejor({
    required int size,
    required int tiempo,
    required int movimientos,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    bool nuevoPrecord = false;

    final mejorTiempo = prefs.getInt('record_tiempo_$size');
    if (mejorTiempo == null || tiempo < mejorTiempo) {
      await prefs.setInt('record_tiempo_$size', tiempo);
      nuevoPrecord = true;
    }

    final mejorMovimientos = prefs.getInt('record_movimientos_$size');
    if (mejorMovimientos == null || movimientos < mejorMovimientos) {
      await prefs.setInt('record_movimientos_$size', movimientos);
      nuevoPrecord = true;
    }

    return nuevoPrecord;
  }
}
