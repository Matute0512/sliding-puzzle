# Auditoría de rendimiento del gameplay — Sliding Puzzle

**Fecha:** 2026-10-09 · **Alcance:** el "lag" (caída de frames) reportado por los testers de la
prueba cerrada durante el juego · **Estado:** diagnóstico aplicado en `cc66f1b`; falta la
verificación en dispositivo (ver §6).

---

## 1. Resumen ejecutivo

El tirón no venía de la animación en sí, sino de **dónde se frenaba la invalidación de pintado**.
Al deslizar una ficha, el `Stack` del tablero se relayouta y se repinta, y esa invalidación subía
por el árbol hasta la primera capa de repintado que encontraba. Esa capa **no** era la de la ruta
(como se asumió en la auditoría del rediseño, ver `d7c7373`), sino la del
**`SingleChildScrollView`** que envuelve al tablero en `game_screen.dart`:

```
cadena desde el Stack del tablero hacia arriba (medida, no inferida)
  [0] RenderStack                 <- el que anima al deslizar
  [1] _RenderLayoutBuilder
  [2] RenderPadding
  [3] RenderDecoratedBox          <- pozo del tablero + boardGlow (blur 13)
  [4] RenderAspectRatio
  [5] RenderFlex                  <- Column: HUD, consigna, tablero, botonera
  [6] RenderPadding
  [7] RenderConstrainedBox
  [8] RenderPositionedBox
  [9] _RenderSingleChildViewport  <-- BOUNDARY: acá se frenaba
 ...
 [25] RenderRepaintBoundary       <- la capa de la ruta (routes.dart:1228)
```

Consecuencia: **en cada frame de los 160 ms del deslizamiento** se volvían a registrar y a
rasterizar el HUD, la fila de consigna, el pozo del tablero **con su halo difuminado** y la
botonera. El header escapaba (está fuera del viewport) y el fondo de la app también (está fuera de
la capa de la ruta), así que ninguno de los dos era el culpable.

Los dos arreglos aplicados (`cc66f1b`) atacan esa raíz: una capa de repintado **alrededor del
tablero** y el traslado del estado que cambia por jugada a `ValueNotifier`, para que una jugada no
reconstruya el árbol entero de la pantalla.

| sospechoso | veredicto |
|---|---|
| M1 — `RepaintBoundary` por ficha | **Dirección correcta, ubicación equivocada.** Son *hijos* del nodo que anima, así que no podían frenar la propagación. Se conservan (son lo que abarata el re-registro del tablero) y se **agrega** la capa que faltaba. |
| 2 — El fondo (`GameBackground`) | **No está en el camino de repintado del gameplay.** Sus painters son estáticos y vive fuera de la capa de la ruta. Su costo real es *overdraw* de pantalla completa, no repintado. |
| B4 — Rebuild del Scaffold | **Real y subestimado por 13-17×**: 583 / 779 / **1031** elementos por movimiento (3×3 / 4×4 / 5×5). Es un costo de *un* frame por jugada, no por frame de animación. |

---

## 2. Cómo se midió

Sin dispositivo: dos mediciones deterministas dentro de un widget test temporal (ya borrado), más la
lectura del SDK **Flutter 3.44.2**.

1. **Costo de rebuild por movimiento.** Se cuenta cuántos `Element` hay bajo el `State` de
   `GameScreen` con `Element.visitChildren`. Un `setState` ahí reconstruye **todo** su subárbol
   (cada `updateChild` vuelve a llamar `build`), así que ese conteo *es* el número de rebuilds por
   movimiento.
2. **Jerarquía de capas.** Se camina el árbol de `RenderObject` hacia arriba desde el `Stack` del
   tablero marcando `isRepaintBoundary`; y se cuentan las capas por **identidad de `RenderObject`**
   (no por `Element`, que resuelve hacia abajo y cuenta la misma capa hasta 3 veces).
3. **Código del framework.** `_RenderSingleChildViewport.isRepaintBoundary => true`
   (`single_child_scroll_view.dart:429`), la capa por ruta (`routes.dart:1228`) y el dibujado de los
   sprites 9-slice con **un solo** `drawImageNine` y el `ColorFilter` dentro del `Paint`
   (`decoration_image.dart:729`).

