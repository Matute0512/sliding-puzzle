import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import '../services/coins_service.dart';
import '../services/skin_service.dart';
import '../services/sound_service.dart';
import '../theme/app_theme.dart';
import '../theme/kenney_ui.dart';
import 'coins_pill.dart';

/// Diálogo modal de la Tienda de Fichas (Tile Skins).
///
/// Permite al jugador previsualizar, comprar y equipar diferentes temas
/// de color arcade para las fichas del tablero utilizando sus monedas.
class SkinsDialog extends StatelessWidget {
  const SkinsDialog({super.key});

  /// Muestra el modal de la tienda en pantalla.
  static Future<void> mostrar(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => const SkinsDialog(),
    );
  }

  String _nombreSkin(AppLocalizations l10n, String id) => switch (id) {
    'classic' => l10n.skinClassic,
    'emerald' => l10n.skinEmerald,
    'crimson' => l10n.skinCrimson,
    'cyber' => l10n.skinCyber,
    'amber' => l10n.skinAmber,
    _ => id,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return KenneyDialog(
      maxWidth: 360,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Cabecera: Título arcade y píldora de saldo de monedas
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.skinsShopTitle.toUpperCase(),
                style: const TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: KenneyInk.primary,
                  letterSpacing: 0.5,
                ),
              ),
              const CoinsPill(esInteractivo: false),
            ],
          ),
          const SizedBox(height: 16),

          // Listado de skins disponibles
          Flexible(
            child: SingleChildScrollView(
              child: AnimatedBuilder(
                animation: Listenable.merge([
                  SkinService.skinEquipadaListenable,
                  SkinService.skinsDesbloqueadasListenable,
                  CoinsService.saldoListenable,
                ]),
                builder: (context, _) {
                  final equipadaId = SkinService.skinEquipadaListenable.value;
                  final desbloqueadas =
                      SkinService.skinsDesbloqueadasListenable.value;
                  final saldo = CoinsService.saldo;

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: SkinService.skinsDisponibles.map((skin) {
                      final estaEquipada = skin.id == equipadaId;
                      final estaDesbloqueada = desbloqueadas.contains(skin.id);
                      final puedeComprar = saldo >= skin.precio;

                      return _SkinCard(
                        skin: skin,
                        nombre: _nombreSkin(l10n, skin.id),
                        estaEquipada: estaEquipada,
                        estaDesbloqueada: estaDesbloqueada,
                        puedeComprar: puedeComprar,
                        onEquipar: () async {
                          HapticFeedback.lightImpact();
                          SoundService.reproducirClick();
                          await SkinService.equiparSkin(skin.id);
                        },
                        onComprar: () async {
                          if (!puedeComprar) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(l10n.skinInsufficientCoins),
                                duration: const Duration(seconds: 2),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            return;
                          }
                          HapticFeedback.mediumImpact();
                          SoundService.reproducirVictoria();
                          await SkinService.comprarSkin(skin.id);
                        },
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Botón de cierre
          SizedBox(
            width: double.infinity,
            child: KenneyButton(
              slice: KenneySlices.outlineButton,
              padding: const EdgeInsets.symmetric(vertical: 12),
              onPressed: () {
                SoundService.reproducirClick();
                Navigator.of(context).pop();
              },
              child: Text(
                l10n.cancel.toUpperCase(),
                style: const TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: KenneyInk.secondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SkinCard extends StatelessWidget {
  final TileSkin skin;
  final String nombre;
  final bool estaEquipada;
  final bool estaDesbloqueada;
  final bool puedeComprar;
  final VoidCallback onEquipar;
  final VoidCallback onComprar;

  const _SkinCard({
    required this.skin,
    required this.nombre,
    required this.estaEquipada,
    required this.estaDesbloqueada,
    required this.puedeComprar,
    required this.onEquipar,
    required this.onComprar,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: estaEquipada
            ? skin.colorFicha.withValues(alpha: 0.12)
            : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: estaEquipada
              ? skin.colorAcento
              : const Color(0xFFCBD5E1),
          width: estaEquipada ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        children: [
          // Vista previa 3D en miniatura de la ficha
          Container(
            width: 40,
            height: 40,
            decoration: KenneySlices.primarySquare
                .decoration(tint: skin.colorFicha)
                .copyWith(
                  boxShadow: [
                    BoxShadow(
                      color: skin.colorSombra,
                      offset: const Offset(0, 3),
                      blurRadius: 0,
                    ),
                  ],
                ),
            alignment: Alignment.center,
            child: const Text(
              '7',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Nombre de la skin
          Expanded(
            child: Text(
              nombre,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 12,
                fontWeight: estaEquipada ? FontWeight.bold : FontWeight.w600,
                color: estaEquipada ? skin.colorFicha : KenneyInk.primary,
              ),
            ),
          ),

          // Acción (Equipada / Equipar / Comprar)
          if (estaEquipada)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: skin.colorFicha,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check, size: 14, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(
                    l10n.skinEquipped,
                    style: const TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            )
          else if (estaDesbloqueada)
            KenneyButton(
              slice: KenneySlices.outlineButton,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              onPressed: onEquipar,
              child: Text(
                l10n.skinEquip,
                style: const TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: KenneyInk.primary,
                ),
              ),
            )
          else
            KenneyButton(
              slice: KenneySlices.primaryButton,
              tint: puedeComprar ? const Color(0xFFF59E0B) : const Color(0xFF94A3B8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              onPressed: onComprar,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.monetization_on_rounded,
                    size: 13,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    '${skin.precio}',
                    style: const TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
