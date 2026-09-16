# Graph Report - sliding_puzzle  (2026-09-16)

## Corpus Check
- 95 files · ~130,664 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 484 nodes · 590 edges · 29 communities (21 shown, 4 thin omitted)
- Extraction: 98% EXTRACTED · 2% INFERRED · 0% AMBIGUOUS · INFERRED: 10 edges (avg confidence: 0.87)
- Token cost: 85,236 input · 0 output

## Community Hubs (Navigation)
- Game Screen & Victory Flow
- Settings Screen UI
- Challenge Levels Screen
- Firebase Leaderboard Service
- CI Pipeline & Privacy Policy
- App Bootstrap & Settings Provider
- Local Records & Preferences
- Audio Service
- Home Screen & Store Review
- Theme & Design Tokens
- Game Timer Tests
- Puzzle Core Logic
- iOS Platform Shell
- Widget Test Harness
- Web PWA Manifest
- HUD & Tile Widget Tests
- Gradle Wrapper Script
- App Icon Visual Identity
- Firebase Service Test
- Settings Screen Test
- Records Service Test
- Android Entry Point
- Web Bootstrap Loader
- DevTools Config
- Tile Control Concept

## God Nodes (most connected - your core abstractions)
1. `sliding_puzzle Package` - 13 edges
2. `AppColors` - 12 edges
3. `AppSettingsProvider` - 8 edges
4. `AppDelegate` - 5 edges
5. `build-release Job (AAB)` - 5 edges
6. `Sliding Puzzle Privacy Policy` - 5 edges
7. `Top 5 Global Leaderboard` - 5 edges
8. `CI Workflow` - 4 edges
9. `Cloud Firestore Score Storage` - 4 edges
10. `Sliding Puzzle` - 4 edges

## Surprising Connections (you probably didn't know these)
- `Privacy Policy Web Page (index.html)` --conceptually_related_to--> `Sliding Puzzle Privacy Policy`  [AMBIGUOUS]
  index.html → PRIVACY_POLICY.md
- `Difficulty Levels (3x3, 4x4, 5x5)` --conceptually_related_to--> `Top 5 Global Leaderboard`  [INFERRED]
  README.md → PRIVACY_POLICY.md
- `Top 5 Global Leaderboard (Firebase Firestore)` --conceptually_related_to--> `Top 5 Global Leaderboard`  [INFERRED]
  README.md → PRIVACY_POLICY.md
- `Sliding Puzzle` --references--> `sliding_puzzle Package`  [AMBIGUOUS]
  README.md → pubspec.yaml
- `sliding_puzzle Package` --conceptually_related_to--> `CI Workflow`  [INFERRED]
  pubspec.yaml → .github/workflows/ci.yml

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **Sliding Puzzle Feature Set** — readme_sliding_puzzle, readme_difficulty_levels, readme_challenge_mode, readme_global_leaderboard, readme_dark_mode, readme_sound_music, readme_gesture_controls, readme_poppins_font [EXTRACTED 1.00]
- **Firebase Global Leaderboard Data Flow** — readme_global_leaderboard, privacy_policy_top_5_global, privacy_policy_firebase_authentication_anonymous, privacy_policy_cloud_firestore, privacy_policy_anonymous_uid, privacy_policy_public_alias, pubspec_firebase_auth, pubspec_cloud_firestore [INFERRED 0.95]
- **CI Release Pipeline** — _github_workflows_ci_ci_workflow, _github_workflows_ci_quality_job, _github_workflows_ci_build_release_job, _github_workflows_ci_jdk21_gradle_override, _github_workflows_ci_release_signing, _github_workflows_ci_obfuscated_build [EXTRACTED 1.00]
- **ficha_icono Visual Identity System** — assets_icon_ficha_icono_app_icon, assets_icon_ficha_icono_tile_grid_motif, assets_icon_ficha_icono_pipe_connector_motif, assets_icon_ficha_icono_dark_squircle_container, assets_icon_ficha_icono_raised_tile_shading [EXTRACTED 1.00]

## Communities (29 total, 4 thin omitted)

### Community 0 - "Game Screen & Victory Flow"
Cohesion: 0.04
Nodes (49): ConfettiController, dart:async, _alternarPausa, _avisoTop, build, _celebrar, _confettiController, createState (+41 more)

### Community 1 - "Settings Screen UI"
Cohesion: 0.05
Nodes (41): @immutable, IconData, _CeldaNivel, _ResumenProgreso, _FilaEstrellas, _FilaResultado, _ItemAyuda, _SeccionTop (+33 more)

### Community 2 - "Challenge Levels Screen"
Cohesion: 0.05
Nodes (41): game_screen.dart, bloqueado, build, _cantidadNiveles, _cargando, _cargarProgreso, ChallengeLevelsScreen, _ChallengeLevelsScreenState (+33 more)

### Community 3 - "Firebase Leaderboard Service"
Cohesion: 0.05
Nodes (39): DateTime, int?, android, DefaultFirebaseOptions, ios, web, alias, compareTo (+31 more)

### Community 4 - "CI Pipeline & Privacy Policy"
Cohesion: 0.07
Nodes (35): build-release Job (AAB), CI Workflow, JDK 21 gradle.java.home Override, Obfuscated AAB Build, quality Job (analyze, test, Android lint), Release Signing Step, Flutter Lint Ruleset, Privacy Policy Web Page (index.html) (+27 more)

### Community 5 - "App Bootstrap & Settings Provider"
Cohesion: 0.07
Nodes (29): bool get, ChangeNotifier, firebase_options.dart, build, inicializar, _inicializarFirebase, limpiarDatosViejos, main (+21 more)

