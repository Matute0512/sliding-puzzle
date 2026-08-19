import 'dart:async';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import '../logic/puzzle_logic.dart';
import '../services/records_service.dart';
import '../services/sound_service.dart';
import '../theme/app_theme.dart';
import '../widgets/hud_card.dart';
import '../widgets/puzzle_tile.dart';

/// Pantalla principal del juego donde se muestra el tablero.
class GameScreen extends StatefulWidget {
  final int size;
  const GameScreen({super.key, required this.size});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late List<int> _tablero;
  int _movimientos = 0;
  int _segundos = 0;
  Timer? _timer;
  bool _juegoIniciado = false;
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _tablero = PuzzleLogic.generarTablero(widget.size);
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 4),
    );
    SoundService.iniciarMusica();
  }

  @override
  void dispose() {
    _detenerTimer();
    _confettiController.dispose();
    // No detenemos la música: es un recurso compartido con el HomeScreen
    // (raíz). Detenerla acá corría DESPUÉS de que HomeScreen la reanudara al
    // volver del juego (el dispose corre al terminar la animación de salida),
    // dejando el menú en silencio.
    super.dispose();
  }

  void _iniciarTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _segundos++);
    });
  }

  void _detenerTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void _onTapFicha(int indice) {
    if (!PuzzleLogic.puedeMover(_tablero, indice, widget.size)) return;

    if (!_juegoIniciado) {
      _juegoIniciado = true;
      _iniciarTimer();
    }

    SoundService.reproducirClick();

    setState(() {
      _tablero = PuzzleLogic.mover(_tablero, indice, widget.size);
      _movimientos++;
    });

    if (PuzzleLogic.estaResuelto(_tablero)) {
      _detenerTimer();
      _mostrarVictoria();
    }
  }

  Future<void> _mostrarVictoria() async {
    final esPrecord = await RecordsService.guardarPartida(
      size: widget.size,
      tiempo: _segundos,
      movimientos: _movimientos,
    );

    await SoundService.pausarMusica();
    if (!mounted) return;

    SoundService.reproducirVictoria();
    _confettiController.play();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Stack(
        alignment: Alignment.topCenter,
        children: [
          AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              esPrecord ? '🏆 ¡Nuevo récord!' : '🎉 ¡Ganaste!',
              style: const TextStyle(fontFamily: 'Poppins',fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _FilaResultado(
                  icono: Icons.timer,
                  label: 'Tiempo',
                  valor: '${_segundos}s',
                ),
                const SizedBox(height: 8),
                _FilaResultado(
                  icono: Icons.sports_esports,
                  label: 'Movimientos',
                  valor: '$_movimientos',
                ),
                if (esPrecord)
                  const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: Text(
                      '¡Superaste tu mejor marca!',
                      style: TextStyle(fontFamily: 'Poppins',
                        color: Color(0xFFF59E0B),
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.seedColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    _reiniciar();
                  },
                  child: const Text(
                    'Jugar de nuevo',
                    style: TextStyle(fontFamily: 'Poppins',fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
          // Confetti encima del dialog
          ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            numberOfParticles: 30,
            gravity: 0.3,
            colors: const [
              Color(0xFF4361EE),
              Color(0xFF10B981),
              Color(0xFFF59E0B),
              Color(0xFFEF4444),
              Colors.white,
            ],
          ),
        ],
      ),
    );
  }

  void _reiniciar() {
    _detenerTimer();
    SoundService.reanudarMusica();
    setState(() {
      _tablero = PuzzleLogic.generarTablero(widget.size);
      _movimientos = 0;
      _segundos = 0;
      _juegoIniciado = false;
    });
  }

  void _mostrarAyuda() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          '🧩 ¿Cómo jugar?',
          style: TextStyle(fontFamily: 'Poppins',fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ItemAyuda(
              texto: 'Tocá una ficha adyacente al espacio vacío para moverla.',
            ),
            _ItemAyuda(
              texto: 'El objetivo es ordenar los números en orden ascendente.',
            ),
            _ItemAyuda(
              texto:
                  'El espacio vacío debe quedar en la esquina inferior derecha.',
            ),
            _ItemAyuda(
              texto:
                  '¡Intentá resolverlo en el menor tiempo y movimientos posibles!',
            ),
            SizedBox(height: 16),
            Center(
              child: Text(
                '1  2  3\n4  5  6\n7  8  ☐',
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.seedColor,
                  height: 1.8,
                ),
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.seedColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text(
                '¡Entendido!',
                style: TextStyle(fontFamily: 'Poppins',fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
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
        actions: [
          IconButton(
            icon: Icon(Icons.help_outline, color: colors.textPrimary),
            onPressed: _mostrarAyuda,
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: colors.textPrimary),
            onPressed: _reiniciar,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Juego normal
          SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: HudCard(
                              icono: Icons.timer,
                              label: 'Tiempo',
                              valor: '${_segundos}s',
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: HudCard(
                              icono: Icons.sports_esports,
                              label: 'Movimientos',
                              valor: '$_movimientos',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      AspectRatio(
                        aspectRatio: 1,
                        child: GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: widget.size,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                              ),
                          itemCount: widget.size * widget.size,
                          itemBuilder: (context, indice) {
                            return PuzzleTile(
                              numero: _tablero[indice],
                              size: widget.size,
                              onTap: () => _onTapFicha(indice),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Confetti encima del juego
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              numberOfParticles: 30,
              gravity: 0.3,
              colors: const [
                Color(0xFF4361EE),
                Color(0xFF10B981),
                Color(0xFFF59E0B),
                Color(0xFFEF4444),
                Colors.white,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Fila de resultado en el diálogo de victoria
class _FilaResultado extends StatelessWidget {
  final IconData icono;
  final String label;
  final String valor;

  const _FilaResultado({
    required this.icono,
    required this.label,
    required this.valor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icono, color: AppTheme.seedColor, size: 20),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(fontFamily: 'Poppins',color: colors.textSecondary),
        ),
        Text(
          valor,
          style: TextStyle(fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
          ),
        ),
      ],
    );
  }
}

/// Item de ayuda para el dialog de instrucciones
class _ItemAyuda extends StatelessWidget {
  final String texto;

  const _ItemAyuda({required this.texto});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '• ',
            style: TextStyle(color: AppTheme.seedColor, fontSize: 16),
          ),
          Expanded(
            child: Text(
              texto,
              style: TextStyle(fontFamily: 'Poppins',
                fontSize: 14,
                color: colors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
