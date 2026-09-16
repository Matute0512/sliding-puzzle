# Graph Report - sliding_puzzle  (2026-09-16)

## Corpus Check
- 10 files · ~135,282 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 567 nodes · 694 edges · 42 communities (29 shown, 9 thin omitted)
- Extraction: 98% EXTRACTED · 2% INFERRED · 0% AMBIGUOUS · INFERRED: 14 edges (avg confidence: 0.89)
- Token cost: 53,414 input · 0 output

## Community Hubs (Navigation)
- Game Screen & Victory Flow
- Firebase Leaderboard Service
- Screens & Shared Widgets
- Saved Game Service
- Privacy Policy & Data Disclosure
- Home Screen & Store Review
- Audio Service
- Local Records & Preferences
- Theme & Design Tokens
- Game Timer Tests
- Challenge Levels Screen
- Puzzle Core Logic
- iOS Platform Shell
- App Bootstrap & Settings
- App Settings Provider
- Widget Test Harness
- Puzzle Tile Widget
- HUD Card Widget
- Reusable Private Widgets
- Settings Screen UI
- Web PWA Manifest
- HUD & Tile Widget Tests
- CI Release Pipeline
- Alias Dialog Test
- Gradle Wrapper Script
- App Icon Visual Identity
- Firebase Service Test
- Settings Screen Test
- Dependency Docs Links
- Android Entry Point
- Confetti Dependency
- Audio Dependency
- Poppins Font Asset
- Rate Prompt Dependency
- Web Bootstrap Loader
- Flutter Lint Ruleset
- DevTools Config
- Cronometro Concept

## God Nodes (most connected - your core abstractions)
1. `AppColors` - 8 edges
2. `AppSettingsProvider` - 8 edges
3. `Top 5 Global Leaderboard` - 6 edges
4. `AppDelegate` - 5 edges
5. `build-release Job (AAB)` - 5 edges
6. `Sliding Puzzle (proyecto Flutter)` - 5 edges
7. `4x4 Rounded Tile Grid Motif` - 4 edges
8. `ficha_icono.png - Sliding Puzzle App Icon` - 4 edges
9. `PartidaGuardada` - 4 edges
10. `Politica de Privacidad (pagina web)` - 4 edges

## Surprising Connections (you probably didn't know these)
- `Alias publico (maximo 5 caracteres, mayusculas)` --semantically_similar_to--> `Alias publico (hasta 5 caracteres)`  [INFERRED] [semantically similar]
  index.html → README.md
- `Politica de Privacidad (pagina web)` --semantically_similar_to--> `PRIVACY_POLICY.md`  [INFERRED] [semantically similar]
  index.html → README.md
- `iOS Launch Screen Assets` --conceptually_related_to--> `Sliding Puzzle (proyecto Flutter)`  [INFERRED]
  ios/Runner/Assets.xcassets/LaunchImage.imageset/README.md → README.md
- `Badge de version del README (2.2.1)` --conceptually_related_to--> `Package sliding_puzzle v2.3.1+9`  [AMBIGUOUS]
  README.md → pubspec.yaml
- `Top 5 Global Leaderboard` --references--> `Firebase Anonymous Authentication`  [EXTRACTED]
  README.md → PRIVACY_POLICY.md

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **CI Release Pipeline** — _github_workflows_ci_ci_workflow, _github_workflows_ci_quality_job, _github_workflows_ci_build_release_job, _github_workflows_ci_jdk21_gradle_override, _github_workflows_ci_release_signing, _github_workflows_ci_obfuscated_build [EXTRACTED 1.00]
- **ficha_icono Visual Identity System** — assets_icon_ficha_icono_app_icon, assets_icon_ficha_icono_tile_grid_motif, assets_icon_ficha_icono_pipe_connector_motif, assets_icon_ficha_icono_dark_squircle_container, assets_icon_ficha_icono_raised_tile_shading [EXTRACTED 1.00]
- **Firebase Global Leaderboard Data Flow** — readme_top_5_global, privacy_policy_firebase_authentication_anonymous, privacy_policy_cloud_firestore, privacy_policy_anonymous_uid, privacy_policy_public_alias, pubspec_firebase_auth, pubspec_cloud_firestore [INFERRED 0.95]
- **Flujo del Top 5 Global (identidad anonima, alias, puntaje, Firestore)** — readme_top_5_global, readme_alias_publico, readme_firebase_service, index_firebase_authentication, index_cloud_firestore, index_anonymous_uid, index_puntaje_data [INFERRED 0.85]
- **Divulgacion de datos de la politica de privacidad** — index_politica_privacidad, index_no_pii, index_alias_publico, index_anonymous_uid, index_puntaje_data, index_data_deletion [EXTRACTED 1.00]
- **Panel de configuracion (tema, sonido, musica) y su persistencia** — readme_app_settings_provider, readme_modo_oscuro, readme_sonido_musica, readme_sound_service, pubspec_provider, pubspec_flutter_soloud [EXTRACTED 1.00]

