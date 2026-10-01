import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sliding_puzzle/screens/challenge_levels_screen.dart';
import 'package:sliding_puzzle/theme/kenney_ui.dart';

import '../helpers/localized_app.dart';

/// Geometría de la pantalla del Modo Desafío contra su frame de Figma
/// (nodo `4:2689`, iPhone de 400 × 844).
///
/// Estos números son la parte del diseño que se puede verificar sin ojos: si
/// alguien toca el padding de la pantalla, la proporción de las tarjetas o el
/// alto del header, el rediseño deja de coincidir con el frame y esto lo avisa.
void main() {
  /// Deja la superficie de test en el tamaño del frame.
  Future<void> montarEnFrame(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(const {});
    tester.view.physicalSize = const Size(400, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      appLocalizada(home: const ChallengeLevelsScreen()),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('la grilla es de 4 columnas y las tarjetas miden como el frame',
      (tester) async {
    await montarEnFrame(tester);

    final grid = tester.widget<GridView>(find.byType(GridView));
    final delegate =
        grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;

    expect(delegate.crossAxisCount, 4);
    expect(delegate.mainAxisSpacing, 10);
    expect(delegate.crossAxisSpacing, 10);
    expect(delegate.childAspectRatio, closeTo(82.5 / 112, 0.0001));

    // 400 de ancho menos los 20 de padding de cada lado: 360 para 4 tarjetas
    // con 10 de separación ⇒ 82,5 de ancho, y 112 de alto por la proporción.
    final tarjeta = find.byType(KenneySurface);
    expect(tarjeta, findsWidgets);
    expect(tester.getSize(tarjeta.first).width, closeTo(82.5, 0.6));
    expect(tester.getSize(tarjeta.first).height, closeTo(112, 0.6));
  });

  testWidgets('la cabecera, la tarjeta y el aviso tienen el alto del frame',
      (tester) async {
    await montarEnFrame(tester);

    // El frame fija 56 para el header, 72 para la tarjeta de progreso y 52 para
    // el aviso del pie. Se buscan por su alto, que es lo que los define.
    final altos = tester
        .widgetList<SizedBox>(find.byType(SizedBox))
        .map((s) => s.height)
        .toSet();

    expect(altos, containsAll(<double>[56, 72, 52]));
  });

  testWidgets('el aviso del pie va fuera del scroll de la grilla',
      (tester) async {
    await montarEnFrame(tester);

    // Con 20 niveles la grilla no entra en el frame (el mockup dibuja 12, o sea
    // 3 filas): scrollable, con el aviso fijo abajo. Si el aviso quedara dentro
    // del scroll, se iría con las filas que no se ven.
    final scrollDeLaGrilla = find.descendant(
      of: find.byType(GridView),
      matching: find.byType(Scrollable),
    );
    expect(scrollDeLaGrilla, findsOneWidget);

    expect(
      find.text('Completá el nivel 1 para desbloquear el siguiente.'),
      findsOneWidget,
    );
  });
}
