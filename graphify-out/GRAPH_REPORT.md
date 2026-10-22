# Graph Report - sliding_puzzle  (2026-10-22)

## Corpus Check
- 123 files · ~120,467 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 1144 nodes · 1555 edges · 74 communities (62 shown, 8 thin omitted)
- Extraction: 99% EXTRACTED · 1% INFERRED · 0% AMBIGUOUS · INFERRED: 15 edges (avg confidence: 0.88)
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- AppTheme & Arcade Color Tokens
- GameScreen Gameplay & Victory Flow
- Kenney 9-Slice Sprites & GameBackground
- SavedGameService, SoundService & Locales
- Dificultad Enum & RecordsScreen
- ImageTile & Baked Photo Tile Textures
- AppSettingsProvider & Audio Toggles
- HomeScreen & Asset Precache
- PuzzleBoard & Baked Sockets Layer
- Impeller Pre-Tinted Sprite & Tile Rendering
- DailyChallengeService (UTC Seed & Storage)
- PuzzleLogic & Challenge Calibration
- DailyResultsDialog & Share Flow
- GameScreen Repaint & Frame Geometry Guards
- ChallengeLevels & Alias Dialog Widget Tests
- iOS Runner AppDelegate & SceneDelegate
- BestRunService (Local-First Personal Records)
- FirebaseService (Global Top 5 Firestore)
- DailyLeaderboardService
- ChallengeLevelsScreen Grid & Progress UI
- DifficultyButton & ModeSwitch Widgets
- SettingsScreen UI
- DailyPreviewDialog & Daily Mode Tests
- SavedGameService & Continue Game Tests
- GameHeader & Overflow Menu
- BFS/A* PuzzleSolver Test Helper
- HomeHeader Widget
- Challenge Level Calibration Tests
- ArcadeButton 9-Slice Widget
- ArcadePanel Surface Widget
- DailyVictoryDialog & Confetti
- App Entrypoint (main.dart)
- GameScreen Timer & HudCard Tests
- BestRunCard Home Widget
- Localization & Settings Widget Tests
- Daily & Records Service Unit Tests
- PuzzleTile & ImageTile Widget Tests
- PuzzleLogic & Difficulty Unit Tests
- Kenney Slice Geometry Tests
- Navigation & Route Callbacks
- AliasDialog Input Widget
- GameControls Bottom Bar
- Web PWA Manifest
- Performance Audit (AUDITORIA_RENDIMIENTO.md)
- Project Documentation & Package Metadata
- LocalizedApp Test Wrapper
- Daily Fallback Landscape Photograph
- HudCard Stat Widget
- BestRunService & BestRunCard Tests
- DefaultFirebaseOptions Config
- Board & Challenge State Classes
- HeaderSquareButton Widget
- Privacy Policy (PRIVACY_POLICY.md)
- GitHub Actions CI & Release AAB Pipeline
- Firebase Privacy & Score Schema
- Android Gradle Wrapper
- App Icon Visual Identity (ficha_icono.png)
- CustomPainters (_FondoArcade, _SocketsPainter, _RecorteFichaPainter)
- Duration Formatting (duracion.dart)
- FirebaseService Unit Tests
- Android MainActivity.kt
- Public Privacy Policy Page (index.html)
- Flutter Localization Config (l10n.yaml)
- KenneySlice Immutable Value Class
- Play Store URL Constant (app_info.dart)
- GameScreen Widget Root
- HomeScreen Widget Root
- Web Bootstrap Loader (web/index.html)
- Dart Static Analysis Options
- Flutter DevTools Options

## God Nodes (most connected - your core abstractions)
1. `AppColors` - 17 edges
2. `AUDITORIA_RENDIMIENTO.md (Auditoria y Optimizacion Impeller 120Hz)` - 7 edges
3. `Sliding Puzzle ? Edicion Arcade (README.md)` - 7 edges
4. `AppDelegate` - 5 edges
5. `AppSettingsProvider` - 5 edges
6. `ImageTileState` - 5 edges
7. `Diferimiento de I/O y dialogos hasta completar la transicion de ruta` - 5 edges
8. `Bare Trees Reflected in Still Water (monochrome landscape photograph)` - 5 edges
9. `PartidaGuardada` - 4 edges
10. `ImageTile` - 4 edges

