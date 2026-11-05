# Auditoría y Optimización de Rendimiento — Sliding Puzzle

**Fecha:** 2026-10-22 · **Versión:** 3.0.4+17 · **Entorno validado:** Flutter 3.44.2 (Dart 3.12.2) · **Motor gráfico:** Impeller (Android 15, Motorola Moto G84 5G a 120 Hz) · **Estado:** Cerrado y verificado en dispositivo físico (`--profile`).

---

## 1. Resumen ejecutivo: cuál era el problema real

El proyecto atravesó **tres ciclos de optimización** hasta eliminar por completo las caídas de frames reportadas tanto al deslizar fichas (especialmente en el tablero **5×5** y en el **Desafío Diario** con fotos) como al navegar hacia las pantallas de **Juego**, **Modo Desafío** y **Récords**.

La razón por la que los dos primeros ciclos no alcanzaron por sí solos fue una diferencia arquitectónica fundamental entre **Skia** (el motor clásico asumido en las primeras auditorías) e **Impeller** (el motor por defecto de Flutter 3.44 en Android):

| Aspecto | Skia (supuesto inicial) | Impeller (motor real en Android) |
|---|---|---|
| ¿`RepaintBoundary` evita re-grabar la capa en el hilo UI? | Sí | Sí (`OffsetLayer` retiene el `DisplayList`) |
| ¿Existe un *raster cache* automático de capas en GPU? | Sí: una capa limpia se rasteriza una vez y se reutiliza como textura | **No.** Las `DisplayList` retenidas se vuelven a ejecutar en la GPU en **cada frame** |
| Costo del hilo **Raster (GPU)** por frame | $\approx$ sólo lo que cambió + composición | $\approx$ **toda la escena visible**, aunque las capas no se hayan invalidado |

En un dispositivo con pantalla de **120 Hz** (presupuesto total de **8,33 ms por frame**), aislar el árbol con `RepaintBoundary` alivió al hilo **UI**, pero dejó intacto el cuello de botella del hilo **Raster (GPU)**: en cada frame de los 160 ms del deslizamiento (o de los 450 ms de una transición de ruta), la GPU seguía ejecutando decenas de desenfoques gaussianos (`MaskFilter.blur`), filtros de color en tiempo real (`ColorFilter.mode`), recortes por *stencil* (`ClipRRect` + `ClipRect`), capas fuera de pantalla (`Opacity` / `saveLayer`) y cientos de *quads* 9-slice.

La solución definitiva combinó **contención de invalidaciones y rebuilds en el hilo UI** (Ciclos 1 y 2) con **reducción drástica del costo de rasterización en GPU y horneado manual en texturas `ui.Image`** (Ciclo 3).

---

## 2. Diagnóstico detallado de los 4 problemas y cómo se resolvieron

### 2.1. Fuga de repintado al deslizar y rebuild masivo por jugada (Hilo UI)

#### Cuál era el problema
1. **Escape del `markNeedsPaint` hacia el `SingleChildScrollView`:**
   En `lib/widgets/puzzle_board.dart`, el `RepaintBoundary` del tablero se había colocado inicialmente **adentro** del `LayoutBuilder`. Cuando una ficha se desliza, `AnimatedPositioned` marca `needsLayout` en el `Stack` y el relayout sube hasta su *relayout boundary*: el `LayoutBuilder`. Como Flutter finaliza todo layout llamando a `markNeedsPaint()`, la invalidación de pintado nacía en el `_RenderLayoutBuilder` —**por encima** del `RepaintBoundary` del tablero— y subía por el árbol hasta frenarse recién en el `_RenderSingleChildViewport` del `SingleChildScrollView` de `lib/screens/game_screen.dart`:
   ```text
   [0] RenderStack                 <- anima al deslizar
   [1] RenderRepaintBoundary       <- estaba acá adentro (no frenaba al padre)
   [2] _RenderLayoutBuilder        <- relayout boundary: emite markNeedsPaint() al terminar layout
   [3] RenderPadding
   [4] RenderDecoratedBox          <- pozo del tablero + halo
   ...
   [9] _RenderSingleChildViewport  <- acá recién se frenaba la invalidación
   ```
   Como consecuencia, cada frame del deslizamiento volvía a registrar el HUD, la fila de consigna, el pozo del tablero y la botonera.
2. **Escape por las tarjetas del HUD:**
   Aunque el cronómetro tenía su propio `RepaintBoundary`, las tarjetas de **movimientos** y de **piezas colocadas** (en el Desafío Diario) no tenían capa propia: al incrementar el contador en el frame del toque, su `Text` invalidaba el viewport completo.
