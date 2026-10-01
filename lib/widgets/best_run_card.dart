import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../logic/duracion.dart';
import '../services/best_run_service.dart';
import '../theme/app_theme.dart';
import 'arcade_panel.dart';

/// Tarjeta "Mejor partida" del menú.
///
/// Va sobre [ArcadePanel] y no sobre un sprite: por dentro es navy profundo, y
/// ahí los sprites de Kenney se aplanan (ver la nota de `ArcadePanel`). Como
/// consecuencia el texto sale de `AppColors`, no de `KenneyInk`.
///
/// Con [marca] en `null` muestra el estado vacío en vez de desaparecer: si la
/// tarjeta se ocultara, el menú se reacomodaría entero la primera vez que el
/// jugador gana algo, y el salto se leería como un error.
///
/// No es tocable a propósito. El frame no le pone chevron ni ningún otro indicio
/// de que lo sea, y los récords completos ya están en el trofeo del header.
class BestRunCard extends StatelessWidget {
  const BestRunCard({super.key, required this.marca});

  final MejorPartida? marca;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final l10n = AppLocalizations.of(context)!;
    final actual = marca;

    return ArcadePanel(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        children: [
          Row(
            children: [
              _BadgeTrofeo(vacio: actual == null),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.bestRun.toUpperCase(),
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      // Sin marca todavía, el hueco va con guiones y no con un
                      // cero: un "00:00" se leería como un récord real.
                      actual == null ? '--:--' : duracionMmSs(actual.tiempoSegundos),
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: colors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              if (actual != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      l10n.bestRunMoves(actual.movimientos).toUpperCase(),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.accentCyan,
                      ),
                    ),
                    const SizedBox(height: 3),
                    // El frame dice "TABLERO 4×4", pero acá se reemplaza por
                    // esta frase a propósito: la tarjeta muestra el récord de un
                    // tablero concreto, y "Récord en 4×4" dice eso mismo **y**
                    // que es una marca a superar, en el mismo renglón. Poner las
                    // dos repetiría el tamaño dos veces.
                    Text(
                      l10n.bestRunRecordOn(actual.tamano).toUpperCase(),
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: colors.textMuted,
                      ),
                    ),
                  ],
                )
              else
                Flexible(
                  child: Text(
                    l10n.bestRunEmpty,
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: colors.textMuted,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          // La barra del frame. Es decorativa: el diseño no le da ningún valor
          // que pueda representar, así que no se inventa uno.
          const _Barra(),
        ],
      ),
    );
  }
}

/// Cuadrado con el trofeo a la izquierda de la tarjeta.
class _BadgeTrofeo extends StatelessWidget {
  const _BadgeTrofeo({required this.vacio});

  /// Sin marca, el trofeo va apagado y en contorno: el ícono lleno y a color
  /// prometería un récord que todavía no existe.
  final bool vacio;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: _badgeFondo,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _badgeBorde),
      ),
      child: Icon(
        vacio ? Icons.emoji_events_outlined : Icons.emoji_events_rounded,
        size: 20,
        color: vacio ? colors.textMuted : AppTheme.accentCyan,
      ),
    );
  }
}

/// Línea fina al pie de la tarjeta, del frame.
class _Barra extends StatelessWidget {
  const _Barra();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 3,
      decoration: BoxDecoration(
        color: _barraColor,
        borderRadius: BorderRadius.circular(99),
      ),
    );
  }
}

/// Fondo y borde del badge del trofeo: el azul del frame con alfa muy baja.
const Color _badgeFondo = Color(0x26536CFF);
const Color _badgeBorde = Color(0x546D8BFF);

/// La barra al pie de la tarjeta.
const Color _barraColor = Color(0xFF15264B);
