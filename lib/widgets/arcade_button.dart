import 'package:flutter/material.dart';

import '../theme/kenney_ui.dart';

/// Botón ancho del menú: chip con ícono, título, subtítulo y chevron.
///
/// La forma la pone el sprite 9-slice de Kenney tintado con [tint]. El mismo
/// widget sirve para el verde de "Fácil" y para el violeta del Desafío Diario:
/// el sprite gris es un mapa de sombreado y `modulate` lo recolorea entero, así
/// que un solo asset cubre todos los colores (ver [KenneySlice.decoration]).
///
/// El texto va **oscuro** y no blanco. Sobre estos fondos vivos el blanco falla
/// WCAG AA (~2.5:1 sobre el verde y ~2.2:1 sobre el ámbar), mientras que la
/// tinta oscura da ~7:1 y ~8:1. Es la misma razón que ya documentaba el
/// `DifficultyButton` viejo.
class ArcadeButton extends StatelessWidget {
  const ArcadeButton({
    super.key,
    required this.onTap,
    required this.tint,
    required this.icono,
    required this.titulo,
    required this.subtitulo,
    this.semantica,
  });

  final VoidCallback onTap;

  /// Color que se le aplica al sprite gris (ver [KenneySlice.decoration]).
  final Color tint;

  final IconData icono;
  final String titulo;
  final String subtitulo;

  /// Etiqueta de accesibilidad. Si es `null` se arma con el título y el
  /// subtítulo **sin pasar a mayúsculas**: el texto en pantalla va en versalitas
  /// por estilo, y un lector de pantalla que recibe todo en mayúsculas puede
  /// deletrearlo letra por letra.
  final String? semantica;

  /// Alto del botón, del frame.
  static const double _alto = 64;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semantica ?? '$titulo. $subtitulo',
      child: SizedBox(
        height: _alto,
        child: KenneySurface(
          slice: KenneySlices.primaryButton,
          tint: tint,
          // El `Material` va transparente y por dentro del sprite: así la tinta
          // del `InkWell` se pinta arriba del fondo en vez de taparlo.
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Row(
                  children: [
                    // El ícono es decorativo: la etiqueta útil ya la pone el
                    // `Semantics` de arriba, así que no aporta nada repetirlo.
                    ExcludeSemantics(
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: _chipFondo,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(icono, size: 18, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            titulo.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: _tinta,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            subtitulo,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: _tintaSuave,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: _tintaSuave,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Tinta de los botones: el `#071127` del frame. Casi negro, no blanco, por el
/// contraste (ver la nota de la clase).
const Color _tinta = Color(0xFF071127);

/// Segunda línea y chevron: la misma tinta al 72%, como en el frame.
const Color _tintaSuave = Color(0xB8071127);

/// Fondo del chip del ícono: la misma tinta al 22%, como en el frame.
const Color _chipFondo = Color(0x38071127);
