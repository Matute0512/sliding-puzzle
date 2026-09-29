import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/kenney_ui.dart';

/// Tarjeta del HUD para mostrar tiempos y movimientos.
///
/// La superficie es un sprite 9-slice de Kenney, y **sin tintar**: los sprites
/// del pack tienen un solo aspecto, no siguen el tema claro/oscuro de la app.
/// Eso obliga a fijar los colores del texto en vez de sacarlos de `AppColors`
/// (ver [KenneyInk]): en tema oscuro `textPrimary` es casi blanco, y texto casi
/// blanco sobre un panel gris claro no se lee.
class HudCard extends StatelessWidget {
  final IconData icono;
  final String label;
  final String valor;

  const HudCard({
    super.key,
    required this.icono,
    required this.label,
    required this.valor,
  });

  @override
  Widget build(BuildContext context) {
    return KenneySurface(
      slice: KenneySlices.flatPanel,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      child: Column(
        children: [
          Icon(icono, color: AppTheme.seedColor, size: 22),
          const SizedBox(height: 4),
          Text(
            valor,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: KenneyInk.primary,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: KenneyInk.secondary),
          ),
        ],
      ),
    );
  }
}