3. **Rebuild de toda la pantalla y de las $n^2$ celdas en cada jugada:**
   Tocar una ficha llamaba `setState` en `GameScreen`, reconstruyendo **586 (3×3), 782 (4×4) y 1034 (5×5) elementos**. Aun después de migrar a `ValueNotifier`, `PuzzleBoard` seguía recreando desde cero los 25 sockets y las 24 instancias de `PuzzleTile` (~690 elementos en 5×5) con *closures* nuevas por índice en cada movimiento, cuando en realidad sólo cambian entre 3 y 5 fichas vecinas al hueco.

#### Cómo se resolvió
- **`RepaintBoundary` por fuera del `LayoutBuilder`** en `lib/widgets/puzzle_board.dart`:
  `RepaintBoundary(child: LayoutBuilder(...))` garantiza que tanto el relayout del `LayoutBuilder` como el pintado del `Stack` compartan exactamente la misma frontera de repintado.
- **Estado reactivo y HUD sellado** en `lib/screens/game_screen.dart`:
  `_tablero`, `_movimientos`, `_segundos` y `_record` usan `ValueNotifier` + `ValueListenableBuilder`, cada uno envuelto en su propio `RepaintBoundary`. Ninguna jugada ni lectura de disco dispara `setState` en `GameScreen`.
- **Memoización de instancias de `PuzzleTile` por `(numero, activa)`** en `lib/widgets/puzzle_board.dart`:
  `PuzzleBoard` pasó a `StatefulWidget`, indexa los callbacks por el **número de la ficha** (`_onTapNumero`, `_deslizarNumero`) en lugar de su posición en la lista, y conserva en caché el widget `PuzzleTile` de cada ficha mientras su estado `activa` y el tamaño de celda no cambien. Al mover una ficha en 5×5, las ~20 fichas que no cambiaron de estado reutilizan exactamente la misma instancia de widget y Flutter corta el rebuild de sus subárboles en $O(1)$.

---

### 2.2. Caída de fluidez en el tablero 5×5 (Costo GPU $O(n^2)$ bajo Impeller)

#### Cuál era el problema
Con la contención del hilo UI resuelta, el tablero 3×3 y 4×4 iba fluido a 120 Hz, pero el **5×5** seguía perdiendo frames durante los 160 ms del deslizamiento. El inventario de comandos de GPU por frame en 5×5 explicaba por qué:

| Elemento | Trabajo ejecutado en GPU en cada frame (5×5) |
|---|---|
| **25 sockets** (`esVacio: true`) | 25 sprites 9-slice (`225` quads) + **25 `BoxShadow` con `blurRadius: 4`** (`MaskFilter.blur`) + 25 bordes |
| **24 fichas** (`PuzzleTile`) | 24 sprites 9-slice (`216` quads) + **24 `ColorFilter.mode(seedColor, BlendMode.modulate)`** + **24 `BoxShadow` con `blurRadius: 8`** + 24 sombras duras + 24 textos |
| **Pozo del tablero** (`GameScreen`) | 1 `BoxShadow` grande del tamaño del tablero con **`blurRadius: 13`** |
| **49 `AnimatedContainer`** | 49 `StatefulElement` + 49 `AnimationController` para interpolar un borde de 2 px durante 150 ms |
| **24 `RepaintBoundary` por ficha** | 24 `OffsetLayer` retenidas dentro del `Stack` que Impeller debía recorrer y componer sin beneficio de *raster cache* |

En total: **50 desenfoques gaussianos fuera de pantalla**, **441 quads texturizados**, **24 filtros de color en GPU** y **26 capas de composición** ejecutándose 120 veces por segundo.

#### Cómo se resolvió
1. **Cero desenfoques gaussianos (`blurRadius: 0`)** en `lib/widgets/puzzle_tile.dart` y `lib/screens/game_screen.dart`:
   - Se quitó el `BoxShadow(blurRadius: 4)` de los sockets (era negro al 8 % de alfa, imperceptible sobre el pozo oscuro).
   - En las fichas se quitó la sombra gaussiana secundaria (`blurRadius: 8`) y se conservó la sombra dura 3D característica del estilo arcade (`color: AppColors.accentShadow, blurRadius: 0, offset: Offset(0, 4)`), que la GPU dibuja como un `RRect` sólido sin pasada de blur.
   - En el pozo del tablero se reemplazó `blurRadius: 13` por un bisel inferior duro (`blurRadius: 0, offset: Offset(0, 6)`).
