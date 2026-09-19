import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

/// ⚠️ DIÁLOGO TEMPORAL — reemplazar por la pantalla de resultados del día.
///
/// Cierra el Desafío Diario: muestra el resultado y devuelve al menú. Por ahora
/// no comparte nada ni muestra el ranking del día, que todavía no existe.
///
/// Sigue el patrón de `AliasDialog`: la UI vive en su propio widget y se abre
/// con un `mostrar` estático. El `ConfettiController` llega desde afuera porque
/// es del `State` del juego (se libera con él, no con el diálogo).
class DailyVictoryDialog extends StatelessWidget {
  final int movimientos;
  final int segundos;
  final ConfettiController confetti;

  const DailyVictoryDialog({
    super.key,
    required this.movimientos,
    required this.segundos,
    required this.confetti,
  });

  /// Muestra el diálogo y resuelve cuando el jugador lo cierra.
  static Future<void> mostrar(
    BuildContext context, {
    required int movimientos,
    required int segundos,
    required ConfettiController confetti,
  }) {
    return showDialog<void>(
      context: context,
      // Sin descarte por toque afuera: el diálogo es la única salida al menú,
      // así que no debe poder cerrarse por accidente dejando al jugador en un
      // tablero ya terminado.
      barrierDismissible: false,
      builder: (_) => DailyVictoryDialog(
        movimientos: movimientos,
        segundos: segundos,
        confetti: confetti,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).extension<AppColors>()!;

    return Stack(
      alignment: Alignment.topCenter,
      children: [
        AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            l10n.dailyVictoryTitle,
            style: const TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _FilaResultado(
                icono: Icons.timer,
                label: l10n.time,
                valor: l10n.secondsShort(segundos),
              ),
              const SizedBox(height: 8),
              _FilaResultado(
                icono: Icons.sports_esports,
                label: l10n.moves,
                valor: '$movimientos',
              ),
              const SizedBox(height: 16),
              Text(
                l10n.dailyVictoryBody,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: colors.textSecondary),
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.seedColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                // Solo cierra el diálogo. Quien lo abre se encarga de volver al
                // menú, así el diálogo no necesita saber de navegación.
                onPressed: () => Navigator.pop(context),
                child: Text(
                  l10n.backToMenu,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
        ConfettiWidget(
          confettiController: confetti,
          blastDirectionality: BlastDirectionality.explosive,
          numberOfParticles: 30,
          gravity: 0.3,
          colors: const [
            Color(0xFF4361EE),
            Color(0xFF10B981),
            Color(0xFFF59E0B),
            Color(0xFFEF4444),
            Colors.white,
          ],
        ),
      ],
    );
  }
}

/// Fila "icono + etiqueta + valor" del resultado. Copia local de la que usa el
/// diálogo de victoria clásico: al ser un diálogo temporal no vale la pena
/// acoplarlos, y así borrar este archivo no toca el juego normal.
class _FilaResultado extends StatelessWidget {
  final IconData icono;
  final String label;
  final String valor;

  const _FilaResultado({
    required this.icono,
    required this.label,
    required this.valor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Row(
      children: [
        Icon(icono, size: 20, color: AppTheme.seedColor),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 15, color: colors.textSecondary),
          ),
        ),
        Text(
          valor,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
          ),
        ),
      ],
    );
  }
}
