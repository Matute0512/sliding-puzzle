import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_info.dart';
import '../l10n/app_localizations.dart';
import '../services/records_service.dart';
import '../services/sound_service.dart';
import '../theme/app_theme.dart';
import '../theme/kenney_ui.dart';

/// Diálogo modal arcade para invitar al usuario a calificar la app en Google Play.
class RatingDialog extends StatelessWidget {
  const RatingDialog({
    super.key,
    required this.onCalificar,
    required this.onAhoraNo,
  });

  final VoidCallback onCalificar;
  final VoidCallback onAhoraNo;

  /// Muestra el modal en pantalla y gestiona la apertura de la tienda o el enfriamiento.
  static Future<void> mostrar(BuildContext context) async {
    var respondioCalificar = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => RatingDialog(
        onCalificar: () {
          respondioCalificar = true;
          Navigator.pop(dialogContext);
        },
        onAhoraNo: () {
          Navigator.pop(dialogContext);
        },
      ),
    );

    if (respondioCalificar) {
      await RecordsService.marcarAppCalificada();
      final uri = Uri.parse(urlPlayStore);
      try {
        final abierto = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        if (!abierto && context.mounted) {
          final l10n = AppLocalizations.of(context);
          if (l10n != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.playStoreError)),
            );
          }
        }
      } catch (_) {
        if (context.mounted) {
          final l10n = AppLocalizations.of(context);
          if (l10n != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.playStoreError)),
            );
          }
        }
      }
    } else {
      // Usuario seleccionó "Ahora no" o cerró tocando fuera / botón atrás.
      await RecordsService.registrarSolicitudRating();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return KenneyDialog(
      maxWidth: 360,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 5 estrellas doradas arcade
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              5,
              (_) => const Padding(
                padding: EdgeInsets.symmetric(horizontal: 2),
                child: Icon(
                  Icons.star_rounded,
                  size: 32,
                  color: Color(0xFFF59E0B),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Título
          Text(
            l10n.rateTitle,
            style: const TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: KenneyInk.primary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),

          // Mensaje
          Text(
            l10n.rateBody,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12.5,
              height: 1.4,
              color: KenneyInk.secondary,
            ),
          ),
          const SizedBox(height: 20),

          // Botón principal: Calificar en Play Store
          SizedBox(
            width: double.infinity,
            child: KenneyButton(
              slice: KenneySlices.primaryButton,
              tint: const Color(0xFFF59E0B),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              onPressed: () {
                HapticFeedback.lightImpact();
                SoundService.reproducirClick();
                onCalificar();
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.star_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      l10n.rateButton.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),

          // Botón secundario: Ahora no
          TextButton(
            onPressed: () {
              SoundService.reproducirClick();
              onAhoraNo();
            },
            child: Text(
              l10n.notNow,
              style: const TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 12,
                color: KenneyInk.secondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
