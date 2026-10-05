import 'package:flutter/material.dart';

import 'app_theme.dart';

/// Un sprite del UI Pack de Kenney junto con su receta 9-slice.
///
/// [centerSlice] es el rectángulo interior del PNG que sí se puede estirar. Al
/// pintarlo, las 4 esquinas quedan intactas, los 4 bordes se estiran en un solo
/// eje y el centro se estira en los dos. Escalar el sprite entero (sin esto)
/// deformaría las esquinas redondeadas y engordaría el borde.
@immutable
class KenneySlice {
  /// Ruta del asset, relativa a la raíz del paquete.
  final String asset;

  /// Zona estirable, en píxeles de la imagen (no en píxeles lógicos).
  final Rect centerSlice;

  const KenneySlice(this.asset, this.centerSlice);

  /// El fondo 9-slice listo para colgar de un `DecoratedBox`.
  ///
  /// [tint] recolorea el sprite. Los sprites de forma que usa la app son los
  /// **grises**, y no por gusto: el gris de Kenney es un mapa de sombreado
  /// (blanco en el brillo, gris claro en la cara, más oscuro en el borde y el
  /// bisel). Multiplicarlo por un color con `BlendMode.modulate` devuelve
  /// exactamente el mismo sombreado pero en ese color, así que un solo sprite
  /// cubre el verde de "fácil", el ámbar de "medio", el rojo de "difícil" y el
  /// violeta del diario.
  ///
  /// Los sprites ya coloreados del pack no sirven para esto: el azul de Kenney
  /// no se puede volver ámbar. Por eso el subconjunto curado trae los grises.
  BoxDecoration decoration({Color? tint}) => BoxDecoration(
    image: DecorationImage(
      image: AssetImage(asset),
      centerSlice: centerSlice,
      // `fill` no es opcional: con cualquier otro `BoxFit` las 9 regiones se
      // escalan con el mismo factor y `centerSlice` no tendría ningún efecto
      // (se vería como un simple escalado de la imagen completa).
      fit: BoxFit.fill,
      colorFilter: tint == null
          ? null
          : ColorFilter.mode(tint, BlendMode.modulate),
    ),
  );
}

/// Sprites curados del UI Pack de Kenney (CC0).
///
/// El pack completo (4.2 MB, ~1000 PNG de todos los colores y estilos) **no**
/// está en el repo: ver `.gitignore`. Estos son los pocos que la app usa; si
/// agregás uno nuevo, copialo a `assets/ui/kenney/` y, sobre todo, calculá su
/// `centerSlice` en vez de estimarlo (ver la nota de abajo).
///
/// Los rects de acá se midieron píxel por píxel sobre los PNG reales. El método
/// es: para un candidato `(l, t, r, b)`, comprobar que las 4 bandas de borde
/// sean de **un solo color** a lo largo de su eje de estirado, y que el centro
/// sea de un solo color. Si una banda no lo fuera, al estirarla arrastraría una
/// franja de color equivocado a lo largo del botón.
///
/// Nota sobre los sprites `depth`: llevan el borde inferior un píxel más
/// adentro que el superior (55 en vez de 56 en un PNG de 64 de alto). La última
/// fila de la cara trae el antialias del bisel 3D; si se incluye en la banda
/// lateral, ese antialias se estira en vertical y deja una línea tenue de color
/// corrido en los costados.
abstract final class KenneySlices {
  static const String _dir = 'assets/ui/kenney';

  // --- Rectangulares (192x64) ---

  /// Botón relleno con el bisel 3D clásico. Acción primaria.
  static const primaryButton = KenneySlice(
    '$_dir/button_rectangle_depth_flat.png',
    Rect.fromLTRB(8, 8, 184, 55),
  );

  /// Botón relleno plano, sin bisel. Para paneles y tarjetas: a tamaño grande
  /// el bisel 3D del primario se leería como un botón gigante.
  static const flatPanel = KenneySlice(
    '$_dir/button_rectangle_flat.png',
    Rect.fromLTRB(8, 8, 184, 56),
  );

  /// Botón solo con contorno. Da jerarquía sin cambiar de color: acción
  /// secundaria frente al [primaryButton].
  static const outlineButton = KenneySlice(
    '$_dir/button_rectangle_border.png',
    Rect.fromLTRB(8, 8, 184, 56),
  );

  /// Rectángulo hundido, como un campo de texto. Para "pozos": el fondo del
  /// tablero, donde encajan las fichas.
  static const insetWell = KenneySlice(
    '$_dir/input_rectangle.png',
    Rect.fromLTRB(8, 8, 184, 56),
  );

