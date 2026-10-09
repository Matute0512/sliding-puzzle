# 🧩 Sliding Puzzle — Edición Arcade

Un juego moderno de puzzle deslizante desarrollado con Flutter y Dart. Disponible para Android, iOS y Web desde un único código fuente.

![Flutter](https://img.shields.io/badge/Flutter-3.44.2-02569B?style=flat&logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.12.2-0175C2?style=flat&logo=dart)
![Version](https://img.shields.io/badge/versión-3.0.2-success)
![License](https://img.shields.io/badge/licencia-MIT-blue)
[![CI](https://github.com/Matute0512/sliding-puzzle/actions/workflows/ci.yml/badge.svg)](https://github.com/Matute0512/sliding-puzzle/actions/workflows/ci.yml)

---

## 🎮 Sobre el juego

Sliding Puzzle es un juego de lógica clásico donde el jugador debe ordenar las fichas numeradas, ya sea tocándolas o deslizándolas en dirección al espacio vacío. El objetivo es acomodar los números en orden ascendente con el espacio vacío en la esquina inferior derecha.

La **Edición Arcade** es el rediseño visual completo de la app. La interfaz dejó atrás la paleta propia con tipografía Poppins y pasó a una identidad de salón de arcade, construida con el **UI Pack de Kenney** (CC0) sobre la estructura de un archivo de **Figma**. En el mismo ciclo se blindó el rendimiento del tablero y se agregó soporte de idioma español/inglés.

---

## 🕹️ La Edición Arcade

### Estética: un híbrido deliberado entre Figma y Kenney

El rediseño no es "fiel al frame" ni "100% Kenney", sino una mezcla consciente, y el motivo es técnico:

Los sprites del UI Pack son **mapas de sombreado claros**. Multiplicarlos por un navy profundo —como el `#101B3D` de las tarjetas del frame— aplasta el bisel y deja un bloque liso. Por eso:

- **Superficies oscuras** (tarjeta de récord, track del switch) → se pintan **planas**, con los valores exactos del frame (`ArcadePanel`).
- **Elementos interactivos y vivos** (botones de dificultad, píldora del switch, fichas) → sprite de Kenney **tintado**, como ya hacía la app.

La consecuencia de accesibilidad está asumida: sobre las superficies oscuras el texto sale de `AppColors`, y sobre los botones tintados va tinta oscura (`#071127`), porque el blanco sobre verde o ámbar no pasa WCAG AA.

### Escalado 9-slice

Los sprites se dibujan con `centerSlice`: el PNG trae un marco de esquinas y bordes que **no** debe deformarse, y `centerSlice` marca el rectángulo interior que sí se estira. Como el bisel vive en los bordes, el botón puede crecer a cualquier ancho sin que el marco se estire ni se pixele. `KenneySlices` guarda el `centerSlice` **medido** de cada PNG en vez de estimarlo.

### Tintado con `BlendMode.modulate`

Los sprites son grises a propósito: son mapas de sombreado, no colores. El tinte entra con `ColorFilter.mode(tint, BlendMode.modulate)`, que **multiplica**: lo claro sigue claro, la sombra sigue oscura, y el color se aplica sin aplanar el relieve. Con `srcIn` el sprite quedaría de un color plano y se perdería el efecto.

La tipografía también viene del pack: **Kenney Future** es la fuente por defecto de toda la app. Es ~38% más ancha que Poppins —con la que está medido el frame— y tiene métricas verticales más altas, así que los tamaños de texto se ajustaron uno por uno (en el header, por ejemplo, el título bajó de 20 a 17 px y se le fijó el interlineado: a 20 se partía en dos líneas).

### Fondo global y `SafeArea`

El "Layered arcade background" —degradado vertical, grilla modular, dos glows y un velo de legibilidad— se monta **una sola vez** en `MaterialApp.builder`, no por pantalla: así el patrón es continuo y no se reinicia al navegar. Para que se vea, **todos los `Scaffold` van con el fondo transparente**; ninguno debe poner `backgroundColor`.

El rediseño además sacó los `AppBar`. Como consecuencia, cada pantalla es responsable de su propio `SafeArea` en el `body`: sin él, el header y las tarjetas del HUD se dibujaban debajo de la barra de estado. Las pantallas que sí conservan un `AppBar` (ajustes, récords, prueba de imagen) ya tienen el inset resuelto por el framework.

### Blindaje de rendimiento

El rediseño se auditó antes de publicarse y se corrigieron sus dos puntos calientes de pintado. En `lib/` **no había ni un solo `RepaintBoundary`**, así que cualquier invalidación de pintado subía hasta la primera capa que encontrara. La auditoría de rendimiento del 2026-10-09 (`AUDITORIA_RENDIMIENTO_GAMEPLAY.md`) encontró que esa capa no era la de la ruta —como se asumió entonces— sino la del `SingleChildScrollView` que envuelve al tablero, y agregó la que faltaba.

- **Fichas del tablero** — cada ficha va en su propio `RepaintBoundary`, y los n² sockets —que no cambian nunca— comparten **una sola** capa. Al deslizarse una ficha el `Stack` se relayouta y se repinta, pero las demás se recomponen desde su capa cacheada en vez de volver a dibujar el sprite 9-slice con borde y sombras en cada frame de la animación.
- **Tablero completo** — el `Stack` del tablero va además dentro de su propia capa. Los boundaries de las fichas son *hijos* del nodo que anima, no ancestros, así que no podían frenar la propagación hacia arriba: sin esta capa, cada frame de los 160 ms del deslizamiento volvía a registrar y a rasterizar todo el contenido del scroll —el HUD, la consigna, el pozo con su halo y la botonera—. Con ella la propagación se corta en el borde del tablero; el pozo y su halo quedan afuera a propósito, así que tampoco se re-rasterizan.
- **Cronómetro** — la tarjeta del tiempo lleva su propio `RepaintBoundary`. El rebuild ya estaba acotado a esa card; lo que **no** lo estaba era el pintado, así que el tick de 1 Hz repintaba header, HUD y tablero una vez por segundo.
- **HUD y estado de la partida** — el tablero y el contador de movimientos se publican por `ValueNotifier` (mismo patrón que el cronómetro), con sus consumidores en `ValueListenableBuilder`. Antes cada jugada llamaba `setState` y reconstruía el `Scaffold` entero —alrededor de 1000 elementos en un 5×5, header y botonera incluidos—; ahora sólo se reconstruyen el tablero y la tarjeta que muestra el contador.
- **Fondo** — los `CustomPainter` de la grilla y los glows devuelven `false` en `shouldRepaint`: son estáticos y su única entrada real es el tamaño, que ya fuerza repintado por layout. Además viven fuera de la capa de la ruta, así que ninguna invalidación de la partida los alcanza.

`RenderRepaintBoundary` es un `RenderProxyBox` sin lógica de clip, así que el desborde de las sombras de las fichas sigue visible. Hay un test que le exige `Clip.none` a todos los `Stack` del tablero para que siga siendo así, y dos guardas más que verifican que la capa del tablero siga en su lugar y que una jugada no reconstruya el header (`test/widget/game_screen_repaint_test.dart`).

---

## ✨ Funcionalidades

- 🟢 **Tres niveles de dificultad** — Fácil (3×3), Medio (4×4), Difícil (5×5)
- ⏱️ **Cronómetro** — arranca en el primer movimiento y se detiene al ganar
- 🏆 **Top 5 Global (Firebase Firestore)** — ranking online por tamaño, con alias público y mejor puntaje por partida libre
- 🕹️ **Modo Desafío** — campaña de 20 niveles deterministas con objetivo de movimientos, estrellas (1-3) y progreso 100% local
- 🗓️ **Desafío Diario** — un tablero con foto por día, igual para todos (semilla UTC), un solo intento y ranking diario en vivo
- 🥇 **Récord personal sin red** — la tarjeta "Mejor partida" del menú se dibuja desde el caché local, sin esperar un round-trip
- 🌐 **Español e inglés** — la app sigue el idioma del sistema, con respaldo en español
- 🎵 **Sonido y música** — efectos y música de fondo (flutter_soloud)
- ⚙️ **Panel de configuración** — sonido y música en un solo lugar
- 👆 **Tocar o deslizar** — mové las fichas tocándolas o deslizándolas en dirección al espacio vacío
- 🎨 **Identidad arcade** — UI Pack de Kenney con escalado 9-slice y tintado dinámico, tipografía Kenney Future
- ❓ **Dialog de ayuda** — instrucciones con el ejemplo del tablero resuelto según la dificultad
- ♿ **Accesibilidad** — contraste WCAG AA y `Semantics` en fichas y sockets
- 📱 **Layout responsive** — móvil, web y escritorio

> **Un solo tema.** El rediseño eliminó el selector claro/oscuro: el juego tiene una única identidad visual y un control que no cambiaría nada sería peor que no tenerlo. Por eso tampoco hay `darkTheme` ni `themeMode` en el `MaterialApp`.

---

## 🥇 Récords: el caché local es la fuente de verdad

La tarjeta "Mejor partida" del menú necesita un dato **instantáneo y sin red**: es lo primero que se ve al abrir la app, y hacerla esperar un round-trip dejaría el menú con un hueco o un spinner en cada arranque. Por eso las marcas se guardan en disco (`SharedPreferences`) al ganar y la tarjeta se dibuja **siempre** desde ahí. El refresco desde Firestore es best-effort.

### Por qué muestra el último tablero y no el mejor absoluto

La tarjeta muestra el récord del **último tablero que el jugador completó**, no el mejor entre todos. El motivo: cualquier criterio absoluto favorece al tablero más chico —un 3×3 se resuelve en menos movimientos *y* en menos tiempo que un 5×5, siempre—, así que el jugador de 5×5 nunca vería reflejado su esfuerzo. Con el tablero como referencia, la marca que se muestra es una que **puede efectivamente intentar romper**, y el renglón "Récord en 4×4" dice cuál es.

### Qué se guarda

`RecordsPersonales` guarda una marca **por tablero** más cuál fue el último completado (`ultimoTamano`). Dentro de un tablero la marca solo se reemplaza si mejora; el tablero vigente cambia siempre, porque lo que el jugador acaba de completar es lo que quiere ver.

El criterio de "mejor" es el del Top 5 —menos movimientos y, en empate, menos tiempo— para que la tarjeta y la pantalla de récords no puedan contradecirse.

La deserialización es **tolerante a propósito**: una entrada ilegible se descarta sola en vez de tirar abajo las demás, y si la marca no coincide con el tablero en el que está indexada se ignora —así la tarjeta cae al estado vacío en vez de mostrar un récord bajo el tamaño equivocado.

### Por qué Firestore no es la fuente de verdad acá

La sesión es **anónima**, así que cada instalación tiene su propio `uid`. El único caso en que el refresco remoto recupera algo es que el caché local se haya perdido con el `uid` intacto; en el uso normal, la marca local —que se reescribe en cada victoria— ya es más completa que lo que Firestore puede contar. Además se consulta **solo el tablero vigente**, que es el único que la tarjeta muestra, para que siga siendo una sola lectura.

---

## 🗓️ Desafío Diario

Un tablero por día, igual para todo el mundo, con **un solo intento**. Es el modo con fotos: en vez de números, las fichas son porciones de una imagen que hay que reconstruir.

### Semilla determinista UTC

El tablero no se guarda ni se sincroniza: se **deriva de la fecha**. La semilla es `YYYYMMDD` en **UTC** y de ahí sale un tablero reproducible, así que dos dispositivos cualesquiera obtienen exactamente el mismo sin hablar entre ellos.

```dart
static int semillaDe(DateTime fecha)              // YYYYMMDD en UTC
static List<int> tableroDe(DateTime ahora)        // PuzzleLogic.generarTableroDiario(semillaDe(ahora))
```

La semilla se captura **una sola vez, al entrar a la pantalla** (`initState`), nunca al ganar. Si alguien arranca a las 23:59 UTC y termina pasada la medianoche, el tablero que jugó es el del día en que *empezó*: recalcularla al ganar mandaría el resultado al ranking del día siguiente y le marcaría como jugado un desafío que nunca vio. Por eso `marcarJugado(semilla)` recibe la semilla en vez de leer el reloj.

La única excepción es **antes del primer movimiento**. Si la app quedó en segundo plano cruzando la medianoche UTC y el jugador todavía no movió ninguna ficha, al volver se recarga el desafío del día nuevo (`GameScreen._adoptarDiaActualSiCambio`): no hay puntaje ni tablero que proteger, y quedarse en el de ayer lo dejaría sin el desafío de hoy. Una vez que la partida arrancó, el día queda congelado.

### Imágenes en Firebase Storage

Empaquetar cientos de fotos habría hecho explotar el tamaño de la app, así que la foto del día se descarga de **Cloud Storage** siguiendo una convención de nombres:

```text
daily/YYYYMMDD.webp       →        daily/20260920.webp
```

Subir la foto del día es solo dejar el archivo con el nombre correcto: no hay índice que mantener ni configuración que tocar. La extensión (`.webp`, la que produce el script que optimiza las fotos) tiene que coincidir **exactamente** con la que pide `DailyChallengeService.rutaImagen`: Storage no negocia formatos ni redirige, así que un desajuste no falla al resolver la URL sino que devuelve `object-not-found` y manda el tablero al respaldo. La URL se resuelve con `getDownloadURL()` del SDK (no armándola a mano), para que funcione con las reglas de seguridad tal como están, mandando el token de la sesión. Las imágenes quedan cacheadas en disco (`cached_network_image`), así que reabrir el desafío el mismo día no vuelve a descargar. La entrada de caché se identifica con `DailyChallengeService.claveCacheImagen(semilla, url)`: la **semilla adelante** para que dos días no puedan compartir entrada ni aunque Storage devolviera la misma URL para ambos, y la **URL detrás** para que reemplazar la foto de un día ya cacheado sí se vea —`CachedNetworkImageProvider` compara por `cacheKey ?? url`, así que con la clave fija en la semilla el `Image` ni siquiera volvería a pedirla.

### Vista previa de la foto

El Desafío Diario abre con la foto del día entera a la vista (`DailyPreviewDialog`), antes de dejar mover ninguna ficha: el tablero arranca desarmado y cada ficha muestra un recorte que, aislado, no dice nada de la imagen completa. La vista previa la muestra **sin recortar** (`BoxFit.contain`), mientras que el tablero la recorta a cuadrado para que cada ficha sea 1/n exacto.

El diálogo escucha el `ValueNotifier` de la imagen, así que **se actualiza solo** cuando la descarga termina: se abre con la foto de respaldo apenas hay un frame y no espera a la red. Si el día cambia con el diálogo abierto, muestra la foto nueva sin necesidad de abrirse otra vez.

### Intento único diario

Completar el desafío marca el día en `SharedPreferences`. Al volver a la pantalla principal, el botón pasa a decir **"Ver Resultados del Día"** y abre el ranking en vez de dejar rejugar. El candado se renueva solo: guarda la fecha, no un booleano, así que mañana la comparación da distinto sin que nadie tenga que limpiar nada.

El ranking diario vive en Firestore, en una ruta aparte del Top 5 clásico: **ordena por tiempo** (no por movimientos, al revés que el clásico) y **escribe siempre**, no solo si el puntaje se clasifica. El resultado propio queda en el dispositivo, suficiente para el botón de compartir.

### Fallback local

El tablero **nunca se ve vacío ni queda injugable**. El respaldo está en dos capas porque son dos fallos distintos:

| Fallo | Quién lo cubre |
|---|---|
| La URL no se resuelve —sin red, foto todavía no subida, Storage rechaza— | `DailyChallengeService.imagenDe` devuelve `imagenRespaldo` |
| La URL resuelve pero la descarga falla | El `errorBuilder` de `ImageTile` cae a `imagenRespaldo` |

Cubrir una sola capa dejaría un agujero: si el archivo existe pero la descarga se corta a mitad, la primera no se entera. Además `GameScreen` arranca con la foto de respaldo ya puesta y la reemplaza cuando llega la del día, así que el tablero es jugable desde el primer frame y, si la foto nunca llega, ya estaba la otra.

Las dos capas **avisan por log** cuando se activan —`Desafío Diario: no se pudo resolver la foto del día …` y `ImageTile: no se pudo descargar la imagen del tablero …`—. Sin ese aviso, una regla de Storage mal puesta se veía idéntica a un día sin foto subida: el tablero funcionaba y nadie notaba que no se estaba jugando la foto del día.

El camino de error **no puede entrar en un bucle de reintentos**: `ImageTile` es `StatelessWidget` —no hay `setState` propio que dispare un rebuild—, el `errorBuilder` devuelve un `AssetImage` empaquetado y nunca vuelve a envolver la imagen de red (no se recursa), y la resolución de la URL corre una sola vez desde `initState`, no en cada `build`.

---

## 🛠️ Tecnologías utilizadas

| Tecnología | Versión | Uso |
|---|---|---|
| Flutter | 3.44.2 | Framework de UI |
| Dart | 3.12.2 | Lenguaje de programación |
| Android (SDK) | targetSdk 36 · minSdk 24 | Plataforma objetivo de release |
| shared_preferences | 2.5.5 | Persistencia local (alias, progreso del Desafío, avisos y récords personales) |
| provider | 6.1.5+1 | Gestión de estado (sonido y música) |
| confetti | 0.8.0 | Animación de confetti al ganar |
| flutter_soloud | 4.0.9 | Efectos de sonido y música de fondo (motor SoLoud) |
| url_launcher | 6.3.1 | Abre la ficha de la app en Google Play (aviso de calificación) |
| **Firebase Authentication (Anonymous)** | firebase_auth 6.6.1 | Sesión anónima para el Top 5 Global |
| **Cloud Firestore** | cloud_firestore 6.9.0 | Base de datos del Top 5 Global y del ranking diario |
| **Firebase Storage** | firebase_storage 13.6.0 | Foto del Desafío Diario (`daily/YYYYMMDD.webp`) |
| cached_network_image | 3.4.1 | Descarga y caché en disco de la foto del día |
| **Kenney UI Pack 2.0** (CC0) | — | Sprites de superficie (9-slice) y tipografía *Kenney Future* |

---

## 📁 Estructura del Proyecto

```text
sliding_puzzle/
├── android/
├── ios/
├── linux/
├── macos/
├── web/
├── windows/
│
├── lib/
│   ├── main.dart
│   ├── firebase_options.dart
│   ├── l10n/ (app_es.arb, app_en.arb, supported_locales.dart)
│   ├── logic/ (puzzle_logic, dificultad, duracion)
│   ├── providers/app_settings_provider.dart
│   ├── screens/ (home, game, challenge_levels, records, settings, image_puzzle_test)
│   ├── services/ (firebase, records, best_run, daily_challenge, daily_leaderboard, saved_game, sound)
│   ├── theme/ (app_theme, kenney_ui)
│   └── widgets/ (puzzle_board, puzzle_tile, image_tile, arcade_panel, arcade_button,
│                 best_run_card, mode_switch, home_header, game_header, game_controls,
│                 hud_card, difficulty_button, header_square_button, y los diálogos del Diario)
│
├── test/
│   ├── widget_test.dart
│   ├── *_test.dart (lógica, servicios y calibración del Desafío)
│   ├── helpers/ (localized_app, puzzle_solver)
│   └── widget/ (tests de pantallas y de geometría de los frames)
│
├── assets/
│   ├── fonts/ (Kenney Future; Poppins queda registrada por si hay que revertir)
│   ├── images/
│   ├── sounds/ (click, victoria, música de fondo)
│   ├── icon/
│   └── ui/kenney/ (subconjunto curado del UI Pack; el pack entero no se versiona)
│
├── pubspec.yaml
├── pubspec.lock
├── README.md
├── PRIVACY_POLICY.md
└── analysis_options.yaml
```

## Descripción de los archivos principales

| Archivo | Responsabilidad |
|----------|----------------|
| `main.dart` | Punto de entrada; monta `GameBackground` una sola vez en `MaterialApp.builder` |
| `screens/home_screen.dart` | Menú principal: header, tarjeta de récord, dificultades y switch de modo |
| `screens/game_screen.dart` | Pantalla del juego: header, HUD, tablero, controles y victoria (los tres modos) |
| `screens/challenge_levels_screen.dart` | Grilla de niveles del Modo Desafío (1-20) con estrellas y candados |
| `screens/records_screen.dart` | Top 5 Global por tamaño de tablero, leído de Cloud Firestore |
| `screens/settings_screen.dart` | Panel de configuración: sonido y música |
| `theme/kenney_ui.dart` | UI Pack de Kenney: `KenneySlice`/`KenneySlices`, botones tintados y `GameBackground` |
| `theme/app_theme.dart` | Tokens del rediseño (colores, radios, tipografía) y el `ThemeData` único |
| `widgets/puzzle_board.dart` | Tablero animado; posiciona las fichas, aísla su repintado y valida los gestos |
| `widgets/puzzle_tile.dart` | Ficha individual con soporte de toque y swipe |
| `logic/puzzle_logic.dart` | Lógica del rompecabezas: mezcla, paridad, movimientos, validación y niveles |
| `logic/dificultad.dart` | Enum `Dificultad` (3×3 a 6×6) y cuáles se ofrecen en la UI |
| `logic/duracion.dart` | Formateo de tiempos (`37s` para el cronómetro vivo, `mm:ss` para las marcas) |
| `services/best_run_service.dart` | Récord personal por tablero, cacheado en disco, y su refresco best-effort |
| `services/daily_challenge_service.dart` | Semilla UTC, tablero del día, foto en Storage y respaldo |
| `services/firebase_service.dart` | Acceso al Top 5 Global en Cloud Firestore (un documento por uid anónimo) |
| `services/records_service.dart` | Persistencia local: alias, progreso del Desafío y avisos |
| `services/sound_service.dart` | Efectos de sonido y música con `flutter_soloud` |

## Plataformas soportadas

- Android
- iOS
- Windows
- Linux
- macOS
- Web

---

## 🚀 Cómo correrlo localmente

### Requisitos previos

- Flutter 3.44.2 o superior
- Dart 3.12.2 o superior

### Instalación

```bash
# Clonar el repositorio
git clone https://github.com/Matute0512/sliding-puzzle.git

# Ir a la carpeta del proyecto
cd sliding-puzzle

# Instalar dependencias
flutter pub get

# Correr en Chrome
flutter run -d chrome

# Correr en Android (requiere Android Studio)
flutter run -d android
```

---

## 🗺️ Roadmap

### v1.0.0 ✅
- Juego de sliding puzzle funcional (3×3, 4×4, 5×5)
- Cronómetro y contador de movimientos
- Récords locales con shared_preferences
- UI moderna y táctil con paleta personalizada
- Dialog de ayuda con instrucciones

### v2.0.0 ✅
- 🎉 Animación de confetti al ganar
- 🌙 Soporte de modo oscuro (claro/oscuro/sistema, persistente)
- 🎵 Efectos de sonido y música de fondo (flutter_soloud)
- 📊 Historial detallado de partidas (top 5 por dificultad)
- ⚙️ Panel de configuración (tema, sonido, música)
- 🧩 Tipografía Poppins empaquetada como asset (funciona sin conexión)

### v2.0.1 ✅
- 🔧 Fix: sombras de fichas inferiores visibles (Clip.none)
- ✨ Animación de deslizamiento real (PuzzleBoard con AnimatedPositioned)
- ⏸️ Pausa del juego + ciclo de vida (AppLifecycleListener)
- ♿ Contraste WCAG AA en todos los elementos interactivos
- 🧏 Accesibilidad: Semantics en fichas y sockets
- 🔧 Fix: SegmentedButton del tema no se corta con fuentes grandes

### v2.0.2 ✅
- 👆 Gestos de deslizamiento: mové las fichas deslizándolas en dirección al hueco, además del toque
- 📐 Fichas más compactas: gap reducido a 4 px con radio de esquina ajustado
- 🧩 Modal de ayuda con la matriz resuelta dinámica según la dificultad

### v2.1.0 ✅
- 🏁 Modo Desafío: campaña de 20 niveles con tableros deterministas, objetivo de movimientos y hasta 3 estrellas
- 💾 Persistencia del progreso: nivel desbloqueado y mejores estrellas por nivel
- ⭐ Modal de calificación con redirección a Google Play

### v2.2.0 ✅
- 🏆 Top 5 Global con Firebase (Authentication anónimo + Cloud Firestore)
- 👤 Alias público de hasta 5 caracteres para publicar el puntaje
- 🔒 Modal de privacidad en la app y política de privacidad publicada

### v2.2.1 ✅
- ⏱️ Fix: el cronómetro de una partida ya ganada no se reanuda al volver de background
- 🎯 Calibración del Modo Desafío 4×4 (niveles 11 a 20)
- 🧹 Limpieza de recursos obsoletos y falsos positivos del lint de Android

### v2.3.0 ✅
- 🗓️ Desafío Diario: un tablero con foto por día, igual para todos (semilla UTC), con un solo intento
- 🖼️ Fotos servidas desde Firebase Storage con respaldo local en dos capas
- 🏅 Ranking diario en vivo, ordenado por tiempo y separado del Top 5 clásico
- 🔗 Botón para compartir el resultado del día

### v2.3.1 ✅
- 🔧 Fix: la extensión de la foto del día (`.webp`) tiene que coincidir con la que pide el servicio
- 🔧 Fix: recargar el desafío al cruzar la medianoche UTC, con la partida sin empezar
- 👁️ Vista previa de la foto al abrir el desafío

### v3.0.0 — Edición Arcade ✅
- 🎨 **Rediseño visual completo** desde Figma: Inicio, Modo Desafío y los dos tableros (numérico y fotográfico)
- 🕹️ **UI Pack de Kenney (CC0)**: superficies con escalado 9-slice y tintado dinámico por `BlendMode.modulate`
- 🔤 **Tipografía Kenney Future** como fuente global, con los tamaños recalibrados
- 🌄 **Fondo arcade global** (degradado, grilla, glows y velo) montado una sola vez para toda la app
- 🥇 **Récord personal con caché local primero**: la tarjeta del menú no depende de la red
- ⚡ **Blindaje de rendimiento**: `RepaintBoundary` por ficha y en el cronómetro, tras una auditoría de repintado
- 🌐 **Español e inglés**, siguiendo el idioma del sistema
- 🧹 Limpieza: dependencia y claves de traducción sin uso

### Pendiente
- 🎨 Fondos animados por dificultad
- 🧩 Habilitar el tablero 6×6 (el motor lo soporta; falta su entrada en récords y su calibración)

---

## 🔒 Privacidad

Consultá nuestra política de privacidad en [PRIVACY_POLICY.md](PRIVACY_POLICY.md): qué datos guarda el Top 5 Global y cómo eliminarlos.

---

## 📄 Licencia

Este proyecto está bajo la licencia MIT.

Los sprites y la tipografía provienen del [UI Pack 2.0 de Kenney](https://kenney.nl/assets/ui-pack) (CC0).

---

> Desarrollado con ❤️ usando Flutter y Dart
