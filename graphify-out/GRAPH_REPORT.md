# Graph Report - sliding_puzzle  (2026-09-19)

## Corpus Check
- 38 files · ~91,343 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 763 nodes · 992 edges · 57 communities (46 shown, 7 thin omitted)
- Extraction: 96% EXTRACTED · 4% INFERRED · 0% AMBIGUOUS · INFERRED: 36 edges (avg confidence: 0.87)
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- Game Screen Core
- Project Overview & Docs
- Home Menu Navigation
- Local Records & Settings
- Saved Game & Board Widgets
- Theme & Shared Widgets
- Audio Service
- Daily Challenge State
- Puzzle Logic & Calibration
- iOS Runner Shell
- Records Screen
- Global Leaderboard Service
- Challenge Levels Screen
- Daily Leaderboard Service
- Daily Results Dialog
- Persistence & Test Wiring
- App Entry & Bootstrap
- Test Puzzle Solver
- Image Puzzle Test Screen
- Widget Test Imports
- Puzzle Tile Widget
- Challenge Calibration Tests
- Daily Victory Dialog
- Timer & HUD Tests
- Challenge UI Components
- Image Tile Widget
- Settings Screen
- Continue Game Tests
- Layout & Board Tests
- Alias Dialog
- Daily Isolation Tests
- Web PWA Manifest
- Screen State Classes
- Localized Test Helper
- Daily Photo Composition
- HUD Card Widget
- Firebase Platform Options
- Service Unit Tests
- CI Release Pipeline
- Alias Dialog Tests
- Gradle Wrapper Script
- App Icon Visual Identity
- Settings Screen Tests
- Settings Feature Set
- Android Activity Shell
- Firestore Identity Model
- Privacy Policy
- App Store Link
- GameScreen Declaration
- Web Bootstrap
- Lint Configuration
- DevTools Config
- Anonymous Auth

## God Nodes (most connected - your core abstractions)
1. `Sliding Puzzle (project)` - 9 edges
2. `AppDelegate` - 5 edges
3. `build-release Job (AAB)` - 5 edges
4. `Modo Desafío (Challenge Mode)` - 5 edges
5. `Top 5 Global Leaderboard` - 5 edges
6. `sliding_puzzle package` - 5 edges
7. `Bare Trees Reflected in Still Water (monochrome landscape photograph)` - 5 edges
8. `AppColors` - 4 edges
9. `4x4 Rounded Tile Grid Motif` - 4 edges
10. `ficha_icono.png - Sliding Puzzle App Icon` - 4 edges

## Surprising Connections (you probably didn't know these)
- `Alias publico (maximo 5 caracteres, mayusculas)` --semantically_similar_to--> `Public Alias (up to 5 chars)`  [INFERRED] [semantically similar]
  index.html → README.md
- `iOS Launch Screen Assets` --conceptually_related_to--> `Sliding Puzzle (project)`  [INFERRED]
  ios/Runner/Assets.xcassets/LaunchImage.imageset/README.md → README.md
- `Sliding Puzzle (project)` --conceptually_related_to--> `Foto del Día (daily image from Cloud Storage)`  [AMBIGUOUS]
  README.md → pubspec.yaml
- `Modo Desafío (Challenge Mode)` --conceptually_related_to--> `cached_network_image 3.4.1 (exact pin)`  [AMBIGUOUS]
  README.md → pubspec.yaml
