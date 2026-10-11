# Auditoría de transiciones y gameplay — Sliding Puzzle

**Fecha:** 2026-10-11 · **Alcance:** el "lag" que siguen reportando los testers en dispositivo
real, en los dos momentos marcados: la transición al abrir un puzzle y el deslizamiento de
fichas · **Estado:** dos arreglos estructurales aplicados; **falta la validación en dispositivo**
(ver §5). Complementa a `AUDITORIA_RENDIMIENTO_GAMEPLAY.md`, que cubrió el ciclo anterior.

Entorno medido: **Flutter 3.44.2** (rev `c9a6c48423`), Dart 3.12.2, **Impeller** (default de
plataforma en Android; no hay opt-out en el `AndroidManifest`).

---

## 1. Resumen ejecutivo

Los dos síntomas **comparten una raíz**: la pantalla de juego es muy cara de rasterizar, y los dos
caminos la fuerzan a rasterizarse entera y repetidamente.

- **Transiciones.** La transición real **no** es la que se suponía. En Android el default del
  framework es `PredictiveBackPageTransitionsBuilder`, que para navegación **programática** (un
  `Navigator.push` en un `onTap`, que es todo lo que hace esta app) delega en
  `FadeForwardsPageTransitionsBuilder`: **450 ms de `FadeTransition` + `SlideTransition` sobre el
  subárbol real**. Dos detalles de esa receta son caros:
  `RenderAnimatedOpacity` resuelve a una `OpacityLayer` (composite fuera de pantalla con alfa de la
  ruta entera) durante ~337 de los 450 ms, y `RenderFractionalTranslation` **no** usa una capa de
  transformación: pinta a los hijos en `offset + translation * size`, un desplazamiento sub-píxel
  que cambia en cada frame y derrota cualquier caché de raster. Resultado: ~27 frames de
  rasterizado completo de pantalla. **El hilo UI no es el cuello**: construye la pantalla en el
  frame 0 (582 rebuilds) y después queda en ~22 rebuilds de *wrappers* por frame.
  (Se descartó por medición el *snapshotting* de ruta: `SnapshotWidget` = 0 en el árbol.)

- **Gameplay.** La contención del repintado **estaba rota**, y es el hallazgo principal de esta
  auditoría. El `RepaintBoundary` del tablero vivía **adentro** del `LayoutBuilder`, que es el
  boundary de *relayout* del tablero. Como el framework cierra todo layout con `markNeedsPaint()`,
  la invalidación que produce mover una ficha **nacía en el `LayoutBuilder`** y subía hasta el
  viewport del `SingleChildScrollView`: cada frame del deslizamiento volvía a registrar y
  rasterizar el HUD, la consigna, el pozo con su halo `blurRadius: 13` y la botonera. Encima, un
  repintado del tablero cuesta **49 sombras gaussianas + 49 sprites 9-slice + 24 textos**, y escala
  con n².

Los dos arreglos van en ese orden: mover la capa del tablero por fuera del `LayoutBuilder`, y
cambiar el perfil de costo de la transición con `pageTransitionsTheme`.

---

## 2. Cómo se midió

Sin dispositivo: instrumentación de los flags de debug del framework
(`debugPrintRebuildDirtyWidgets`, `debugPrintMarkNeedsPaintStacks`, `debugPrintMarkNeedsLayoutStacks`)
dentro de un widget test temporal (ya borrado), más conteo estructural del árbol de `Element` y de
`RenderObject`. Complementado con la lectura del SDK 3.44.2.

Dos notas sobre qué dicen esos números:

- El print de `RenderObject.markNeedsPaint` sale **sólo** para objetos que son capa de repintado y
  tienen capa propia, así que contar esas líneas cuenta exactamente **qué capas se agregan a
  `_nodesNeedingPaint`** en un frame. Es la medida directa del alcance del repintado.
- El print de `markNeedsLayout` está condicionado a `_isRelayoutBoundary`, así que identifica a los
  **boundaries de relayout** (`rendering/object.dart`).

**Lo que esto NO mide:** tiempos reales de UI ni de Raster. Un widget test no tiene rasterizador ni
GPU, así que prueba *el mecanismo y la magnitud del trabajo desperdiciado*, no fps. Ver §5.

### 2.1. Presupuesto estático del tablero (medido)

|  | 3×3 | 4×4 | **5×5** |
|---|---|---|---|
| elementos bajo `GameScreen` / bajo `PuzzleBoard` | 586 / 239 | 782 / 435 | **1034 / 687** |
| `RenderObject` bajo el tablero / pantalla | 137 / 305 | 249 / 417 | **393 / 561** |
| capas `RepaintBoundary` bajo el tablero / pantalla | 10 / 12 | 17 / 19 | **26 / 28** |
| `AnimatedContainer` (una por celda) | 17 | 31 | **49** |
| sprites 9-slice (`DecorationImage.centerSlice`) | 17 | 31 | **49** |
| sombras con blur (`BoxShadow.blurRadius > 0`) | 17 | 31 | **49** |
| `RenderParagraph` (números) | 8 | 15 | **24** |

