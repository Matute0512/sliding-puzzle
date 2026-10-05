import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Cuadrado de 40 del header, con la superficie y el borde del frame.
///
/// Lo comparten el header del menú ([HomeHeader]) y el del Modo Desafío: los dos
/// frames traen el mismo botón, y tenerlo dos veces era la forma más fácil de
/// que se separaran al primer retoque.
///
/// Cuando [onTap] es `null` el botón es solo la decoración: el gesto lo maneja
/// el widget que lo envuelve (en el menú lo mete un `PopupMenuButton`).
///
/// El glifo entra como [child] y no como `IconData` porque no siempre es un
/// ícono de Material: el chevron de volver del Modo Desafío es un sprite de
/// Kenney, y además el tamaño cambia entre el chevron (19) y el trofeo (18) del
/// frame, así que lo fija quien llama.
///
/// El color y el borde van en el `Material` y no en un `Container` adentro del
/// `InkWell`: un `Container` con `color` se pinta por encima de la tinta del
/// ripple —que va sobre el `Material` más cercano— y el toque quedaría sin
/// respuesta visual.
class HeaderSquareButton extends StatelessWidget {
  const HeaderSquareButton({
    super.key,
    required this.child,
    this.tooltip,
    this.onTap,
  });

  final Widget child;
  final String? tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final forma = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: const BorderSide(color: AppTheme.headerButtonBorder),
    );

    final cuadrado = Material(
      color: AppTheme.headerButtonSurface,
      shape: forma,
      child: InkWell(
        onTap: onTap,
        customBorder: forma,
        child: SizedBox(
          width: AppTheme.headerButtonSize,
          height: AppTheme.headerButtonSize,
          child: Center(child: child),
        ),
      ),
    );

    if (tooltip == null) return cuadrado;
    return Tooltip(message: tooltip!, child: cuadrado);
  }
}
