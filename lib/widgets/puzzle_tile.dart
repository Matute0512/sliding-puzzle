import 'package:flutter/material.dart';
import '../logic/puzzle_logic.dart';
import '../theme/app_theme.dart';

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

  const PuzzleTile({
    super.key,
    required this.numero,
    required this.size,
    required this.onTap,
    this.onSwipe,
    this.activa = false,
    this.esSocket = false,
  });

  @override
  Widget build(BuildContext context) {
    final esVacio = numero == 0;
    final colors = Theme.of(context).extension<AppColors>()!;

    final contenido = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        color: esVacio ? colors.emptyTile : AppTheme.seedColor,
        borderRadius: BorderRadius.circular(12),
        // La ficha vacía lleva un contorno sutil: en tema claro #E2E8F0
        // sobre el fondo casi no se distingue (~1.14:1).
        border: esVacio
            ? Border.all(
                color: colors.textSecondary.withValues(alpha: 0.4),
                width: 1.5,
              )
            : activa
            ? Border.all(color: Colors.white.withValues(alpha: 0.9), width: 2.5)
            : null,
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
      child: Center(
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
      label: esVacio ? 'Hueco vacío' : 'Ficha $numero',
      hint: 'Toca o desliza hacia el hueco para mover',
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