  /// Igual que [insetWell] pero solo el contorno.
  static const insetWellOutline = KenneySlice(
    '$_dir/input_outline_rectangle.png',
    Rect.fromLTRB(8, 8, 184, 56),
  );

  // --- Cuadrados (64x64) ---

  /// Botón cuadrado con bisel. Para acciones compactas de una sola ficha.
  static const primarySquare = KenneySlice(
    '$_dir/button_square_depth_flat.png',
    Rect.fromLTRB(8, 8, 56, 55),
  );

  /// Cuadrado plano, sin bisel. Para celdas de tablero y casillas.
  static const flatSquare = KenneySlice(
    '$_dir/button_square_flat.png',
    Rect.fromLTRB(8, 8, 56, 56),
  );

  /// Cuadrado solo con contorno.
  static const outlineSquare = KenneySlice(
    '$_dir/button_square_border.png',
    Rect.fromLTRB(8, 8, 56, 56),
  );

  // --- Sueltos (no se estiran: se usan a tamaño fijo) ---

  static const iconCheck = '$_dir/icon_checkmark.png';
  static const iconCross = '$_dir/icon_cross.png';
  static const iconPlayLight = '$_dir/icon_play_light.png';
  static const iconPlayDark = '$_dir/icon_play_dark.png';
  static const iconArrowUpLight = '$_dir/icon_arrow_up_light.png';
  static const iconArrowUpDark = '$_dir/icon_arrow_up_dark.png';
  static const iconRepeat = '$_dir/icon_repeat_light.png';
  /// Estrella **gris a propósito**: es la máscara de sombreado que se tinta con
  /// el color que corresponda (ver [KenneyIcon.tint]). Las variantes de color
  /// del pack no sirven para esto, y además el pack no trae bronce: las
  /// estrellas de color son azul, verde, gris, rojo y amarillo, así que un
  /// podio oro/plata/bronce solo se puede armar tintando.
  static const star = '$_dir/star.png';

  /// Contorno de estrella para las pendientes. Ya es gris en todas las
  /// variantes del pack (el contorno de Kenney es neutro), así que se usa sin
  /// tintar.
  static const starOutline = '$_dir/star_outline.png';
  static const divider = '$_dir/divider.png';

  static const arrowEast = '$_dir/arrow_basic_e.png';
  static const arrowWest = '$_dir/arrow_basic_w.png';
  static const arrowNorth = '$_dir/arrow_basic_n.png';
  static const arrowSouth = '$_dir/arrow_basic_s.png';
}

/// Colores de texto para poner **encima** de un sprite de Kenney.
///
/// No salen de `AppColors` a propósito. Los sprites del pack tienen un solo
/// aspecto (no siguen el tema claro/oscuro de la app) y son claros, así que el
/// texto que va arriba tiene que ser oscuro siempre. Si se usara
/// `AppColors.textPrimary`, en tema oscuro —donde es casi blanco— el texto
/// quedaría ilegible sobre el panel.
abstract final class KenneyInk {
  /// Títulos y valores.
  static const Color primary = Color(0xFF1E293B);

  /// Texto secundario. 4.9:1 sobre el gris del sprite (AA).
  static const Color secondary = Color(0xFF5B6B83);

  /// Líneas y divisores sobre el panel. En vez de `AppColors.emptyTile`, que en
  /// tema oscuro es casi del color del panel y desaparecería.
  static const Color line = Color(0xFFCBD5E1);
}