- `Cloud Firestore` --references--> `cloud_firestore`  [INFERRED]
  index.html → pubspec.yaml

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **CI Release Pipeline** — _github_workflows_ci_ci_workflow, _github_workflows_ci_quality_job, _github_workflows_ci_build_release_job, _github_workflows_ci_jdk21_gradle_override, _github_workflows_ci_release_signing, _github_workflows_ci_obfuscated_build [EXTRACTED 1.00]
- **ficha_icono Visual Identity System** — assets_icon_ficha_icono_app_icon, assets_icon_ficha_icono_tile_grid_motif, assets_icon_ficha_icono_pipe_connector_motif, assets_icon_ficha_icono_dark_squircle_container, assets_icon_ficha_icono_raised_tile_shading [EXTRACTED 1.00]
- **Divulgacion de datos de la politica de privacidad** — index_politica_privacidad, index_no_pii, index_alias_publico, index_anonymous_uid, index_puntaje_data, index_data_deletion [EXTRACTED 1.00]
- **Firebase Global Leaderboard Data Flow** — privacy_policy_firebase_authentication_anonymous, privacy_policy_cloud_firestore, privacy_policy_anonymous_uid, privacy_policy_public_alias, pubspec_firebase_auth, pubspec_cloud_firestore [INFERRED 0.95]
- **Firebase backend stack for the global leaderboard and daily image** — readme_top_5_global_leaderboard, pubspec_firebase_core, pubspec_firebase_auth, pubspec_cloud_firestore, pubspec_firebase_storage, pubspec_foto_del_dia [INFERRED 0.85]
- **Localization codegen chain (ARB template to generated AppLocalizations)** — l10n_arb_dir, l10n_template_arb_file, l10n_app_localizations, pubspec_flutter_localizations, pubspec_generate_true, readme_i18n_es_en [INFERRED 0.85]
- **Local shared_preferences persistence flow** — pubspec_shared_preferences, readme_alias_publico, readme_modo_desafio, readme_sistema_de_estrellas, readme_modo_oscuro [INFERRED 0.75]
- **Monochrome Landscape Compositional System** — assets_images_pexels_toni_clavel_62572784_38947608_photograph, assets_images_pexels_toni_clavel_62572784_38947608_monochrome_composition, assets_images_pexels_toni_clavel_62572784_38947608_silhouette_backlight, assets_images_pexels_toni_clavel_62572784_38947608_reflection_symmetry, assets_images_pexels_toni_clavel_62572784_38947608_misty_hillside_layers [INFERRED 0.85]

## Communities (57 total, 7 thin omitted)

### Community 0 - "Game Screen Core"
Cohesion: 0.03
Nodes (60): dart:async, int get, _alternarPausa, _avisoTop, build, _cargarImagenDiaria, _celebrar, _confettiController (+52 more)

### Community 1 - "Project Overview & Docs"
Cohesion: 0.06
Nodes (44): Alias publico (maximo 5 caracteres, mayusculas), Identificador anonimo (UID), Cloud Firestore, Eliminacion de datos del Top 5 Global, Firebase Authentication (sesion anonima), No recoleccion de PII, Politica de Privacidad (pagina web), Datos del puntaje (movimientos y tiempo en segundos) (+36 more)

### Community 2 - "Home Menu Navigation"
Cohesion: 0.06
Nodes (34): AppLifecycleListener, _avisarFalloTienda, build, _cargarEstadoDiario, _cargarPartidaGuardada, _continuarPartida, createState, _descartarPartidaGuardada (+26 more)

### Community 3 - "Local Records & Settings"
Cohesion: 0.06
Nodes (33): bool get, ChangeNotifier, alternarMusica, alternarSonido, AppSettingsProvider, cambiarTema, _claveMusica, _claveSonido (+25 more)

### Community 4 - "Saved Game & Board Widgets"
Cohesion: 0.06
Nodes (28): ImageProvider, localesSoportados, borrar, _clave, desdeJson, esDesafio, guardar, movimientos (+20 more)

### Community 5 - "Theme & Shared Widgets"
Cohesion: 0.07
Nodes (26): @immutable, Color, accentShadow, AppColors, AppTheme, background, cardBackground, copyWith (+18 more)

### Community 6 - "Audio Service"
Cohesion: 0.07
Nodes (27): alternarMusica, alternarSonido, _claveMusica, _claveSonido, detenerMusica, _fuenteClick, _fuenteMusica, _fuenteVictoria (+19 more)

