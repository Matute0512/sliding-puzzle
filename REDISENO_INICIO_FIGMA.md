# Rediseño de Inicio desde Figma

Registro del rediseño de la pantalla de **Inicio y dificultad** implementado el **2026-09-30** en la rama `feat/kenney-ui-overhaul`, commit `56b6ffd`.

## Origen del diseño

- **Frame:** `4:2593` — "Inicio y dificultad"
- **Archivo:** `cGqNbWlao4ZsRsPgm75vcB`
- **URL:** https://www.figma.com/design/cGqNbWlao4ZsRsPgm75vcB

El frame es la fuente de verdad visual. Si hay que continuar el rediseño, conviene volver ahí en vez de reconstruirlo de memoria.

Del frame **no** se implementó el status bar de iOS (9:41, señal, wifi, batería) ni el home indicator: son *chrome* de mockup, no parte de la app.

## Decisiones acordadas

| Punto | Decisión |
|---|---|
| Dificultad "Experto" | El enum la declara, pero **no tiene botón**: la UI ofrece 3, como el frame. |
| Estilo | **Híbrido**: estructura y colores del frame; forma de botón (9-slice) y tipografía siguen siendo de Kenney. |
| Features fuera del frame | Se **conservan todas** (continuar partida, Desafío Diario, ajustes, privacidad), integradas al layout nuevo. |
| Fondo | Se **reemplazó el global** de la app, no solo el de esta pantalla. |
| Récord del menú | Caché local + refresco best-effort desde Firestore. |

### Por qué "híbrido" y no fiel al frame

Los sprites del UI Pack de Kenney son **mapas de sombreado claros**: multiplicarlos por un navy profundo (como el `#101B3D` de las tarjetas del frame) aplasta el bisel y deja un bloque liso. Por eso:

- **Superficies oscuras** (tarjeta de récord, track del switch) → planas, con los valores exactos del frame (`ArcadePanel`).
- **Elementos interactivos y vivos** (botones de dificultad, píldora del switch) → sprite de Kenney tintado, como ya hacía la app.

Consecuencia de accesibilidad: sobre las superficies oscuras el texto sale de `AppColors`; sobre los botones tintados va tinta oscura (`#071127`), porque el blanco sobre verde/ámbar falla WCAG AA.

### Tipografía

`Kenney Future` es **~38% más ancha** que la Inter con la que está medido el frame, y tiene métricas verticales más altas. En el header, el título bajó de 20 a 17 px y se le fijó el interlineado: a 20 se partía en dos líneas y desbordaba los 56 px del diseño.

## Qué se construyó

### Nuevos

| Archivo | Qué es |
|---|---|
| `lib/logic/dificultad.dart` | Enum `Dificultad` (facil 3, medio 4, dificil 5, experto 6) + `jugables`. |
| `lib/services/best_run_service.dart` | Récord personal por tablero + el último completado. |
| `lib/widgets/arcade_panel.dart` | Contenedor navy plano del rediseño. |
| `lib/widgets/arcade_button.dart` | Botón ancho: chip con ícono, título, subtítulo, chevron. |
| `lib/widgets/best_run_card.dart` | Tarjeta "Mejor partida". |
| `lib/widgets/mode_switch.dart` | Segmentado Clásico / Desafío. |
| `lib/widgets/home_header.dart` | Título + las dos acciones cuadradas. |

### Modificados

- `lib/screens/home_screen.dart` — layout completo; se fue el `AppBar`.
- `lib/widgets/difficulty_button.dart` — ahora recibe una `Dificultad` y resuelve color, ícono y textos.
- `lib/theme/kenney_ui.dart` — `GameBackground` pasó de baldosa repetida a degradado + grilla + glows.
- `lib/theme/app_theme.dart` — tokens del frame, `textMuted` nuevo, `gameBackground` a `#05091C`, `hudTint` a `#101B3D`.
- `lib/services/firebase_service.dart` — `obtenerMejorPropio(size)`.
- `lib/screens/game_screen.dart` — guarda la marca local al ganar una partida libre.
- `lib/l10n/app_es.arb`, `app_en.arb` — claves nuevas.

## Estructura de la pantalla

