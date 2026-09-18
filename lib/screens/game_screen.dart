import 'dart:async';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../l10n/app_localizations.dart';
import '../logic/puzzle_logic.dart';
import '../services/firebase_service.dart';
import '../services/records_service.dart';
import '../services/saved_game_service.dart';
import '../services/sound_service.dart';
import '../theme/app_theme.dart';
import '../widgets/alias_dialog.dart';
import '../widgets/hud_card.dart';
import '../widgets/puzzle_board.dart';

/// Pantalla principal del juego donde se muestra el tablero.
class GameScreen extends StatefulWidget {
  final int size;

  /// Nivel del Modo Desafío en curso. Si es `null`, es una partida clásica
  /// (tablero aleatorio + récord de tiempo/movimientos).
  final int? nivelDesafio;

  /// Partida guardada que se debe retomar. Si es `null`, arranca una nueva.
  final PartidaGuardada? partidaInicial;

  const GameScreen({
    super.key,
    required this.size,
    this.nivelDesafio,
    this.partidaInicial,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late List<int> _tablero;
  late final int _objetivo;
  int _movimientos = 0;
  // El tiempo se aísla en un ValueNotifier: cada segundo solo se re-construye
  // la tarjeta del HUD, no todo el tablero.
  final ValueNotifier<int> _segundos = ValueNotifier<int>(0);

  /// Segundos ya jugados que traía una partida retomada. Un `Stopwatch` no
  /// puede arrancar en un valor distinto de cero, así que el tiempo total de la
  /// partida es siempre `_segundosAcumulados + _cronometro.elapsed`. Sin este
  /// desplazamiento, retomar una partida reiniciaría el reloj a 0 y publicaría
  /// en el Top 5 un tiempo imposible de batir.
  int _segundosAcumulados = 0;

  /// Cronómetro real de la partida: es la fuente de verdad del tiempo. Se
  /// arranca en el primer movimiento y se detiene en el mismo instante en que
  /// el tablero queda resuelto, así que el tiempo registrado es el transcurrido
  /// exacto (sin el redondeo del tick de 1 Hz que usa el HUD).
  final Stopwatch _cronometro = Stopwatch();

  /// `true` desde que el tablero queda resuelto. Bloquea todo reinicio del
  /// reloj una vez ganada la partida: sin esto, mandar la app a background y
  /// volver reactivaba el cronómetro detrás del modal de victoria.
  bool _juegoTerminado = false;

  /// Aviso del Top 5 Global mostrado dentro del modal de victoria. Lo llena la
  /// consulta de red cuando termina, para no retrasar la celebración.
  final ValueNotifier<String?> _avisoTop = ValueNotifier<String?>(null);

  /// Identifica la partida en curso, para descartar la respuesta de red de una
  /// partida que ya se reinició.
  int _partidaId = 0;

  bool _juegoIniciado = false;
  bool _pausado = false;
  Timer? _timer;
  late ConfettiController _confettiController;
  late final AppLifecycleListener _lifecycleListener;

  /// `true` cuando esta partida pertenece al Modo Desafío.
  bool get _esDesafio => widget.nivelDesafio != null;

  /// Tablero inicial según el modo: scramble clásico aleatorio o scramble
  /// determinista del nivel de desafío (misma semilla por nivel).
  List<int> _nuevoTablero() {
    final nivel = widget.nivelDesafio;
    return nivel != null
        ? PuzzleLogic.generarTableroDesafio(nivel)
        : PuzzleLogic.generarTablero(widget.size);
  }

  @override
  void initState() {
    super.initState();
    _objetivo = _esDesafio
        ? PuzzleLogic.configuracionNivel(widget.nivelDesafio!).objetivo
        : 0;
    final guardada = widget.partidaInicial;
    if (guardada != null) {
      // Partida retomada: tablero, movimientos y tiempo vienen del disco. El
      // cronómetro sigue detenido hasta el próximo movimiento, así que el
      // jugador no pierde tiempo mientras mira el tablero.
      _tablero = List<int>.from(guardada.tablero);
      _movimientos = guardada.movimientos;
      _segundosAcumulados = guardada.segundos;
      _segundos.value = guardada.segundos;
      _juegoIniciado = true;
    } else {
      _tablero = _nuevoTablero();
    }
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
    _avisoTop.dispose();
    // No detenemos la música: es un recurso compartido con el HomeScreen
    // (raíz). Detenerla acá corría DESPUÉS de que HomeScreen la reanudara al
    // volver del juego (el dispose corre al terminar la animación de salida),
    // dejando el menú en silencio.
    super.dispose();
  }

  void _pausarSiJugando() {
    // La app pasa a background: no contamos ese tiempo como parte de la partida.
    // Si la partida ya está ganada no hay nada que pausar (y reanudarla después
    // rearrancaría el reloj por detrás del modal).
    if (_juegoIniciado && !_pausado && !_juegoTerminado) {
      _detenerTimer();
      // Guardamos al ir a background: si el sistema termina el proceso, la
      // partida todavía se puede retomar desde el menú.
      unawaited(_guardarPartida());
      if (mounted) setState(() => _pausado = true);
    }
  }

  /// Guarda la partida en curso para poder retomarla desde el menú.
  ///
  /// Solo se guarda una partida ya empezada y sin terminar: un tablero intacto
  /// no es "una partida en curso" y no debe ofrecer "Continuar Partida".
  Future<void> _guardarPartida() async {
    if (!_juegoIniciado || _juegoTerminado) return;
    await SavedGameService.guardar(
      PartidaGuardada(
        esDesafio: _esDesafio,
        size: widget.size,
        nivel: widget.nivelDesafio,
        tablero: _tablero,
        movimientos: _movimientos,
        segundos: _segundosTotales,
      ),
    );
  }

  /// Sale al menú principal limpiando la pila de navegación.
  ///
  /// Se usa `popUntil` en vez de `pop` porque en el Modo Desafío hay una
  /// pantalla intermedia (la grilla de niveles) entre el juego y el menú, y
  /// porque cierra de una sola pasada el diálogo de victoria que está encima.
  ///
  /// Si hay un teclado abierto —el diálogo del alias pudo quedar atrás— se
  /// cierra primero y se le da un turno a la animación antes de desmontar la
  /// pantalla: hacerlo todo en el mismo frame superponía la transición del
  /// teclado con la de la ruta.
  Future<void> _volverAlMenu() async {
    final tecladoAbierto = MediaQuery.of(context).viewInsets.bottom > 0;
    FocusManager.instance.primaryFocus?.unfocus();

    if (tecladoAbierto) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    if (!mounted) return;

    Navigator.of(context).popUntil((ruta) => ruta.isFirst);
  }

  void _reanudarSiJugando() {
    if (_juegoIniciado && _pausado && !_juegoTerminado && mounted) {
      setState(() {
        _pausado = false;
        _iniciarTimer();
      });
    }
  }

  /// Arranca el cronómetro y el refresco del HUD. La cuenta la lleva el
  /// [Stopwatch]; el `Timer` solo vuelca el valor a la UI cada segundo.
  void _iniciarTimer() {
    if (_timer != null) return;
    _cronometro.start();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _segundos.value = _segundosAcumulados + _cronometro.elapsed.inSeconds;
    });
  }

