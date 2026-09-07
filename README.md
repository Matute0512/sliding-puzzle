# 🧩 Sliding Puzzle

Un juego moderno de puzzle deslizante desarrollado con Flutter y Dart. Disponible para Android, iOS y Web desde un único código fuente.

![Flutter](https://img.shields.io/badge/Flutter-3.44.2-02569B?style=flat&logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.12.2-0175C2?style=flat&logo=dart)
![Version](https://img.shields.io/badge/versión-2.0.2-success)
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
| **Cloud Firestore** | cloud_firestore 6.9.0 | Base de datos del Top 5 Global |
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

### v2.1.0 — Internacionalización (i18n)
- 🌐 Soporte multi-idioma (ES / EN)

### v3.0.0 — Leaderboard global
- 🏆 Ranking online global entre jugadores

### Pendiente
- 🎨 Fondos animados por dificultad

---

## 🔒 Privacidad

Consultá nuestra política de privacidad en [PRIVACY_POLICY.md](PRIVACY_POLICY.md): qué datos guarda el Top 5 Global y cómo eliminarlos.

---

## 📄 Licencia

Este proyecto está bajo la licencia MIT.

---

> Desarrollado con ❤️ usando Flutter y Dart
