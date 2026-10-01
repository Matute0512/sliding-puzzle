import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sliding_puzzle/screens/game_screen.dart';
import 'package:sliding_puzzle/widgets/game_controls.dart';
import 'package:sliding_puzzle/widgets/hud_card.dart';
import 'package:sliding_puzzle/widgets/puzzle_board.dart';

import '../helpers/localized_app.dart';

/// Geometría de la pantalla de partida contra su frame de Figma
/// (nodo `4:2825` "Tablero numérico", iPhone de 400 × 844).
///
/// Es la parte del diseño que se puede verificar sin ojos: si alguien toca el
/// padding de la pantalla, el alto de las cards o el del pozo, el rediseño deja
/// de coincidir con el frame y esto lo avisa.
void main() {
  Future<void> montarEnFrame(WidgetTester tester, {required int size}) async {
    SharedPreferences.setMockInitialValues(const {});
    tester.view.physicalSize = const Size(400, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(appLocalizada(home: GameScreen(size: size)));
    await tester.pump();
  }

  testWidgets('las cards del HUD y la botonera tienen el alto del frame',
      (tester) async {
    await montarEnFrame(tester, size: 5);

    // El frame fija 54 para las cards de stat y 52 para los botones del pie.
    expect(tester.getSize(find.byType(HudCard).first).height, 54);
    expect(tester.getSize(find.byType(GameControls)).height, 52);
  });

  testWidgets('el tablero es cuadrado y ocupa el ancho disponible',
      (tester) async {
    await montarEnFrame(tester, size: 5);

    // 400 de ancho menos los 20 de padding de cada lado dan 360 de pozo. El
    // borde de 2 px de la decoración se descuenta como padding —igual que
    // documenta `puzzle_tile.dart`— y después van los 8 de padding del pozo:
    // 360 − 4 − 16 = 340, o sea fichas de 64,8 contra las 64 del frame.
    //
    // El frame clava el pozo en 352 en vez de a lo ancho, 8 px menos. Acá se
    // toma el ancho disponible a propósito: el tablero tiene que adaptarse a
    // 3×3, 4×4 y 6×6 en pantallas de cualquier tamaño, y 8 px no cambian la
    // lectura.
    final tablero = tester.getSize(find.byType(PuzzleBoard));
    expect(tablero.width, closeTo(340, 0.6));
    expect(tablero.height, closeTo(340, 0.6));
  });

  testWidgets('la partida libre muestra las tres cards del frame',
      (tester) async {
    await montarEnFrame(tester, size: 5);

    // El frame trae Tiempo, Movs y Récord. El Récord solo aparece en partida
    // libre, así que acá tienen que estar las tres.
    expect(find.byType(HudCard), findsNWidgets(3));
  });

  testWidgets('el modo foto muestra el header y la consigna del frame',
      (tester) async {
    SharedPreferences.setMockInitialValues(const {});
    tester.view.physicalSize = const Size(400, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      appLocalizada(home: const GameScreen(size: 3, esDiario: true)),
    );
    await tester.pumpAndSettle();

    // La vista previa del día se abre sola al entrar: se cierra para poder
    // mirar la pantalla de juego.
    final empezar = find.text('¡Empezar!');
    if (empezar.evaluate().isNotEmpty) {
      await tester.tap(empezar);
      await tester.pumpAndSettle();
    }

    // El frame del tablero fotográfico no titula con el tamaño sino con el modo;
    // el tamaño se muda a la píldora de la consigna.
    expect(find.text('PUZZLE FOTO'), findsOneWidget);
    expect(find.text('DESAFÍO DIARIO'), findsOneWidget);

    // Tiempo, Movs y Piezas. La tercera es propia del modo foto: en el Diario no
    // hay récord que mostrar.
    expect(find.byType(HudCard), findsNWidgets(3));
    expect(find.text('PIEZAS'), findsOneWidget);
    expect(find.text('RECONSTRUÍ LA IMAGEN'), findsOneWidget);
    expect(find.text('3×3'), findsOneWidget);
  });
}