  /// Detiene el cronómetro y sincroniza el HUD con el tiempo real acumulado.
  void _detenerTimer() {
    _timer?.cancel();
    _timer = null;
    _cronometro.stop();
    _segundos.value = _segundosAcumulados + _cronometro.elapsed.inSeconds;
  }

  /// Tiempo total de la partida: lo ya jugado (si se retomó) más lo que lleva
  /// el cronómetro en esta sesión.
  int get _segundosTotales => _segundosAcumulados + _cronometro.elapsed.inSeconds;

  void _onTapFicha(int indice) {
    if (_pausado || _juegoTerminado) return;

    if (!PuzzleLogic.puedeMover(_tablero, indice, widget.size)) {
      // Feedback para un tap inválido (antes era un no-op silencioso).
      HapticFeedback.selectionClick();
      return;
    }

    // El reloj arranca con el primer movimiento y se reanuda si venía detenido
    // (partida retomada). `_iniciarTimer` continúa el Stopwatch en vez de
    // reiniciarlo, así que el tiempo ya acumulado se conserva.
    _juegoIniciado = true;
    if (_timer == null) _iniciarTimer();

    SoundService.reproducirClick();

    setState(() {
      _tablero = PuzzleLogic.mover(_tablero, indice, widget.size);
      _movimientos++;
    });

    if (PuzzleLogic.estaResuelto(_tablero)) {
      // Se marca terminada ANTES de detener el reloj: a partir de acá ninguna
      // otra ruta (pausa, reanudar, ciclo de vida) puede volver a arrancarlo.
      _juegoTerminado = true;
      _detenerTimer();
      // La partida terminó: ya no hay nada que retomar.
      SavedGameService.borrar();
      _mostrarVictoria();
    }
  }

