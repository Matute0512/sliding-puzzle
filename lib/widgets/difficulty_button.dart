import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../logic/dificultad.dart';
import '../theme/app_theme.dart';
import 'arcade_button.dart';

/// Botón de una dificultad de la partida libre.
///
/// Resuelve sola el color, el ícono y los textos a partir de [dificultad], así
/// que la pantalla de inicio solo tiene que preocuparse por el `onTap`. La
/// presentación vive acá y no en el enum a propósito: `Dificultad` es dominio y
/// no debería saber de `Color` ni de `IconData`, igual que `AppTheme.podiumColor`
/// traduce un puesto del ranking a un color sin que el ranking lo sepa.
class DifficultyButton extends StatelessWidget {
  const DifficultyButton({
    super.key,
    required this.dificultad,
    required this.onTap,
  });

  final Dificultad dificultad;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final (color, icono) = _estilo(dificultad);
    final tablero = l10n.boardSize(dificultad.tamano);

    return ArcadeButton(
      onTap: onTap,
      tint: color,
      icono: icono,
      titulo: _titulo(l10n, dificultad),
      subtitulo: tablero,
      semantica: '${_titulo(l10n, dificultad)}. $tablero',
    );
  }
}

/// Color e ícono de cada dificultad.
///
/// Los tres primeros son los del frame. [Dificultad.experto] todavía no tiene
/// botón (ver `Dificultad.jugables`), pero el `switch` tiene que ser exhaustivo,
/// así que lleva el violeta provisional de `AppTheme`.
(Color, IconData) _estilo(Dificultad dificultad) => switch (dificultad) {
      Dificultad.facil => (AppTheme.difficultyEasy, Icons.auto_awesome_rounded),
      Dificultad.medio => (AppTheme.difficultyMedium, Icons.bolt_rounded),
      Dificultad.dificil => (
        AppTheme.difficultyHard,
        Icons.local_fire_department_rounded,
      ),
      Dificultad.experto => (
        AppTheme.difficultyExpert,
        Icons.workspace_premium_rounded,
      ),
    };

String _titulo(AppLocalizations l10n, Dificultad dificultad) =>
    switch (dificultad) {
      Dificultad.facil => l10n.difficultyEasy,
      Dificultad.medio => l10n.difficultyMedium,
      Dificultad.dificil => l10n.difficultyHard,
      Dificultad.experto => l10n.difficultyExpert,
    };
