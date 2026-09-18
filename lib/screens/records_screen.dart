import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/firebase_service.dart';
import '../theme/app_theme.dart';

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
      backgroundColor: colors.background,
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
                    fontSize: 14,
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _cargarTops,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.seedColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.refresh),
                  label: Text(
                    l10n.retry,
                    style: const TextStyle(fontWeight: FontWeight.bold),
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
    final colors = Theme.of(context).extension<AppColors>()!;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
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
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                descripcion,
                style: TextStyle(
                  fontSize: 13,
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (top.isEmpty)
            Text(
              l10n.top5Empty,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 13,
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
                      SizedBox(
                        width: 28,
                        child: Text(
                          '#',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: colors.textSecondary,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          l10n.aliasColumn,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: colors.textSecondary,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Icon(
                              Icons.sports_esports,
                              size: 14,
                              color: colors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              l10n.movesColumn,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: colors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Icon(
                              Icons.timer,
                              size: 14,
                              color: colors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              l10n.timeColumn,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: colors.textSecondary,
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

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 28,
                          child: Text(
                            '$puesto',
                            style: TextStyle(
                              fontSize: esPrimero ? 16 : 13,
                              fontWeight: FontWeight.bold,
                              color: esPrimero
                                  ? const Color(0xFFF59E0B)
                                  : colors.textSecondary,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            puntaje.alias,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: esPrimero
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: colors.textPrimary,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            '${puntaje.movimientos}',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: esPrimero
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: colors.textPrimary,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            l10n.secondsShort(puntaje.tiempoSegundos),
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: esPrimero
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: colors.textPrimary,
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