  void _alternarPausa() {
    if (_juegoTerminado) return;
    setState(() => _pausado = !_pausado);
    if (_pausado) {
      _detenerTimer();
      unawaited(_guardarPartida());
    } else if (_juegoIniciado) {
      _iniciarTimer();
    }
  }

  /// Festejo inmediato: sonido, confeti y pausa de la música. Se llama en el
  /// mismo instante en que el tablero queda resuelto, sin ningún `await` que
  /// pueda retrasarlo. (`pausarMusica` no tiene `await` interno, así que se
  /// ejecuta ya; no se espera para no ceder el turno antes de mostrar el modal.)
  void _celebrar() {
    SoundService.reproducirVictoria();
    _confettiController.play();
    SoundService.pausarMusica();
  }

  Future<void> _mostrarVictoria() async {
    if (_esDesafio) {
      await _mostrarVictoriaDesafio();
      return;
    }

    // El modal sale al instante y el ranking global se resuelve por detrás:
    // esperar la red acá retrasaba toda la celebración un round-trip.
    _celebrar();
    _resolverPuestoGlobal(_partidaId);

    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
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
            // El título y el aviso reaccionan al resultado del ranking, que
            // puede llegar después de que el modal ya esté en pantalla.
            title: ValueListenableBuilder<String?>(
              valueListenable: _avisoTop,
              builder: (_, aviso, _) => Text(
                aviso != null ? l10n.victoryTop5 : l10n.victoryWon,
                style: const TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _FilaResultado(
                  icono: Icons.timer,
                  label: l10n.time,
                  valor: l10n.secondsShort(_segundos.value),
                ),
                const SizedBox(height: 8),
                _FilaResultado(
                  icono: Icons.sports_esports,
                  label: l10n.moves,
                  valor: '$_movimientos',
                ),
                ValueListenableBuilder<String?>(
                  valueListenable: _avisoTop,
                  builder: (_, aviso, _) {
                    if (aviso == null) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        aviso,
                        style: const TextStyle(
                          color: Color(0xFFF59E0B),
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    );
                  },
                ),
              ],
            ),
            actions: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton(
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
                    child: Text(
                      l10n.playAgain,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 4),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.seedColor,
                    ),
                    // Un único `popUntil`: cierra el diálogo Y el juego de una
                    // pasada, en vez de encadenar dos navegaciones en el mismo
                    // frame (dos animaciones de salida superpuestas).
                    onPressed: () => unawaited(_volverAlMenu()),
                    icon: const Icon(Icons.exit_to_app_rounded, size: 18),
                    label: Text(
                      l10n.backToMenu,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
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

  /// Resuelve el puesto en el Top 5 Global por detrás del modal de victoria y,
  /// si el jugador clasificó, completa el aviso del modal cuando la respuesta
  /// llega. [idPartida] descarta respuestas tardías de una partida ya reiniciada
  /// (si no, el aviso de la partida anterior aparecería en el modal siguiente).
  Future<void> _resolverPuestoGlobal(int idPartida) async {
    final puesto = await _registrarPuntajeLibre();
    if (puesto == null || !mounted || idPartida != _partidaId) return;
    _avisoTop.value = AppLocalizations.of(context)!.top5Entered(puesto);
  }

  /// Registra la partida libre en el Top 5 Global si clasifica.
  ///
  /// Si el puntaje entra al Top 5 y el usuario todavía no eligió alias, se lo
  /// pide primero. Devuelve el puesto (1..5) o `null` si no clasificó, si el
  /// usuario canceló el alias o si la red no está disponible.
  Future<int?> _registrarPuntajeLibre() async {
    // Los valores de la partida se congelan acá. Como esto corre en segundo
    // plano, el jugador puede tocar "Jugar de nuevo" mientras la red responde,
    // y _reiniciar() pone _movimientos y _segundos en cero: releerlos después
    // de un await publicaría un puntaje falso (0 movimientos) en el ranking
    // global, imposible de superar.
    final movimientos = _movimientos;
    final tiempoSegundos = _segundos.value;

    final puestoPosible = await FirebaseService.posicionActualPuntaje(
      size: widget.size,
      movimientos: movimientos,
      tiempoSegundos: tiempoSegundos,
    );
    if (puestoPosible == null) return null;

    var alias = await RecordsService.obtenerAlias();
    if (alias == null) {
      // La lectura anterior es asíncrona: si la pantalla se fue mientras tanto,
      // abrir el diálogo del alias usaría un contexto muerto.
      if (!mounted) return null;
      alias = await _pedirAlias();
    }
    if (alias == null || alias.isEmpty) return null;
    await RecordsService.guardarAlias(alias);

    return FirebaseService.registrarSiClasifica(
      size: widget.size,
      alias: alias,
      movimientos: movimientos,
      tiempoSegundos: tiempoSegundos,
    );
  }

  /// Diálogo para elegir el alias del Top 5 Global (máx. 5 letras mayúsculas).
  /// Devuelve el alias normalizado o `null` si el usuario canceló.
  ///
  /// La UI vive en [AliasDialog]: el controlador del campo tiene que ser
  /// propiedad de un `State` para que se libere junto con el widget, y no antes.
  Future<String?> _pedirAlias() => AliasDialog.mostrar(context);

  /// Diálogo de victoria del Modo Desafío. Registra el progreso (estrellas y
  /// desbloqueo del siguiente nivel), muestra las estrellas obtenidas y ofrece
  /// "Siguiente Nivel" (devuelve `true` a la grilla para encadenar), "Reintentar"
  /// (misma semilla) y "Volver a niveles".
  Future<void> _mostrarVictoriaDesafio() async {
    final nivel = widget.nivelDesafio!;
    // Festejo inmediato, igual que en partida libre.
    _celebrar();

    // Las estrellas son una función pura del resultado, así que el modal ya las
    // conoce sin esperar a la persistencia. Se guarda el progreso (local, sin
    // red) antes de mostrar el modal para que el desbloqueo del siguiente nivel
    // esté escrito cuando el jugador toque "Siguiente Nivel".
    final estrellas = PuzzleLogic.estrellasPara(_movimientos, _objetivo);
    await RecordsService.registrarVictoriaDesafio(
      nivel: nivel,
      movimientos: _movimientos,
      objetivo: _objetivo,
    );
    if (!mounted) return;

    final haySiguiente = nivel < 20;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final colors = Theme.of(dialogContext).extension<AppColors>()!;
        final l10n = AppLocalizations.of(dialogContext)!;
        return Stack(
          alignment: Alignment.topCenter,
          children: [
            AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                l10n.levelPassed(nivel),
                style: const TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _FilaEstrellas(estrellas: estrellas),
                  const SizedBox(height: 12),
                  _FilaResultado(
                    icono: Icons.sports_esports,
                    label: l10n.moves,
                    valor: '$_movimientos',
                  ),
                  const SizedBox(height: 8),
                  _FilaResultado(
                    icono: Icons.flag_rounded,
                    label: l10n.goal,
                    valor: l10n.goalMoves(_objetivo),
                  ),
                ],
              ),
              actions: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (haySiguiente) ...[
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.seedColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(context); // cierra el diálogo
                          Navigator.pop(context, true); // encadena el siguiente
                        },
                        child: Text(
                          l10n.nextLevel,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.seedColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context); // cierra el diálogo
                        _reiniciar();
                      },
                      child: Text(
                        l10n.retry,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context); // cierra el diálogo
                        Navigator.pop(context, false); // vuelve a la grilla
                      },
                      child: Text(
                        l10n.backToLevels,
                        style: TextStyle(color: colors.textSecondary),
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.seedColor,
                      ),
                      // Salta la grilla de niveles y el juego de una pasada.
                      onPressed: () => unawaited(_volverAlMenu()),
                      icon: const Icon(Icons.exit_to_app_rounded, size: 18),
                      label: Text(
                        l10n.backToMenu,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ],
            ),
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
        );
      },
    );
  }

  void _reiniciar() {
    _detenerTimer();
    _cronometro.reset();
    // El tiempo acumulado se descarta junto con el tablero: la partida que se
    // retomó ya no existe.
    _segundosAcumulados = 0;
    _segundos.value = 0;
    _pausado = false;
    // Partida nueva: se limpia el estado de "terminada" y se invalida cualquier
    // respuesta de red que siga pendiente de la partida anterior.
    _juegoTerminado = false;
    _avisoTop.value = null;
    _partidaId++;
    // Reiniciar abandona la partida en curso: no queda nada que continuar.
    unawaited(SavedGameService.borrar());
    SoundService.reanudarMusica();
    setState(() {
      _tablero = _nuevoTablero();
      _movimientos = 0;
      _juegoIniciado = false;
    });
  }

  void _mostrarAyuda() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        final l10n = AppLocalizations.of(dialogContext)!;
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            l10n.howToPlayTitle,
            style: const TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ItemAyuda(texto: l10n.howToPlay1),
              _ItemAyuda(texto: l10n.howToPlay2),
              _ItemAyuda(texto: l10n.howToPlay3),
              _ItemAyuda(texto: l10n.howToPlay4),
              _ItemAyuda(texto: l10n.howToPlay5),
              const SizedBox(height: 16),
              Center(child: _tableroResuelto()),
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
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(
                  l10n.gotIt,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Vista previa del tablero resuelto según la dificultad actual:
  /// números de 1 a size²-1 en orden ascendente y el hueco '□' abajo a la derecha.
  /// Cada celda tiene ancho fijo para que las columnas queden alineadas
  /// aunque los números tengan dos dígitos (4x4 y 5x5).
  Widget _tableroResuelto() {
    final n = widget.size;
    final total = n * n;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var fila = 0; fila < n; fila++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var col = 0; col < n; col++)
                  SizedBox(
                    width: 30,
                    child: Text(
                      // La última celda (fila×n+col == total-1) es el hueco.
                      fila * n + col == total - 1
                          ? '□'
                          : '${fila * n + col + 1}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: n == 3 ? 18 : n == 4 ? 16 : 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.seedColor,
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final l10n = AppLocalizations.of(context)!;

    // `PopScope` envuelve el Scaffold para interceptar el botón Atrás del
    // sistema (y el gesto de retroceso) y guardar la partida antes de salir.
    // No afecta a las salidas explícitas ("Volver al Menú"), que navegan por su
    // cuenta con `popUntil` sin pasar por este callback.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        // El navigator se captura antes del await: usar `context` después de
        // una pausa asíncrona es lo que marca el lint
        // use_build_context_synchronously.
        final navigator = Navigator.of(context);
        await _guardarPartida();
        if (!mounted) return;
        navigator.pop();
      },
      child: Scaffold(
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
            tooltip: _pausado ? l10n.resume : l10n.pause,
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
                      if (_esDesafio)
                        Row(
                          children: [
                            Expanded(
                              child: HudCard(
                                icono: Icons.sports_esports,
                                label: l10n.moves,
                                valor: '$_movimientos',
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: HudCard(
                                icono: Icons.flag_rounded,
                                label: l10n.goal,
                                valor: l10n.goalMoves(_objetivo),
                              ),
                            ),
                          ],
                        )
                      else
                        Row(
                          children: [
                            Expanded(
                              child: ValueListenableBuilder<int>(
                                valueListenable: _segundos,
                                builder: (context, segundos, _) => HudCard(
                                  icono: Icons.timer,
                                  label: l10n.time,
                                  valor: l10n.secondsShort(segundos),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: HudCard(
                                icono: Icons.sports_esports,
                                label: l10n.moves,
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
                    tooltip: l10n.resume,
                    onPressed: _alternarPausa,
                  ),
                ),
              ),
            ),
        ],
      ),
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

/// Estrellas obtenidas en el diálogo de victoria del Modo Desafío.
class _FilaEstrellas extends StatelessWidget {
  final int estrellas;

  const _FilaEstrellas({required this.estrellas});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < 3; i++)
          Icon(
            i < estrellas ? Icons.star_rounded : Icons.star_outline_rounded,
            color: i < estrellas
                ? const Color(0xFFF59E0B)
                : colors.textSecondary,
            size: 36,
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
