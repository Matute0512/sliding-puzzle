import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../logic/puzzle_logic.dart';
import '../services/records_service.dart';
import '../services/sound_service.dart';
import '../theme/app_theme.dart';
import 'game_screen.dart';

/// Pantalla del Modo Desafío: una campaña de 20 niveles (1 a 10 en 3x3,
/// 11 a 20 en 4x4) con un objetivo de movimientos y hasta 3 estrellas por
/// nivel. Muestra el progreso desbloqueado, las mejores estrellas por nivel
/// y candados en los niveles todavía bloqueados.
class ChallengeLevelsScreen extends StatefulWidget {
  const ChallengeLevelsScreen({super.key});

  @override
  State<ChallengeLevelsScreen> createState() => _ChallengeLevelsScreenState();
}

class _ChallengeLevelsScreenState extends State<ChallengeLevelsScreen> {
  static const int _cantidadNiveles = 20;

  int _nivelMaximo = 1;
  Map<int, int> _estrellas = const {};
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarProgreso();
  }

  Future<void> _cargarProgreso() async {
    // Cargamos ambos en paralelo y refrescamos la grilla.
    final futuroNivel = RecordsService.obtenerNivelMaximo();
    final futuroEstrellas = RecordsService.obtenerEstrellas();
    final nivel = await futuroNivel;
    final estrellas = await futuroEstrellas;
    if (!mounted) return;
    setState(() {
      _nivelMaximo = nivel;
      _estrellas = estrellas;
      _cargando = false;
    });
  }

  /// Encadena niveles desde [nivelInicial] jugando con una pausa de música por
  /// partida. El GameScreen informa con `true` cuando el jugador pidió "Siguiente
  /// Nivel"; la grilla avanza sola hasta que el jugador vuelve (y recarga).
  Future<void> _jugarNiveles(int nivelInicial) async {
    var nivel = nivelInicial;
    await SoundService.pausarMusica();
    if (!mounted) return;
    // Capturamos el navigator una vez para no usar el BuildContext a través de
    // las pausas asíncronas del bucle (lint use_build_context_synchronously).
    final navigator = Navigator.of(context);
    while (mounted) {
      final config = PuzzleLogic.configuracionNivel(nivel);
      final avanzar = await navigator.push<bool>(
        MaterialPageRoute(
          builder: (_) => GameScreen(size: config.size, nivelDesafio: nivel),
        ),
      );
      if (!mounted) return;
      // Al volver de una partida, refrescamos progreso y música del menú.
      if (avanzar != true || nivel >= _cantidadNiveles) break;
      nivel++;
    }
    SoundService.reanudarMusica();
    await _cargarProgreso();
  }

  void _tocarNivel(int nivel) {
    if (nivel <= _nivelMaximo) {
      _jugarNiveles(nivel);
      return;
    }
    // Nivel bloqueado: feedback táctil + aviso.
    HapticFeedback.vibrate();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('Completá el nivel anterior para desbloquear'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
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
            const Icon(Icons.flag_rounded, color: AppTheme.seedColor, size: 22),
            const SizedBox(width: 8),
            Text(
              'Modo Desafío',
              style: TextStyle(
                color: colors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                      child: _ResumenProgreso(
                        nivelMaximo: _nivelMaximo,
                        totalEstrellas: _estrellas.values.fold(
                          0,
                          (a, b) => a + b,
                        ),
                        colors: colors,
                      ),
                    ),
                    Expanded(
                      child: GridView.builder(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 96,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.92,
                        ),
                        itemCount: _cantidadNiveles,
                        itemBuilder: (context, i) {
                          final nivel = i + 1;
                          final bloqueado = nivel > _nivelMaximo;
                          return _CeldaNivel(
                            nivel: nivel,
                            estrellas: _estrellas[nivel] ?? 0,
                            bloqueado: bloqueado,
                            esActual: !bloqueado && nivel == _nivelMaximo,
                            onTap: () => _tocarNivel(nivel),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

/// Tarjeta resumen del progreso: nivel alcanzado y estrellas totales.
class _ResumenProgreso extends StatelessWidget {
  final int nivelMaximo;
  final int totalEstrellas;
  final AppColors colors;

  const _ResumenProgreso({
    required this.nivelMaximo,
    required this.totalEstrellas,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
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
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nivel alcanzado',
                  style: TextStyle(
                    fontSize: 13,
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$nivelMaximo / 20',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Estrellas',
                style: TextStyle(
                  fontSize: 13,
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.star_rounded,
                    color: Color(0xFFF59E0B),
                    size: 20,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$totalEstrellas / 60',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Celda de un nivel de la grilla: número, candado si está bloqueado y las
/// estrellas obtenidas (ámbar las ganadas, contorno las pendientes).
class _CeldaNivel extends StatelessWidget {
  final int nivel;
  final int estrellas;
  final bool bloqueado;
  final bool esActual;
  final VoidCallback onTap;

  const _CeldaNivel({
    required this.nivel,
    required this.estrellas,
    required this.bloqueado,
    required this.esActual,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Semantics(
      button: true,
      label: bloqueado
          ? 'Nivel $nivel bloqueado'
          : 'Nivel $nivel, $estrellas de 3 estrellas',
      child: Material(
        color: bloqueado ? colors.emptyTile : colors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: esActual
                  ? Border.all(color: AppTheme.seedColor, width: 2)
                  : null,
              boxShadow: bloqueado
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (bloqueado)
                  Icon(
                    Icons.lock_outline_rounded,
                    color: colors.textSecondary,
                    size: 24,
                  )
                else
                  Text(
                    '$nivel',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: esActual
                          ? AppTheme.seedColor
                          : colors.textPrimary,
                    ),
                  ),
                if (bloqueado)
                  const SizedBox(height: 6)
                else
                  const SizedBox(height: 4),
                if (bloqueado)
                  Text(
                    'Bloqueado',
                    style: TextStyle(
                      fontSize: 9,
                      color: colors.textSecondary,
                    ),
                  )
                else
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < 3; i++)
                        Icon(
                          i < estrellas
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          color: i < estrellas
                              ? const Color(0xFFF59E0B)
                              : colors.textSecondary,
                          size: 16,
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