2. **Sprite pre-tintado offline (`primarySquareSeed`)** con `tool/tint_sprite.py` y `lib/theme/kenney_ui.dart`:
   - Todas las fichas numeradas se tintaban en GPU con `ColorFilter.mode(AppTheme.seedColor, BlendMode.modulate)` sobre `button_square_depth_flat.png`.
   - Se creó el script reproducible `tool/tint_sprite.py`, que aplica la multiplicación exacta por canal `(r * 0x43 // 255, g * 0x61 // 255, b * 0xEE // 255, a)` sobre la paleta del PNG original y genera `assets/ui/kenney/button_square_depth_flat_seed.png` (355 bytes).
   - `PuzzleTile` usa `KenneySlices.primarySquareSeed.decoration()` **sin `ColorFilter`**, eliminando 24 filtros de color por frame con resultado visual idéntico píxel a píxel.
3. **Horneado de los $n^2$ sockets en una única textura (`_CapaSockets`)** en `lib/widgets/puzzle_board.dart`:
   - Los $n^2$ sockets debajo de las fichas son completamente estáticos durante toda la partida.
   - Se reemplazaron los 25 widgets `PuzzleTile(esVacio: true)` por `_CapaSockets`, que resuelve el `ui.Image` de `KenneySlices.flatSquare` una sola vez y rasteriza la grilla completa de $n^2$ sockets (9-slice + borde de 1 px) en una única textura GPU (`ui.Image`) mediante `ui.PictureRecorder` y `picture.toImageSync(wPx, hPx)`.
   - Durante el deslizamiento, el fondo del tablero pasa de **25 subárboles y 225 quads por frame a 1 solo `RawImage` (1 quad texturizado)**.
4. **Reemplazo de `AnimatedContainer` por `DecoratedBox` estáticos y poda de capas** en `lib/widgets/puzzle_tile.dart` y `lib/widgets/puzzle_board.dart`:
   - Cada ficha usa dos `DecoratedBox` livianos (`background` y `foreground` para el anillo de ficha movible) sin `AnimationController`.
   - Se quitaron los 24 `RepaintBoundary` individuales por ficha dentro del `Stack`, dejando únicamente el `RepaintBoundary` exterior del tablero.

---

### 2.3. Caída de fluidez en el Desafío Diario (Modo Foto)

#### Cuál era el problema
A pesar de ser un tablero 3×3, el **Desafío Diario** presentaba caída de frames al deslizar fichas por cuatro causas específicas de `lib/widgets/image_tile.dart`:
1. **Doble recorte por *stencil* en cada ficha:** Cada `ImageTile` anidaba un `ClipRRect` (esquinas redondeadas de la celda) y un `ClipRect` (recorte rectangular), forzando **16 operaciones de stencil buffer por frame** en la GPU.
2. **9× de *overdraw* de la foto completa por ficha:** Dentro de cada celda se montaba un `LayoutBuilder` + `OverflowBox(maxWidth: n * celda, maxHeight: n * celda)` que dibujaba la **imagen completa del día escalada a $3\times 3$ veces el área de la celda** para mostrar apenas $1/9$ de su superficie.
3. **Sprite 9-slice oculto detrás de la foto:** `PuzzleTile` seguía pintando el sprite 9-slice de Kenney debajo de `ImageTile`, aunque la foto opaca lo tapaba por completo.
4. **Decodificación a resolución nativa:** La imagen descargada de Firebase Storage se decodificaba sin límite de dimensiones.

#### Cómo se resolvió
1. **Horneado de cada porción redondeada en una textura `ui.Image` del tamaño de la celda (`_CacheTexturaFicha`)** en `lib/widgets/image_tile.dart`:
   - Se agregó la función pura `ImageTile.recorteDe( index: ..., n: ..., tamanoImagen: ... )`, que calcula el `Rect` fuente exacto de la celda dentro del cuadrado central de la imagen (`BoxFit.cover`).
   - `ImageTile` resuelve el `ImageStream` del `ImageProvider` una sola vez (cayendo automáticamente al `ImageProvider` de `respaldo` y registrando el error por `debugPrint` si falla la red) y rasteriza con `PictureRecorder` → `toImageSync` un `ui.Image` del tamaño exacto de una ficha (`ladoPx × ladoPx`) que ya incluye el `clipRRect` y el `drawImageRect(src, dst)`.
   - En cada frame del deslizamiento, cada ficha fotográfica pinta únicamente un `RawImage` del tamaño de su celda: **0 `ClipRRect`, 0 `ClipRect`, 0 `OverflowBox`, 0 `LayoutBuilder` y 0 overdraw**.
