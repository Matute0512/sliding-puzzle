import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Tarjeta del HUD para mostrar tiempos y movimientos
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
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icono, color: AppTheme.seedColor, size: 22),
          const SizedBox(height: 4),
          Text(
            valor,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