/// Fondo de la app: el "Layered arcade background" del rediseño.
///
/// Se monta **una sola vez**, envolviendo la app desde `MaterialApp.builder`
/// (ver `main.dart`), y no por pantalla. Así todas comparten el mismo fondo y el
/// degradado no se reinicia al navegar: es un fondo fijo de arcade, no algo que
/// viaje con cada ruta. Por eso los `Scaffold` van con el fondo transparente.
///
/// Son cuatro capas, de abajo hacia arriba:
///
/// 1. El degradado vertical ([AppTheme.backdropTop] y compañía).
/// 2. La grilla modular, que dibuja [_GrillaModularPainter].
/// 3. Los dos glows de [_AtmosferaPainter].
/// 4. El velo de legibilidad, que oscurece los extremos.
///
/// **Antes esto era una baldosa repetida** de [KenneySlices.flatSquare]. Se
/// cambió por capas: el pack no trae ninguna textura repetible —`Preview.png` y
/// `Sample.png` de su raíz son collages de documentación, no patrones— y el
/// cuadrado plano tileado se leía como una grilla de botones, no como un fondo.
class GameBackground extends StatelessWidget {
  const GameBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        // Color de base: es el respaldo mientras pinta el degradado y lo que se
        // ve por detrás de todo.
        color: AppTheme.gameBackground,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.backdropTop,
            AppTheme.backdropMiddle,
            AppTheme.backdropBottom,
          ],
          stops: [0, 0.52, 1],
        ),
      ),
      child: Stack(
        // `passthrough` para que el contenido de la app reciba las constraints
        // de pantalla completa tal cual, sin que el Stack las relaje.
        fit: StackFit.passthrough,
        children: [
          // Las tres capas decorativas van con `IgnorePointer`: son fondo, y
          // sin esto se comerían los toques que sí tienen que llegar al
          // contenido de arriba.
          const Positioned.fill(
            child: IgnorePointer(child: CustomPaint(painter: _Grilla())),
          ),
          const Positioned.fill(
            child: IgnorePointer(child: CustomPaint(painter: _Atmosfera())),
          ),
          const Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppTheme.veilTop,
                      Colors.transparent,
                      AppTheme.veilBottom,
                    ],
                    stops: [0, 0.45, 1],
                  ),
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

/// La grilla modular del fondo, una línea cada [AppTheme.gridStep] píxeles.
///
/// Va con `CustomPaint` y no con una `Column`/`Row` de `Divider`s porque en una
/// pantalla alta son ~40 líneas: como widgets sería un árbol de decenas de
/// elementos para algo que es puro dibujo.
class _Grilla extends CustomPainter {
  const _Grilla();

  @override
  void paint(Canvas canvas, Size size) {
    final paso = AppTheme.gridStep;
    final normal = Paint()
      ..color = AppTheme.gridLine
      ..strokeWidth = 1;
    final acento = Paint()
      ..color = AppTheme.gridLineAccent
      ..strokeWidth = 1;

    // Se cuenta con enteros en vez de acumular `x += paso`: con doubles, el
    // error de redondeo corre las líneas y el `% 4` del acento deja de caer
    // donde tiene que caer.
    for (var i = 0; i * paso <= size.width; i++) {
      final x = i * paso;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        i % 4 == 0 ? acento : normal,
      );
    }
    for (var i = 0; i * paso <= size.height; i++) {
      final y = i * paso;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        i % 4 == 0 ? acento : normal,
      );
    }
  }

  @override
  bool shouldRepaint(_Grilla oldDelegate) => false;
}

/// Los dos glows del fondo ("atmosphere" en el frame).
///
/// Se pintan como `RadialGradient` en un `CustomPainter` en vez de posicionar
/// dos `Container` con `Align`/`FractionallySizedBox`: el glow es un círculo que
/// **sangra** por los bordes de la pantalla, y expresarlo como layout obliga a
/// pelear con `AspectRatio` contra constraints de pantalla completa.
class _Atmosfera extends CustomPainter {
  const _Atmosfera();

  @override
  void paint(Canvas canvas, Size size) {
    // Las posiciones y los tamaños salen del frame (400x844) llevados a
    // fracciones, para que escalen con cualquier pantalla en vez de quedar
    // clavados en píxeles de un mockup.
    _glow(
      canvas,
      size,
      centro: const Offset(0.25, 0.07),
      diametro: 1.05,
      color: AppTheme.backdropGlowUpper,
      alfa: 0.20,
    );
    _glow(
      canvas,
      size,
      centro: const Offset(0.85, 0.81),
      diametro: 0.90,
      color: AppTheme.backdropGlowLower,
      alfa: 0.16,
    );
  }

  void _glow(
    Canvas canvas,
    Size size, {
    required Offset centro,
    required double diametro,
    required Color color,
    required double alfa,
  }) {
    final radio = size.width * diametro / 2;
    final punto = Offset(size.width * centro.dx, size.height * centro.dy);
    final rect = Rect.fromCircle(center: punto, radius: radio);

    canvas.drawCircle(
      punto,
      radio,
      Paint()
        ..shader = RadialGradient(
          colors: [color.withValues(alpha: alfa), color.withValues(alpha: 0)],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_Atmosfera oldDelegate) => false;
}

/// Superficie 9-slice: pinta [slice] de fondo y encima coloca [child].
///
/// Sirve para reemplazar los `Container(decoration: BoxDecoration(...))` que
/// hoy hacen de tarjeta, panel o pozo. Se ajusta al tamaño de [child] más
/// [padding]; ojo con dejarlo más chico que los márgenes del sprite (16px en
/// los rectangulares, 16px en los cuadrados), porque ahí las esquinas se
/// pisarían entre sí y el borde se vería aplastado.
class KenneySurface extends StatelessWidget {
  const KenneySurface({
    super.key,
    required this.slice,
    this.padding = EdgeInsets.zero,
    this.tint,
    this.child,
  });

  final KenneySlice slice;
  final EdgeInsetsGeometry padding;

  /// Recolorea el sprite (ver [KenneySlice.decoration]).
  final Color? tint;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: slice.decoration(tint: tint),
      child: Padding(padding: padding, child: child),
    );
  }
}

