import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

/// Botonera del pie de la partida: reiniciar y pausar.
///
/// Antes eran dos `IconButton` sin rótulo en el `AppBar`. El frame los baja al
/// pie con texto, que es donde se buscan a mitad de partida —y donde el pulgar
/// llega sin soltar el tablero—.
class GameControls extends StatelessWidget {
  const GameControls({
    super.key,
    required this.pausado,
    required this.onReiniciar,
    required this.onPausar,
  });

  final bool pausado;
  final VoidCallback onReiniciar;
  final VoidCallback onPausar;

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
        const SizedBox(width: 10),
        Expanded(
          child: _BotonControl(
            // El botón dice lo que va a pasar, no el estado: en pausa ofrece
            // reanudar.
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

/// Botón ancho del pie.
///
/// [primario] usa el azul vivo del frame; el secundario se queda en la
/// superficie oscura con la tinta apagada. El color va en el `Material` y no en
/// un `Container` adentro del `InkWell`, o la tinta del ripple quedaría tapada.
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
              Icon(icono, size: 17, color: tinta),
              const SizedBox(width: 8),
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
