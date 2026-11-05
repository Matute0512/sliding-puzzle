# Tienda Arcade de Temas de Fichas (Tile Skins) + Pista Inteligente (Versión 27)

## Problem Statement
¿Cómo podríamos darle un propósito aspiracional y continuo al saldo de monedas acumuladas (`CoinsService`) y, al mismo tiempo, ayudar a los jugadores casuales que se bloquean en tableros `4x4` y `5x5` sin saber qué ficha mover?

## Recommended Direction
Implementar en la **Versión 27 (`+27`)** dos nuevos sumideros de economía (*coin sinks*) integrados en la estética arcade actual de Kenney UI:

1. **Tienda Arcade de Skins de Fichas (`SkinService`):**
   - Aprovechar el sistema de tintes sobre sprites 9-slice (`KenneySlices` en `PuzzleTile`) para ofrecer paletas desbloqueables con monedas (ej. *Clásico Azul* gratis, *Esmeralda Retro* `100 🪙`, *Neón Cyberpunk* `200 🪙`, *Fuego Carmesí* `300 🪙`, *Oro Real* `500 🪙`).
   - Hacer interactiva la píldora de monedas (`CoinsPill`) en `HomeScreen` para abrir el modal de colección y equipamiento de skins.
2. **Pista Inteligente (*Smart Hint*) en `GameScreen`:**
   - Agregar una acción que resalte visualmente en el tablero cuál es la siguiente ficha óptima a deslizar (usando distancia Manhattan / paso inverso en `PuzzleLogic`) a cambio de monedas o anuncio bonificado.

## Key Assumptions to Validate
- [ ] Los tintes de las nuevas paletas mantienen contraste WCAG AA legible con los números de `PuzzleTile` tanto en tema claro como oscuro.
- [ ] Una heurística de 1-2 pasos con distancia Manhattan (más desempate anti-retroceso) es instantánea en `5x5` sin bloquear el hilo de UI.
- [ ] Los precios de las skins (`100` a `500 🪙`) equilibran la inflación de monedas introducida por los premios de la Racha Diaria de la v26.

## MVP Scope (Para v27)
- **Incluye:**
  - `lib/services/skin_service.dart` con persistencia en `SharedPreferences` (`skins_desbloqueadas`, `skin_equipada`).
  - 5 paletas de colores predefinidas en `AppTheme`.
  - Modal de tienda/selección accesible desde `CoinsPill`.
  - Resaltado de ficha sugerida en `PuzzleBoard` / `PuzzleTile`.
- **Queda fuera (Not Doing):**
  - Compra de monedas con dinero real (IAP).
  - Skins que cambien la tipografía o geometría 9-slice (todas usan los sprites curados de `assets/ui/kenney/` para no aumentar el tamaño del AAB).
  - Pistas en el Desafío Diario si alteran la equidad competitiva del Top 5 diario.

## Archivos Estimados (9 archivos)
1. `lib/services/skin_service.dart` (Nuevo)
2. `lib/theme/app_theme.dart`
3. `lib/widgets/puzzle_tile.dart`
4. `lib/widgets/puzzle_board.dart`
5. `lib/logic/puzzle_logic.dart`
6. `lib/services/coins_service.dart`
7. `lib/widgets/coins_pill.dart`
8. `lib/screens/home_screen.dart`
9. `lib/l10n/app_es.arb` y `lib/l10n/app_en.arb`