## Communities (42 total, 9 thin omitted)

### Community 0 - "Game Screen & Victory Flow"
Cohesion: 0.04
Nodes (56): ConfettiController, dart:async, int get, _alternarPausa, _avisoTop, build, _celebrar, _confettiController (+48 more)

### Community 1 - "Firebase Leaderboard Service"
Cohesion: 0.05
Nodes (39): DateTime, int?, android, DefaultFirebaseOptions, ios, web, alias, compareTo (+31 more)

### Community 2 - "Screens & Shared Widgets"
Cohesion: 0.06
Nodes (34): AppColors, GameScreen, _GameScreenState, HomeScreen, _HomeScreenState, build, _cargando, _cargarTops (+26 more)

### Community 3 - "Saved Game Service"
Cohesion: 0.06
Nodes (32): dart:convert, borrar, _clave, desdeJson, esDesafio, guardar, movimientos, nivel (+24 more)

### Community 4 - "Privacy Policy & Data Disclosure"
Cohesion: 0.07
Nodes (33): Alias publico (maximo 5 caracteres, mayusculas), Identificador anonimo (UID), Cloud Firestore, Eliminacion de datos del Top 5 Global, Firebase Authentication (sesion anonima), No recoleccion de PII, Politica de Privacidad (pagina web), Datos del puntaje (movimientos y tiempo en segundos) (+25 more)

### Community 5 - "Home Screen & Store Review"
Cohesion: 0.07
Nodes (31): AppLifecycleListener, _avisarFalloTienda, build, _cargarPartidaGuardada, _continuarPartida, createState, _descartarPartidaGuardada, dispose (+23 more)

### Community 6 - "Audio Service"
Cohesion: 0.07
Nodes (28): alternarMusica, alternarSonido, _claveMusica, _claveSonido, detenerMusica, _fuenteClick, _fuenteMusica, _fuenteVictoria (+20 more)

### Community 7 - "Local Records & Preferences"
Cohesion: 0.07
Nodes (25): _claveAlias, _claveAppCalificada, _claveEstrellas, _claveNivelMaximo, _clavesHistorialLibre, _clavesViejas, guardarAlias, limpiarDatosViejos (+17 more)

### Community 8 - "Theme & Design Tokens"
Cohesion: 0.08
Nodes (23): Color, accentShadow, AppTheme, background, cardBackground, copyWith, dark, emptyTile (+15 more)

### Community 9 - "Game Timer Tests"
Cohesion: 0.10
Nodes (20): AnimatedPositioned, return, ancho, _avanzarRelojReal, cabeza, caminos, cola, fichas (+12 more)

### Community 10 - "Challenge Levels Screen"
Cohesion: 0.10
Nodes (20): game_screen.dart, bloqueado, build, _cantidadNiveles, _cargando, _cargarProgreso, ChallengeLevelsScreen, _ChallengeLevelsScreenState (+12 more)

### Community 11 - "Puzzle Core Logic"
Cohesion: 0.10
Nodes (20): configuracionNivel, _corregirParidad, desafioMargenObjetivo4x4, desafioProfundidadMax4x4, desafioProfundidadMin4x4, _desplazamiento, Direccion, direccionHaciaVacio (+12 more)

### Community 12 - "iOS Platform Shell"
Cohesion: 0.11
Nodes (14): Any, Bool, Flutter, FlutterAppDelegate, FlutterImplicitEngineBridge, FlutterImplicitEngineDelegate, FlutterSceneDelegate, AppDelegate (+6 more)

### Community 13 - "App Bootstrap & Settings"
Cohesion: 0.13
Nodes (16): ChangeNotifier, firebase_options.dart, build, inicializar, _inicializarFirebase, limpiarDatosViejos, main, settings (+8 more)

### Community 14 - "App Settings Provider"
Cohesion: 0.14
Nodes (13): bool get, alternarMusica, alternarSonido, cambiarTema, _claveMusica, _claveSonido, _claveTema, inicializar (+5 more)

### Community 15 - "Widget Test Harness"
Cohesion: 0.18
Nodes (10): AnimatedContainer, dart:math, package:sliding_puzzle/screens/challenge_levels_screen.dart, package:sliding_puzzle/screens/game_screen.dart, package:sliding_puzzle/screens/home_screen.dart, package:sliding_puzzle/widgets/puzzle_board.dart, ScrollableState, Stack (+2 more)

