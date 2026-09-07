# Graph Report - sliding_puzzle  (2026-09-07)

## Corpus Check
- 44 files · ~132,814 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 428 nodes · 516 edges · 24 communities (18 shown, 2 thin omitted)
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `a6d6fc3a`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- settings_screen.dart
- game_screen.dart
- package:flutter/material.dart
- sound_service.dart
- app_settings_provider.dart
- app_theme.dart
- challenge_levels_screen.dart
- records_service.dart
- AppDelegate
- records_screen.dart
- 🧩 Sliding Puzzle
- puzzle_logic.dart
- home_screen.dart
- manifest.json
- puzzle_board.dart
- gradlew
- MainActivity.kt
- LaunchImage.imageset/README.md
- firebase_service.dart
- puzzle_tile.dart

## God Nodes (most connected - your core abstractions)
1. `AppColors` - 12 edges
2. `🧩 Sliding Puzzle` - 11 edges
3. `AppSettingsProvider` - 8 edges
4. `🗺️ Roadmap` - 8 edges
5. `Política de Privacidad — Sliding Puzzle` - 7 edges
6. `AppDelegate` - 5 edges
7. `Flutter` - 3 edges
8. `RunnerTests` - 3 edges
9. `SlidingPuzzleApp` - 3 edges
10. `ChallengeLevelsScreen` - 3 edges

## Surprising Connections (you probably didn't know these)
- `build` --references--> `AppSettingsProvider`  [EXTRACTED]
  lib/main.dart → lib/providers/app_settings_provider.dart
- `build` --references--> `AppSettingsProvider`  [EXTRACTED]
  lib/screens/settings_screen.dart → lib/providers/app_settings_provider.dart
- `SlidingPuzzleApp` --references--> `AppSettingsProvider`  [EXTRACTED]
  lib/main.dart → lib/providers/app_settings_provider.dart
- `SettingsScreen` --references--> `AppSettingsProvider`  [EXTRACTED]
  lib/screens/settings_screen.dart → lib/providers/app_settings_provider.dart

## Import Cycles
- None detected.

## Communities (24 total, 2 thin omitted)

### Community 0 - "settings_screen.dart"
Cohesion: 0.06
Nodes (42): ChangeNotifier, firebase_options.dart, IconData, build, inicializar, _inicializarFirebase, limpiarDatosViejos, main (+34 more)

### Community 1 - "game_screen.dart"
Cohesion: 0.05
Nodes (43): ConfettiController, dart:async, int?, _alternarPausa, build, _confettiController, createState, _detenerTimer (+35 more)

### Community 2 - "package:flutter/material.dart"
Cohesion: 0.07
Nodes (31): AnimatedContainer, dart:math, package:flutter/material.dart, package:flutter_test/flutter_test.dart, package:provider/provider.dart, package:shared_preferences/shared_preferences.dart, package:sliding_puzzle/logic/puzzle_logic.dart, package:sliding_puzzle/providers/app_settings_provider.dart (+23 more)

### Community 3 - "sound_service.dart"
Cohesion: 0.07
Nodes (28): alternarMusica, alternarSonido, _claveMusica, _claveSonido, detenerMusica, _fuenteClick, _fuenteMusica, _fuenteVictoria (+20 more)

### Community 4 - "app_settings_provider.dart"
Cohesion: 0.13
Nodes (14): bool get, alternarMusica, alternarSonido, cambiarTema, _claveMusica, _claveSonido, _claveTema, inicializar (+6 more)

### Community 5 - "app_theme.dart"
Cohesion: 0.08
Nodes (23): Color, accentShadow, AppTheme, background, cardBackground, copyWith, dark, emptyTile (+15 more)

### Community 6 - "challenge_levels_screen.dart"
Cohesion: 0.10
Nodes (20): game_screen.dart, bloqueado, build, _cantidadNiveles, _cargando, _cargarProgreso, ChallengeLevelsScreen, _ChallengeLevelsScreenState (+12 more)

### Community 7 - "records_service.dart"
Cohesion: 0.11
Nodes (18): dart:convert, _claveAlias, _claveAppCalificada, _claveEstrellas, _claveNivelMaximo, _clavesHistorialLibre, _clavesViejas, guardarAlias (+10 more)

### Community 8 - "AppDelegate"
Cohesion: 0.11
Nodes (14): Any, Bool, Flutter, FlutterAppDelegate, FlutterImplicitEngineBridge, FlutterImplicitEngineDelegate, FlutterSceneDelegate, AppDelegate (+6 more)

### Community 9 - "records_screen.dart"
Cohesion: 0.10
Nodes (21): GameScreen, _GameScreenState, build, _cargando, _cargarTops, color, createState, _cuerpo (+13 more)

### Community 10 - "🧩 Sliding Puzzle"
Cohesion: 0.07
Nodes (27): 1. Qué servicios usamos, 2. Qué datos recopilamos, 3. Para qué se usan, 4. Qué NO recopilamos, 5. Eliminación de tus datos, 6. Contacto, Política de Privacidad — Sliding Puzzle, 🚀 Cómo correrlo localmente (+19 more)

### Community 11 - "puzzle_logic.dart"
Cohesion: 0.11
Nodes (17): configuracionNivel, _corregirParidad, _desplazamiento, Direccion, direccionHaciaVacio, estaResuelto, estrellasPara, generarTablero (+9 more)

### Community 12 - "home_screen.dart"
Cohesion: 0.09
Nodes (24): AppLifecycleListener, _avisarFalloTienda, build, createState, dispose, HomeScreen, _HomeScreenState, initState (+16 more)

### Community 13 - "manifest.json"
Cohesion: 0.18
Nodes (10): background_color, description, display, icons, name, orientation, prefer_related_applications, short_name (+2 more)

### Community 14 - "puzzle_board.dart"
Cohesion: 0.25
Nodes (7): build, _deslizarFicha, PuzzleBoard, size, tablero, List, puzzle_tile.dart

### Community 15 - "gradlew"
Cohesion: 0.60
Nodes (3): gradlew script, die(), warn()

### Community 22 - "firebase_service.dart"
Cohesion: 0.07
Nodes (27): DateTime, android, DefaultFirebaseOptions, ios, web, alias, compareTo, esMejorQue (+19 more)

### Community 23 - "puzzle_tile.dart"
Cohesion: 0.14
Nodes (14): @immutable, AppColors, activa, build, esSocket, numero, onSwipe, onTap (+6 more)

## Knowledge Gaps
- **252 isolated node(s):** `XCTest`, `DefaultFirebaseOptions`, `web`, `android`, `ios` (+247 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 313 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **2 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `AppColors` connect `puzzle_tile.dart` to `settings_screen.dart`, `game_screen.dart`, `app_theme.dart`, `challenge_levels_screen.dart`, `records_screen.dart`, `home_screen.dart`?**
  _High betweenness centrality (0.048) - this node is a cross-community bridge._
- **Why does `AppSettingsProvider` connect `settings_screen.dart` to `app_settings_provider.dart`?**
  _High betweenness centrality (0.017) - this node is a cross-community bridge._
- **What connects `XCTest`, `DefaultFirebaseOptions`, `web` to the rest of the system?**
  _252 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `settings_screen.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.05656565656565657 - nodes in this community are weakly interconnected._
- **Should `game_screen.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.045454545454545456 - nodes in this community are weakly interconnected._
- **Should `package:flutter/material.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.06747638326585695 - nodes in this community are weakly interconnected._
- **Should `sound_service.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.06896551724137931 - nodes in this community are weakly interconnected._