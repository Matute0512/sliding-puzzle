import 'dart:async';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../logic/puzzle_logic.dart';
import '../services/records_service.dart';
import '../services/sound_service.dart';
import '../theme/app_theme.dart';
import '../widgets/hud_card.dart';
import '../widgets/puzzle_board.dart';

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
  // El temporizador se aísla en un ValueNotifier: cada segundo solo se
  // re-construye la tarjeta del HUD, no todo el tablero.
  final ValueNotifier<int> _segundos = ValueNotifier<int>(0);
  bool _juegoIniciado = false;
  bool _pausado = false;
  Timer? _timer;
  late ConfettiController _confettiController;
  late final AppLifecycleListener _lifecycleListener;

  @override
  void initState() {
    super.initState();
    _tablero = PuzzleLogic.generarTablero(widget.size);
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 4),
    );
    _lifecycleListener = AppLifecycleListener(
      onHide: _pausarSiJugando,
      onPause: _pausarSiJugando,
      onResume: _reanudarSiJugando,
    );
    SoundService.iniciarMusica();
  }

  @override
  void dispose() {
    _detenerTimer();
    _confettiController.dispose();
    _lifecycleListener.dispose();
    _segundos.dispose();
    // No detenemos la música: es un recurso compartido con el HomeScreen
    // (raíz). Detenerla acá corría DESPUÉS de que HomeScreen la reanudara al
    // volver del juego (el dispose corre al terminar la animación de salida),
    // dejando el menú en silencio.
    super.dispose();
  }

  void _pausarSiJugando() {
    // La app pasa a background: no contamos ese tiempo como parte de la partida.
    if (_juegoIniciado && !_pausado) {
      _detenerTimer();
      if (mounted) setState(() => _pausado = true);
    }
  }

  void _reanudarSiJugando() {
    if (_juegoIniciado && _pausado && mounted) {
      setState(() {
        _pausado = false;
        _iniciarTimer();
      });
    }
  }

  void _iniciarTimer() {
    if (_timer != null) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _segundos.value++;
    });
  }

  void _detenerTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void _onTapFicha(int indice) {
    if (_pausado) return;

    if (!PuzzleLogic.puedeMover(_tablero, indice, widget.size)) {
      // Feedback para un tap inválido (antes era un no-op silencioso).
      HapticFeedback.selectionClick();
      return;
    }

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

  void _alternarPausa() {
    setState(() => _pausado = !_pausado);
    if (_pausado) {
      _detenerTimer();
    } else if (_juegoIniciado) {
      _iniciarTimer();
    }
  }

  Future<void> _mostrarVictoria() async {
    final esPrecord = await RecordsService.guardarPartida(
      size: widget.size,
      tiempo: _segundos.value,
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
              style: const TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _FilaResultado(
                  icono: Icons.timer,
                  label: 'Tiempo',
                  valor: '${_segundos.value}s',
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
                      style: TextStyle(
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
                    style: TextStyle(fontWeight: FontWeight.bold),
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
    _segundos.value = 0;
    _pausado = false;
    SoundService.reanudarMusica();
    setState(() {
      _tablero = PuzzleLogic.generarTablero(widget.size);
      _movimientos = 0;
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
          style: TextStyle(fontWeight: FontWeight.bold),
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
              texto: 'Las fichas con borde blanco son las que podés mover.',
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
                style: TextStyle(
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
                style: TextStyle(fontWeight: FontWeight.bold),
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
            tooltip: _pausado ? 'Reanudar' : 'Pausar',
            icon: Icon(
              _pausado ? Icons.play_arrow : Icons.pause,
              color: colors.textPrimary,
            ),
            onPressed: _alternarPausa,
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
                            child: ValueListenableBuilder<int>(
                              valueListenable: _segundos,
                              builder: (context, segundos, _) => HudCard(
                                icono: Icons.timer,
                                label: 'Tiempo',
                                valor: '${segundos}s',
                              ),
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
                        child: PuzzleBoard(
                          tablero: _tablero,
                          size: widget.size,
                          onTileTap: _onTapFicha,
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
          // Overlay de pausa
          if (_pausado)
            Positioned.fill(
              child: ColoredBox(
                color: colors.background.withValues(alpha: 0.72),
                child: Center(
                  child: IconButton(
                    iconSize: 72,
                    icon: Icon(
                      Icons.play_circle_fill,
                      color: colors.textPrimary,
                    ),
                    tooltip: 'Reanudar',
                    onPressed: _alternarPausa,
                  ),
                ),
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
          style: TextStyle(color: colors.textSecondary),
        ),
        Text(
          valor,
          style: TextStyle(
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
              style: TextStyle(
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
