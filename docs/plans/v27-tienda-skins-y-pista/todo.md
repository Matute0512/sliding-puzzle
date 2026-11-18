# Lista de Tareas v27: Tienda Arcade de Skins + Pista Inteligente

## Fase 1: Servicios y Lógica
- [x] **Tarea 1.1: `SkinService` y persistencia de skins**
  - Crear `lib/services/skin_service.dart` con catálogo de 5 skins (`classic`, `emerald`, `crimson`, `cyber`, `amber`).
  - Métodos `inicializar()`, `desbloquearSkin(id)`, `equiparSkin(id)`, `estaDesbloqueada(id)`.
  - Notificador reactivo `skinEquipadaListenable`.
  - Pruebas unitarias en `test/skin_service_test.dart`.
- [x] **Tarea 1.2: `PuzzleLogic.calcularPista` (Heurística de Pista Inteligente)**
  - Implementar cálculo de distancia Manhattan y evaluación con lookahead de 2 pasos.
  - Soportar `ultimoIndiceMovido` para prevenir rebote cíclico.
  - Pruebas unitarias en `test/puzzle_hint_test.dart` cubriendo tableros 3x3, 4x4 y 5x5.

## Fase 2: Componentes UI y Visual Craft (/impeccable)
- [x] **Tarea 2.1: `SkinsDialog` (Tienda de Skins Arcade)**
  - Crear `lib/widgets/skins_dialog.dart` con estilo Kenney UI (panel navy, marco arcade, lista de skins con mini-fichas 3D).
  - Indicadores de estado: "Equipada", "Usar", o precio "🪙 100".
  - Confirmación de compra con descuento reactivo de monedas.
- [x] **Tarea 2.2: Interactividad en `CoinsPill`**
  - Envolver `CoinsPill` en un detector de gestos con feedback táctil para abrir `SkinsDialog`.
- [x] **Tarea 2.3: Aplicar skin equipada en el tablero**
  - Conectar `PuzzleTile` al `SkinService.skinEquipadaListenable` para tintar los sprites numéricos.
  - Agregar estado `esSugerida` para el resaltado pulsante de la Pista Inteligente.
- [x] **Tarea 2.4: Botón de Pista en `GameScreen`**
  - Agregar botón de bombilla/pista en el HUD del juego.
  - Validar costo (15 monedas) o anuncio recompensado si no alcanza el saldo.
  - Activar el resaltado pulsante temporal de la ficha recomendada.

## Fase 3: Localización y Verificación de Calidad
- [x] **Tarea 3.1: Textos y traducciones**
  - Agregar traducciones en `lib/l10n/app_es.arb` y `lib/l10n/app_en.arb`.
- [x] **Tarea 3.2: Verificación estática y de tests**
  - Ejecutar `flutter analyze` (0 errores / 0 warnings).
  - Ejecutar suite completa con `flutter test` (287/287 tests pasando).
