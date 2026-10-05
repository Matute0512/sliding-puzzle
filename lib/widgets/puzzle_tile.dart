import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../logic/puzzle_logic.dart';
import '../theme/app_theme.dart';
import '../theme/kenney_ui.dart';
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
        // El hueco lleva un contorno claro, pero **por debajo** del blanco pleno
        // que marca las movibles: si el hueco también fuera blanco, la ayuda
        // ("las fichas con borde blanco son las que podés mover") dejaría de ser
        // cierta. El frame los pinta igual de claros; acá se separan a propósito.
        ? Border.all(color: AppTheme.emptySlotBorder, width: 1)
        : activa
        ? const Border.fromBorderSide(
            BorderSide(color: Colors.white, width: 2),
          )
        // La ficha en reposo también lleva borde en el frame: es lo que la
        // despega de sus vecinas, porque el degradado del sprite es casi el
        // mismo en todas.
        : Border.all(color: AppTheme.tileBorder, width: 1);
    final radio = BorderRadius.circular(_radioFicha);

    // El fondo de la ficha es un sprite 9-slice: la celda vacía usa el cuadrado
    // plano (se lee como hueco) y la ocupada el cuadrado con bisel, tintado con
    // el color de la app.
    //
    // Sin `borderRadius` en la decoración a propósito: el sprite ya trae sus
    // esquinas redondeadas dibujadas, y recortarlo además con el radio de
    // `_radioFicha` (12) le comería el borde, porque la esquina del sprite mide
    // 8px lógicos y no escala con la celda. `_radioFicha` se sigue usando para
    // el anillo de "movible" y para el recorte de `ImageTile`.
    final fondo = (esVacio ? KenneySlices.flatSquare : KenneySlices.primarySquare)
        .decoration(tint: esVacio ? null : AppTheme.seedColor);

    final contenido = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: fondo.copyWith(
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
      foregroundDecoration: BoxDecoration(border: borde, borderRadius: radio),
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
                                ? 24
                                : size == 4
                                ? 19
                                : 14,
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
///
/// 8 es la esquina del sprite del pack y la del frame: al coincidir, el anillo
/// de "movible" calza justo sobre el canto del sprite en vez de cortarlo.
const _radioFicha = 8.0;