2. **Omisión del sprite 9-slice en modo imagen** en `lib/widgets/puzzle_tile.dart`:
   - Cuando `conImagen` es `true`, la decoración de fondo de `PuzzleTile` omite el `DecorationImage` 9-slice y conserva únicamente el `borderRadius` y la sombra dura 3D exterior.
3. **Decodificación acotada con `ResizeImage`** en `lib/services/daily_challenge_service.dart`:
   - `DailyChallengeService.imagenDe` envuelve el `CachedNetworkImageProvider` en `ResizeImage(..., width: 1024, policy: ResizeImagePolicy.fit)`, preservando intacta la `cacheKey` compuesta (`semilla_url`).

---

### 2.4. Lag al tocar los botones de navegación (Juego, Modo Desafío y Récords)

#### Cuál era el problema
Al presionar una dificultad, el botón de **Modo Desafío** o el botón de **Récords**, había un pequeño tirón perceptible en el arranque y desarrollo de la transición de ruta por cinco motivos combinados:
1. **Snapshot sincrónico de la ruta entrante (`toImageSync`):**
   `ZoomPageTransitionsBuilder` (configurado en `lib/theme/app_theme.dart`) tiene por defecto `allowEnterRouteSnapshotting: true`, lo que toma una captura en textura de toda la pantalla entrante en el primer frame del `Navigator.push`, bloqueando el hilo Raster justo al tocar el botón.
2. **19 capas `Opacity` (`saveLayer`) en la grilla del Modo Desafío:**
   En `lib/screens/challenge_levels_screen.dart`, los niveles bloqueados (hasta 19 de las 20 celdas al iniciar la campaña) envolvían su contenido en `Opacity(opacity: 0.55)`. En Impeller, cada `Opacity` sobre un subárbol con sprite + texto fuerza un `saveLayer` fuera de pantalla: **19 buffers intermedios creados y compuestos en cada frame de la transición**.
3. **Blur gigante (`blurRadius: 34`) en `ArcadePanel`:**
   `lib/widgets/arcade_panel.dart` (usado en la tarjeta de récord del menú, en el selector de dificultad de `RecordsScreen` y en las filas del ranking) aplicaba un `BoxShadow` con `blurRadius: 34` que la GPU debía desenfocar en cada frame de la transición.
4. **Trabajos asíncronos y diálogos disparando `setState` en mitad de la animación de entrada:**
   - En `GameScreen`: `_cargarRecord()` hacía `setState` cuando `SharedPreferences` respondía a mitad del push, y el `DailyPreviewDialog` se abría en el frame 1 (`addPostFrameCallback`) superponiendo su barrera y animación con la transición de la ruta.
   - En `ChallengeLevelsScreen`: `_cargarProgreso()` llamaba `setState` durante la animación de entrada.
   - En `RecordsScreen`: `_cargarTops()` lanzaba las lecturas a Firestore y llamaba `setState` mientras la ruta todavía se estaba animando.
5. **Sprites sin precargar y doble `CustomPainter` en el fondo global:**
   En la primera apertura del tablero, los PNG de Kenney se decodificaban de forma asíncrona durante el push; además, `GameBackground` dividía la grilla y los glows en dos `CustomPainter` separados sin `RepaintBoundary` propio.

#### Cómo se resolvió
1. **`ZoomPageTransitionsBuilder(allowEnterRouteSnapshotting: false)`** en `lib/theme/app_theme.dart`:
   Elimina el congelamiento sincrónico de `toImageSync` en el frame 0 al abrir cualquier pantalla en Android.
2. **Eliminación de los 19 `Opacity` en `ChallengeLevelsScreen`** (`lib/screens/challenge_levels_screen.dart`):
   Se reemplazó el widget `Opacity(opacity: 0.55)` por un tinte pre-atenuado (`_tinteNivelBloqueado = Color(0xFF7C8396)`) aplicado directamente sobre el sprite de la celda bloqueada y colores con alfa directo en el texto/ícono, envolviendo cada `_CeldaNivel` en un `RepaintBoundary`. Resultado: **0 `saveLayer`** en la grilla de 20 niveles.
3. **Sombra dura en `ArcadePanel`** (`lib/widgets/arcade_panel.dart`):
   Se reemplazó el `BoxShadow(blurRadius: 34, offset: Offset(0, 14))` por una sombra dura arcade (`blurRadius: 0, offset: Offset(0, 6)`).
