import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sliding_puzzle/widgets/alias_dialog.dart';

import '../helpers/localized_app.dart';

/// App mínima con un botón que abre el diálogo y entrega el resultado a
/// [alCerrar]. Devuelve también la clave del navigator, para poder desmontar
/// las rutas desde el test.
({Widget app, GlobalKey<NavigatorState> navegador}) _montar(
  void Function(String?) alCerrar,
) {
  final navegador = GlobalKey<NavigatorState>();
  return (
    navegador: navegador,
    app: appLocalizada(
      navigatorKey: navegador,
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () async {
                alCerrar(await AliasDialog.mostrar(context));
              },
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('Publicar devuelve el alias normalizado', (tester) async {
    String? resultado;
    await tester.pumpWidget(_montar((r) => resultado = r).app);

    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);

    // Con espacio delante y en minúsculas: debe salir recortado y en
    // mayúsculas. El espacio cuenta para el tope de 5 del formatter, así que se
    // entra exactamente eso: 1 espacio + 4 letras.
    await tester.enterText(find.byType(TextField), ' mate');
    await tester.tap(find.text('Publicar'));
    await tester.pumpAndSettle();

    expect(resultado, 'MATE');
  });

  testWidgets('el campo recorta a 5 caracteres', (tester) async {
    String? resultado;
    await tester.pumpWidget(_montar((r) => resultado = r).app);

    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'ABCDEFGH');
    await tester.tap(find.text('Publicar'));
    await tester.pumpAndSettle();

    expect(resultado, 'ABCDE');
  });

  testWidgets('"Ahora no" devuelve null', (tester) async {
    String? resultado;
    await tester.pumpWidget(_montar((r) => resultado = r).app);

    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ahora no'));
    await tester.pumpAndSettle();

    expect(resultado, isNull);
  });

  testWidgets('un alias vacío no se publica', (tester) async {
    String? resultado;
    await tester.pumpWidget(_montar((r) => resultado = r).app);

    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    // Sin escribir nada, "Publicar" manda una cadena vacía: debe normalizarse
    // a null para no publicar un puntaje sin alias.
    await tester.tap(find.text('Publicar'));
    await tester.pumpAndSettle();

    expect(resultado, isNull);
  });

  testWidgets(
    'desmontar el diálogo de golpe no usa el controlador ya liberado',
    (tester) async {
      final montado = _montar((_) {});
      await tester.pumpWidget(montado.app);

      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'MATE');

      // Se replica lo que hace "Volver al Menú": un `popUntil` que se lleva
      // puesta la ruta del diálogo sin darle tiempo a cerrarse con calma.
      final navigator = montado.navegador.currentState!;
      navigator.popUntil((ruta) => ruta.isFirst);

      // El diálogo sigue montado mientras corre su animación de salida. Si el
      // controlador se liberara fuera del `State` —como antes—, un rebuild acá
      // lanzaba "A TextEditingController was used after being disposed".
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(TextField), findsNothing);
    },
  );

  testWidgets(
    'el contenido del diálogo es scrolleable (el teclado recorta el alto)',
    (tester) async {
      await tester.pumpWidget(_montar((_) {}).app);
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();

      // Con el teclado insets abajo, el contenido debe poder desplazarse en vez
      // de desbordar (era el "RenderFlex overflowed" del reporte).
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(SingleChildScrollView),
        ),
        findsOneWidget,
      );
    },
  );
}
