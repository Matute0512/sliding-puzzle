import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sliding_puzzle/services/coins_service.dart';
import 'package:sliding_puzzle/services/skin_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    CoinsService.reiniciarEstadoParaTests(0);
    SkinService.reiniciarParaTests();
  });

  group('SkinService — Catálogo y Estado Inicial', () {
    test('el catálogo contiene las 5 skins con sus precios y colores', () {
      expect(SkinService.catalogo.length, equals(5));
      expect(SkinService.catalogo['classic']!.precio, equals(0));
      expect(SkinService.catalogo['emerald']!.precio, equals(100));
      expect(SkinService.catalogo['crimson']!.precio, equals(200));
      expect(SkinService.catalogo['cyber']!.precio, equals(300));
      expect(SkinService.catalogo['amber']!.precio, equals(500));
    });

    test('la skin classic está desbloqueada y equipada por defecto', () async {
      await SkinService.inicializar();

      expect(SkinService.estaDesbloqueada(SkinService.skinClasicaId), isTrue);
      expect(SkinService.skinEquipada.id, equals(SkinService.skinClasicaId));
      expect(SkinService.skinEquipadaListenable.value, equals(SkinService.skinClasicaId));
    });
  });

  group('SkinService — Compras y Equipamiento', () {
    test('no permite comprar una skin si el saldo de monedas es insuficiente', () async {
      await SkinService.inicializar();
      CoinsService.reiniciarEstadoParaTests(50); // Emerald cuesta 100

      final exito = await SkinService.comprarSkin('emerald');

      expect(exito, isFalse);
      expect(SkinService.estaDesbloqueada('emerald'), isFalse);
      expect(CoinsService.saldo, equals(50));
      expect(SkinService.skinEquipada.id, equals('classic'));
    });

    test('compra exitosa descuenta monedas, desbloquea y auto-equipa la skin', () async {
      await SkinService.inicializar();
      CoinsService.reiniciarEstadoParaTests(150);

      final exito = await SkinService.comprarSkin('emerald');

      expect(exito, isTrue);
      expect(SkinService.estaDesbloqueada('emerald'), isTrue);
      expect(CoinsService.saldo, equals(50));
      expect(SkinService.skinEquipada.id, equals('emerald'));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getStringList('skins_desbloqueadas'), contains('emerald'));
      expect(prefs.getString('skin_equipada'), equals('emerald'));
    });

    test('no se puede equipar una skin bloqueada', () async {
      await SkinService.inicializar();

      final exito = await SkinService.equiparSkin('cyber');

      expect(exito, isFalse);
      expect(SkinService.skinEquipada.id, equals('classic'));
    });

    test('se puede alternar entre skins ya desbloqueadas sin costo', () async {
      SharedPreferences.setMockInitialValues({
        'skins_desbloqueadas': ['classic', 'emerald'],
        'skin_equipada': 'classic',
      });
      await SkinService.inicializar();
      CoinsService.reiniciarEstadoParaTests(10);

      final exito = await SkinService.equiparSkin('emerald');

      expect(exito, isTrue);
      expect(SkinService.skinEquipada.id, equals('emerald'));
      expect(CoinsService.saldo, equals(10)); // No descuenta saldo
    });
  });
}
