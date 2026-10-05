import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../theme/kenney_ui.dart';
import 'arcade_panel.dart';

/// Switch segmentado Clásico / Desafío.
///
/// **No guarda estado a propósito.** La pantalla de inicio *es* el modo Clásico,
/// así que "Clásico" está siempre activo y tocar "Desafío" navega a la grilla de
/// niveles; no hay nada que alternar. Un `SegmentedButton` con estado propio, o
/// un `TabBar`, mentirían sobre eso: darían a entender que se puede volver a
/// Clásico sin salir de la pantalla, y el segmento activo es un cartel, no un
/// control.
class ModeSwitch extends StatelessWidget {
  const ModeSwitch({super.key, required this.onDesafio});

  /// Tocar "Desafío". Navega a la grilla de niveles.
  final VoidCallback onDesafio;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final l10n = AppLocalizations.of(context)!;

    return ArcadePanel(
      color: AppTheme.switchTrack,
      borderColor: AppTheme.switchBorder,
      radius: AppTheme.switchRadius,
      shadow: false,
      padding: const EdgeInsets.all(5),
      child: SizedBox(
        height: 44,
        child: Row(
          children: [
            Expanded(
              child: KenneySurface(
                slice: KenneySlices.flatPanel,
                tint: AppTheme.switchActive,
                child: Center(
                  child: Text(
                    l10n.classicMode.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onDesafio,
                  borderRadius: BorderRadius.circular(AppTheme.switchPillRadius),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.sports_martial_arts_rounded,
                        size: 14,
                        color: colors.textSecondary,
                      ),
                      const SizedBox(width: 7),
                      Text(
                        l10n.challengeTab.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
