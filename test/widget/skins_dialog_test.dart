import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sliding_puzzle/services/coins_service.dart';
import 'package:sliding_puzzle/services/skin_service.dart';
import 'package:sliding_puzzle/widgets/skins_dialog.dart';

import '../helpers/localized_app.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    SkinService.reiniciarParaTests();
    await SkinService.inicializar();
    CoinsService.reiniciarEstadoParaTests(150);
  });

  tearDown(() {
    SkinService.reiniciarParaTests();
    CoinsService.reiniciarEstadoParaTests(0);
  });

  testWidgets('SkinsDialog muestra el catálogo completo de 5 skins',
      (tester) async {
    await tester.pumpWidget(
      appLocalizada(
        home: const Scaffold(
          body: SkinsDialog(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('TIENDA DE FICHAS'), findsOneWidget);
    expect(find.text('Clásico Azul'), findsOneWidget);
    expect(find.text('Esmeralda Retro'), findsOneWidget);
    expect(find.text('Fuego Carmesí'), findsOneWidget);
    expect(find.text('Ciber Neón'), findsOneWidget);
    expect(find.text('Oro Real'), findsOneWidget);
    expect(find.text('EQUIPADA'), findsOneWidget);
  });

  testWidgets('Compra de skin descuenta monedas y la equipa', (tester) async {
    await tester.pumpWidget(
      appLocalizada(
        home: const Scaffold(
          body: SkinsDialog(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(SkinService.skinEquipada.id, equals('classic'));
    expect(CoinsService.saldo, equals(150));

    // Comprar Esmeralda (100 monedas)
    final botonEmerald = find.text('100');
    expect(botonEmerald, findsOneWidget);
    await tester.tap(botonEmerald);
    await tester.pumpAndSettle();

    expect(CoinsService.saldo, equals(50));
    expect(SkinService.skinEquipada.id, equals('emerald'));
    expect(SkinService.estaDesbloqueada('emerald'), isTrue);
  });

  testWidgets('Intento de compra sin saldo suficiente muestra advertencia',
      (tester) async {
    CoinsService.reiniciarEstadoParaTests(50);

    await tester.pumpWidget(
      appLocalizada(
        home: const Scaffold(
          body: SkinsDialog(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Intentar comprar Carmesí (200 monedas) con solo 50
    final botonCrimson = find.text('200');
    expect(botonCrimson, findsOneWidget);
    await tester.tap(botonCrimson);
    await tester.pumpAndSettle();

    expect(CoinsService.saldo, equals(50));
    expect(SkinService.skinEquipada.id, equals('classic'));
    expect(find.byType(SnackBar), findsOneWidget);
  });

  testWidgets('Alternar entre skins desbloqueadas no cuesta monedas',
      (tester) async {
    await SkinService.comprarSkin('emerald');

    await tester.pumpWidget(
      appLocalizada(
        home: const Scaffold(
          body: SkinsDialog(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(SkinService.skinEquipada.id, equals('emerald'));
    expect(find.text('USAR'), findsOneWidget); // Classic está desbloqueada pero no equipada

    await tester.tap(find.text('USAR'));
    await tester.pumpAndSettle();

    expect(SkinService.skinEquipada.id, equals('classic'));
    expect(CoinsService.saldo, equals(50)); // No cambió el saldo al equipar
  });
}
