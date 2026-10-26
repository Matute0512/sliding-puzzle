import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/coins_service.dart';
import '../theme/app_theme.dart';

/// Botonera del pie de la partida: reiniciar, deshacer movimiento y pausar.
class GameControls extends StatelessWidget {
  const GameControls({
    super.key,
    required this.pausado,
    required this.puedeDeshacer,
    required this.onReiniciar,
    required this.onPausar,
    required this.onDeshacer,
  });

  final bool pausado;
  final bool puedeDeshacer;
  final VoidCallback onReiniciar;
  final VoidCallback onPausar;
  final VoidCallback onDeshacer;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      children: [
        Expanded(
          child: _BotonControl(
            icono: Icons.refresh,
            label: l10n.restart.toUpperCase(),
            onTap: onReiniciar,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ValueListenableBuilder<int>(
            valueListenable: CoinsService.saldoListenable,
            builder: (context, saldo, _) {
              final tieneMonedas = saldo >= CoinsService.costoDeshacer;
              return _BotonControlDeshacer(
                label: l10n.undo.toUpperCase(),
                tieneMonedas: tieneMonedas,
                habilitado: puedeDeshacer && !pausado,
                onTap: onDeshacer,
              );
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _BotonControl(
            icono: pausado ? Icons.play_arrow : Icons.pause,
            label: (pausado ? l10n.resume : l10n.pause).toUpperCase(),
            onTap: onPausar,
            primario: true,
          ),
        ),
      ],
    );
  }
}

/// Botón central dedicado a deshacer movimientos, indicando si consume 10 monedas
/// o si requiere ver un anuncio bonificado por saldo insuficiente.
class _BotonControlDeshacer extends StatelessWidget {
  const _BotonControlDeshacer({
    required this.label,
    required this.tieneMonedas,
    required this.habilitado,
    required this.onTap,
  });

  final String label;
  final bool tieneMonedas;
  final bool habilitado;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    final forma = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppTheme.controlRadius),
      side: BorderSide(
        color: habilitado
            ? (tieneMonedas
                ? const Color(0xFFF59E0B).withValues(alpha: 0.6)
                : AppTheme.accentCyan.withValues(alpha: 0.6))
            : AppTheme.controlBorder.withValues(alpha: 0.3),
      ),
    );

    final tinta = habilitado
        ? (tieneMonedas ? const Color(0xFFF59E0B) : AppTheme.accentCyan)
        : colors.textSecondary.withValues(alpha: 0.3);

    return Material(
      color: habilitado
          ? AppTheme.controlSurface
          : AppTheme.controlSurface.withValues(alpha: 0.4),
      shape: forma,
      child: InkWell(
        onTap: habilitado ? onTap : null,
        customBorder: forma,
        child: SizedBox(
          height: AppTheme.controlHeight,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.undo_rounded,
                size: 16,
                color: tinta,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    color: tinta,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              if (tieneMonedas) ...[
                Icon(
                  Icons.monetization_on_rounded,
                  size: 11,
                  color: tinta,
                ),
                Text(
                  '${CoinsService.costoDeshacer}',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: tinta,
                  ),
                ),
              ] else ...[
                Icon(
                  Icons.smart_display_rounded,
                  size: 13,
                  color: tinta,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Botón ancho del pie.
class _BotonControl extends StatelessWidget {
  const _BotonControl({
    required this.icono,
    required this.label,
    required this.onTap,
    this.primario = false,
  });

  final IconData icono;
  final String label;
  final VoidCallback onTap;
  final bool primario;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    final forma = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppTheme.controlRadius),
      side: BorderSide(
        color: primario ? AppTheme.controlPrimaryBorder : AppTheme.controlBorder,
      ),
    );
    final tinta = primario ? colors.textPrimary : AppTheme.labelBlue;

    return Material(
      color: primario ? AppTheme.controlPrimary : AppTheme.controlSurface,
      shape: forma,
      child: InkWell(
        onTap: onTap,
        customBorder: forma,
        child: SizedBox(
          height: AppTheme.controlHeight,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icono, size: 16, color: tinta),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: tinta,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
