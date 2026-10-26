import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Servicio de gestión y persistencia local del saldo de monedas del jugador.
///
/// Las monedas se obtienen completando partidas (Modo Clásico, Modo Desafío y
/// Desafío Diario) y se consumen para deshacer movimientos en el tablero.
class CoinsService {
  static const String _claveSaldo = 'monedas_saldo';
  static const String _claveBienvenida = 'monedas_bienvenida_entregada';

  /// Saldo inicial otorgado una única vez al iniciar la aplicación por primera vez.
  static const int saldoBienvenida = 20;

  /// Costo en monedas de deshacer un movimiento en el tablero.
  static const int costoDeshacer = 10;

  /// Monedas otorgadas al resolver el Desafío Diario.
  static const int recompensaDiario = 25;

  /// Notificador reactivo del saldo actual de monedas en memoria.
  static final ValueNotifier<int> saldoListenable = ValueNotifier<int>(0);

  /// Saldo actual de monedas.
  static int get saldo => saldoListenable.value;

  /// Carga el saldo persistido en `SharedPreferences` y otorga las monedas
  /// de bienvenida si es la primera vez que se ejecuta el juego.
  static Future<void> inicializar() async {
    final prefs = await SharedPreferences.getInstance();
    final bienvenidaEntregada = prefs.getBool(_claveBienvenida) ?? false;

    if (!bienvenidaEntregada) {
      final saldoActual = prefs.getInt(_claveSaldo) ?? 0;
      final nuevoSaldo = saldoActual + saldoBienvenida;
      await prefs.setInt(_claveSaldo, nuevoSaldo);
      await prefs.setBool(_claveBienvenida, true);
      saldoListenable.value = nuevoSaldo;
    } else {
      saldoListenable.value = prefs.getInt(_claveSaldo) ?? 0;
    }
  }

  /// Calcula la recompensa en monedas para el Modo Clásico según el tamaño del tablero:
  /// - 3×3: +10 🪙
  /// - 4×4: +20 🪙
  /// - 5×5: +30 🪙
  static int recompensaClasico(int size) => switch (size) {
    3 => 10,
    4 => 20,
    5 => 30,
    _ => 10,
  };

  /// Calcula la recompensa en monedas para el Modo Desafío según las estrellas obtenidas:
  /// - 1 ⭐: +10 🪙
  /// - 2 ⭐: +20 🪙
  /// - 3 ⭐: +30 🪙
  static int recompensaDesafio(int estrellas) => switch (estrellas) {
    1 => 10,
    2 => 20,
    3 => 30,
    _ => 10,
  };

  /// Agrega [cantidad] monedas al saldo del jugador y persiste el cambio.
  static Future<void> agregarMonedas(int cantidad) async {
    if (cantidad <= 0) return;
    final prefs = await SharedPreferences.getInstance();
    final nuevoSaldo = saldoListenable.value + cantidad;
    await prefs.setInt(_claveSaldo, nuevoSaldo);
    saldoListenable.value = nuevoSaldo;
  }

  /// Descuenta [costo] monedas si el saldo actual es suficiente.
  /// Devuelve `true` si se pudo realizar la transacción o `false` si no alcanza.
  static Future<bool> gastarMonedas(int costo) async {
    if (costo <= 0) return true;
    if (saldoListenable.value < costo) return false;

    final prefs = await SharedPreferences.getInstance();
    final nuevoSaldo = saldoListenable.value - costo;
    await prefs.setInt(_claveSaldo, nuevoSaldo);
    saldoListenable.value = nuevoSaldo;
    return true;
  }

  /// Restablece el saldo en memoria para pruebas unitarias.
  @visibleForTesting
  static void reiniciarEstadoParaTests([int saldo = 0]) {
    saldoListenable.value = saldo;
  }
}