1. **Header** — título centrado; el botón de grilla abre un menú con Ajustes y Privacidad; el trofeo va a Récords.
2. **Continuar partida** (si hay una pendiente) — va primero porque retomar es lo más probable para quien vuelve al menú.
3. **Tarjeta "Mejor partida"**
4. **Intro de dificultad** + los tres botones.
5. **Switch Clásico / Desafío** — "Clásico" está siempre activo y no responde al toque: la pantalla *es* el modo Clásico, así que el segmento activo es un cartel, no un control.
6. **Desafío Diario**

## La tarjeta "Mejor partida"

Muestra el récord del **último tablero completado**, no el mejor absoluto entre todos.

El motivo: cualquier criterio absoluto favorece al tablero más chico —un 3×3 se resuelve en menos movimientos *y* en menos tiempo que un 5×5, siempre—, así que el jugador de 5×5 nunca vería reflejado su esfuerzo. Con el tablero como referencia, la marca que se muestra es una que el jugador puede efectivamente intentar romper, y el renglón **"Récord en 4×4"** dice cuál es.

Detalles de implementación:

- Se guarda una marca **por tablero**, más cuál fue el último completado (`RecordsPersonales`). Dentro de un tablero, la marca solo se reemplaza si mejora; el tablero vigente cambia siempre.
- El criterio de "mejor" es el del Top 5 (menos movimientos, luego menos tiempo), para que la tarjeta y la pantalla de récords no puedan contradecirse.
- La tarjeta se dibuja siempre desde el caché local: es lo primero que se ve al abrir la app y no puede depender de la red. El refresco de Firestore es best-effort y consulta **un solo** tablero (el vigente).
- Con la sesión anónima, cada instalación tiene su propio uid, así que el refresco remoto solo recupera historial si el caché local se perdió con el uid intacto. **En la práctica el caché local es la fuente de verdad.**

## Detalles que se desvían del frame

- **Íconos:** equivalentes de Material (`bolt_rounded`, `local_fire_department_rounded`, etc.). El proyecto no tiene `flutter_svg` y no se sumó la dependencia por siete íconos. El frame usa un set tipo Lucide.
- **Glows del fondo:** se reproducen con `RadialGradient` en vez de los dos SVG difusos del frame, que es exactamente lo que esos SVG son. Los tonos están leídos del render.
- **`TABLERO 4×4` → `RÉCORD EN 4×4`:** el frame pone el tamaño ahí; se cambió la frase en el mismo renglón para que diga el tamaño *y* que es una marca a superar, sin repetir el dato dos veces.
- **La barra fina al pie de la tarjeta** ("Record progress" en Figma) quedó como divisor decorativo: el diseño no le da ninguna semántica deducible.

## Verificación

- `flutter analyze` — sin issues.
- `flutter test` — **201 tests**, todos pasan.
- **Revisión visual: aprobada en dispositivo el 2026-10-05.** El layout y la
  interfaz quedaron aprobados por el usuario. (Al aprobarse, la suite ya estaba
  en 208 tests: los 201 de arriba son los del momento de este commit.)

Tests que cubren lo nuevo: `test/dificultad_test.dart`, `test/best_run_service_test.dart`, `test/widget/{difficulty_button,best_run_card,mode_switch}_test.dart`.

**Gotcha para futuros tests:** varios textos del menú se pintan en versalitas por estilo, así que las aserciones buscan la forma **renderizada** (`'ELEGÍ UNA DIFICULTAD'`, `'DESAFÍO'`), no la del catálogo.

## Pendientes y deuda

- **Tablero 6×6 (`Dificultad.experto`)**: el motor ya lo soporta, pero habilitarlo requiere sumar la entrada en `records_screen.dart` (los tamaños están hardcodeados), crear `leaderboard_6x6` en Firestore con sus reglas, y aceptar que el solver de `challenge_calibration_test.dart` no puede verificar su óptimo (tope de 4M nodos, solo resuelve 3×3 y 4×4). `AppTheme.difficultyExpert` es un violeta **provisional**: el frame no define ese cuarto color.
- **Dos formatos de tiempo en la app**: la tarjeta usa `mm:ss` (como el frame), el resto usa `37s`. Si se unifican, el que debería ceder es el de la tarjeta.
- **Paneles claros de Kenney** en récords y niveles: cambiaron de fondo (el backdrop es nuevo en toda la app) y no se revisaron visualmente.
- **Fuente única del color de dificultad**: los tres colores viven en `AppTheme` y el mapeo color/ícono en `difficulty_button.dart`. Si se habilita `experto`, el mapeo a `records_screen.dart` es manual.