**Lo que esto NO mide y por qué hace falta un perfil en dispositivo:** los tiempos reales de UI y de
Raster. Un widget test no tiene rasterizador ni GPU, así que la auditoría prueba *el mecanismo y la
magnitud del trabajo desperdiciado*, no que el arreglo se traduzca en fps. Ver §5.

---

## 3. Los tres sospechosos, en detalle

### 3.1. M1 — Las capas de composición (`RepaintBoundary` por ficha)

`markNeedsPaint` propaga hacia **arriba** y se detiene en el primer ancestro que sea capa de
repintado. Los boundaries que agregó `d7c7373` están en `puzzle_board.dart`, **dentro** de cada
`AnimatedPositioned`: son hermanos del nodo que anima, no ancestros.

- ✅ Hacen su trabajo: mientras el `Stack` se repinta, las demás fichas se recomponen desde su capa
  cacheada en vez de volver a dibujar el sprite con borde y sombras.
- ❌ No pueden frenar la propagación: cuando cambia `left`/`top`, la invalidación sube hasta el
  viewport y arrastra con ella todo el contenido del scroll.

**El arreglo no es quitarlos, es agregar la capa que faltaba.** Poner un boundary alrededor de
`PuzzleBoard` y volver a dibujar el tablero como una sola capa haría que, en cada frame del
deslizamiento, se rastericen las 49 celdas con su sprite, su borde, su número y **sus sombras
difuminadas** (`blurRadius: 8` por ficha, `4` por socket). Los boundaries por ficha son justamente
lo que hace que el re-registro del tablero sea casi sólo composición de capas ya cacheadas.

Cifras de capas reales (5×5): **25** `RenderRepaintBoundary` bajo `PuzzleBoard` (24 fichas + 1 capa
compartida de sockets), 27 bajo `GameScreen`, 29 en toda la app.

> Queda una pregunta abierta que sólo se responde midiendo (F2, §5): bajo Impeller una capa retenida
> no es necesariamente una textura separada como en Skia, así que podría convenir *menos* capas. Eso
> se decide con un A/B en dispositivo, no por razonamiento.

### 3.2. El fondo (`GameBackground`, `kenney_ui.dart:189`)

- **No se repinta durante el gameplay.** `_Grilla` y `_Atmosfera` devuelven `shouldRepaint => false`
  y, además, el fondo se monta en `MaterialApp.builder`, **por encima** del `Navigator`: está fuera
  de la capa de la ruta, así que ninguna invalidación de la partida lo alcanza. Cachearlo en una
  imagen no ahorraría *pintado* — ya está cacheado.
- **El `BlendMode` no cuesta lo que parece.** El tintado de los sprites es `BlendMode.modulate` como
  `ColorFilter` sobre un `DecorationImage` con `centerSlice`, y el framework lo dibuja con **un
  `drawImageNine`** con el filtro dentro del `Paint`. No hay `saveLayer` ni nueve dibujos.
- **Lo que sí cuesta** es *overdraw*: cuatro capas de pantalla completa apiladas (degradado base,
  grilla ~24 líneas, dos `RadialGradient` grandes y velo). La escena se rasteriza entera en cada
  frame, así que eso se paga siempre; no es la causa de los tirones al deslizar, pero es candidato
  si el perfil marca Raster/GPU como cuello de botella general (F5).

**La sobrecarga gráfica que sí estaba en el camino caliente es del tablero, no del fondo**: el
`boardGlow` del pozo (`blurRadius: 13`, `game_screen.dart`) se re-rasterizaba en cada frame del
deslizamiento. Eso lo arregla la capa del tablero, que lo deja afuera.

### 3.3. B4 — El rebuild del Scaffold

