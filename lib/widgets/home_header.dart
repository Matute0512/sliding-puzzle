import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import 'header_square_button.dart';

/// Header del menú: título centrado y dos acciones cuadradas a los costados.
///
/// Reemplaza al `AppBar` que tenía la pantalla, que sumaba una altura y un
/// `leading` implícito sin aportar nada: acá no hay ruta anterior a la que
/// volver.
///
/// Los dos slots son los del frame. Como el diseño trae **tres** acciones
/// (ajustes, privacidad y récords) y solo dos lugares, el botón izquierdo —el
/// ícono de grilla del frame— abre un menú con las dos primeras, y el trofeo de
/// la derecha va directo a récords, que es lo que ese ícono ya promete.
class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    required this.onAjustes,
    required this.onPrivacidad,
    required this.onRecords,
  });

  final VoidCallback onAjustes;
  final VoidCallback onPrivacidad;
  final VoidCallback onRecords;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final l10n = AppLocalizations.of(context)!;

    return SizedBox(
      height: 56,
      child: Row(
        children: [
          _MenuCuadrado(
            onAjustes: onAjustes,
            onPrivacidad: onPrivacidad,
            color: colors,
            l10n: l10n,
          ),
          // `Expanded` en el medio y botones del mismo ancho a los costados: así
          // el título queda centrado en la pantalla y no en el espacio libre.
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  // El nombre de la app no se traduce: es el nombre comercial.
                  'Sliding Puzzle'.toUpperCase(),
                  maxLines: 1,
                  style: TextStyle(
                    // 17 y no los 20 del frame: Kenney Future es ~38% más ancha
                    // que la Inter con la que está medido el diseño, y a 20 el
                    // título se partía en dos líneas y desbordaba los 56 px del
                    // header. Es el mismo ajuste que ya se hizo en el resto de
                    // la app al cambiar de tipografía.
                    fontSize: 17,
                    // Kenney Future trae además un interlineado más alto que la
                    // Inter del frame, así que se fija en vez de heredarlo.
                    height: 1.2,
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                  ),
                ),
                Text(
                  l10n.arcadeEdition.toUpperCase(),
                  maxLines: 1,
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
          HeaderSquareButton(
            tooltip: l10n.viewRecords,
            onTap: onRecords,
            child: Icon(
              Icons.emoji_events_rounded,
              size: 19,
              color: colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Las dos acciones que no entran en el header.
enum _AccionMenu { ajustes, privacidad }

/// Botón de grilla, que abre el menú de ajustes y privacidad.
///
/// Usa `PopupMenuButton` en vez de un botón propio que abra un `showMenu`: se
/// encarga solo de anclar el menú debajo del botón y de cerrarlo al tocar afuera
/// o al volver atrás, que es justo la parte fácil de romper a mano.
class _MenuCuadrado extends StatelessWidget {
  const _MenuCuadrado({
    required this.onAjustes,
    required this.onPrivacidad,
    required this.color,
    required this.l10n,
  });

  final VoidCallback onAjustes;
  final VoidCallback onPrivacidad;
  final AppColors color;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_AccionMenu>(
      tooltip: l10n.settingsTitle,
      // Opaco y no `AppTheme.arcadeSurface`, que lleva alfa: un menú flotante
      // translúcido deja leer lo de atrás y se vuelve ilegible.
      color: AppTheme.hudTint,
      onSelected: (accion) => switch (accion) {
        _AccionMenu.ajustes => onAjustes(),
        _AccionMenu.privacidad => onPrivacidad(),
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: _AccionMenu.ajustes,
          child: _FilaMenu(
            icono: Icons.settings_outlined,
            label: l10n.settingsTitle,
            color: color,
          ),
        ),
        PopupMenuItem(
          value: _AccionMenu.privacidad,
          child: _FilaMenu(
            icono: Icons.privacy_tip_outlined,
            label: l10n.privacyTitle,
            color: color,
          ),
        ),
      ],
      child: HeaderSquareButton(
        // El `Tooltip` lo pone el `PopupMenuButton`: poner otro acá los dejaría
        // superpuestos.
        onTap: null,
        child: Icon(
          Icons.grid_view_rounded,
          size: 19,
          color: color.textPrimary,
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
        Text(
          label,
          style: TextStyle(fontSize: 13, color: color.textPrimary),
        ),
      ],
    );
  }
}

