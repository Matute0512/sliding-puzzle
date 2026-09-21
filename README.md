# 🧩 Sliding Puzzle

Un juego moderno de puzzle deslizante desarrollado con Flutter y Dart. Disponible para Android, iOS y Web desde un único código fuente.

![Flutter](https://img.shields.io/badge/Flutter-3.44.2-02569B?style=flat&logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.12.2-0175C2?style=flat&logo=dart)
![Version](https://img.shields.io/badge/versión-2.3.1-success)
![License](https://img.shields.io/badge/licencia-MIT-blue)
[![CI](https://github.com/Matute0512/sliding-puzzle/actions/workflows/ci.yml/badge.svg)](https://github.com/Matute0512/sliding-puzzle/actions/workflows/ci.yml)

---

## 🎮 Sobre el juego

Sliding Puzzle es un juego de lógica clásico donde el jugador debe ordenar las fichas numeradas, ya sea tocándolas o deslizándolas en dirección al espacio vacío. El objetivo es acomodar los números en orden ascendente con el espacio vacío en la esquina inferior derecha.

---

## ✨ Funcionalidades

- 🟢 **Tres niveles de dificultad** — Fácil (3×3), Medio (4×4), Difícil (5×5)
- ⏱️ **Cronómetro** — arranca en el primer movimiento y se detiene al ganar
- 🏆 **Top 5 Global Leaderboards (Firebase Firestore)** — ranking online por tamaño (3×3, 4×4 y 5×5) con Alias público y mejor puntaje por partida libre
- 🕹️ **Modo Desafío** — campaña de 20 niveles deterministas con objetivo de movimientos, estrellas (1-3) y progreso 100% local
- 🌙 **Modo oscuro** — claro/oscuro/sistema, con preferencia persistente
- 🎵 **Sonido y música** — efectos de sonido y música de fondo (flutter_soloud)
- ⚙️ **Panel de configuración** — tema, sonido y música en un solo lugar
- 👆 **Tocar o deslizar** — mové las fichas tocándolas o deslizándolas en dirección al espacio vacío
- 📐 **Tablero compacto** — fichas más unidas (gap de 4 px) con radio de esquina ajustado
- 🎨 **UI moderna y táctil** — paleta de colores personalizada, fuente Poppins y efecto 3D en las fichas
- ❓ **Dialog de ayuda** — instrucciones del juego con ejemplo del tablero resuelto según la dificultad
- 📱 **Layout responsive** — funciona en móvil, web y escritorio
- 🗓️ **Desafío Diario** — un tablero por día igual para todos (semilla UTC), un solo intento y ranking diario en vivo

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
| shared_preferences | 2.5.5 | Persistencia local (alias, progreso del Modo Desafío y avisos) |
| provider | 6.1.5+1 | Gestión de estado (tema, sonido y música) |
| confetti | 0.8.0 | Animación de confetti al ganar |
| flutter_soloud | 4.0.9 | Efectos de sonido y música de fondo (motor SoLoud) |
| url_launcher | 6.3.1 | Abre la ficha de la app en Google Play (aviso de calificación) |
| **Firebase Authentication (Anonymous)** | firebase_auth 6.6.1 | Sesión anónima para el Top 5 Global |
| **Cloud Firestore** | cloud_firestore 6.9.0 | Base de datos del Top 5 Global y del ranking diario |
| **Firebase Storage** | firebase_storage 13.6.0 | Foto del Desafío Diario (`daily/YYYYMMDD.webp`) |
| cached_network_image | 3.4.1 | Descarga y caché en disco de la foto del día |
| Poppins | — | Tipografía empaquetada como asset (sin descarga en runtime) |

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
├── test/
│   └── puzzle_logic_test.dart
│
├── lib/
│   ├── main.dart
│   ├── firebase_options.dart
│   ├── logic/puzzle_logic.dart
│   ├── providers/app_settings_provider.dart
│   ├── screens/ (home, challenge_levels, game, records, settings)
│   ├── services/ (firebase, records, sound)
│   ├── theme/app_theme.dart
│   └── widgets/ (difficulty_button, hud_card, puzzle_board, puzzle_tile)
│
├── assets/
│   ├── fonts/ (Poppins Regular, Medium, Bold)
│   └── sounds/ (click, victory, background music)
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
| `main.dart` | Punto de entrada de la aplicación |
| `screens/home_screen.dart` | Menú principal con selección de dificultad |
| `screens/game_screen.dart` | Pantalla del juego: tablero, HUD, temporizador y victoria |
| `screens/challenge_levels_screen.dart` | Grilla de niveles del Modo Desafío (1-20) con estrellas y candados |
| `screens/records_screen.dart` | Top 5 Global por tamaño de tablero, leído de Cloud Firestore |
| `screens/settings_screen.dart` | Panel de configuración: tema, sonido y música |
| `widgets/puzzle_board.dart` | Tablero animado que posiciona las fichas y valida los gestos de deslizamiento |
| `widgets/puzzle_tile.dart` | Ficha individual con soporte de toque y swipe |
| `logic/puzzle_logic.dart` | Lógica del rompecabezas: mezcla, paridad, movimientos, validación, dirección del deslizamiento y niveles de desafío |
| `services/firebase_service.dart` | Acceso al Top 5 Global en Cloud Firestore (un documento por usuario anónimo) |
| `services/records_service.dart` | Persistencia local con `shared_preferences`: alias, progreso del Modo Desafío y avisos |
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
- 🔧 Fix: sombras de fichas inferiores visibles (Clip.none en GridView)
- ✨ Animación de deslizamiento real (PuzzleBoard con AnimatedPositioned)
- ⏸️ Pausa del juego + ciclo de vida (AppLifecycleListener)
- ♿ Contraste WCAG AA en todos los elementos interactivos
- 🧏 Accesibilidad: Semantics en fichas y sockets
- 🧪 28 tests unitarios y de widget
- 🔧 Fix: SegmentedButton del tema no se corta con fuentes grandes

### v2.0.2 ✅
- 👆 Gestos de deslizamiento: mové las fichas deslizándolas en dirección al hueco, además del toque
- 📐 Fichas más compactas: gap reducido a 4 px con radio de esquina ajustado
- 🧩 Modal de ayuda con la matriz resuelta dinámica según la dificultad (3×3, 4×4 y 5×5), con columnas alineadas incluso con números de dos dígitos

### v2.1.0 ✅
- 🏁 Modo Desafío: campaña de 20 niveles con tableros deterministas (misma semilla por nivel), objetivo de movimientos y hasta 3 estrellas por nivel
- 💾 Persistencia del progreso: nivel desbloqueado y mejores estrellas por nivel
- ⭐ Modal de calificación con redirección a Google Play

### v2.2.0 ✅
- 🏆 Top 5 Global con Firebase (Authentication anónimo + Cloud Firestore)
- 👤 Alias público de hasta 5 caracteres para publicar el puntaje
- 🔒 Modal de privacidad en la app y política de privacidad publicada

### v2.2.1 ✅
- ⏱️ Fix: el cronómetro de una partida ya ganada no se reanuda al volver de background
- 🎯 Calibración del Modo Desafío 4x4 (niveles 11 a 20): el objetivo supera la profundidad del scramble para que las 3 estrellas sean alcanzables
- 🧹 Limpieza de recursos obsoletos y falsos positivos del lint de Android

### Pendiente
- 🌐 Soporte multi-idioma (ES / EN)
- 🎨 Fondos animados por dificultad

---

## 🔒 Privacidad

Consultá nuestra política de privacidad en [PRIVACY_POLICY.md](PRIVACY_POLICY.md): qué datos guarda el Top 5 Global y cómo eliminarlos.

---

## 📄 Licencia

Este proyecto está bajo la licencia MIT.

---

> Desarrollado con ❤️ usando Flutter y Dart