### Community 7 - "Daily Challenge State"
Cohesion: 0.07
Nodes (26): _claveResultado, _claveUltimoDia, DailyChallengeService, fromJson, guardarResultado, imagenDe, imagenRespaldo, marcarJugado (+18 more)

### Community 8 - "Puzzle Logic & Calibration"
Cohesion: 0.08
Nodes (24): configuracionNivel, _corregirParidad, desafioMargenObjetivo4x4, desafioProfundidadMax4x4, desafioProfundidadMin4x4, _desplazamiento, diarioProfundidad, diarioSize (+16 more)

### Community 9 - "iOS Runner Shell"
Cohesion: 0.11
Nodes (14): Any, Bool, Flutter, FlutterAppDelegate, FlutterImplicitEngineBridge, FlutterImplicitEngineDelegate, FlutterSceneDelegate, AppDelegate (+6 more)

### Community 10 - "Records Screen"
Cohesion: 0.11
Nodes (19): AppLocalizations, build, _cargando, _cargarTops, color, createState, _cuerpo, descripcion (+11 more)

### Community 11 - "Global Leaderboard Service"
Cohesion: 0.11
Nodes (18): DateTime, alias, compareTo, esMejorQue, fecha, FirebaseService, fromDocument, id (+10 more)

### Community 12 - "Challenge Levels Screen"
Cohesion: 0.11
Nodes (18): game_screen.dart, bloqueado, build, _cantidadNiveles, _cargando, _cargarProgreso, colors, createState (+10 more)

### Community 13 - "Daily Leaderboard Service"
Cohesion: 0.11
Nodes (18): alias, _coleccion, compareTo, DailyLeaderboardService, esMejorQue, fecha, fromDocument, id (+10 more)

### Community 14 - "Daily Results Dialog"
Cohesion: 0.11
Nodes (17): ../app_info.dart, Color get, accion, build, _colorPuesto, colors, _compartir, createState (+9 more)

### Community 15 - "Persistence & Test Wiring"
Cohesion: 0.14
Nodes (14): package:shared_preferences/shared_preferences.dart, package:sliding_puzzle/l10n/app_localizations_en.dart, package:sliding_puzzle/l10n/app_localizations_es.dart, package:sliding_puzzle/main.dart, package:sliding_puzzle/screens/home_screen.dart, package:sliding_puzzle/services/daily_challenge_service.dart, package:sliding_puzzle/services/daily_leaderboard_service.dart, main (+6 more)

### Community 16 - "App Entry & Bootstrap"
Cohesion: 0.13
Nodes (16): AppSettingsProvider, firebase_options.dart, l10n/supported_locales.dart, build, inicializar, _inicializarFirebase, limpiarDatosViejos, main (+8 more)

### Community 17 - "Test Puzzle Solver"
Cohesion: 0.13
Nodes (14): AnimatedPositioned, return, ancho, cabeza, caminos, cola, fichas, jugarSecuencia (+6 more)

### Community 18 - "Image Puzzle Test Screen"
Cohesion: 0.14
Nodes (14): build, createState, ImagePuzzleTestScreen, _ImagePuzzleTestScreenState, initState, _movimientos, _onTapFicha, _reiniciar (+6 more)

### Community 19 - "Widget Test Imports"
Cohesion: 0.15
Nodes (12): dart:convert, Error, Exception, Image, OverflowBox, package:flutter/material.dart, package:sliding_puzzle/widgets/puzzle_tile.dart, _imagenPrueba (+4 more)

### Community 20 - "Puzzle Tile Widget"
Cohesion: 0.14
Nodes (13): image_tile.dart, activa, build, esSocket, imagen, imagenRespaldo, numero, onSwipe (+5 more)

### Community 21 - "Challenge Calibration Tests"
Cohesion: 0.14
Nodes (13): int?, static const int, _adyacente, _buscar, _conflictosLineales, _h, _hallado, main (+5 more)

