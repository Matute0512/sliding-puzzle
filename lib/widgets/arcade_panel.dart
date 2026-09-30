import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Contenedor navy de las tarjetas del rediseño: la de mejor partida y el track
/// del switch de modo.
///
/// Es un `DecoratedBox` plano y **no** un `KenneySurface`, y eso es deliberado.
/// Los sprites del pack son mapas de sombreado claros: multiplicarlos por un
/// navy tan oscuro como [AppTheme.arcadeSurface] aplasta el bisel hasta dejar un
/// bloque liso, que es lo peor de los dos mundos —ni el relieve del sprite ni la
/// limpieza de un plano—. El sprite se reserva para lo que sí recibe un color
/// vivo: los botones (ver `ArcadeButton`).
///
/// Como la superficie queda **oscura**, el texto que va adentro sale de
/// `AppColors` y no de `KenneyInk`: `KenneyInk` es para texto sobre sprite
/// claro, y ahí sería ilegible.
class ArcadePanel extends StatelessWidget {
  const ArcadePanel({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.color = AppTheme.arcadeSurface,
    this.borderColor = AppTheme.arcadeBorder,
    this.radius = AppTheme.arcadeRadius,
    this.shadow = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final Color borderColor;
  final double radius;

  /// Sombra proyectada. El switch de modo la apaga: está apoyado sobre el
  /// contenido en vez de flotar por encima como la tarjeta de récord.
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor),
        boxShadow: shadow ? const [_sombra] : null,
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

/// La sombra del frame: `0 16 34 rgba(0,0,0,0.44)`. El negro al 44% es `0x70`.
const BoxShadow _sombra = BoxShadow(
  color: Color(0x70000000),
  blurRadius: 34,
  offset: Offset(0, 16),
);
