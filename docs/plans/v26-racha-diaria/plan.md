# Spec & Implementation Plan: Racha Diaria + Escudo Protector (Versión 26)

## 1. Objective
Convertir el **Desafío Diario** en un hábito recurrente estilo *Wordle / Duolingo* incorporando un sistema de **Racha Diaria (*Daily Streak*)** con:
- Conteo automático de días UTC consecutivos completados (`rachaActual` y `mejorRacha`).
- **Bonus escalonado de monedas** al completar el Desafío Diario según la racha vigente.
- **Escudo Protector / Reparación de Racha (*Streak Repair*):** Cuando el jugador saltea exactamente **1 día** (jugó anteayer pero no ayer), permitirle recuperar su racha antes o al jugar hoy gastando monedas (`50 🪙`) o viendo un anuncio bonificado.
- Visualización de la racha en el menú principal (`HomeScreen`), en el diálogo de victoria diaria (`DailyVictoryDialog`), en los resultados del día (`DailyResultsDialog`) y en el texto compartido al portapapeles (`🔥`).

## 2. Tech Stack & Commands
- **Framework:** Flutter / Dart `^3.12.1`
- **Persistencia local:** `shared_preferences: ^2.5.5`
- **Monetización / Ads:** `google_mobile_ads: ^9.2.0` (`AdMobService.mostrarBonificado`)
- **Comandos de verificación:**
  - Analizar código: `flutter analyze`
  - Ejecutar tests focalizados: `flutter test test/daily_challenge_service_test.dart`
  - Ejecutar suite completa: `flutter test`
  - Regenerar localizaciones: `flutter gen-l10n` (o `flutter pub get`)

## 3. Architecture & Data Model Decisions

### 3.1. Cálculo de fechas UTC puras en `DailyChallengeService`
- Actualmente `DailyChallengeService.semillaDe(DateTime)` devuelve un entero `YYYYMMDD` en UTC.
- Para saber con exactitud matemática la distancia en días entre dos semillas (`YYYYMMDD`) cruzando fines de mes, años bisiestos o fin de año, agregaremos:
  - `DateTime fechaDeSemilla(int semilla)` → reconstruye `DateTime.utc(year, month, day)`.
  - `int diasEntreSemillas(int semillaAnterior, int semillaPosterior)` → `fechaDeSemilla(semillaPosterior).difference(fechaDeSemilla(semillaAnterior)).inDays`.
- **Reglas de transición al evaluar/completar el día `semillaHoy`:**
  - Si `ultimoDia == null`: racha arranca en `1` al ganar hoy.
  - Si `diasEntreSemillas(ultimoDia, semillaHoy) == 0`: ya jugó hoy, mantiene `rachaActual`.
  - Si `diasEntreSemillas(ultimoDia, semillaHoy) == 1`: jugó ayer → al ganar hoy, `rachaActual = rachaGuardada + 1`.
  - Si `diasEntreSemillas(ultimoDia, semillaHoy) == 2`: **Racha en riesgo (salteó 1 solo día, ayer)**.
    - Puede **reparar la racha** pagando `CoinsService.costoEscudoRacha` (`50 🪙`) o viendo un anuncio bonificado, lo que adelanta virtualmente la continuidad para que al ganar hoy su racha continúe en `rachaGuardada + 1` en vez de reiniciarse a `1`.
  - Si `diasEntreSemillas(ultimoDia, semillaHoy) > 2`: la racha expiró y vuelve a `0` (o `1` al completar hoy), pero `mejorRacha` se conserva siempre.

### 3.2. Economía de Monedas en `CoinsService`
- `recompensaDiario = 25` (base actual intacta).
- `costoEscudoRacha = 50` (5 veces el costo de deshacer, accesible pero valioso).
- `bonusRachaDiaria(int racha)`:
  - Otorga `+5 🪙` adicionales por cada día extra de racha a partir del día 2, con un tope de `+25 🪙` de bonus (es decir, desde el día 6 en adelante gana `25 base + 25 bonus = 50 🪙`).
  - Fórmula pura: `((racha - 1).clamp(0, 5)) * 5`.

### 3.3. Experiencia en UI (`HomeScreen`, `DailyVictoryDialog`, `DailyResultsDialog`)
- **`HomeScreen`:**
  - El botón del Desafío Diario muestra la racha vigente en el subtítulo cuando el jugador tiene racha activa (`🔥 X días`) o avisa si tiene una racha reparable de ayer.
  - Si el jugador entra al Desafío Diario teniendo una racha de `>= 1` en riesgo (`dias == 2`), antes de iniciar o al ganar puede activar el **Escudo de Racha** (`50 🪙` o anuncio bonificado) mediante un diálogo ligero con estilo `KenneyDialog`.
- **`DailyVictoryDialog` y `GameScreen`:**
  - Muestra la fila de **Racha** (`🔥 X días` + récord si lo superó) y el desglose/total de monedas ganadas (`+25` base + bonus de racha).
- **`DailyResultsDialog`:**
  - Muestra una píldora/resumen con la racha actual y la mejor racha histórica del jugador.
  - El texto copiado al portapapeles (`dailyShareText` / `dailyShareTextWithStreak`) incluye `🔥 X` cuando el jugador tiene racha activa.

## 4. Boundaries
- **Always do:** Mantener compatibilidad total con los datos ya guardados en `SharedPreferences` de usuarios en `v3.2.4+25` (si un usuario jugó ayer en v25 y actualiza hoy a v26, su `_claveUltimoDia` existente debe reconocerse como `racha = 1` para pasar a `2` al ganar hoy). Correr `flutter analyze` y `flutter test` en cada slice.
- **Ask first:** Cualquier cambio en reglas de Firestore o dependencias de `pubspec.yaml` (no se requieren para esta versión).
- **Never do:** Usar `DateTime.now()` directo dentro de la lógica de racha sin pasar por `DailyChallengeService.reloj()`, para garantizar que todos los cruces de medianoche y rachas sean 100% testeables en unit/widget tests.

## 5. Dependency Graph & Vertical Slices

```
Slice 1: Motor de Racha + Economía (DailyChallengeService + CoinsService + Unit Tests)
    │
    ▼
Slice 2: Localizaciones ES/EN + Victoria Diaria y Compartir con Racha (l10n + DailyVictoryDialog + DailyResultsDialog + GameScreen)
    │
    ▼
Slice 3: Visibilidad en HomeScreen + Diálogo de Escudo Protector (50 🪙 / AdMob) + Widget Tests + Bump v3.3.0+26
```

## 6. Risks and Mitigations
| Risk | Impact | Mitigation |
|---|---|---|
| Usuario que actualiza desde v25 ya tenía `_claveUltimoDia` pero no `_claveRachaActual` | Medio | Si `_claveUltimoDia` existe y `_claveRachaActual` es `null`, inferir base `1` para no perder el día que ya jugó en v25. |
| Fallo de carga de AdMob cuando el usuario elige reparar racha con video | Bajo | Reutilizar el patrón de `GameScreen`: si `AdMobService.mostrarBonificado` falla, mostrar `SnackBar` con `adNotReady` y conservar la opción de pagar con monedas o continuar sin escudo. |
| Romper tests existentes de `daily_challenge_button_test.dart` o `game_screen_daily_test.dart` | Medio | Mantener los textos base o actualizar las aserciones verificando cada test tras cada slice. |