### Community 22 - "Daily Victory Dialog"
Cohesion: 0.15
Nodes (12): ConfettiController, build, confetti, DailyVictoryDialog, _FilaResultado, icono, label, mostrar (+4 more)

### Community 23 - "Timer & HUD Tests"
Cohesion: 0.17
Nodes (11): helpers/localized_app.dart, package:sliding_puzzle/widgets/hud_card.dart, _avanzarRelojReal, main, pump, runAsync, _segundosHud, textos (+3 more)

### Community 24 - "Challenge UI Components"
Cohesion: 0.15
Nodes (13): _CeldaNivel, _ResumenProgreso, _FilaEstrellas, _FilaResultado, _ItemAyuda, _BotonContinuar, _SeccionTop, _FilaSwitch (+5 more)

### Community 25 - "Image Tile Widget"
Cohesion: 0.17
Nodes (11): BorderRadius, alineacionDe, borderRadius, build, imagen, _imagenConRespaldo, ImageTile, numero (+3 more)

### Community 26 - "Settings Screen"
Cohesion: 0.17
Nodes (11): image_puzzle_test_screen.dart, _CardConfiguracion, child, colors, descripcion, icono, label, onChanged (+3 more)

### Community 27 - "Continue Game Tests"
Cohesion: 0.17
Nodes (11): PartidaGuardada, _bombearVictoria, _casiResuelto, _enCurso, _partidaDesafio, _partidaEnCurso, _partidaLibre, _pulsarAtras (+3 more)

### Community 28 - "Layout & Board Tests"
Cohesion: 0.18
Nodes (9): AnimatedContainer, dart:math, package:sliding_puzzle/screens/challenge_levels_screen.dart, package:sliding_puzzle/screens/game_screen.dart, package:sliding_puzzle/widgets/puzzle_board.dart, ScrollableState, Stack, main (+1 more)

### Community 29 - "Alias Dialog"
Cohesion: 0.18
Nodes (10): AppColors, l10n/app_localizations.dart, build, _controller, createState, dispose, mostrar, _publicar (+2 more)

### Community 30 - "Daily Isolation Tests"
Cohesion: 0.18
Nodes (9): ../helpers/puzzle_solver.dart, package:sliding_puzzle/services/saved_game_service.dart, package:sliding_puzzle/widgets/image_tile.dart, main, _tablero3x3, main, montarDiario, n (+1 more)

### Community 31 - "Web PWA Manifest"
Cohesion: 0.18
Nodes (10): background_color, description, display, icons, name, orientation, prefer_related_applications, short_name (+2 more)

### Community 32 - "Screen State Classes"
Cohesion: 0.27
Nodes (10): ChallengeLevelsScreen, _ChallengeLevelsScreenState, HomeScreen, _HomeScreenState, AliasDialog, _AliasDialogState, DailyResultsDialog, _DailyResultsDialogState (+2 more)

### Community 33 - "Localized Test Helper"
Cohesion: 0.20
Nodes (9): package:sliding_puzzle/l10n/app_localizations.dart, package:sliding_puzzle/l10n/supported_locales.dart, package:sliding_puzzle/theme/app_theme.dart, required Widget home,
  Locale, appLocalizada, home, locale, localesSoportados (+1 more)

### Community 34 - "Daily Photo Composition"
Cohesion: 0.28
Nodes (9): Low Ridge Horizon Band, Misty Receding Hillside Depth Layers, Monochrome Grayscale Composition, Pexels (stock photography source), Bare Trees Reflected in Still Water (monochrome landscape photograph), Mirrored Water Reflection Symmetry, Backlit Tree Silhouettes Against Haze, Toni Clavel (photographer) (+1 more)

### Community 35 - "HUD Card Widget"
Cohesion: 0.25
Nodes (7): IconData, build, HudCard, icono, label, valor, theme/app_theme.dart

### Community 36 - "Firebase Platform Options"
Cohesion: 0.25
Nodes (7): android, DefaultFirebaseOptions, ios, web, package:firebase_core/firebase_core.dart, package:flutter/foundation.dart, static const FirebaseOptions

