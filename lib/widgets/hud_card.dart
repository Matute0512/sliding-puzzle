import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/kenney_ui.dart';

/// Tarjeta del HUD para mostrar tiempos y movimientos.
///
/// La superficie es un sprite 9-slice de Kenney tintado con [AppTheme.hudTint]:
/// un azul profundo que la integra al fondo del juego, en vez del gris claro
/// del pack que se leía como un parche pegado arriba de la escena.
///
/// Como el tinte deja la superficie **oscura**, el texto sale del tema
/// (`AppColors`) y no de `KenneyInk`: `KenneyInk` es para texto sobre sprite
/// claro, y acá el texto oscuro no se leería.
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
    final colors = Theme.of(context).extension<AppColors>()!;

    return KenneySurface(
      slice: KenneySlices.flatPanel,
      tint: AppTheme.hudTint,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      child: Column(
        children: [
          Icon(icono, color: AppTheme.seedColor, size: 22),
          const SizedBox(height: 4),
          Text(
            valor,
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: colors.textSecondary),
          ),
        ],
      ),
    );
  }
}