/// Diálogo con superficie 9-slice de Kenney.
///
/// Reemplaza a `AlertDialog`, que no deja envolver título, contenido y acciones
/// en un mismo fondo. A cambio hay que reponer a mano lo que el `AlertDialog`
/// hacía gratis, y lo que importa es [maxWidth]: `Dialog` no acota el ancho, así
/// que el contenido se estira hasta los bordes de la pantalla. Con un hijo
/// cuadrado adentro (la foto del Desafío Diario lo es, por `AspectRatio`) eso da
/// un cuadrado gigante que se sale de la pantalla por abajo.
class KenneyDialog extends StatelessWidget {
  const KenneyDialog({
    super.key,
    required this.child,
    this.slice = KenneySlices.flatPanel,
    this.padding = const EdgeInsets.fromLTRB(20, 20, 20, 24),
    this.maxWidth = 340,
  });

  final Widget child;
  final KenneySlice slice;
  final EdgeInsetsGeometry padding;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      // El fondo y la sombra los pone el sprite, no el Material.
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: KenneySurface(slice: slice, padding: padding, child: child),
      ),
    );
  }
}

/// Botón con fondo 9-slice.
///
/// Conserva el `InkWell` (en vez de un `GestureDetector`) para no perder el
/// ripple, el foco por teclado ni la semántica de botón. Por eso el fondo va en
/// un `DecoratedBox` *por fuera* del `Material` transparente: así la tinta se
/// pinta arriba del sprite en vez de taparlo.
///
/// Ojo: los tests tocan los botones por `find.text(...)` o `find.byIcon(...)`,
/// así que el [child] tiene que seguir llevando la misma etiqueta o el mismo
/// ícono que antes.
class KenneyButton extends StatelessWidget {
  const KenneyButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.slice = KenneySlices.primaryButton,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    this.tint,
  });

  /// `null` deja el botón deshabilitado (y atenuado).
  final VoidCallback? onPressed;
  final Widget child;
  final KenneySlice slice;
  final EdgeInsetsGeometry padding;

  /// Recolorea el sprite (ver [KenneySlice.decoration]).
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onPressed == null ? 0.45 : 1,
      child: DecoratedBox(
        decoration: slice.decoration(tint: tint),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            child: Padding(
              padding: padding,
              // `Center` es seguro acá: con constraints sin acotar se ajusta al
              // hijo en vez de intentar llenar el espacio infinito.
              child: Center(child: child),
            ),
          ),
        ),
      ),
    );
  }
}

/// Ícono de Kenney a tamaño fijo.
///
/// Los PNG sueltos del pack (íconos, flechas, estrellas) vienen en una grilla de
/// 32 o 64 px y no están pensados para estirarse: se dibujan a [size] y listo.
/// No llevan `centerSlice`.
///
/// [tint] recolorea el sprite igual que en [KenneySlice.decoration]: con
/// `BlendMode.modulate` sobre un sprite **gris**, que es un mapa de sombreado.
/// Sobre un sprite ya coloreado el resultado sale embarrado, así que si hay que
/// tintarlo, hay que copiar la variante gris del pack (ver [KenneySlices.star]).
class KenneyIcon extends StatelessWidget {
  const KenneyIcon(
    this.asset, {
    super.key,
    this.size = 24,
    this.tint,
    this.semanticLabel,
  });

  final String asset;
  final double size;
  final Color? tint;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      asset,
      width: size,
      height: size,
      // `modulate` y no `srcIn`: `srcIn` pinta el ícono de un color plano y se
      // come el sombreado (el brillo, la cara y la sombra del sprite).
      color: tint,
      colorBlendMode: tint == null ? null : BlendMode.modulate,
      semanticLabel: semanticLabel,
    );
  }
}
