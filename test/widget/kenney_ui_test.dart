import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sliding_puzzle/theme/kenney_ui.dart';

import '../helpers/localized_app.dart';

/// Todos los sprites 9-slice que declara [KenneySlices]. Si se agrega uno nuevo
/// y no se suma acá, queda sin cubrir.
const Map<String, KenneySlice> _slices = {
  'primaryButton': KenneySlices.primaryButton,
  'flatPanel': KenneySlices.flatPanel,
  'outlineButton': KenneySlices.outlineButton,
  'insetWell': KenneySlices.insetWell,
  'insetWellOutline': KenneySlices.insetWellOutline,
  'primarySquare': KenneySlices.primarySquare,
  'flatSquare': KenneySlices.flatSquare,
  'outlineSquare': KenneySlices.outlineSquare,
};

/// Decodifica el asset y devuelve su tamaño real en píxeles.
Future<ui.Size> _tamanoDelAsset(String asset) async {
  final data = await rootBundle.load(asset);
  final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
  final frame = await codec.getNextFrame();
  final size = ui.Size(
    frame.image.width.toDouble(),
    frame.image.height.toDouble(),
  );
  frame.image.dispose();
  codec.dispose();
  return size;
}

void main() {
  group('sprites de Kenney', () {
    // El error clásico acá es copiar el rect de un sprite de 192x64 a uno de
    // 64x64, o pasarse del borde. `paintImage` lo tira como assert recién al
    // pintar, así que sin este test se descubre mirando la pantalla.
    test('cada asset existe y su centerSlice entra en la imagen', () async {
      for (final entry in _slices.entries) {
        final slice = entry.value;
        final size = await _tamanoDelAsset(slice.asset);

        expect(
          size.width,
          greaterThan(0),
          reason: '${entry.key}: ${slice.asset} no se pudo decodificar',
        );

        final r = slice.centerSlice;
        expect(
          r.left,
          greaterThan(0),
          reason: '${entry.key}: el borde izquierdo no puede ser 0',
        );
        expect(
          r.top,
          greaterThan(0),
          reason: '${entry.key}: el borde superior no puede ser 0',
        );
        expect(
          r.right,
          lessThanOrEqualTo(size.width),
          reason:
              '${entry.key}: right=${r.right} se pasa del ancho (${size.width})',
        );
        expect(
          r.bottom,
          lessThanOrEqualTo(size.height),
          reason:
              '${entry.key}: bottom=${r.bottom} se pasa del alto '
              '(${size.height})',
        );
        // Sin zona estirable no hay 9-slice: sería una imagen estirada.
        expect(
          r.width,
          greaterThan(0),
          reason: '${entry.key}: no queda centro horizontal',
        );
        expect(
          r.height,
          greaterThan(0),
          reason: '${entry.key}: no queda centro vertical',
        );
      }
    });

    test('los íconos sueltos también existen', () async {
      const iconos = [
        KenneySlices.iconCheck,
        KenneySlices.iconCross,
        KenneySlices.iconPlayLight,
        KenneySlices.iconPlayDark,
        KenneySlices.iconArrowUpLight,
        KenneySlices.iconArrowUpDark,
        KenneySlices.iconRepeat,
        KenneySlices.star,
        KenneySlices.starOutline,
        KenneySlices.divider,
        KenneySlices.arrowEast,
        KenneySlices.arrowWest,
        KenneySlices.arrowNorth,
        KenneySlices.arrowSouth,
      ];
      for (final asset in iconos) {
        final data = await rootBundle.load(asset);
        expect(
          data.lengthInBytes,
          greaterThan(0),
          reason: '$asset está vacío o no existe',
        );
      }
    });
  });

  group('superficies', () {
    testWidgets('la superficie y el botón se pintan sin excepciones', (
      tester,
    ) async {
      await tester.pumpWidget(
        appLocalizada(
          home: Scaffold(
            body: Column(
              children: [
                const KenneySurface(
                  slice: KenneySlices.flatPanel,
                  child: Text('panel'),
                ),
                KenneyButton(onPressed: () {}, child: const Text('botón')),
                const KenneyButton(
                  onPressed: null,
                  child: Text('deshabilitado'),
                ),
              ],
            ),
          ),
        ),
      );
      // Deja que el ImageProvider resuelva y el árbol pinte de verdad: es ahí
      // donde saltaría un centerSlice fuera de rango.
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('botón'), findsOneWidget);
    });

    testWidgets('el botón deshabilitado no dispara nada al tocarlo', (
      tester,
    ) async {
      await tester.pumpWidget(
        appLocalizada(
          home: const Scaffold(
            body: Center(
              child: KenneyButton(
                onPressed: null,
                child: Text('deshabilitado'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('deshabilitado'));
      await tester.pumpAndSettle();

      // Sigue montado y sin excepciones: un `InkWell` con `onTap: null` no
      // responde, que es lo que se espera de un botón deshabilitado.
      expect(find.text('deshabilitado'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
