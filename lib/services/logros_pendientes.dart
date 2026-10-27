import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Cola persistente de logros de Google Play Games pendientes de envío.
///
/// Un logro se encola en cuanto el jugador cumple la condición y se quita solo
/// cuando Play Games confirma el desbloqueo. Así no se pierde si la victoria
/// ocurre sin sesión iniciada, sin red o si el usuario cerró el popup de
/// inicio de sesión: se reintenta en el próximo arranque o victoria.
///
/// No depende del plugin de Play Games (recibe el envío como callback), por lo
/// que se puede testear con `SharedPreferences.setMockInitialValues`.
class LogrosPendientes {
  LogrosPendientes._();

  /// Clave de `SharedPreferences` con la lista de IDs pendientes.
  @visibleForTesting
  static const String clave = 'play_games_logros_pendientes';

  /// Devuelve los IDs pendientes, en orden de llegada y sin duplicados.
  static Future<List<String>> leer() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(clave) ?? const [];
  }

  /// Agrega [id] a la cola si no estaba. Ignora IDs vacíos.
  static Future<void> encolar(String id) async {
    final limpio = id.trim();
    if (limpio.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final actuales = prefs.getStringList(clave) ?? const [];
    if (actuales.contains(limpio)) return;
    await prefs.setStringList(clave, [...actuales, limpio]);
  }

  /// Intenta enviar cada logro pendiente con [enviar] y quita de la cola solo
  /// los que se enviaron sin error. Devuelve la cantidad enviada con éxito.
  ///
  /// Nunca lanza: un fallo en un logro no corta el envío de los demás.
  static Future<int> sincronizar(Future<void> Function(String id) enviar) async {
    final pendientes = await leer();
    if (pendientes.isEmpty) return 0;

    final enviados = <String>{};
    for (final id in pendientes) {
      try {
        await enviar(id);
        enviados.add(id);
      } catch (e) {
        debugPrint('PlayGames: logro $id queda pendiente: $e');
      }
    }

    if (enviados.isNotEmpty) {
      // Se relee la cola por si se encolaron logros nuevos durante el envío.
      final prefs = await SharedPreferences.getInstance();
      final actuales = prefs.getStringList(clave) ?? const [];
      await prefs.setStringList(
        clave,
        actuales.where((id) => !enviados.contains(id)).toList(),
      );
    }
    return enviados.length;
  }
}