### Community 16 - "Puzzle Tile Widget"
Cohesion: 0.17
Nodes (11): activa, build, esSocket, numero, onSwipe, onTap, PuzzleTile, size (+3 more)

### Community 17 - "HUD Card Widget"
Cohesion: 0.18
Nodes (10): @immutable, IconData, AppColors, build, HudCard, icono, label, valor (+2 more)

### Community 18 - "Reusable Private Widgets"
Cohesion: 0.18
Nodes (11): _CeldaNivel, _ResumenProgreso, _FilaEstrellas, _FilaResultado, _ItemAyuda, _BotonContinuar, _SeccionTop, _CardConfiguracion (+3 more)

### Community 19 - "Settings Screen UI"
Cohesion: 0.18
Nodes (10): child, colors, descripcion, icono, label, onChanged, titulo, valor (+2 more)

### Community 20 - "Web PWA Manifest"
Cohesion: 0.18
Nodes (10): background_color, description, display, icons, name, orientation, prefer_related_applications, short_name (+2 more)

### Community 21 - "HUD & Tile Widget Tests"
Cohesion: 0.22
Nodes (8): package:flutter/material.dart, package:sliding_puzzle/theme/app_theme.dart, package:sliding_puzzle/widgets/hud_card.dart, package:sliding_puzzle/widgets/puzzle_tile.dart, construir, main, construir, main

### Community 22 - "CI Release Pipeline"
Cohesion: 0.47
Nodes (6): build-release Job (AAB), CI Workflow, JDK 21 gradle.java.home Override, Obfuscated AAB Build, quality Job (analyze, test, Android lint), Release Signing Step

### Community 23 - "Alias Dialog Test"
Cohesion: 0.33
Nodes (5): NavigatorState, package:sliding_puzzle/widgets/alias_dialog.dart, main, _montar, navegador

### Community 24 - "Gradle Wrapper Script"
Cohesion: 0.60
Nodes (3): gradlew script, die(), warn()

### Community 25 - "App Icon Visual Identity"
Cohesion: 0.70
Nodes (5): ficha_icono.png - Sliding Puzzle App Icon, Dark Squircle Icon Container, Pipe / Connector Path Motif, Raised Tile Highlight Shading, 4x4 Rounded Tile Grid Motif

### Community 26 - "Firebase Service Test"
Cohesion: 0.40
Nodes (4): package:flutter_test/flutter_test.dart, package:sliding_puzzle/services/firebase_service.dart, main, p

### Community 27 - "Settings Screen Test"
Cohesion: 0.40
Nodes (4): package:provider/provider.dart, package:sliding_puzzle/providers/app_settings_provider.dart, package:sliding_puzzle/screens/settings_screen.dart, main

### Community 28 - "Dependency Docs Links"
Cohesion: 0.40
Nodes (5): provider ^6.1.5+1, assets/sounds/ (assets declarados), providers/app_settings_provider.dart, Modo oscuro (claro/oscuro/sistema), Efectos de sonido y musica de fondo

## Ambiguous Edges - Review These
- `Badge de version del README (2.2.1)` → `Package sliding_puzzle v2.3.1+9`  [AMBIGUOUS]
  README.md · relation: conceptually_related_to

## Knowledge Gaps
- **339 isolated node(s):** `child`, `colors`, `descripcion`, `icono`, `label` (+334 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 406 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **9 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **What is the exact relationship between `Badge de version del README (2.2.1)` and `Package sliding_puzzle v2.3.1+9`?**
  _Edge tagged AMBIGUOUS (relation: conceptually_related_to) - confidence is low._
- **Why does `PartidaGuardada` connect `Saved Game Service` to `Game Screen & Victory Flow`, `Home Screen & Store Review`?**
  _High betweenness centrality (0.021) - this node is a cross-community bridge._
- **Why does `AppColors` connect `HUD Card Widget` to `Screens & Shared Widgets`, `Theme & Design Tokens`, `Challenge Levels Screen`, `Puzzle Tile Widget`, `Settings Screen UI`?**
  _High betweenness centrality (0.017) - this node is a cross-community bridge._
- **Why does `AppSettingsProvider` connect `App Bootstrap & Settings` to `Settings Screen UI`, `App Settings Provider`?**
  _High betweenness centrality (0.010) - this node is a cross-community bridge._
- **What connects `child`, `colors`, `descripcion` to the rest of the system?**
  _339 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Game Screen & Victory Flow` be split into smaller, more focused modules?**
  _Cohesion score 0.03508771929824561 - nodes in this community are weakly interconnected._
- **Should `Firebase Leaderboard Service` be split into smaller, more focused modules?**
  _Cohesion score 0.04878048780487805 - nodes in this community are weakly interconnected._