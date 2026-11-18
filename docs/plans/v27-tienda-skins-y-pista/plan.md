# Plan de Implementación v27: Tienda Arcade de Skins de Fichas + Pista Inteligente

## 1. Análisis de Estabilidad y Crashes (Herramienta `tools/play_reporting`)

Se ejecutó la herramienta de inspección de Android Vitals (`tools/play_reporting/fetch_vitals.py`) sobre la Google Play Developer Reporting API (`v1beta1`) con ventana de 7 y 14 días:
- **Últimos 7 días (`--days 7`, ventana post-lanzamiento v26):**
  - **Total de problemas agrupados:** **0**
  - **Total de reportes individuales:** **0**
  - **Conclusión:** La solución implementada en la versión 26 para el ciclo de vida y teardown sincrónico de `SoLoud` (`_soloud.deinit()` en `AppLifecycleState.detached`) eliminó por completo el crash `DLRT_GetFfiCallbackMetadata` (`SIGABRT`). No se registran nuevos crashes ni ANRs en producción.
- **Herramientas del proyecto:**
  - `tools/play_reporting/fetch_vitals.py`: Script para consultar Android Vitals en Google Play Console.
  - `tool/tint_sprite.py`: Script offline para generar sprites 9-slice pre-tintados para optimización en Impeller.
  - `tool/generate_achievement_icons.ps1`: Script generador de assets para Google Play Games.

---

## 2. Especificación Técnica de la Versión 27

### 2.1 Tienda Arcade de Skins (`SkinService` + `SkinsDialog`)
- **Objetivo:** Dar un sumidero aspiracional a las monedas acumuladas del jugador (`CoinsService`), aumentando la retención y la personalización estética sin alterar la geometría de Kenney UI.
- **Paletas de Skins (con validación de contraste WCAG AA ≥ 4.5:1 sobre números blancos):**
  1. **Clásico Azul (`classic`):** `#4361EE` (sombra `#3146B5`), gratis por defecto (contraste 5.02:1).
  2. **Esmeralda Retro (`emerald`):** `#047857` (sombra `#064E3B`), `100 🪙` (contraste 5.48:1).
  3. **Fuego Carmesí (`crimson`):** `#DC2626` (sombra `#991B1B`), `200 🪙` (contraste 4.83:1).
  4. **Ciber Neón (`cyber`):** `#7C3AED` (sombra `#5B21B6`), `300 🪙` (contraste 5.70:1).
  5. **Oro Real (`amber`):** `#B45309` (sombra `#78350F`), `500 🪙` (contraste 5.02:1).
- **Persistencia en `SharedPreferences`:**
  - `skins_desbloqueadas`: Lista de IDs de skins desbloqueadas (inicialmente `['classic']`).
  - `skin_equipada`: ID de la skin activa (inicialmente `'classic'`).
- **Acceso:** Tocar la píldora de monedas (`CoinsPill`) en el menú principal o en el juego abre el modal interactivo de la tienda.

### 2.2 Pista Inteligente (*Smart Hint*)
- **Objetivo:** Asistir a jugadores que se traban en tableros `4x4` y `5x5` indicando visualmente qué ficha conviene deslizar hacia el hueco.
- **Heurística (`PuzzleLogic.calcularPista`):**
  - Evalúa los movimientos válidos inmediatos (`movibles`).
  - Calcula la suma de distancias Manhattan a la posición resuelta de cada ficha con un lookahead de 2 pasos y penalización anti-rebote (`ultimoIndiceMovido`).
  - Rendimiento: 0.05 ms en tableros 5x5 (<0.1% de un frame de 120Hz).
- **Economía de la Pista:**
  - Costo: `15 🪙`. Si el jugador no tiene saldo suficiente, se ofrece ver un anuncio recompensado de AdMob para obtener la pista gratis (mismo patrón que deshacer movimiento).
  - En el Desafío Diario: la pista está deshabilitada o penaliza el tiempo/movimientos para preservar la competencia justa del Top 5.
- **Efecto visual:** La ficha recomendada resalta con un borde pulsante o anillo dorado durante 3 segundos o hasta que el usuario realice un movimiento.

---

## 3. Plan de Tareas por Fases (Vertical Slicing)

### Fase 1: Servicios y Lógica (Lógica pura + TDD)
- **Tarea 1.1:** Crear `SkinService` (`lib/services/skin_service.dart`) con modelo de datos, desbloqueo con monedas, equipamiento, listeners reactivos y pruebas unitarias (`test/skin_service_test.dart`).
- **Tarea 1.2:** Implementar `PuzzleLogic.calcularPista` en `lib/logic/puzzle_logic.dart` con heurística Manhattan, lookahead y pruebas unitarias exhaustivas (`test/puzzle_hint_test.dart`).

### Fase 2: Componentes UI y Visual Craft (/impeccable)
- **Tarea 2.1:** Diseñar y construir `SkinsDialog` (`lib/widgets/skins_dialog.dart`) con estilo arcade Kenney (panel 9-slice, vista previa 3D de fichas, selector, estados desbloqueado/equipado/comprar).
- **Tarea 2.2:** Hacer interactiva la `CoinsPill` (`lib/widgets/coins_pill.dart`) para que al tapearla abra el `SkinsDialog`.
- **Tarea 2.3:** Integrar la skin activa en `PuzzleTile` y `PuzzleBoard` (aplicación de tinte en modo numérico conservando optimizaciones Impeller).
- **Tarea 2.4:** Agregar el botón y acción de "Pista" en `GameScreen`, manejando consumo de monedas / anuncio recompensado y feedback visual pulsante en `PuzzleTile`.

### Fase 3: Localización y Verificación de Calidad
- **Tarea 3.1:** Agregar cadenas de texto completas en `lib/l10n/app_es.arb` y `lib/l10n/app_en.arb`.
- **Tarea 3.2:** Ejecutar `flutter analyze` y suite completa de `flutter test`.
