import 'package:flutter/material.dart';
import 'package:sliding_puzzle/models/record_game.dart';
import '../services/records_service.dart';
import '../theme/app_theme.dart';

/// Pantalla que muestra el historial de récords por dificultad.
class RecordsScreen extends StatefulWidget {
  const RecordsScreen({super.key});

  @override
  State<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen> {
  final Map<int, List<RecordGame>> _historial = {};
  bool _cargando = true;

  static const _dificultades = [
    {
      'size': 3,
      'label': '😊  Fácil',
      'desc': 'Tablero 3×3',
      'color': Color(0xFF10B981),
    },
    {
      'size': 4,
      'label': '😤  Medio',
      'desc': 'Tablero 4×4',
      'color': Color(0xFFF59E0B),
    },
    {
      'size': 5,
      'label': '💀  Difícil',
      'desc': 'Tablero 5×5',
      'color': Color(0xFFEF4444),
    },
  ];

  @override
  void initState() {
    super.initState();
    _cargarHistorial();
  }

  Future<void> _cargarHistorial() async {
    for (final d in _dificultades) {
      final size = d['size'] as int;
      _historial[size] = await RecordsService.obtenerHistorial(size);
    }
    setState(() => _cargando = false);
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
        title: Text(
          '🏆 Récords',
          style: TextStyle(fontFamily: 'Poppins',
            color: colors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: ListView.separated(
                  padding: const EdgeInsets.all(24),
                  itemCount: _dificultades.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 16),
                  itemBuilder: (context, i) {
                    final d = _dificultades[i];
                    final size = d['size'] as int;
                    return _SeccionDificultad(
                      label: d['label'] as String,
                      descripcion: d['desc'] as String,
                      color: d['color'] as Color,
                      historial: _historial[size] ?? [],
                      colors: colors,
                    );
                  },
                ),
              ),
            ),
    );
  }
}

class _SeccionDificultad extends StatelessWidget {
  final String label;
  final String descripcion;
  final Color color;
  final List<RecordGame> historial;
  final AppColors colors;

  const _SeccionDificultad({
    required this.label,
    required this.descripcion,
    required this.color,
    required this.historial,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
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
                style: TextStyle(fontFamily: 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                descripcion,
                style: TextStyle(fontFamily: 'Poppins',
                  fontSize: 13,
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Lista de partidas o mensaje vacío
          if (historial.isEmpty)
            Text(
              'Sin récords todavía — ¡jugá para establecer uno!',
              style: TextStyle(fontFamily: 'Poppins',
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
                          style: TextStyle(fontFamily: 'Poppins',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: colors.textSecondary,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Row(
                          children: [
                            Icon(
                              Icons.timer,
                              size: 14,
                              color: colors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Tiempo',
                              style: TextStyle(fontFamily: 'Poppins',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: colors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.sports_esports,
                            size: 14,
                            color: colors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Movimientos',
                            style: TextStyle(fontFamily: 'Poppins',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Filas de partidas
                ...historial.asMap().entries.map((entry) {
                  final puesto = entry.key + 1;
                  final partida = entry.value;
                  final esPrimero = puesto == 1;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 28,
                          child: Text(
                            esPrimero ? '🥇' : '$puesto',
                            style: TextStyle(fontFamily: 'Poppins',
                              fontSize: esPrimero ? 16 : 13,
                              fontWeight: FontWeight.bold,
                              color: esPrimero
                                  ? AppTheme.seedColor
                                  : colors.textSecondary,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            '${partida.tiempo}s',
                            style: TextStyle(fontFamily: 'Poppins',
                              fontSize: 15,
                              fontWeight: esPrimero
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: colors.textPrimary,
                            ),
                          ),
                        ),
                        Text(
                          '${partida.movimientos}',
                          style: TextStyle(fontFamily: 'Poppins',
                            fontSize: 15,
                            fontWeight: esPrimero
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: colors.textPrimary,
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
