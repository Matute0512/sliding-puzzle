# 🧩 Sliding Puzzle

Un juego moderno de puzzle deslizante desarrollado con Flutter y Dart. Disponible para Android, iOS y Web desde un único código fuente.

![Flutter](https://img.shields.io/badge/Flutter-3.44.2-02569B?style=flat&logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.12.2-0175C2?style=flat&logo=dart)
![Version](https://img.shields.io/badge/versión-2.0.0-success)
![License](https://img.shields.io/badge/licencia-MIT-blue)

---

## 🎮 Sobre el juego

Sliding Puzzle es un juego de lógica clásico donde el jugador debe ordenar las fichas numeradas deslizándolas hacia el espacio vacío. El objetivo es acomodar los números en orden ascendente con el espacio vacío en la esquina inferior derecha.

---

## ✨ Funcionalidades

- 🟢 **Tres niveles de dificultad** — Fácil (3×3), Medio (4×4), Difícil (5×5)
- ⏱️ **Cronómetro** — arranca en el primer movimiento y se detiene al ganar
- 🏆 **Récords locales** — mejor tiempo y menor cantidad de movimientos guardados por dificultad
- 🎨 **UI moderna y táctil** — paleta de colores personalizada, fuente Poppins y efecto 3D en las fichas
- ❓ **Dialog de ayuda** — instrucciones del juego con ejemplo del tablero resuelto
- 📱 **Layout responsive** — funciona en móvil, web y escritorio

---

## 🛠️ Tecnologías utilizadas

| Tecnología | Versión | Uso |
|---|---|---|
| Flutter | 3.44.1 | Framework de UI |
| Dart | 3.12.1 | Lenguaje de programación |
| shared_preferences | 2.5.5 | Almacenamiento local de récords |
| provider | 6.1.5+1 | Gestión de estado (tema, sonido y música) |
| confetti | 0.8.0 | Animación de confetti al ganar |
| flutter_soloud | 4.0.9 | Efectos de sonido y música de fondo (motor SoLoud) |
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
│   ├── logic/puzzle_logic.dart
│   ├── models/record_game.dart
│   ├── providers/app_settings_provider.dart
│   ├── screens/ (home, game, records, settings)
│   ├── services/ (records, sound)
│   ├── theme/app_theme.dart
│   └── widgets/ (difficulty_button, hud_card, puzzle_tile)
│
├── assets/
│   ├── fonts/ (Poppins Regular, Medium, Bold)
│   └── sounds/ (click, victory, background music)
│
├── pubspec.yaml
├── pubspec.lock
├── README.md
└── analysis_options.yaml
```

## Descripción de los archivos principales

| Archivo | Responsabilidad |
|----------|----------------|
| `main.dart` | Punto de entrada de la aplicación |
| `screens/home_screen.dart` | Menú principal con selección de dificultad |
| `screens/game_screen.dart` | Pantalla del juego: tablero, HUD, temporizador y victoria |
| `screens/records_screen.dart` | Visualización del historial de récords por dificultad |
| `screens/settings_screen.dart` | Panel de configuración: tema, sonido y música |
| `logic/puzzle_logic.dart` | Lógica del rompecabezas: mezcla, paridad, movimientos y validación |
| `services/records_service.dart` | Persistencia de récords mediante `shared_preferences` |
| `services/sound_service.dart` | Efectos de sonido y música con `flutter_soloud` |

## Plataformas soportadas

- Android
- iOS
- Windows
- Linux
- macOS
- Web
```

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

### Pendiente
- 🎨 Fondos animados por dificultad

---

## 📄 Licencia

Este proyecto está bajo la licencia MIT.

---

> Desarrollado con ❤️ usando Flutter y Dart