Cada `BoxShadow` se dibuja con `MaskFilter.blur` (`painting/box_shadow.dart:72`, aplicado por
`_paintShadows` en `painting/box_decoration.dart:448`): un blur gaussiano por sombra, o sea una
pasada fuera de pantalla cada uno. Son **24 fichas a `blurRadius: 8` más 25 sockets a 4** = 49
blurs por repintado completo del tablero. Ese es el costo que escala n².

---

## 3. El hallazgo principal: la contención del repintado

`PuzzleBoard` envolvía al `Stack` que anima con un `RepaintBoundary`, pero **por dentro** del
`LayoutBuilder`. La cadena real es:

```
PuzzleBoard
  LayoutBuilder            <- boundary de RELAYOUT del tablero
    RepaintBoundary        <- estaba acá adentro
      Stack                <- el que anima al deslizar
        RepaintBoundary × 1 (sockets) + × 24 (fichas)
```

El tile se mueve → `Positioned.applyParentData` marca needs-layout en el `Stack` → el relayout sube
hasta el `LayoutBuilder` → **el framework termina todo layout con `markNeedsPaint()`**
(`RenderObject.layout` y `_layoutWithoutResize`) → esa invalidación de pintado sube desde el
`LayoutBuilder`, que está **por encima** del `RepaintBoundary`, así que éste no puede frenarla, y
para en el viewport del `SingleChildScrollView` (`_RenderSingleChildViewport.isRepaintBoundary =>
true`, `single_child_scroll_view.dart:429`).

Medición del alcance, **por cada frame de los 160 ms del deslizamiento**, en 5×5:

| | capas repintadas por frame | ¿viewport? |
|---|---|---|
| **antes** | 6-7: `RenderRepaintBoundary`×5-6 **+ `_RenderSingleChildViewport`×1** | **sí, siempre** |
| **después** | 6: `RenderRepaintBoundary`×6 | **no** |

Consecuencia de "antes": en cada frame se volvían a registrar y rasterizar el HUD, la fila de
consigna, el pozo del tablero con su halo (`blurRadius: 13`, `game_screen.dart`) y la botonera —
exactamente el modo de falla que el ciclo anterior (`cc66f1b`) creía haber cerrado. Su test
guardián pasaba igual: verificaba *dónde* estaba el boundary y *de qué tamaño*, pero no que la
invalidación quedara contenida. Al romperlo a mano se ve el agujero: con el boundary adentro, el
guardián viejo **pasa** y el nuevo falla con
`Actual: _RenderSingleChildViewport:<...>`.

Las dos mediciones que sostienen el mecanismo, además del código del framework:

```
layouts por frame (antes y después):  [_RenderLayoutBuilder×1  RenderStack×1]
```

O sea: el `LayoutBuilder` **es** el boundary de relayout y se re-layoutea en cada frame. El
relayout en sí es barato; lo que costaba era que su `markNeedsPaint()` se llevara puesto a todo el
contenido del scroll.

### 3.1. Un costo que queda (no lo toca este arreglo)

En el **frame de la jugada** (el instante del toque, no los 10 frames siguientes) el viewport se
sigue repintando una vez, y la causa es otra: la tarjeta de **movimientos** del HUD no tiene
`RepaintBoundary` propio, mientras que la del **cronómetro** sí (`game_screen.dart`). Cambiar
`_movimientos` repinta esa tarjeta, y al no tener capa propia la invalidación llega al viewport.

```
frame de la jugada:  [_RenderSingleChildViewport×1  RenderRepaintBoundary×1]
```

Es **un** frame por jugada, no el churn sostenido de los 160 ms. Queda como candidato trivial
(espejar el boundary del cronómetro), fuera del alcance de este cambio.

---

## 4. Qué se aplicó

**F1 — La capa del tablero pasa por fuera del `LayoutBuilder`** (`lib/widgets/puzzle_board.dart`)

`RepaintBoundary(child: LayoutBuilder(...))` en lugar de `LayoutBuilder(builder: ... RepaintBoundary(child: Stack(...)))`.
`RenderRepaintBoundary` es un `RenderProxyBox`: no recorta ni cambia el layout, así que la sombra de
la fila inferior sigue desbordando (`Clip.none`) y la geometría que lee
`test/helpers/puzzle_solver.dart` no se corre. Los boundaries por ficha y el de los sockets siguen
adentro y hacen lo suyo.

**F2 — Perfil de costo de la transición** (`lib/theme/app_theme.dart`)

`pageTransitionsTheme` con `ZoomPageTransitionsBuilder` en Android, partiendo de
`const PageTransitionsTheme().builders` y cambiando **sólo** Android: el constructor reemplaza el
mapa entero y una plataforma ausente cae al fallback del framework, así que listar sólo Android
habría movido iOS y macOS de `CupertinoPageTransitionsBuilder` a Zoom.

