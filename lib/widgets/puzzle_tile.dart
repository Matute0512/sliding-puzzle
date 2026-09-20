import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../logic/puzzle_logic.dart';
import '../theme/app_theme.dart';
import 'image_tile.dart';

/// Ficha individual del tablero del puzzle.
class PuzzleTile extends StatelessWidget {
  final int numero;
  final int size;
  final VoidCallback onTap;

  /// Reporta un deslizamiento sobre la ficha; `null` si no maneja swipe.
  final ValueChanged<Direccion>? onSwipe;

  /// Resalta la ficha cuando es movible (adyacente al hueco).
  final bool activa;

  /// Ficha de "socket": el fondo de una celda del tablero. No expone
  /// semántica (TalkBack no la lee) ni maneja gestos.
  final bool esSocket;

  /// Si no es `null`, la ficha muestra su porción de esta imagen en vez del
  /// número. El número se sigue usando para la semántica y para saber qué
  /// recorte corresponde (ver [ImageTile]).
  ///
  /// Solo cambia el *contenido* de la ficha: sombras, borde de "movible",
  /// gestos y semántica siguen igual que en el modo numérico.
  final ImageProvider? imagen;

  /// Imagen a la que caer si [imagen] no carga. Ver `ImageTile.respaldo`.
  final ImageProvider? imagenRespaldo;

  const PuzzleTile({
    super.key,
    required this.numero,
    required this.size,
    required this.onTap,
    this.onSwipe,
    this.activa = false,
    this.esSocket = false,
    this.imagen,
    this.imagenRespaldo,
  });

  @override
  Widget build(BuildContext context) {
    final esVacio = numero == 0;
    final colors = Theme.of(context).extension<AppColors>()!;
    final l10n = AppLocalizations.of(context)!;
    final conImagen = imagen != null && !esVacio;

    // El borde vive en `foregroundDecoration`, no en `decoration`, a propósito.
    // Un borde dentro de `decoration` le mete padding al hijo (`BoxDecoration`
    // aporta `border.dimensions` como padding), y eso encoge el área de
    // contenido: en modo imagen, la ficha movible mostraría su porción un 5%
    // más chica que las demás —las piezas se encogerían justo al volverse
    // movibles y se verían costuras—. En `foregroundDecoration` se pinta encima
    // sin tocar el layout, así que todas las celdas miden lo mismo.
    final borde = esVacio
        // La ficha vacía lleva un contorno sutil: en tema claro #E2E8F0 sobre
        // el fondo casi no se distingue (~1.14:1).
        ? Border.all(
            color: colors.textSecondary.withValues(alpha: 0.4),
            width: 1.5,
          )
        : activa
        ? Border.all(color: Colors.white.withValues(alpha: 0.9), width: 2.5)
        : null;
    final radio = BorderRadius.circular(_radioFicha);

    final contenido = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        color: esVacio ? colors.emptyTile : AppTheme.seedColor,
        borderRadius: radio,
        boxShadow: esVacio
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ]
            : [
                const BoxShadow(
                  color: AppTheme.accentShadow,
                  offset: Offset(0, 4),
                  blurRadius: 0,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      foregroundDecoration: borde == null
          ? null
          : BoxDecoration(border: borde, borderRadius: radio),
      // La imagen va sin `Center` ni padding: ocupa la celda entera. El número,
      // en cambio, se centra con un margen para que respire.
      child: conImagen
          ? ImageTile(
              imagen: imagen!,
              respaldo: imagenRespaldo,
              numero: numero,
              size: size,
              borderRadius: radio,
            )
          : Center(
              child: esVacio
                  ? null
                  : Padding(
                      padding: const EdgeInsets.all(6),
                      // FittedBox escala el número hacia abajo si la fuente del
                      // sistema es muy grande, evitando desbordes en la celda.
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '$numero',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: size == 3
                                ? 28
                                : size == 4
                                ? 22
                                : 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
            ),
    );

    if (esSocket) {
      return ExcludeSemantics(child: contenido);
    }

    return Semantics(
      button: true,
      label: esVacio ? l10n.emptySlot : l10n.tileLabel(numero),
      hint: l10n.tileHint,
      child: GestureDetector(
        onTap: onTap,
        onHorizontalDragEnd: onSwipe == null
            ? null
            : (details) {
                final v = details.primaryVelocity ?? 0;
                if (v.abs() < _velocidadMinima) return;
                onSwipe!(v > 0 ? Direccion.derecha : Direccion.izquierda);
              },
        onVerticalDragEnd: onSwipe == null
            ? null
            : (details) {
                final v = details.primaryVelocity ?? 0;
                if (v.abs() < _velocidadMinima) return;
                onSwipe!(v > 0 ? Direccion.abajo : Direccion.arriba);
              },
        child: contenido,
      ),
    );
  }
}

/// Velocidad mínima (px/s) para considerar un deslizamiento un swipe real.
/// Un simple toque nunca alcanza el umbral ni genera un drag-end.
const _velocidadMinima = 50.0;

/// Radio de las esquinas de la ficha. Lo comparten el contenedor y el recorte
/// de [ImageTile] para que las esquinas de la imagen coincidan con las del
/// fondo en vez de quedar cuadradas por dentro de un borde redondeado.
const _radioFicha = 12.0;