## Surprising Connections (you probably didn't know these)
- `Diferimiento de I/O y dialogos hasta completar la transicion de ruta` --implemented_by--> `_mostrarPreviewAlTerminarTransicion`  [EXTRACTED]
  D:/Dev/Portafolio/Dart/sliding_puzzle/AUDITORIA_RENDIMIENTO.md → lib/screens/game_screen.dart
- `Diferimiento de I/O y dialogos hasta completar la transicion de ruta` --implemented_by--> `_cargarTopsAlTerminarTransicion`  [EXTRACTED]
  D:/Dev/Portafolio/Dart/sliding_puzzle/AUDITORIA_RENDIMIENTO.md → lib/screens/records_screen.dart
- `Identidad Edicion Arcade (Figma + Kenney 9-slice + Kenney Future)` --implemented_by--> `AppColors`  [EXTRACTED]
  D:/Dev/Portafolio/Dart/sliding_puzzle/README.md → lib/theme/app_theme.dart
- `Diferimiento de I/O y dialogos hasta completar la transicion de ruta` --references--> `AppTheme`  [EXTRACTED]
  D:/Dev/Portafolio/Dart/sliding_puzzle/AUDITORIA_RENDIMIENTO.md → lib/theme/app_theme.dart
- `AUDITORIA_RENDIMIENTO.md (Auditoria y Optimizacion Impeller 120Hz)` --references--> `_FondoArcade`  [EXTRACTED]
  D:/Dev/Portafolio/Dart/sliding_puzzle/AUDITORIA_RENDIMIENTO.md → lib/theme/kenney_ui.dart

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **CI pre-publish pipeline (quality gate -> signed obfuscated AAB)** — _github_workflows_ci_quality_job, _github_workflows_ci_build_release_job, _github_workflows_ci_android_lint, _github_workflows_ci_keystore_configure, _github_workflows_ci_build_aab [EXTRACTED 1.00]
- **ficha_icono Visual Identity System** — assets_icon_ficha_icono_app_icon, assets_icon_ficha_icono_tile_grid_motif, assets_icon_ficha_icono_pipe_connector_motif, assets_icon_ficha_icono_dark_squircle_container, assets_icon_ficha_icono_raised_tile_shading [EXTRACTED 1.00]
- **Pipeline de optimizacion del tablero a 120 Hz bajo Impeller** — doc_auditoria_rendimiento, concept_impeller_no_raster_cache, concept_baked_sockets_texture, concept_baked_photo_tiles, lib_widgets_puzzle_board_puzzleboard, lib_widgets_puzzle_board_capasockets, lib_widgets_puzzle_tile_puzzletile, lib_theme_kenney_ui_primarysquareseed, asset_button_square_depth_flat_seed, tool_tint_sprite, test_widget_game_screen_repaint_test [EXTRACTED 1.00]
- **Divulgacion de datos de la politica de privacidad** — index_politica_privacidad, index_no_pii, index_alias_publico, index_anonymous_uid, index_puntaje_data, index_data_deletion [EXTRACTED 1.00]
- **Localization codegen chain (ARB template to generated AppLocalizations)** — l10n_arb_dir, l10n_template_arb_file, l10n_app_localizations [INFERRED 0.85]
- **Monochrome Landscape Compositional System** — assets_images_pexels_toni_clavel_62572784_38947608_photograph, assets_images_pexels_toni_clavel_62572784_38947608_monochrome_composition, assets_images_pexels_toni_clavel_62572784_38947608_silhouette_backlight, assets_images_pexels_toni_clavel_62572784_38947608_reflection_symmetry, assets_images_pexels_toni_clavel_62572784_38947608_misty_hillside_layers [INFERRED 0.85]
- **Firebase Global Leaderboard Data Flow** — privacy_policy_top_5_global, privacy_policy_firebase_authentication_anonymous, privacy_policy_cloud_firestore, privacy_policy_anonymous_uid, privacy_policy_public_alias [INFERRED 0.95]

