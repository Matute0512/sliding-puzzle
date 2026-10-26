import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sliding_puzzle/services/coins_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(const {});
    CoinsService.reiniciarEstadoParaTests(0);
  });

  group('CoinsService.inicializar', () {
    test('otorga saldo de bienvenida (20) en el primer inicio', () async {
      SharedPreferences.setMockInitialValues({});

      await CoinsService.inicializar();

      expect(CoinsService.saldo, equals(CoinsService.saldoBienvenida));
      expect(CoinsService.saldoListenable.value, equals(20));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('monedas_saldo'), equals(20));
      expect(prefs.getBool('monedas_bienvenida_entregada'), isTrue);
    });

    test('no vuelve a otorgar saldo de bienvenida si ya fue entregado', () async {
      SharedPreferences.setMockInitialValues({
        'monedas_saldo': 35,
        'monedas_bienvenida_entregada': true,
      });

      await CoinsService.inicializar();

      expect(CoinsService.saldo, equals(35));
      expect(CoinsService.saldoListenable.value, equals(35));
    });
  });

  group('CoinsService transacciones', () {
    test('agregarMonedas suma correctamente al saldo y persiste', () async {
      SharedPreferences.setMockInitialValues({
        'monedas_saldo': 10,
        'monedas_bienvenida_entregada': true,
      });
      await CoinsService.inicializar();

      await CoinsService.agregarMonedas(25);

      expect(CoinsService.saldo, equals(35));
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('monedas_saldo'), equals(35));

      // Agregar <= 0 no modifica saldo
      await CoinsService.agregarMonedas(0);
      await CoinsService.agregarMonedas(-5);
      expect(CoinsService.saldo, equals(35));
    });

    test('gastarMonedas descuenta si hay saldo suficiente y rechaza si no alcanza', () async {
      SharedPreferences.setMockInitialValues({
        'monedas_saldo': 15,
        'monedas_bienvenida_entregada': true,
      });
      await CoinsService.inicializar();

      final pudoGastar10 = await CoinsService.gastarMonedas(CoinsService.costoDeshacer);
      expect(pudoGastar10, isTrue);
      expect(CoinsService.saldo, equals(5));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('monedas_saldo'), equals(5));

      // Intento de gastar 10 teniendo solo 5
      final pudoGastarMas = await CoinsService.gastarMonedas(10);
      expect(pudoGastarMas, isFalse);
      expect(CoinsService.saldo, equals(5));
      expect(prefs.getInt('monedas_saldo'), equals(5));

      // Gastar <= 0 devuelve true sin modificar saldo
      final gastoCero = await CoinsService.gastarMonedas(0);
      expect(gastoCero, isTrue);
      expect(CoinsService.saldo, equals(5));
    });
  });

  group('CoinsService cálculos de recompensas', () {
    test('recompensaClasico según tamaño', () {
      expect(CoinsService.recompensaClasico(3), equals(10));
      expect(CoinsService.recompensaClasico(4), equals(20));
      expect(CoinsService.recompensaClasico(5), equals(30));
      expect(CoinsService.recompensaClasico(6), equals(10));
    });

    test('recompensaDesafio según estrellas', () {
      expect(CoinsService.recompensaDesafio(1), equals(10));
      expect(CoinsService.recompensaDesafio(2), equals(20));
      expect(CoinsService.recompensaDesafio(3), equals(30));
      expect(CoinsService.recompensaDesafio(0), equals(10));
    });

    test('recompensaDiario es 25', () {
      expect(CoinsService.recompensaDiario, equals(25));
    });
  });
}