Medido: mover una ficha reconstruía **583 (3×3), 779 (4×4) y 1031 (5×5) elementos**, de los cuales
238 / 434 / **686** eran del tablero. La estimación de la auditoría anterior ("~60-80 widgets, es
barato") se quedaba corta por 13-17×.

Matiz que evita sobre-corregir: el `setState` ocurría **una vez por jugada**, al tocar la ficha; los
160 ms siguientes los animaba `AnimatedPositioned` por su cuenta. O sea que esto explica un tirón en
el instante del toque (que es cuando el usuario lo percibe), no la caída sostenida durante el
deslizamiento. Comparte la raíz con M1: nadie había aislado el tablero del resto de la pantalla.

---

## 4. Qué se aplicó (`cc66f1b`, rama `develop`)

**F1 — Aislamiento del tablero** (`lib/widgets/puzzle_board.dart`)

`RepaintBoundary` alrededor del `Stack` que anima, **por dentro** del `Container` decorado de
`GameScreen`, para que el pozo y su halo queden fuera del dominio de repintado. Se conservan los
boundaries por ficha y el de los sockets.

`RenderRepaintBoundary` es un `RenderProxyBox`: no recorta ni cambia el layout, así que la sombra de
la fila inferior sigue desbordando (`Clip.none`) y la geometría que lee
`test/helpers/puzzle_solver.dart` no se corre.

**F4 — Aislamiento del rebuild** (`lib/screens/game_screen.dart`)

`_tablero` y `_movimientos` pasan a `ValueNotifier` (mismo patrón que el cronómetro), con sus
consumidores en `ValueListenableBuilder`, y `_onTapFicha` deja de llamar `setState`. La tarjeta de
"piezas" del Diario también escucha al tablero, del que es función. `setState` queda reservado para
lo que sí cambia la estructura: el velo de pausa y el récord del tablero.

> Nota de implementación: migrar **sólo** `_movimientos` no habría alcanzado el objetivo, porque el
> mismo `setState` cargaba también `_tablero` y el Chrome se habría seguido reconstruyendo igual. Se
> migraron los dos.

**Guardas** (3, todas verificadas rompiéndolas a mano para confirmar que fallan)

- `test/widget/game_screen_repaint_test.dart` — la capa de repintado del tablero tiene que ser un
  `RenderRepaintBoundary` del tamaño exacto de `PuzzleBoard` (si falta, el boundary más cercano
  vuelve a ser el viewport), y mover una ficha no puede cambiar la instancia del `GameHeader`.
- `test/widget/game_screen_daily_test.dart` — la tarjeta de piezas del Diario tiene que llegar a
  `8 / 9` con el tablero resuelto (8 y no 9: el hueco no cuenta como pieza colocada).

**Validación:** `flutter analyze` sin issues y `flutter test` con **211/211** en verde.

---

## 5. Pendiente (por orden de prioridad)

- **F0 — Medir en dispositivo.** Build `--profile` en un gama baja, no en emulador. Con
  **Repaint Rainbow** activado, el flash debería haberse reducido al rectángulo del tablero
  (antes cubría HUD, consigna, pozo y botonera). En el timeline, comparar hilos **UI vs Raster** y
  usar el **discriminador 3×3 vs 5×5**: si el tirón escala con el tablero, el cuello está en el
  tablero; si es constante, en el Chrome o en el overdraw.
- **F2 — A/B de las variantes de capas.** Hoy: capas por ficha + capa de tablero. A probar: sin las
  capas por ficha (el tablero pasa a rasterizarse entero por frame). Sólo tiene sentido si F0 marca
  el Raster como cuello y el 5×5 como el peor caso.
- **F3 — Bajar el costo por ficha.** `AnimatedContainer` por ficha (49 `StatefulElement` + tweens
  por rebuild, para animar sólo el anillo de "movible"), y `FittedBox` + `Padding` + `Center` por
  celda. Los dos tocan decisiones de diseño/accesibilidad, no sólo rendimiento.
- **F5 — Overdraw del fondo.** Empezar por fusionar el velo dentro del degradado base (una pasada de
  pantalla completa menos, sin cambio visual). Bakear el fondo a una textura queda como último
  recurso: suma ~10 MB de textura a DPR 3 y hay que regenerarla si cambia el tamaño.

---

## 6. Invariantes que no hay que romper

- `Clip.none` en los dos `Stack` del tablero y el desborde de la sombra de la fila inferior
  (`test/widget_test.dart`).
- El `key` en el `AnimatedPositioned`, del que `test/helpers/puzzle_solver.dart` deduce las
  posiciones para jugar partidas enteras en los tests.
- El `padding` del pozo **afuera** de `PuzzleBoard` (`game_screen.dart`): si se mueve adentro, el
  tablero se corre respecto de la cuenta de `getSize` y los tests de partida completa fallan.
- La capa del cronómetro y la de cada `PuzzleTile`: no forman parte de este arreglo.