### Community 6 - "Local Records & Preferences"
Cohesion: 0.07
Nodes (27): dart:convert, _claveAlias, _claveAppCalificada, _claveEstrellas, _claveNivelMaximo, _clavesHistorialLibre, _clavesViejas, guardarAlias (+19 more)

### Community 7 - "Audio Service"
Cohesion: 0.07
Nodes (28): alternarMusica, alternarSonido, _claveMusica, _claveSonido, detenerMusica, _fuenteClick, _fuenteMusica, _fuenteVictoria (+20 more)

### Community 8 - "Home Screen & Store Review"
Cohesion: 0.09
Nodes (24): AppLifecycleListener, _avisarFalloTienda, build, createState, dispose, HomeScreen, _HomeScreenState, initState (+16 more)

### Community 9 - "Theme & Design Tokens"
Cohesion: 0.08
Nodes (23): Color, accentShadow, AppTheme, background, cardBackground, copyWith, dark, emptyTile (+15 more)

### Community 10 - "Game Timer Tests"
Cohesion: 0.10
Nodes (20): AnimatedPositioned, return, ancho, _avanzarRelojReal, cabeza, caminos, cola, fichas (+12 more)

### Community 11 - "Puzzle Core Logic"
Cohesion: 0.10
Nodes (20): configuracionNivel, _corregirParidad, desafioMargenObjetivo4x4, desafioProfundidadMax4x4, desafioProfundidadMin4x4, _desplazamiento, Direccion, direccionHaciaVacio (+12 more)

### Community 12 - "iOS Platform Shell"
Cohesion: 0.11
Nodes (14): Any, Bool, Flutter, FlutterAppDelegate, FlutterImplicitEngineBridge, FlutterImplicitEngineDelegate, FlutterSceneDelegate, AppDelegate (+6 more)

### Community 13 - "Widget Test Harness"
Cohesion: 0.18
Nodes (10): AnimatedContainer, dart:math, package:sliding_puzzle/screens/challenge_levels_screen.dart, package:sliding_puzzle/screens/game_screen.dart, package:sliding_puzzle/screens/home_screen.dart, package:sliding_puzzle/widgets/puzzle_board.dart, ScrollableState, Stack (+2 more)

### Community 14 - "Web PWA Manifest"
Cohesion: 0.18
Nodes (10): background_color, description, display, icons, name, orientation, prefer_related_applications, short_name (+2 more)

### Community 15 - "HUD & Tile Widget Tests"
Cohesion: 0.22
Nodes (8): package:flutter/material.dart, package:sliding_puzzle/theme/app_theme.dart, package:sliding_puzzle/widgets/hud_card.dart, package:sliding_puzzle/widgets/puzzle_tile.dart, construir, main, construir, main

### Community 16 - "Gradle Wrapper Script"
Cohesion: 0.60
Nodes (3): gradlew script, die(), warn()

### Community 17 - "App Icon Visual Identity"
Cohesion: 0.70
Nodes (5): ficha_icono.png - Sliding Puzzle App Icon, Dark Squircle Icon Container, Pipe / Connector Path Motif, Raised Tile Highlight Shading, 4x4 Rounded Tile Grid Motif

### Community 18 - "Firebase Service Test"
Cohesion: 0.40
Nodes (4): package:flutter_test/flutter_test.dart, package:sliding_puzzle/services/firebase_service.dart, main, p

### Community 19 - "Settings Screen Test"
Cohesion: 0.40
Nodes (4): package:provider/provider.dart, package:sliding_puzzle/providers/app_settings_provider.dart, package:sliding_puzzle/screens/settings_screen.dart, main

### Community 20 - "Records Service Test"
Cohesion: 0.50
Nodes (3): package:shared_preferences/shared_preferences.dart, package:sliding_puzzle/services/records_service.dart, main

## Ambiguous Edges - Review These
- `Sliding Puzzle Privacy Policy` → `Privacy Policy Web Page (index.html)`  [AMBIGUOUS]
  index.html · relation: conceptually_related_to
- `Sliding Puzzle` → `sliding_puzzle Package`  [AMBIGUOUS]
  README.md · relation: references

## Knowledge Gaps
- **284 isolated node(s):** `XCTest`, `DefaultFirebaseOptions`, `web`, `android`, `ios` (+279 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 346 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **4 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **What is the exact relationship between `Sliding Puzzle Privacy Policy` and `Privacy Policy Web Page (index.html)`?**
  _Edge tagged AMBIGUOUS (relation: conceptually_related_to) - confidence is low._
- **What is the exact relationship between `Sliding Puzzle` and `sliding_puzzle Package`?**
  _Edge tagged AMBIGUOUS (relation: references) - confidence is low._
- **Why does `AppColors` connect `Settings Screen UI` to `Game Screen & Victory Flow`, `Home Screen & Store Review`, `Challenge Levels Screen`, `Theme & Design Tokens`?**
  _High betweenness centrality (0.046) - this node is a cross-community bridge._
- **Why does `AppSettingsProvider` connect `App Bootstrap & Settings Provider` to `Settings Screen UI`?**
  _High betweenness centrality (0.012) - this node is a cross-community bridge._
- **What connects `XCTest`, `DefaultFirebaseOptions`, `web` to the rest of the system?**
  _284 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Game Screen & Victory Flow` be split into smaller, more focused modules?**
  _Cohesion score 0.04 - nodes in this community are weakly interconnected._
- **Should `Settings Screen UI` be split into smaller, more focused modules?**
  _Cohesion score 0.05496828752642706 - nodes in this community are weakly interconnected._