4. **Diferimiento de cargas e interacciones hasta finalizar la transición de la ruta:**
   - `GameScreen._mostrarPreviewAlTerminarTransicion()` (`lib/screens/game_screen.dart`), `ChallengeLevelsScreen._cargarProgresoDespuesDeTransicion()` (`lib/screens/challenge_levels_screen.dart`) y `RecordsScreen._cargarTopsDespuesDeTransicion()` (`lib/screens/records_screen.dart`) escuchan `ModalRoute.of(context)?.animation` y esperan a `AnimationStatus.completed` antes de abrir el diálogo o aplicar el `setState` con los datos cargados.
   - `_record` en `GameScreen` se publica mediante `ValueNotifier<MejorPartida?>` únicamente al contenedor de su tarjeta en el HUD.
5. **Precarga de recursos y fondo unificado:**
   - `HomeScreen.didChangeDependencies` (`lib/screens/home_screen.dart`) precarga en `ImageCache` los sprites de Kenney del tablero y `DailyChallengeService.imagenRespaldo`.
   - `GameBackground` (`lib/theme/kenney_ui.dart`) unificó la grilla y los halos radiales en un único `CustomPainter` (`_FondoArcade`) envuelto en su propio `RepaintBoundary`.

---

## 3. Resumen comparativo (Antes vs. Después en 5×5 y Diario)

| Métrica por frame / por jugada | Antes (v3.0.0 inicial) | Después (v3.0.3 optimizado) |
|---|---|---|
| Alcance del `markNeedsPaint` al deslizar | `_RenderSingleChildViewport` (pantalla entera) | `RenderRepaintBoundary` exterior de `PuzzleBoard` |
| Elementos reconstruidos por jugada (5×5) | **1034** (`GameScreen` entero) → **687** (`PuzzleBoard`) | **Solo las 3–5 fichas** cuyo estado `activa` cambia |
| Desenfoques gaussianos (`blurRadius > 0`) en el tablero (5×5) | **50 blurs por frame** (25 sockets + 24 fichas + 1 pozo) | **0 blurs** (sombras 3D duras `blurRadius: 0`) |
| Filtros de color en GPU (`ColorFilter.modulate`) en fichas | **24 por frame** | **0** (sprite pre-tintado `primarySquareSeed`) |
| Dibujo de los 25 sockets de fondo (5×5) | 25 subárboles · **225 quads + 25 bordes por frame** | **1 quad texturizado (`RawImage`)** horneado en `ui.Image` |
| `AnimatedContainer` activos en el tablero (5×5) | **49** (`StatefulElement` + `AnimationController`) | **0** (`DecoratedBox` estáticos) |
| Desafío Diario (3×3 con foto): clips y overdraw por frame | **16 stencil clips** + **9× overdraw** por ficha + 9-slice oculto | **0 clips en vivo** · **1 `RawImage` pre-recortado por ficha** · sin 9-slice |
| `saveLayer` (`Opacity`) en `ChallengeLevelsScreen` | **Hasta 19 por frame** durante la transición | **0** (tinte pre-atenuado `_tinteNivelBloqueado`) |

---

## 4. Invariantes arquitectónicos y guardas de regresión

Los siguientes invariantes están protegidos por tests automatizados en `test/widget/game_screen_repaint_test.dart`, `test/widget/image_tile_test.dart` y `test/widget_test.dart`:

1. **Frontera de repintado del tablero:** El `RepaintBoundary` de `PuzzleBoard` debe envolver **por fuera** al `LayoutBuilder`, de modo que `_capaDeRepintado(layoutBuilder)` y `_capaDeRepintado(stack)` sean exactamente el mismo `RenderRepaintBoundary` y ninguna invalidación alcance al `_RenderSingleChildViewport`.
2. **Aislamiento del HUD:** Las tarjetas de cronómetro, movimientos, piezas colocadas y récord deben conservar su propio `RepaintBoundary` y actualizarse vía `ValueListenableBuilder` sin reconstruir `GameHeader` ni `GameScreen`.
3. **Presupuesto Raster de las celdas:** Ningún `DecoratedBox` dentro de `PuzzleBoard` puede tener un `BoxShadow` con `blurRadius > 0` ni un `DecorationImage` con `colorFilter != null`.
4. **Reutilización de instancias en `PuzzleBoard`:** Al mover una ficha, las fichas cuyo estado `activa` no cambia deben conservar exactamente la misma instancia de widget `PuzzleTile` (`identical(antes, despues)`).
5. **Geometría y desborde visual:** El `Stack` del tablero mantiene `Clip.none` para que la sombra dura inferior de 4 px de la última fila no se recorte, el `padding` del pozo permanece en `GameScreen` por fuera de `PuzzleBoard`, y cada ficha conserva su `AnimatedPositioned(key: ValueKey(numero))` utilizado por `test/helpers/puzzle_solver.dart`.

