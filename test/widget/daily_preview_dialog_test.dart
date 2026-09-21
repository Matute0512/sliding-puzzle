import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sliding_puzzle/services/daily_challenge_service.dart';
import 'package:sliding_puzzle/widgets/daily_preview_dialog.dart';

import '../helpers/localized_app.dart';

/// La vista previa del Desafío Diario.
///
/// El caso que más importa acá es el de la foto que **llega tarde**: el diálogo
/// se abre apenas se entra al diario —esperar a la red dejaría al jugador
/// mirando un tablero desarmado— así que tiene que actualizarse solo cuando la
/// descarga termina. Si no, mostraría la foto de respaldo para siempre y el
/// jugador armaría un puzzle distinto del que vio.
void main() {
  /// Foto de respaldo empaquetada, la misma que usa producción.
  const respaldo = DailyChallengeService.imagenRespaldo;

  /// PNG válido de 1x1, para tener una imagen que no sea [respaldo] y que no
  /// dispare el `errorBuilder` por no poder decodificarse.
  final fotoDelDia = MemoryImage(
    base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk'
      'YPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
    ),
  );

  /// La `Image` que está dibujando el diálogo.
  Image imagenDelDialogo(WidgetTester tester) => tester.widget<Image>(
    find.descendant(
      of: find.byType(DailyPreviewDialog),
      matching: find.byType(Image),
    ),
  );

  /// Abre la vista previa sobre una pantalla cualquiera y devuelve el notifier
  /// de la foto, para poder hacerla llegar "después".
  Future<ValueNotifier<ImageProvider?>> abrirPreview(
    WidgetTester tester, {
    ImageProvider? inicial,
  }) async {
    final imagen = ValueNotifier<ImageProvider?>(inicial);
    addTearDown(imagen.dispose);

    await tester.pumpWidget(
      appLocalizada(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => DailyPreviewDialog.mostrar(
                  context,
                  imagen: imagen,
                  respaldo: respaldo,
                ),
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pump();
    await tester.pump();
    return imagen;
  }

  testWidgets('se abre con un título y el botón de empezar', (tester) async {
    await abrirPreview(tester, inicial: respaldo);

    expect(find.byType(DailyPreviewDialog), findsOneWidget);
    expect(find.text('La foto de hoy'), findsOneWidget);
    expect(find.text('¡Empezar!'), findsOneWidget);
  });

  testWidgets('muestra la foto entera, sin recortar', (tester) async {
    await abrirPreview(tester, inicial: fotoDelDia);

    // `contain` y no `cover`: la vista previa dibuja la foto completa. Es la
    // diferencia entre ver qué hay que armar y ver solo la parte que el
    // tablero recorta al cuadrado.
    expect(imagenDelDialogo(tester).fit, BoxFit.contain);
    expect(imagenDelDialogo(tester).image, same(fotoDelDia));
  });

  testWidgets('muestra el respaldo mientras la foto del día no llega', (
    tester,
  ) async {
    await abrirPreview(tester, inicial: null);

    expect(
      imagenDelDialogo(tester).image,
      same(respaldo),
      reason: 'el diálogo nunca puede quedar vacío',
    );
  });

  testWidgets('se actualiza cuando la foto del día termina de bajar', (
    tester,
  ) async {
    // Así entra en producción: el diálogo se abre con la foto empaquetada y la
    // descarga se resuelve por detrás.
    final imagen = await abrirPreview(tester, inicial: respaldo);
    expect(imagenDelDialogo(tester).image, same(respaldo));

    imagen.value = fotoDelDia;
    await tester.pump();

    expect(
      imagenDelDialogo(tester).image,
      same(fotoDelDia),
      reason: 'el diálogo tiene que escuchar al notifier, no quedarse con la '
          'foto que había cuando se abrió',
    );
  });

  testWidgets('el botón de empezar cierra el diálogo', (tester) async {
    await abrirPreview(tester, inicial: respaldo);

    await tester.tap(find.text('¡Empezar!'));
    await tester.pump();
    await tester.pump();

    expect(find.byType(DailyPreviewDialog), findsNothing);
  });
}
