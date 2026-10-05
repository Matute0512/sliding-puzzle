import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/firebase_service.dart';
import '../theme/app_theme.dart';
import '../theme/kenney_ui.dart';

/// Pantalla del Top 5 Global por tamaño de tablero (3x3, 4x4 y 5x5).
///
/// Lee de Firestore (`FirebaseService.obtenerTop`) en lugar de la persistencia
/// local. Muestra estados de carga y error con reintento.
class RecordsScreen extends StatefulWidget {
  const RecordsScreen({super.key});

  @override
  State<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen> {
  final Map<int, List<PuntajeGlobal>> _tops = {};
  bool _cargando = true;
  bool _huboError = false;

  /// Tamaños de tablero con ranking global. Solo los números: los textos de
  /// cada sección se arman en [build] porque son traducibles y ya no pueden
  /// vivir en una lista `const`.
  static const List<int> _tamanos = [3, 4, 5];

  @override
  void initState() {
    super.initState();
    _cargarTops();
  }

  Future<void> _cargarTops() async {
    setState(() {
      _cargando = true;
      _huboError = false;
    });

    try {
      final resultados = await Future.wait(
        _tamanos.map((size) => FirebaseService.obtenerTop(size)),
      );
      if (!mounted) return;
      setState(() {
        for (var i = 0; i < _tamanos.length; i++) {
          _tops[_tamanos[i]] = resultados[i];
        }
        _cargando = false;
      });
    } catch (_) {
      // Sin conexión o Firestore no disponible: mostramos el estado de error.
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _huboError = true;
      });
    }
  }

  /// Secciones del Top 5, con las etiquetas ya traducidas.
  List<({int size, String label, String desc, Color color})> _dificultades(
    AppLocalizations l10n,
  ) => [
    (
      size: 3,
      label: l10n.difficultyEasy,
      desc: l10n.boardSize(3),
      color: const Color(0xFF10B981),
    ),
    (
      size: 4,
      label: l10n.difficultyMedium,
      desc: l10n.boardSize(4),
      color: const Color(0xFFF59E0B),
    ),
    (
      size: 5,
      label: l10n.difficultyHard,
      desc: l10n.boardSize(5),
      color: const Color(0xFFEF4444),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      // Sin `backgroundColor`: el fondo lo pinta `GameBackground`
      // desde `MaterialApp.builder`. Ver `AppTheme.game`.
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: colors.textPrimary),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.emoji_events,
              color: AppTheme.seedColor,
              size: 22,
            ),
            const SizedBox(width: 8),
            Text(
              l10n.top5Title,
              style: TextStyle(
                color: colors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: _cuerpo(colors, l10n),
    );
  }

  Widget _cuerpo(AppColors colors, AppLocalizations l10n) {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_huboError) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.cloud_off_rounded,
                  size: 48,
                  color: colors.textSecondary,
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.top5Error,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                KenneyButton(
                  tint: AppTheme.seedColor,
                  onPressed: _cargarTops,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.refresh, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        l10n.retry,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final dificultades = _dificultades(l10n);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: ListView.separated(
          padding: const EdgeInsets.all(24),
          itemCount: dificultades.length,
          separatorBuilder: (_, _) => const SizedBox(height: 16),
          itemBuilder: (context, i) {
            final d = dificultades[i];
            return _SeccionTop(
              label: d.label,
              descripcion: d.desc,
              color: d.color,
              top: _tops[d.size] ?? const [],
              l10n: l10n,
            );
          },
        ),
      ),
    );
  }
}

class _SeccionTop extends StatelessWidget {
  final String label;
  final String descripcion;
  final Color color;
  final List<PuntajeGlobal> top;
  final AppLocalizations l10n;

  const _SeccionTop({
    required this.label,
    required this.descripcion,
    required this.color,
    required this.top,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    // La superficie es un panel 9-slice de Kenney, claro en los dos temas: por
    // eso los textos de adentro usan KenneyInk y no AppColors.
    return KenneySurface(
      slice: KenneySlices.flatPanel,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header de dificultad
          Row(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: KenneyInk.primary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                descripcion,
                style: const TextStyle(
                  fontSize: 11,
                  color: KenneyInk.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (top.isEmpty)
            Text(
              l10n.top5Empty,
              style: const TextStyle(
                color: KenneyInk.secondary,
                fontSize: 11,
              ),
            )
          else
            Column(
              children: [
                // Encabezados de columna
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 28,
                        child: Text(
                          '#',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: KenneyInk.secondary,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          l10n.aliasColumn,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: KenneyInk.secondary,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            const Icon(
                              Icons.sports_esports,
                              size: 14,
                              color: KenneyInk.secondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              l10n.movesColumn,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: KenneyInk.secondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            const Icon(
                              Icons.timer,
                              size: 14,
                              color: KenneyInk.secondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              l10n.timeColumn,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: KenneyInk.secondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Filas del Top 5
                ...top.asMap().entries.map((entry) {
                  final puesto = entry.key + 1;
                  final puntaje = entry.value;
                  final esPrimero = puesto == 1;
                  final colorPodio = AppTheme.podiumColor(puesto);

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 28,
                          // Los tres primeros puestos van con estrella de podio
                          // (oro, plata y bronce); del 4º en adelante, el número
                          // pelado, que no necesita destacarse.
                          child: colorPodio != null
                              ? KenneyIcon(
                                  KenneySlices.star,
                                  size: 20,
                                  tint: colorPodio,
                                  // El número desaparece de la vista, así que
                                  // el puesto tiene que quedar en la semántica.
                                  semanticLabel: '$puesto',
                                )
                              : Text(
                                  '$puesto',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: KenneyInk.secondary,
                                  ),
                                ),
                        ),
                        Expanded(
                          child: Text(
                            puntaje.alias,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: esPrimero
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: KenneyInk.primary,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            '${puntaje.movimientos}',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: esPrimero
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: KenneyInk.primary,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            l10n.secondsShort(puntaje.tiempoSegundos),
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: esPrimero
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: KenneyInk.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
        ],
      ),
    );
  }
}
