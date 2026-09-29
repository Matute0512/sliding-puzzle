import 'package:flutter/material.dart';

import '../theme/kenney_ui.dart';

/// Botón reutilizable para cada nivel de dificultad.
///
/// La forma la pone el sprite 9-slice de Kenney y el color lo pone [color]: el
/// sprite gris es un mapa de sombreado, así que se multiplica por el color de
/// la dificultad y sale el mismo bisel 3D del pack pero en verde, ámbar, rojo o
/// violeta. Ver [KenneySlice.decoration].
class DifficultyButton extends StatelessWidget {
  final String label;
  final String descripcion;
  final Color color;
  final VoidCallback onTap;

  /// Color del texto del botón. Por defecto oscuro (#0B1220), que es el que
  /// pasa WCAG AA sobre verde/naranja/rojo. Permite pasar blanco para fondos
  /// oscuros como el `seedColor` (Modo Desafío).
  final Color? foregroundColor;

  const DifficultyButton({
    super.key,
    required this.label,
    required this.descripcion,
    required this.color,
    required this.onTap,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    // Texto oscuro: el blanco sobre verde/naranja falla WCAG AA (~2.5:1 y
    // ~2.2:1). #0B1220 da ~7:1 y ~8:1 respectivamente.
    final textColor = foregroundColor ?? const Color(0xFF0B1220);

    return SizedBox(
      width: double.infinity,
      child: KenneyButton(
        onPressed: onTap,
        tint: color,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            Text(
              descripcion,
              style: TextStyle(fontSize: 12, color: textColor),
            ),
          ],
        ),
      ),
    );
  }
}