`Zoom` cambia el perfil de ese costo: reemplaza el subárbol por un *snapshot* (`SnapshotWidget`) y
anima la textura, así que se paga una rasterización y el resto de los frames son composición
barata. **Sus dos costos propios, que hay que tener presentes:** esa rasterización es **sincrónica**
(`Layer.toImageSync`, en el primer frame de la transición) y la página entrante queda **congelada**
mientras el snapshot está activo. Si el primer frame resultara un congelamiento largo, el ajuste a
probar es `ZoomPageTransitionsBuilder(allowEnterRouteSnapshotting: false)`.

Efecto lateral deliberado: en Android U o superior se pierde el gesto de *predictive back* del
default.

**Guardas** (`test/widget/game_screen_repaint_test.dart`)

Tercer invariante: **la primera capa de repintado hacia arriba desde el `LayoutBuilder` tiene que
ser un `RenderRepaintBoundary`**, y tiene que ser *la misma* capa que la del `Stack` — así el
relayout y el pintado del tablero no pueden separarse en dos capas y arrastrar a la pantalla.
Además del test, se extrajo `_capaDeRepintado(RenderObject)` para no repetir el ascenso a mano.

Sensibilidad verificada rompiéndola a mano (con el boundary adentro, el guardián nuevo falla y el
viejo pasa). `flutter analyze` sin issues y `flutter test` con **212/212** en verde.

---

## 5. Pendiente (por orden de prioridad)

- **F0 — Medir en dispositivo. Es lo único que cierra esta auditoría.** `flutter run --profile` en
  un gama baja, **no** en emulador, con Repaint Rainbow, Performance Overlay y DevTools.
  Predicciones falsables:
  - **El test decisivo de §3:** con Repaint Rainbow, deslizar una ficha. El flash tiene que quedar
    **limitado al rectángulo del tablero**. Si vuelve a cubrir el HUD, la consigna, el pozo con su
    halo o la botonera, la contención se rompió otra vez.
  - **Transición:** comparar hilos UI vs Raster al tocar una dificultad. El hilo UI sólo debería
    tener un pico en el frame 0 (la build de la pantalla); el resto tiene que ser Raster.
  - **Discriminador n:** 3×3 vs 5×5. Si el tirón escala con el tablero, el cuello está en el
    tablero; si es constante, en el chrome o en el overdraw.
  - **Zoom vs FadeForwards:** comparar el mismo push con y sin el `pageTransitionsTheme`. Si el
    primer frame con Zoom resulta un congelamiento perceptible, aplicar el ajuste de
    `allowEnterRouteSnapshotting`.
- **F3 — La tarjeta de movimientos sin capa propia** (§3.1). Un frame por jugada. Espejar el
  `RepaintBoundary` que ya tiene el cronómetro.
- **F4 — `AnimatedContainer` por celda.** 49 `StatefulElement` + 49 `AnimationController` para
  animar un borde de 2 px, y **3-5 de ellos animan en cada jugada** (el anillo de "movible" cambia
  en las fichas vecinas al hueco). Medido: 8-12 rebuilds por frame de deslizamiento, de los cuales
  la mayoría son esos `AnimatedContainer`. Toca diseño/accesibilidad, no sólo rendimiento.
- **F5 — A/B de las capas por ficha** (la F2 del ciclo anterior, todavía abierta). Bajo Skia las 26
  capas bajo el tablero abaratan el raster; **bajo Impeller no hay equivalente al raster cache de
  Skia**, así que podrían ser sólo overhead de composición. Con §3 ya resuelto, la pregunta es
  secundaria: el costo dominante era el **área** invalidada, no el número de capas.
- **F6 — Overdraw del fondo.** Cuatro capas de pantalla completa apiladas en `GameBackground`. No
  está en el camino de repintado (vive fuera de la capa de la ruta), pero se paga siempre.

**Descartados por medición** (para no volver sobre ellos): el *snapshotting* de ruta (el default
previo no lo usa); el confeti (no repinta en reposo: `pump` idle = 0 rebuilds, y su
`AnimationController` no hace `repeat`); el fondo (fuera del camino de repintado — re-confirma el
ciclo anterior); la decodificación de assets (los sprites de Kenney son PNG de 286-565 bytes).

---

## 6. Invariantes que no hay que romper

- Los del ciclo anterior: `Clip.none` en los dos `Stack` del tablero y el desborde de la sombra de
  la fila inferior (`test/widget_test.dart`); el `key` en el `AnimatedPositioned`, del que
  `test/helpers/puzzle_solver.dart` deduce las posiciones; el `padding` del pozo **afuera** de
  `PuzzleBoard`; la capa del cronómetro y la de cada `PuzzleTile`.
- **Nuevo:** `RepaintBoundary` **por fuera** del `LayoutBuilder` de `PuzzleBoard`. Lo vigila
  `test/widget/game_screen_repaint_test.dart`, y no alcanza con que la capa exista: tiene que ser la
  primera hacia arriba desde el `LayoutBuilder` y la misma que la del `Stack`.