## Communities (74 total, 8 thin omitted)

### Community 0 - "AppTheme & Arcade Color Tokens"
Cohesion: 0.03
Nodes (78): accentCyan, accentShadow, arcadeBorder, arcadeRadius, arcadeSurface, backdropBottom, backdropGlowLower, backdropGlowUpper (+70 more)

### Community 1 - "GameScreen Gameplay & Victory Flow"
Cohesion: 0.03
Nodes (76): int get, _adoptarDiaActualSiCambio, _alternarPausa, _avisoTop, build, _cargarImagenDiaria, _cargarRecord, _celebrar (+68 more)

### Community 2 - "Kenney 9-Slice Sprites & GameBackground"
Cohesion: 0.04
Nodes (46): app_theme.dart, arrowEast, arrowNorth, arrowSouth, arrowWest, asset, build, centerSlice (+38 more)

### Community 3 - "SavedGameService, SoundService & Locales"
Cohesion: 0.04
Nodes (43): localesSoportados, borrar, _clave, desdeJson, esDesafio, guardar, movimientos, nivel (+35 more)

### Community 4 - "Dificultad Enum & RecordsScreen"
Cohesion: 0.05
Nodes (39): Dificultad, jugables, paraTamano, tamano, build, _cargando, _cargarTops, color (+31 more)

### Community 5 - "ImageTile & Baked Photo Tile Textures"
Cohesion: 0.05
Nodes (39): @visibleForTesting, BorderRadius, double?, ImageProvider? get, ImageStream?, ImageStreamListener?, alineacionDe, _avisadas (+31 more)

### Community 6 - "AppSettingsProvider & Audio Toggles"
Cohesion: 0.05
Nodes (38): bool get, game_screen.dart, alternarMusica, alternarSonido, _claveMusica, _claveSonido, inicializar, _musicaActivada (+30 more)

### Community 7 - "HomeScreen & Asset Precache"
Cohesion: 0.05
Nodes (38): AppLifecycleListener, dart:async, _assetsPrecargados, _avisarFalloTienda, build, _cargarEstadoDiario, _cargarPartidaGuardada, createState (+30 more)

### Community 8 - "PuzzleBoard & Baked Sockets Layer"
Cohesion: 0.06
Nodes (34): _activaCacheada, build, cache, _cacheTextura, createState, _deslizarNumero, dibujarCeldas, didChangeDependencies (+26 more)

