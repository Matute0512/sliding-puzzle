import 'package:flutter/material.dart';

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

  static const _dificultades = [
    {
      'size': 3,
      'label': 'Fácil',
      'desc': 'Tablero 3×3',
      'color': Color(0xFF10B981),
    },
    {
      'size': 4,
      'label': 'Medio',
      'desc': 'Tablero 4×4',
      'color': Color(0xFFF59E0B),
    },
    {
      'size': 5,
      'label': 'Difícil',
      'desc': 'Tablero 5×5',
      'color': Color(0xFFEF4444),
    },
  ];

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
        _dificultades.map(
          (d) => FirebaseService.obtenerTop(d['size'] as int),
        ),
      );
      if (!mounted) return;
      setState(() {
        for (var i = 0; i < _dificultades.length; i++) {
          _tops[_dificultades[i]['size'] as int] = resultados[i];
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

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

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
              'Top 5 Global',
              style: TextStyle(
                color: colors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: _cuerpo(colors),
    );
  }

  Widget _cuerpo(AppColors colors) {
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
                  'No se pudo cargar el Top 5 Global.\n'
                  'Revisá tu conexión e intentá de nuevo.',
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
                  label: const Text(
                    'Reintentar',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: ListView.separated(
          padding: const EdgeInsets.all(24),
          itemCount: _dificultades.length,
          separatorBuilder: (_, _) => const SizedBox(height: 16),
          itemBuilder: (context, i) {
            final d = _dificultades[i];
            final size = d['size'] as int;
            return _SeccionTop(
              label: d['label'] as String,
              descripcion: d['desc'] as String,
              color: d['color'] as Color,
              top: _tops[size] ?? const [],
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

  const _SeccionTop({
    required this.label,
    required this.descripcion,
    required this.color,
    required this.top,
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
              'Todavía no hay puntajes globales — ¡jugá para entrar al Top 5!',
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
                          'Alias',
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
                              'Movs',
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
                              'Tiempo',
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
                            '${puntaje.tiempoSegundos}s',
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
