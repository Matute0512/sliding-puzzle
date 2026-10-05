import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../theme/kenney_ui.dart';
import 'header_square_button.dart';

/// Header de la partida: volver, tablero y dificultad, y el menú de ajustes.
///
/// Reemplaza al `AppBar`, que apilaba tres `IconButton` sueltos (ayuda, pausa y
/// reiniciar) sin rótulo. Pausa y reiniciar bajaron a la botonera del pie, como
/// el frame; la ayuda se fue al menú del engranaje, que es el slot que el frame
/// sí define.
class GameHeader extends StatelessWidget {
  const GameHeader({
    super.key,
    required this.titulo,
    required this.subtitulo,
    required this.onVolver,
    required this.onAjustes,
    required this.onAyuda,
  });

  /// Primera línea, en versalitas. Ej. "TABLERO 5×5".
  final String titulo;

  /// Segunda línea, en versalitas y cian. Ej. "MODO DIFÍCIL".
  final String subtitulo;

  final VoidCallback onVolver;
  final VoidCallback onAjustes;
  final VoidCallback onAyuda;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        height: 56,
        child: Row(
          children: [
            HeaderSquareButton(
              // El tooltip de volver ya viene traducido por Material.
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              onTap: onVolver,
              child: KenneyIcon(
                KenneySlices.arrowWest,
                size: 19,
                tint: colors.textPrimary,
              ),
            ),
            // `Expanded` en el medio y botones del mismo ancho a los costados:
            // así el título queda centrado en la pantalla y no en el espacio
            // libre. Mismo criterio que `HomeHeader` y el header del Desafío.
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    titulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      // 17 y no los 20 del frame: Kenney Future es ~38% más
                      // ancha que la Inter del diseño. Ver `HomeHeader`.
                      fontSize: 17,
                      height: 1.2,
                      fontWeight: FontWeight.w800,
                      color: colors.textPrimary,
                    ),
                  ),
                  Text(
                    subtitulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 9,
                      height: 1.2,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.accentCyan,
                    ),
                  ),
                ],
              ),
            ),
            _MenuAjustes(onAjustes: onAjustes, onAyuda: onAyuda),
          ],
        ),
      ),
    );
  }
}

/// Las dos acciones del menú del engranaje.
enum _AccionMenu { ajustes, ayuda }

/// Engranaje que abre el menú de ajustes y ayuda.
///
/// Usa `PopupMenuButton` en vez de un botón propio que abra un `showMenu`: se
/// encarga solo de anclar el menú debajo del botón y de cerrarlo al tocar afuera
/// o al volver atrás. Es el mismo patrón que el menú del header del menú.
class _MenuAjustes extends StatelessWidget {
  const _MenuAjustes({required this.onAjustes, required this.onAyuda});

  final VoidCallback onAjustes;
  final VoidCallback onAyuda;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final l10n = AppLocalizations.of(context)!;

    return PopupMenuButton<_AccionMenu>(
      tooltip: l10n.settingsTitle,
      // Opaco y no `AppTheme.arcadeSurface`, que lleva alfa: un menú flotante
      // translúcido deja leer el tablero de atrás y se vuelve ilegible.
      color: AppTheme.hudTint,
      onSelected: (accion) => switch (accion) {
        _AccionMenu.ajustes => onAjustes(),
        _AccionMenu.ayuda => onAyuda(),
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: _AccionMenu.ajustes,
          child: _FilaMenu(
            icono: Icons.settings_outlined,
            label: l10n.settingsTitle,
            color: colors,
          ),
        ),
        PopupMenuItem(
          value: _AccionMenu.ayuda,
          child: _FilaMenu(
            icono: Icons.help_outline,
            label: l10n.howToPlayTitle,
            color: colors,
          ),
        ),
      ],
      child: HeaderSquareButton(
        // El `Tooltip` lo pone el `PopupMenuButton`: poner otro acá los dejaría
        // superpuestos.
        onTap: null,
        child: Icon(
          Icons.settings_outlined,
          size: 18,
          color: colors.textPrimary,
        ),
      ),
    );
  }
}

class _FilaMenu extends StatelessWidget {
  const _FilaMenu({
    required this.icono,
    required this.label,
    required this.color,
  });

  final IconData icono;
  final String label;
  final AppColors color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icono, size: 18, color: color.textSecondary),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(fontSize: 13, color: color.textPrimary)),
      ],
    );
  }
}
