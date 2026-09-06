# Graph Report - sliding_puzzle  (2026-09-06)

## Corpus Check
- 40 files · ~129,955 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 380 nodes · 467 edges · 22 communities (16 shown, 2 thin omitted)
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `b991cb56`
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

## God Nodes (most connected - your core abstractions)
1. `AppColors` - 12 edges
2. `🧩 Sliding Puzzle` - 10 edges
3. `AppSettingsProvider` - 8 edges
4. `🗺️ Roadmap` - 8 edges
5. `AppDelegate` - 5 edges
6. `Flutter` - 3 edges
7. `RunnerTests` - 3 edges
8. `SlidingPuzzleApp` - 3 edges
9. `ChallengeLevelsScreen` - 3 edges
10. `_ChallengeLevelsScreenState` - 3 edges

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

## Communities (22 total, 2 thin omitted)

### Community 0 - "settings_screen.dart"
Cohesion: 0.05
Nodes (41): @immutable, IconData, _CeldaNivel, _ResumenProgreso, _FilaEstrellas, _FilaResultado, _ItemAyuda, _SeccionDificultad (+33 more)

### Community 1 - "game_screen.dart"
Cohesion: 0.05
Nodes (41): ConfettiController, dart:async, int?, _alternarPausa, build, _confettiController, createState, _detenerTimer (+33 more)

### Community 2 - "package:flutter/material.dart"
Cohesion: 0.08
Nodes (28): AnimatedContainer, dart:math, package:flutter/material.dart, package:flutter_test/flutter_test.dart, package:provider/provider.dart, package:shared_preferences/shared_preferences.dart, package:sliding_puzzle/logic/puzzle_logic.dart, package:sliding_puzzle/providers/app_settings_provider.dart (+20 more)

### Community 3 - "sound_service.dart"
Cohesion: 0.07
Nodes (28): alternarMusica, alternarSonido, _claveMusica, _claveSonido, detenerMusica, _fuenteClick, _fuenteMusica, _fuenteVictoria (+20 more)

### Community 4 - "app_settings_provider.dart"
Cohesion: 0.08
Nodes (26): bool get, ChangeNotifier, build, inicializar, limpiarDatosViejos, main, settings, SlidingPuzzleApp (+18 more)

### Community 5 - "app_theme.dart"
Cohesion: 0.08
Nodes (23): Color, accentShadow, AppTheme, background, cardBackground, copyWith, dark, emptyTile (+15 more)

### Community 6 - "challenge_levels_screen.dart"
Cohesion: 0.09
Nodes (24): game_screen.dart, bloqueado, build, _cantidadNiveles, _cargando, _cargarProgreso, ChallengeLevelsScreen, _ChallengeLevelsScreenState (+16 more)

### Community 7 - "records_service.dart"
Cohesion: 0.08
Nodes (22): dart:convert, decodeList, encodeList, fromJson, movimientos, RecordGame, tiempo, toJson (+14 more)

### Community 8 - "AppDelegate"
Cohesion: 0.11
Nodes (14): Any, Bool, Flutter, FlutterAppDelegate, FlutterImplicitEngineBridge, FlutterImplicitEngineDelegate, FlutterSceneDelegate, AppDelegate (+6 more)

### Community 9 - "records_screen.dart"
Cohesion: 0.11
Nodes (18): FormatException, build, _cargando, _cargarHistorial, color, colors, createState, descripcion (+10 more)

### Community 10 - "🧩 Sliding Puzzle"
Cohesion: 0.10
Nodes (19): 🚀 Cómo correrlo localmente, Descripción de los archivos principales, 📁 Estructura del Proyecto, ✨ Funcionalidades, Instalación, 📄 Licencia, Pendiente, Plataformas soportadas (+11 more)

### Community 11 - "puzzle_logic.dart"
Cohesion: 0.11
Nodes (17): configuracionNivel, _corregirParidad, _desplazamiento, Direccion, direccionHaciaVacio, estaResuelto, estrellasPara, generarTablero (+9 more)

### Community 12 - "home_screen.dart"
Cohesion: 0.14
Nodes (16): AppLifecycleListener, build, createState, dispose, HomeScreen, _HomeScreenState, initState, _lifecycleListener (+8 more)

### Community 13 - "manifest.json"
Cohesion: 0.18
Nodes (10): background_color, description, display, icons, name, orientation, prefer_related_applications, short_name (+2 more)

### Community 14 - "puzzle_board.dart"
Cohesion: 0.25
Nodes (7): build, _deslizarFicha, PuzzleBoard, size, tablero, List, puzzle_tile.dart

### Community 15 - "gradlew"
Cohesion: 0.60
Nodes (3): gradlew script, die(), warn()

## Knowledge Gaps
- **216 isolated node(s):** `XCTest`, `Direccion`, `PuzzleLogic`, `generarTablero`, `_corregirParidad` (+211 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 271 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **2 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `AppColors` connect `settings_screen.dart` to `game_screen.dart`, `app_theme.dart`, `challenge_levels_screen.dart`, `records_screen.dart`, `home_screen.dart`?**
  _High betweenness centrality (0.055) - this node is a cross-community bridge._
- **Why does `AppSettingsProvider` connect `app_settings_provider.dart` to `settings_screen.dart`?**
  _High betweenness centrality (0.015) - this node is a cross-community bridge._
- **What connects `XCTest`, `Direccion`, `PuzzleLogic` to the rest of the system?**
  _216 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `settings_screen.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.05496828752642706 - nodes in this community are weakly interconnected._
- **Should `game_screen.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.047619047619047616 - nodes in this community are weakly interconnected._
- **Should `package:flutter/material.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.07563025210084033 - nodes in this community are weakly interconnected._
- **Should `sound_service.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.06896551724137931 - nodes in this community are weakly interconnected._