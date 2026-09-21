// `ValueListenable` no viene por `material.dart`: `widgets.dart` re-exporta
// `foundation.dart` con una lista acotada que incluye `ValueNotifier` pero no
// esta interfaz.
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

/// Foto del día a la vista, antes de empezar el Desafío Diario.
///
/// Armar el tablero sin haber visto la imagen es adivinanza: el desafío arranca
/// desarmado y cada ficha muestra un recorte que, aislado, no dice nada de la
/// foto completa. El diálogo la muestra entera y el jugador lo cierra cuando ya
/// la miró, que es el momento en que arranca la partida.
///
/// No arranca nada por su cuenta: el cronómetro del diario sigue detenido hasta
/// el primer movimiento (ver `GameScreen._onTapFicha`), así que mirar la foto
/// con calma no cuesta tiempo.
///
/// Sigue el patrón de `DailyVictoryDialog`: la UI vive en su propio widget y se
/// abre con un `mostrar` estático.
class DailyPreviewDialog extends StatelessWidget {
  /// Foto del día.
  ///
  /// Es un `Listenable` y no un `ImageProvider` suelto porque la descarga está
  /// en vuelo cuando el diálogo se abre —entrar al diario no puede esperar a la
  /// red— y porque el día puede cambiar debajo mientras el diálogo sigue
  /// abierto. En los dos casos el diálogo se tiene que enterar solo.
  ///
  /// `null` significa "todavía no hay foto del día"; se muestra [respaldo].
  final ValueListenable<ImageProvider?> imagen;

  /// Foto que se muestra mientras la del día no llega, o si no llega nunca.
  final ImageProvider respaldo;

  const DailyPreviewDialog({
    super.key,
    required this.imagen,
    required this.respaldo,
  });

  /// Muestra la vista previa y resuelve cuando el jugador la cierra.
  static Future<void> mostrar(
    BuildContext context, {
    required ValueListenable<ImageProvider?> imagen,
    required ImageProvider respaldo,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => DailyPreviewDialog(imagen: imagen, respaldo: respaldo),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).extension<AppColors>()!;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        l10n.dailyPreviewTitle,
        style: const TextStyle(fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ValueListenableBuilder<ImageProvider?>(
            valueListenable: imagen,
            builder: (_, foto, _) => ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AspectRatio(
                aspectRatio: 1,
                // `contain` y no `cover`: acá se muestra la foto entera, tal
                // como se subió. El tablero sí la recorta a cuadrado para que
                // cada ficha sea un pedazo exacto (ver `ImageTile`), pero
                // esconder esa parte acá sería lo contrario de lo que este
                // diálogo viene a resolver. Con las fotos cuadradas que sube el
                // diario las dos formas coinciden.
                child: Image(
                  image: foto ?? respaldo,
                  fit: BoxFit.contain,
                  semanticLabel: l10n.dailyPreviewTitle,
                  loadingBuilder: (_, child, progreso) =>
                      progreso == null ? child : const _CargandoFoto(),
                  // Si la descarga falla se muestra la de respaldo, igual que
                  // en el tablero: el desafío tiene que poder jugarse.
                  errorBuilder: (_, _, _) =>
                      Image(image: respaldo, fit: BoxFit.contain),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.dailyPreviewBody,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: colors.textSecondary),
          ),
        ],
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.seedColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            // Solo cierra el diálogo. Quien lo abre es el dueño de la
            // navegación, igual que en `DailyVictoryDialog`.
            onPressed: () => Navigator.pop(context),
            child: Text(
              l10n.dailyPreviewStart,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}

/// Hueco que ocupa la foto mientras viaja por la red.
///
/// Sin esto el `AspectRatio` colapsaría a la altura del indicador y el diálogo
/// daría un salto al llegar la imagen.
class _CargandoFoto extends StatelessWidget {
  const _CargandoFoto();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: 36,
        height: 36,
        child: CircularProgressIndicator(strokeWidth: 3),
      ),
    );
  }
}