### Community 9 - "Impeller Pre-Tinted Sprite & Tile Rendering"
Cohesion: 0.07
Nodes (31): button_square_depth_flat_seed.png (Sprite 9-slice pre-tintado #4361EE), Impeller sin Raster Cache de capas (DisplayList re-ejecutada por frame), image_tile.dart, ImageProvider?, primarySquareSeed, build, _CargandoFoto, DailyPreviewDialog (+23 more)

### Community 10 - "DailyChallengeService (UTC Seed & Storage)"
Cohesion: 0.08
Nodes (25): claveCacheImagen, _claveResultado, _claveUltimoDia, fromJson, guardarResultado, imagenRespaldo, marcarJugado, marcarJugadoHoy (+17 more)

### Community 11 - "PuzzleLogic & Challenge Calibration"
Cohesion: 0.08
Nodes (24): configuracionNivel, _corregirParidad, desafioMargenObjetivo4x4, desafioProfundidadMax4x4, desafioProfundidadMin4x4, _desplazamiento, diarioProfundidad, diarioSize (+16 more)

### Community 12 - "DailyResultsDialog & Share Flow"
Cohesion: 0.10
Nodes (21): ../app_info.dart, Color get, accion, build, _colorPuesto, _compartir, createState, DailyResultsDialog (+13 more)

### Community 13 - "GameScreen Repaint & Frame Geometry Guards"
Cohesion: 0.11
Nodes (18): dart:math, DecoratedBox, GameHeader, package:flutter/rendering.dart, package:sliding_puzzle/screens/game_screen.dart, package:sliding_puzzle/widgets/game_controls.dart, package:sliding_puzzle/widgets/game_header.dart, package:sliding_puzzle/widgets/puzzle_board.dart (+10 more)

### Community 14 - "ChallengeLevels & Alias Dialog Widget Tests"
Cohesion: 0.11
Nodes (17): GridView, helpers/localized_app.dart, NavigatorState, package:sliding_puzzle/screens/challenge_levels_screen.dart, package:sliding_puzzle/screens/home_screen.dart, package:sliding_puzzle/theme/kenney_ui.dart, package:sliding_puzzle/widgets/alias_dialog.dart, SizedBox (+9 more)

### Community 15 - "iOS Runner AppDelegate & SceneDelegate"
Cohesion: 0.11
Nodes (14): Any, Bool, Flutter, FlutterAppDelegate, FlutterImplicitEngineBridge, FlutterImplicitEngineDelegate, FlutterSceneDelegate, AppDelegate (+6 more)

### Community 16 - "BestRunService (Local-First Personal Records)"
Cohesion: 0.10
Nodes (19): firebase_service.dart, BestRunService, _clave, _escribir, esMejorQue, fecha, fromJson, _leer (+11 more)

### Community 17 - "FirebaseService (Global Top 5 Firestore)"
Cohesion: 0.11
Nodes (18): DateTime, alias, compareTo, esMejorQue, fecha, FirebaseService, fromDocument, id (+10 more)

### Community 18 - "DailyLeaderboardService"
Cohesion: 0.11
Nodes (18): alias, _coleccion, compareTo, DailyLeaderboardService, esMejorQue, fecha, fromDocument, id (+10 more)

### Community 19 - "ChallengeLevelsScreen Grid & Progress UI"
Cohesion: 0.11
Nodes (18): _AvisoDesbloqueo, _BarraProgreso, _CabeceraDesafio, _CeldaNivel, _TarjetaProgreso, _FilaEstrellas, _FilaResultado, _ItemAyuda (+10 more)

### Community 20 - "DifficultyButton & ModeSwitch Widgets"
Cohesion: 0.13
Nodes (15): arcade_button.dart, arcade_panel.dart, ../l10n/app_localizations.dart, build, DifficultyButton, dificultad, _estilo, nombreDificultad (+7 more)

### Community 21 - "SettingsScreen UI"
Cohesion: 0.14
Nodes (15): ChangeNotifier, AppSettingsProvider, build, _CardConfiguracion, child, colors, descripcion, _FilaSwitch (+7 more)

### Community 22 - "DailyPreviewDialog & Daily Mode Tests"
Cohesion: 0.13
Nodes (14): Image, package:sliding_puzzle/widgets/daily_preview_dialog.dart, abrirPreview, fotoDelDia, imagenDelDialogo, main, respaldo, aPrimerPlano (+6 more)

### Community 23 - "SavedGameService & Continue Game Tests"
Cohesion: 0.12
Nodes (14): PartidaGuardada, package:sliding_puzzle/services/saved_game_service.dart, main, _tablero3x3, _bombearVictoria, _casiResuelto, _enCurso, _partidaDesafio (+6 more)

### Community 24 - "GameHeader & Overflow Menu"
Cohesion: 0.13
Nodes (14): _AccionMenu, header_square_button.dart, _AccionMenu, build, color, _FilaMenu, icono, label (+6 more)

### Community 25 - "BFS/A* PuzzleSolver Test Helper"
Cohesion: 0.14
Nodes (13): AnimatedPositioned, ancho, cabeza, caminos, cola, fichas, jugarSecuencia, leerTablero (+5 more)

### Community 26 - "HomeHeader Widget"
Cohesion: 0.14
Nodes (13): AppLocalizations, _AccionMenu, build, color, _FilaMenu, HomeHeader, icono, l10n (+5 more)

### Community 27 - "Challenge Level Calibration Tests"
Cohesion: 0.14
Nodes (13): int?, static const int, _adyacente, _buscar, _conflictosLineales, _h, _hallado, main (+5 more)

### Community 28 - "ArcadeButton 9-Slice Widget"
Cohesion: 0.14
Nodes (13): _alto, ArcadeButton, build, _chipFondo, icono, onTap, semantica, subtitulo (+5 more)

### Community 29 - "ArcadePanel Surface Widget"
Cohesion: 0.15
Nodes (12): BoxShadow, Color, EdgeInsetsGeometry, ArcadePanel, borderColor, build, child, color (+4 more)

### Community 30 - "DailyVictoryDialog & Confetti"
Cohesion: 0.15
Nodes (12): ConfettiController, build, confetti, DailyVictoryDialog, _FilaResultado, icono, label, mostrar (+4 more)

### Community 31 - "App Entrypoint (main.dart)"
Cohesion: 0.15
Nodes (12): firebase_options.dart, l10n/supported_locales.dart, build, inicializar, _inicializarFirebase, limpiarDatosViejos, main, settings (+4 more)

### Community 32 - "GameScreen Timer & HudCard Tests"
Cohesion: 0.15
Nodes (11): ../helpers/puzzle_solver.dart, package:sliding_puzzle/widgets/hud_card.dart, _avanzarRelojReal, main, pump, runAsync, _segundosHud, textos (+3 more)

### Community 33 - "BestRunCard Home Widget"
Cohesion: 0.15
Nodes (12): MejorPartida, _badgeBorde, _badgeFondo, _BadgeTrofeo, _Barra, _barraColor, BestRunCard, build (+4 more)

### Community 34 - "Localization & Settings Widget Tests"
Cohesion: 0.18
Nodes (10): package:flutter/material.dart, package:provider/provider.dart, package:sliding_puzzle/main.dart, package:sliding_puzzle/providers/app_settings_provider.dart, package:sliding_puzzle/screens/settings_screen.dart, package:sliding_puzzle/widgets/mode_switch.dart, main, main (+2 more)

### Community 35 - "Daily & Records Service Unit Tests"
Cohesion: 0.17
Nodes (10): package:shared_preferences/shared_preferences.dart, package:sliding_puzzle/l10n/app_localizations_en.dart, package:sliding_puzzle/l10n/app_localizations_es.dart, package:sliding_puzzle/services/daily_challenge_service.dart, package:sliding_puzzle/services/daily_leaderboard_service.dart, package:sliding_puzzle/services/records_service.dart, main, main (+2 more)

### Community 36 - "PuzzleTile & ImageTile Widget Tests"
Cohesion: 0.17
Nodes (10): dart:convert, Error, Exception, package:sliding_puzzle/widgets/image_tile.dart, package:sliding_puzzle/widgets/puzzle_tile.dart, _imagenPrueba, main, _png1x1 (+2 more)

### Community 37 - "PuzzleLogic & Difficulty Unit Tests"
Cohesion: 0.18
Nodes (9): package:flutter_test/flutter_test.dart, package:sliding_puzzle/logic/dificultad.dart, package:sliding_puzzle/logic/puzzle_logic.dart, package:sliding_puzzle/widgets/arcade_button.dart, package:sliding_puzzle/widgets/difficulty_button.dart, main, main, main (+1 more)

### Community 38 - "Kenney Slice Geometry Tests"
Cohesion: 0.18
Nodes (10): dart:ui, Map, return, codec, data, frame, main, size (+2 more)

### Community 39 - "Navigation & Route Callbacks"
Cohesion: 0.18
Nodes (11): _abrirRecords, _abrirAjustes, _abrirAjustes, _abrirRecords, _continuarPartida, _navegarADesafio, _navegarAJuego, _onTapDiario (+3 more)

### Community 40 - "AliasDialog Input Widget"
Cohesion: 0.20
Nodes (10): AliasDialog, _AliasDialogState, build, _controller, createState, dispose, mostrar, _publicar (+2 more)

### Community 41 - "GameControls Bottom Bar"
Cohesion: 0.18
Nodes (10): _BotonControl, build, GameControls, icono, label, onPausar, onReiniciar, onTap (+2 more)

### Community 42 - "Web PWA Manifest"
Cohesion: 0.18
Nodes (10): background_color, description, display, icons, name, orientation, prefer_related_applications, short_name (+2 more)

### Community 43 - "Performance Audit (AUDITORIA_RENDIMIENTO.md)"
Cohesion: 0.20
Nodes (10): Horneado de recortes redondeados por ficha en Desafio Diario (_CacheTexturaFicha), Horneado de n^2 sockets en una sola textura GPU (_CapaSockets), Diferimiento de I/O y dialogos hasta completar la transicion de ruta, AUDITORIA_RENDIMIENTO.md (Auditoria y Optimizacion Impeller 120Hz), _mostrarPreviewAlTerminarTransicion, _cargarTopsAlTerminarTransicion, imagenDe, AppTheme (+2 more)

### Community 44 - "Project Documentation & Package Metadata"
Cohesion: 0.20
Nodes (10): Kenney UI Pack 2.0 License (CC0 1.0 Universal), _cargarMejorPartida, DailyChallengeService, KenneySlices, Package sliding_puzzle v3.0.3+16 (pubspec.yaml), Desafio Diario (Semilla UTC, Firebase Storage .webp y Fallback en 2 capas), Identidad Edicion Arcade (Figma + Kenney 9-slice + Kenney Future), Modo Desafio (20 niveles deterministas con estrellas) (+2 more)

### Community 45 - "LocalizedApp Test Wrapper"
Cohesion: 0.20
Nodes (9): package:sliding_puzzle/l10n/app_localizations.dart, package:sliding_puzzle/l10n/supported_locales.dart, package:sliding_puzzle/theme/app_theme.dart, required Widget home,
  Locale, appLocalizada, home, locale, localesSoportados (+1 more)

### Community 46 - "Daily Fallback Landscape Photograph"
Cohesion: 0.28
Nodes (9): Low Ridge Horizon Band, Misty Receding Hillside Depth Layers, Monochrome Grayscale Composition, Pexels (stock photography source), Bare Trees Reflected in Still Water (monochrome landscape photograph), Mirrored Water Reflection Symmetry, Backlit Tree Silhouettes Against Haze, Toni Clavel (photographer) (+1 more)

### Community 47 - "HudCard Stat Widget"
Cohesion: 0.25
Nodes (8): IconData, AppColors, build, HudCard, icono, label, valor, ThemeExtension

### Community 48 - "BestRunService & BestRunCard Tests"
Cohesion: 0.22
Nodes (7): package:sliding_puzzle/services/best_run_service.dart, package:sliding_puzzle/widgets/best_run_card.dart, main, marca, main, marca, montar

### Community 49 - "DefaultFirebaseOptions Config"
Cohesion: 0.25
Nodes (7): android, DefaultFirebaseOptions, ios, web, package:firebase_core/firebase_core.dart, package:flutter/foundation.dart, static const FirebaseOptions

### Community 50 - "Board & Challenge State Classes"
Cohesion: 0.32
Nodes (8): ChallengeLevelsScreen, _ChallengeLevelsScreenState, _CapaSockets, _CapaSocketsState, PuzzleBoard, _PuzzleBoardState, State, StatefulWidget

### Community 51 - "HeaderSquareButton Widget"
Cohesion: 0.25
Nodes (7): build, child, HeaderSquareButton, onTap, tooltip, String?, Widget?

### Community 52 - "Privacy Policy (PRIVACY_POLICY.md)"
Cohesion: 0.25
Nodes (8): Anonymous UID, Cloud Firestore Score Storage, Data Deletion Process, Firebase Anonymous Authentication, No PII Collection Principle, Public Alias (max 5 characters), Sliding Puzzle Privacy Policy, Top 5 Global Leaderboard

### Community 53 - "GitHub Actions CI & Release AAB Pipeline"
Cohesion: 0.53
Nodes (6): :app:lint Step (Android lint scoped to app module), flutter build appbundle --release --obfuscate, build-release Job (signed AAB), org.gradle.java.home CI Override, Configurar firma Step (keystore provisioning), quality Job (analyze, test, Android lint)

### Community 54 - "Firebase Privacy & Score Schema"
Cohesion: 0.33
Nodes (6): Cloud Firestore, Firebase Authentication (sesion anonima), No recoleccion de PII, Politica de Privacidad (pagina web), Datos del puntaje (movimientos y tiempo en segundos), Top 5 Global Leaderboard (Firebase Auth Anonimo + Firestore)

### Community 55 - "Android Gradle Wrapper"
Cohesion: 0.60
Nodes (3): gradlew script, die(), warn()

### Community 56 - "App Icon Visual Identity (ficha_icono.png)"
Cohesion: 0.70
Nodes (5): ficha_icono.png - Sliding Puzzle App Icon, Dark Squircle Icon Container, Pipe / Connector Path Motif, Raised Tile Highlight Shading, 4x4 Rounded Tile Grid Motif

### Community 57 - "CustomPainters (_FondoArcade, _SocketsPainter, _RecorteFichaPainter)"
Cohesion: 0.50
Nodes (4): CustomPainter, _FondoArcade, _RecorteFichaPainter, _SocketsPainter

### Community 58 - "Duration Formatting (duracion.dart)"
Cohesion: 0.50
Nodes (3): duracionMmSs, minutos, resto

### Community 59 - "FirebaseService Unit Tests"
Cohesion: 0.50
Nodes (3): package:sliding_puzzle/services/firebase_service.dart, main, p

### Community 61 - "Public Privacy Policy Page (index.html)"
Cohesion: 1.00
Nodes (3): Alias publico (maximo 5 caracteres, mayusculas), Identificador anonimo (UID), Eliminacion de datos del Top 5 Global

### Community 62 - "Flutter Localization Config (l10n.yaml)"
Cohesion: 1.00
Nodes (3): Generated AppLocalizations (app_localizations.dart), ARB Directory (lib/l10n), Template ARB File (app_es.arb)

## Knowledge Gaps
- **727 isolated node(s):** `XCTest`, `urlPlayStore`, `DefaultFirebaseOptions`, `web`, `android` (+722 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 828 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **8 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `AppColors` connect `HudCard Stat Widget` to `AppTheme & Arcade Color Tokens`, `GameScreen Gameplay & Victory Flow`, `BestRunCard Home Widget`, `Dificultad Enum & RecordsScreen`, `AppSettingsProvider & Audio Toggles`, `HomeScreen & Asset Precache`, `GameControls Bottom Bar`, `Project Documentation & Package Metadata`, `DifficultyButton & ModeSwitch Widgets`, `SettingsScreen UI`, `GameHeader & Overflow Menu`, `HomeHeader Widget`, `KenneySlice Immutable Value Class`?**
  _High betweenness centrality (0.046) - this node is a cross-community bridge._
- **Why does `Sliding Puzzle ? Edicion Arcade (README.md)` connect `Project Documentation & Package Metadata` to `Performance Audit (AUDITORIA_RENDIMIENTO.md)`, `Firebase Privacy & Score Schema`?**
  _High betweenness centrality (0.016) - this node is a cross-community bridge._
- **Why does `Top 5 Global Leaderboard (Firebase Auth Anonimo + Firestore)` connect `Firebase Privacy & Score Schema` to `Project Documentation & Package Metadata`?**
  _High betweenness centrality (0.013) - this node is a cross-community bridge._
- **What connects `XCTest`, `urlPlayStore`, `DefaultFirebaseOptions` to the rest of the system?**
  _727 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `AppTheme & Arcade Color Tokens` be split into smaller, more focused modules?**
  _Cohesion score 0.02531645569620253 - nodes in this community are weakly interconnected._
- **Should `GameScreen Gameplay & Victory Flow` be split into smaller, more focused modules?**
  _Cohesion score 0.025974025974025976 - nodes in this community are weakly interconnected._
- **Should `Kenney 9-Slice Sprites & GameBackground` be split into smaller, more focused modules?**
  _Cohesion score 0.0425531914893617 - nodes in this community are weakly interconnected._