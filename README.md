# 🧩 Sliding Puzzle

Un juego moderno de puzzle deslizante desarrollado con Flutter y Dart. Disponible para Android, iOS y Web desde un único código fuente.

![Flutter](https://img.shields.io/badge/Flutter-3.44.1-02569B?style=flat&logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.12.1-0175C2?style=flat&logo=dart)
![Version](https://img.shields.io/badge/versión-1.0.0-success)
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
| google_fonts | 8.1.0 | Tipografía Poppins |

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
│
├── lib/
│   ├── main.dart
│   ├── game_screen.dart
│   ├── puzzle_logic.dart
│   ├── records_screen.dart
│   └── records_service.dart
│
├── pubspec.yaml
├── pubspec.lock
├── README.md
└── analysis_options.yaml
```

## Descripción de los archivos principales

| Archivo | Responsabilidad |
|----------|----------------|
| `main.dart` | Punto de entrada de la aplicación y menú principal |
| `game_screen.dart` | Pantalla principal del juego, tablero, HUD y temporizador |
| `puzzle_logic.dart` | Lógica del rompecabezas: mezcla, movimientos y validación |
| `records_screen.dart` | Visualización de récords locales |
| `records_service.dart` | Persistencia de récords mediante `shared_preferences` |

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

- Flutter 3.44.1 o superior
- Dart 3.12.1 o superior

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

### v2.0.0 🔜
- 🎨 Fondos animados por dificultad
- 🎉 Animación de confetti al ganar
- 🌙 Soporte de modo oscuro
- 🎵 Efectos de sonido
- 📊 Historial detallado de partidas

---

## 📄 Licencia

Este proyecto está bajo la licencia MIT.

---

> Desarrollado con ❤️ usando Flutter y Dart