### Community 37 - "Service Unit Tests"
Cohesion: 0.25
Nodes (6): package:flutter_test/flutter_test.dart, package:sliding_puzzle/services/firebase_service.dart, package:sliding_puzzle/services/records_service.dart, main, p, main

### Community 38 - "CI Release Pipeline"
Cohesion: 0.47
Nodes (6): build-release Job (AAB), CI Workflow, JDK 21 gradle.java.home Override, Obfuscated AAB Build, quality Job (analyze, test, Android lint), Release Signing Step

### Community 39 - "Alias Dialog Tests"
Cohesion: 0.33
Nodes (5): NavigatorState, package:sliding_puzzle/widgets/alias_dialog.dart, main, _montar, navegador

### Community 40 - "Gradle Wrapper Script"
Cohesion: 0.60
Nodes (3): gradlew script, die(), warn()

### Community 41 - "App Icon Visual Identity"
Cohesion: 0.70
Nodes (5): ficha_icono.png - Sliding Puzzle App Icon, Dark Squircle Icon Container, Pipe / Connector Path Motif, Raised Tile Highlight Shading, 4x4 Rounded Tile Grid Motif

### Community 42 - "Settings Screen Tests"
Cohesion: 0.40
Nodes (4): package:provider/provider.dart, package:sliding_puzzle/providers/app_settings_provider.dart, package:sliding_puzzle/screens/settings_screen.dart, main

### Community 43 - "Settings Feature Set"
Cohesion: 0.50
Nodes (5): flutter_soloud, provider, Dark Mode (light/dark/system), Settings Panel, Sound Effects and Background Music

### Community 45 - "Firestore Identity Model"
Cohesion: 0.67
Nodes (3): Anonymous UID, Cloud Firestore Score Storage, Public Alias (max 5 characters)

### Community 46 - "Privacy Policy"
Cohesion: 0.67
Nodes (3): Data Deletion Process, No PII Collection Principle, Sliding Puzzle Privacy Policy

## Ambiguous Edges - Review These
- `Sliding Puzzle (project)` → `Foto del Día (daily image from Cloud Storage)`  [AMBIGUOUS]
  README.md · relation: conceptually_related_to
- `Modo Desafío (Challenge Mode)` → `cached_network_image 3.4.1 (exact pin)`  [AMBIGUOUS]
  README.md · relation: conceptually_related_to
- `sliding_puzzle package` → `assets/images/ bundle`  [AMBIGUOUS]
  pubspec.yaml · relation: shares_data_with

## Knowledge Gaps
- **454 isolated node(s):** `android`, `DefaultFirebaseOptions`, `ios`, `web`, `alias` (+449 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 534 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **7 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **What is the exact relationship between `Sliding Puzzle (project)` and `Foto del Día (daily image from Cloud Storage)`?**
  _Edge tagged AMBIGUOUS (relation: conceptually_related_to) - confidence is low._
- **What is the exact relationship between `Modo Desafío (Challenge Mode)` and `cached_network_image 3.4.1 (exact pin)`?**
  _Edge tagged AMBIGUOUS (relation: conceptually_related_to) - confidence is low._
- **What is the exact relationship between `sliding_puzzle package` and `assets/images/ bundle`?**
  _Edge tagged AMBIGUOUS (relation: shares_data_with) - confidence is low._
- **Why does `PuntajeDiario` connect `Daily Leaderboard Service` to `Daily Results Dialog`?**
  _High betweenness centrality (0.007) - this node is a cross-community bridge._
- **Why does `AppColors` connect `Theme & Shared Widgets` to `HUD Card Widget`?**
  _High betweenness centrality (0.005) - this node is a cross-community bridge._
- **What connects `android`, `DefaultFirebaseOptions`, `ios` to the rest of the system?**
  _454 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Game Screen Core` be split into smaller, more focused modules?**
  _Cohesion score 0.03278688524590164 - nodes in this community are weakly interconnected._