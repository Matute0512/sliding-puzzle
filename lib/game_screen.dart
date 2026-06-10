import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'puzzle_logic.dart';
import 'records_service.dart';

/// Pantalla principal del juego donde se muestra el tablero.
class GameScreen extends StatefulWidget {
  final int size;
  const GameScreen({super.key, required this.size});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

/// StatefulWidget porque el tablero cambia cada vez
/// que el usuario mueve una ficha.
class _GameScreenState extends State<GameScreen> {
  late List<int> _tablero;
  int _movimientos = 0;
  int _segundos = 0;
  Timer? _timer;
  bool _juegoIniciado = false;

  @override
  void initState() {
    super.initState();
    // Generamos el tablero mezclado al iniciar la pantalla
    _tablero = PuzzleLogic.generarTablero(widget.size);
  }

  /// Inicia el cronómetro sumando 1 segundo cada tick
  void _iniciarTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _segundos++);
    });
  }

  /// Detiene el cronómetro
  void _detenerTimer() {
    _timer?.cancel();
    _timer = null;
  }

  /// Maneja el tap en una ficha
  void _onTapFicha(int indice) {
    if (!PuzzleLogic.puedeMover(_tablero, indice, widget.size)) return;

    // Arranca el timer en el primer movimiento
    if (!_juegoIniciado) {
      _juegoIniciado = true;
      _iniciarTimer();
    }

    setState(() {
      _tablero = PuzzleLogic.mover(_tablero, indice);
      _movimientos++;
    });

    if (PuzzleLogic.estaResuelto(_tablero)) {
      _detenerTimer();
      _mostrarVictoria();
    }
  }

  /// Muestra el diálogo de victoria
  Future<void> _mostrarVictoria() async {
    final esPrecord = await RecordsService.guardarSiEsMejor(
      size: widget.size,
      tiempo: _segundos,
      movimientos: _movimientos,
    );

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          esPrecord ? '🏆 ¡Nuevo récord!' : '🎉 ¡Ganaste!',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
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
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  '¡Superaste tu mejor marca!',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFFF59E0B),
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
                backgroundColor: const Color(0xFF4361EE),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
                _reiniciar();
              },
              child: Text(
                'Jugar de nuevo',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Reinicia el tablero
  void _reiniciar() {
    _detenerTimer();
    setState(() {
      _tablero = PuzzleLogic.generarTablero(widget.size);
      _movimientos = 0;
      _segundos = 0;
      _juegoIniciado = false;
    });
  }

  @override
  void dispose() {
    _detenerTimer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      // AppBar transparente e integrada al diseño
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1E293B)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF1E293B)),
            onPressed: _reiniciar,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // HUD con tarjetas dedicadas
                  Row(
                    children: [
                      Expanded(
                        child: _TarjetaHUD(
                          icono: Icons.timer,
                          label: 'Tiempo',
                          valor: '${_segundos}s',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _TarjetaHUD(
                          icono: Icons.sports_esports,
                          label: 'Movimientos',
                          valor: '$_movimientos',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  // Tablero
                  AspectRatio(
                    aspectRatio: 1,
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: widget.size,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: widget.size * widget.size,
                      itemBuilder: (context, indice) {
                        final numero = _tablero[indice];
                        final esVacio = numero == 0;

                        return GestureDetector(
                          onTap: () => _onTapFicha(indice),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            decoration: BoxDecoration(
                              color: esVacio
                                  ? const Color(0xFFE2E8F0)
                                  : const Color(0xFF4361EE),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: esVacio
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.08),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : [
                                      const BoxShadow(
                                        color: Color(0xFF3146B5),
                                        offset: Offset(0, 4),
                                        blurRadius: 0,
                                      ),
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.15),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                            ),
                            child: Center(
                              child: esVacio
                                  ? null
                                  : Text(
                                      '$numero',
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: widget.size == 3
                                            ? 28
                                            : widget.size == 4
                                            ? 22
                                            : 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
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
    );
  }
}

/// Tarjeta del HUD para mostrar tiempo y movimientos
class _TarjetaHUD extends StatelessWidget {
  final IconData icono;
  final String label;
  final String valor;

  const _TarjetaHUD({
    required this.icono,
    required this.label,
    required this.valor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icono, color: const Color(0xFF4361EE), size: 22),
          const SizedBox(height: 4),
          Text(
            valor,
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: const Color(0xFF64748B),
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icono, color: const Color(0xFF4361EE), size: 20),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: GoogleFonts.poppins(color: const Color(0xFF64748B)),
        ),
        Text(
          valor,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }
}
