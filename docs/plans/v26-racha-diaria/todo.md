# Task List: Racha Diaria + Escudo Protector (Versión 26)

## Slice 1: Motor de Racha Diaria y Economía de Monedas (Foundation)

- [x] **Task 1: Implementar cálculo de rachas UTC y escudo en `DailyChallengeService` y bonus en `CoinsService`**
  - **Description:** Agregar en `CoinsService` la constante `costoEscudoRacha = 50` y `bonusRachaDiaria(int racha)`. Agregar en `DailyChallengeService` el modelo `EstadoRachaDiaria` (racha actual, mejor racha, si está en riesgo por haber faltado ayer), funciones puras `fechaDeSemilla` / `diasEntreSemillas`, actualización de racha en `marcarJugado(int semilla)` (manteniendo retrocompatibilidad con v25) y `repararRacha({DateTime? ahora})`.
  - **Acceptance criteria:**
    - [x] `diasEntreSemillas(20260228, 20260301)` devuelve `1` y maneja cambios de mes/año en UTC.
    - [x] Ganar días consecutivos incrementa `rachaActual` y actualiza `mejorRacha`.
    - [x] Si `diasEntreSemillas == 2`, `estadoRacha()` informa `enRiesgo: true` con la racha salvable; si se llama a `repararRacha()`, al ganar hoy la racha continúa en `rachaAnterior + 1`.
    - [x] Si un usuario viene de v25 (tiene `desafio_diario_ultimo_dia` de ayer pero sin clave de racha), se infiere `racha = 1` y pasa a `2` al ganar hoy.
    - [x] `CoinsService.bonusRachaDiaria` devuelve `0` en día 1, `+5` en día 2, hasta `+25` en día 6+.
  - **Verification:**
    - [x] `flutter test test/daily_challenge_service_test.dart test/coins_service_test.dart`
    - [x] `flutter analyze`

## Checkpoint 1: Foundation
- [x] Todos los tests unitarios de servicios pasan (`flutter test test/daily_challenge_service_test.dart test/coins_service_test.dart`)
- [x] `flutter analyze` sin errores ni warnings

---

## Slice 2: Localizaciones, Celebración de Victoria Diaria y Resultados Compartibles

- [x] **Task 2: Agregar claves de localización ES/EN y mostrar racha + bonus en `DailyVictoryDialog`, `DailyResultsDialog` y `GameScreen`**
  - **Description:** Añadir en `app_es.arb` y `app_en.arb` las traducciones para la racha diaria, récord de racha, bonus de monedas por racha, diálogo de escudo protector y formato de compartir con `🔥`. Actualizar `GameScreen._mostrarVictoriaDiario` para otorgar `recompensaTotalDiario`, pasar la racha a `DailyVictoryDialog`, y mostrar la racha actual/máxima e incluirla al compartir en `DailyResultsDialog`.
  - **Acceptance criteria:**
    - [x] `DailyVictoryDialog` muestra la fila de racha (`🔥 Xd`) y el total de monedas ganadas (incluyendo bonus por racha si aplica).
    - [x] `DailyResultsDialog` muestra la racha actual y mejor racha del jugador, e incluye la racha en el texto copiado al portapapeles.
    - [x] `test/l10n_test.dart` y `test/widget/game_screen_daily_test.dart` pasan sin errores.
  - **Verification:**
    - [x] `flutter gen-l10n`
    - [x] `flutter test test/l10n_test.dart test/widget/game_screen_daily_test.dart`
    - [x] `flutter analyze`

## Checkpoint 2: Core Daily Flow
- [x] Flujo de victoria diaria y compartir verificado con tests de widget

---

## Slice 3: Estado de Racha en `HomeScreen`, Modal de Escudo Protector y Bump a v26

- [x] **Task 3: Integrar indicador de racha y diálogo de Escudo Protector en `HomeScreen` + incremento de versión a `+26`**
  - **Description:** Actualizar `HomeScreen` para cargar `EstadoRachaDiaria` junto con el estado diario, mostrar la racha activa o en riesgo en el botón del Desafío Diario, y ofrecer antes de entrar a la partida diaria (cuando `enRiesgo == true`) un diálogo `KenneyDialog` para salvar la racha con `50 🪙` (`CoinsService.gastarMonedas`) o viendo un anuncio bonificado (`AdMobService.mostrarRewardedParaDeshacer`), o continuar sin salvarla. Actualizar `pubspec.yaml` a `version: 3.3.0+26` y agregar tests de widget para el botón diario con racha y rescate.
  - **Acceptance criteria:**
    - [x] `HomeScreen` refleja la racha activa o el estado de racha completada hoy.
    - [x] Si el jugador salteó ayer (`enRiesgo == true`), al tocar el Desafío Diario se le ofrece reparar su racha con monedas o anuncio antes de jugar, o continuar reiniciando la racha.
    - [x] `pubspec.yaml` tiene la versión actualizada a `+26`.
    - [x] Suite completa de tests (`flutter test`) y `flutter analyze` en verde.
  - **Verification:**
    - [x] `flutter test test/widget/daily_challenge_button_test.dart`
    - [x] `flutter test`
    - [x] `flutter analyze`

## Checkpoint 3: Complete (Definition of Done)
- [x] `flutter analyze` → No issues found
- [x] `flutter test` → 100% tests passing
- [x] Documentación de la Opción 2 preservada en `docs/ideas/v27-tienda-skins-y-pista.md`
