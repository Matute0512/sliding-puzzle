import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Tarjeta de stat del HUD: ícono, rótulo y valor.
///
/// Es un `DecoratedBox` plano y **no** un `KenneySurface`, por el mismo motivo
/// que `ArcadePanel`: los sprites del pack son mapas de sombreado claros y
/// tintarlos con este navy tan oscuro aplasta el bisel. El sprite se reserva
/// para lo que recibe un color vivo.
///
/// Como la superficie queda **oscura**, el texto sale del tema (`AppColors`) y
/// no de `KenneyInk`, que es para texto sobre sprite claro.
///
/// [label] llega ya en versalitas: el frame las pinta así y la app las arma en
/// el punto de uso, igual que `HomeHeader` y `ModeSwitch`.
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

    return Container(
      height: AppTheme.statHeight,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppTheme.statSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.statBorder),
      ),
      child: Row(
        children: [
          Icon(icono, color: AppTheme.accentCyan, size: 17),
          const SizedBox(width: 9),
          // `Expanded` y los dos textos con elipsis: en 3 cards la columna de
          // texto queda angosta, y un rótulo largo tiene que recortarse en vez
          // de desbordar la tarjeta.
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: colors.textMuted,
                  ),
                ),
                Text(
                  valor,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
