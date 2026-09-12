import 'dart:math';

/// Dirección en la que se desliza una ficha. Coincide con el sentido en que
/// se mueve la ficha: el usuario empuja la ficha hacia el hueco.
enum Direccion { arriba, abajo, izquierda, derecha }

/// Contiene toda la lógica central del Sliding Puzzle.
/// Opera de forma independiente a la interfaz gráfica.
class PuzzleLogic {
  /// Genera un tablero aleatorio garantizando matemáticamente
  /// que tenga solución y que no comience ya resuelto.
  static List<int> generarTablero(int size) {
    final random = Random();
    List<int> tablero = List.generate(size * size, (i) => i);

    while (true) {
      tablero.shuffle(random);

      // Si no tiene solución, corregimos la paridad de inmediato.
      // Al intercambiar dos fichas (no vacías), la paridad se invierte
      // y el tablero queda matemáticamente resuelto a nivel de solución.
      if (!tieneSolucion(tablero, size)) {
        _corregirParidad(tablero, random);
      }

      // Una vez garantizado que tiene solución, verificamos que no haya
      // quedado ya resuelto por pura casualidad. Si no está resuelto, rompemos el ciclo.
      if (!estaResuelto(tablero)) {
        break;
      }
    }

    return tablero;
  }

  /// Corrige la paridad del tablero intercambiando
  /// dos fichas aleatorias distintas (excluyendo el 0).
  static void _corregirParidad(List<int> tablero, Random random) {
    final indices = List.generate(
      tablero.length,
      (i) => i,
    ).where((i) => tablero[i] != 0).toList();

    indices.shuffle(random);

    int a = indices[0];
    int b = indices[1];

    int temp = tablero[a];
    tablero[a] = tablero[b];
    tablero[b] = temp;
  }

  /// Determina si la ficha seleccionada puede moverse.
  static bool puedeMover(List<int> tablero, int indice, int size) {
    int posVacio = tablero.indexOf(0);

    int filaFicha = indice ~/ size;
    int colFicha = indice % size;

    int filaVacio = posVacio ~/ size;
    int colVacio = posVacio % size;

    // Son adyacentes si comparten fila y su diferencia en columnas es 1,
    // o viceversa.
    bool mismaFila = filaFicha == filaVacio && (colFicha - colVacio).abs() == 1;
    bool mismaColumna =
        colFicha == colVacio && (filaFicha - filaVacio).abs() == 1;

    return mismaFila || mismaColumna;
  }

  /// Devuelve los índices de las fichas que actualmente pueden moverse
  /// (adyacentes al hueco). Útil para dar pistas visuales en la UI.
  static List<int> movibles(List<int> tablero, int size) {
    return [
      for (var i = 0; i < tablero.length; i++)
        if (puedeMover(tablero, i, size)) i,
    ];
  }

  /// Si la ficha [indice] está adyacente al hueco, devuelve la dirección en la
  /// que debe deslizarse para caer en él. `null` si no es adyacente.
  static Direccion? direccionHaciaVacio(
      List<int> tablero, int indice, int size) {
    if (!puedeMover(tablero, indice, size)) return null;

    final posVacio = tablero.indexOf(0);
    // +1 en dx  => el hueco está a la derecha de la ficha
    // +1 en dy  => el hueco está debajo de la ficha
    final dx = (posVacio % size) - (indice % size);
    final dy = (posVacio ~/ size) - (indice ~/ size);

    if (dx == 1) return Direccion.derecha;
    if (dx == -1) return Direccion.izquierda;
    if (dy == 1) return Direccion.abajo;
    return Direccion.arriba;
  }

  /// Mueve una ficha si el movimiento es válido.
  ///
  /// Retorna una nueva lista para preservar la inmutabilidad.
  static List<int> mover(List<int> tablero, int indice, int size) {
    if (!puedeMover(tablero, indice, size)) {
      return List.from(tablero);
    }

    int posVacio = tablero.indexOf(0);

    List<int> nuevo = List.from(tablero);
    nuevo[posVacio] = nuevo[indice];
    nuevo[indice] = 0;

    return nuevo;
  }

  /// Verifica si las fichas están ordenadas y el espacio vacío
  /// se encuentra en la última posición.
  static bool estaResuelto(List<int> tablero) {
    for (int i = 0; i < tablero.length - 1; i++) {
      if (tablero[i] != i + 1) return false;
    }
    return tablero.last == 0;
  }

  /// Verifica si el tablero tiene solucion usando el conteo de inversiones.
  /// No todos los tableros mezclados son resolubles, esto lo garantiza.
  static bool tieneSolucion(List<int> tablero, int size) {
    int inversiones = 0;
    List<int> sinCero = tablero.where((n) => n != 0).toList();

    for (int i = 0; i < sinCero.length; i++) {
      for (int j = i + 1; j < sinCero.length; j++) {
        if (sinCero[i] > sinCero[j]) inversiones++;
      }
    }

    if (size.isOdd) {
      return inversiones.isEven;
    }

    // Tableros pares (4x4,6x6,...). Por si los agregamos mas adelante.
    int posVacio = tablero.indexOf(0);
    int filaVacioDesdeAbajo = size - (posVacio ~/ size);

    if (filaVacioDesdeAbajo.isEven) {
      return inversiones.isOdd;
    }
    return inversiones.isEven;
  }

  /// --- Calibración del Modo Desafío (4x4, niveles 11 a 20) ---
  ///
  /// `profundidad` es cuántos movimientos aleatorios se aplican al tablero
  /// resuelto para desarmarlo; `objetivo` es lo que debe lograr el jugador para
  /// las 3 estrellas. Son valores DISTINTOS a propósito.
  ///
  /// Por qué el objetivo debe ser mayor que la profundidad: el scramble sin
  /// retroceso inmediato es prácticamente una caminata óptima, así que el
  /// óptimo real del tablero generado queda pegado a la profundidad. Medido con
  /// IDA* (2026-09-11, óptimo real por profundidad):
  ///
  ///   D=10 -> 10 (holgura 0)   D=18 -> ~16   D=24 -> ~20   D=40 -> ~30
  ///
  /// Con `objetivo == profundidad` la holgura era 0: las 3 estrellas exigían la
  /// solución óptima exacta (imposible en 4x4 para un humano). Como el scramble
  /// inverso siempre da una solución de exactamente `profundidad` movimientos,
  /// pedir `objetivo > profundidad` garantiza que las 3 estrellas sean
  /// alcanzables por construcción, y el margen le da al jugador su cuota de
  /// error humano. La calibración la vigilan `test/challenge_calibration_test.dart`
  /// (mide el óptimo real de cada nivel) y `test/puzzle_logic_test.dart`
  /// (progresión y relación profundidad/objetivo).
  static const int desafioProfundidadMin4x4 = 18;
  static const int desafioProfundidadMax4x4 = 40;
  static const int desafioMargenObjetivo4x4 = 6;

  /// Configuración de un nivel del Modo Desafío:
  /// tamaño del tablero, profundidad de desarme y objetivo de movimientos.
  ///
  /// - Niveles 1 a 10: tablero 3x3, objetivo de 3 a 12 movimientos.
  /// - Niveles 11 a 20: tablero 4x4, profundidad de 18 a 40 y objetivo de
  ///   24 a 46 movimientos.
  static ({int size, int profundidad, int objetivo}) configuracionNivel(
      int nivel) {
    RangeError.checkValueInInterval(nivel, 1, 20, 'nivel');
    if (nivel <= 10) {
      // 1 -> 3, 2 -> 4, ... 10 -> 12 (progresión lineal exacta). Sin margen:
      // en 3x3 el óptimo sí es alcanzable para un humano, y el objetivo no
      // debe cambiar para no invalidar las estrellas ya ganadas.
      final objetivo = 3 + (nivel - 1);
      return (size: 3, profundidad: objetivo, objetivo: objetivo);
    }
    // 11 -> 18 ... 20 -> 40 de profundidad, con progresión lineal.
    final indice = nivel - 11; // 0..9
    final profundidad = desafioProfundidadMin4x4 +
        ((desafioProfundidadMax4x4 - desafioProfundidadMin4x4) * indice / 9)
            .round();
    return (
      size: 4,
      profundidad: profundidad,
      objetivo: profundidad + desafioMargenObjetivo4x4,
    );
  }

  /// Cantidad de estrellas (1 a 3) logradas según los movimientos usados.
  ///
  /// 3 estrellas si se resuelve dentro del objetivo del nivel; 2 estrellas si
  /// se excede hasta en un 50% (redondeando hacia arriba); 1 estrella por
  /// resolver el tablero.
  static int estrellasPara(int movimientos, int objetivo) {
    if (movimientos <= objetivo) return 3;
    if (movimientos <= (objetivo * 1.5).ceil()) return 2;
    return 1;
  }

  /// Genera el tablero del [nivel] del Modo Desafío.
  ///
  /// Parte del tablero resuelto y aplica exactamente `profundidad` movimientos
  /// aleatorios controlados ("scramble inverso"), desplazando el hueco con una
  /// semilla determinista `Random(nivel)`: el mismo nivel siempre genera el
  /// mismo tablero, en cualquier dispositivo.
  ///
  /// Incluye un mecanismo anti-rebote: nunca se mueve el hueco en la dirección
  /// opuesta a la del movimiento anterior (si el hueco fue a la derecha, no
  /// vuelve de inmediato a la izquierda), evitando scrambles triviales. Eso
  /// también hace que el óptimo del tablero quede cerca de `profundidad`, por
  /// eso el `objetivo` del nivel es mayor (ver [configuracionNivel]).
  static List<int> generarTableroDesafio(int nivel) {
    final config = configuracionNivel(nivel);
    final size = config.size;
    final profundidad = config.profundidad;
    final total = size * size;

    // Semilla estable por nivel. Si el scramble terminara resuelto (caminata
    // cerrada, muy poco probable) se reintenta con la siguiente semilla; como
    // la semilla es fija, el resultado sigue siendo determinista.
    var semilla = nivel;
    while (true) {
      final random = Random(semilla);
      List<int> tablero = List.generate(total, (i) => (i + 1) % total);
      var posHueco = total - 1;
      Direccion? ultimoMovimiento;

      for (var i = 0; i < profundidad; i++) {
        final candidatos = _movimientosPosiblesHueco(posHueco, size);
        final prohibida = _opuesta(ultimoMovimiento);
        if (prohibida != null) candidatos.remove(prohibida);
        final dir = candidatos[random.nextInt(candidatos.length)];
        tablero = _moverHueco(tablero, posHueco, dir, size);
        posHueco += _desplazamiento(dir, size);
        ultimoMovimiento = dir;
      }

      if (!estaResuelto(tablero)) return tablero;
      semilla++;
    }
  }

  /// Direcciones en las que el hueco puede desplazarse desde [posHueco]
  /// sin salirse del tablero.
  static List<Direccion> _movimientosPosiblesHueco(int posHueco, int size) {
    final fila = posHueco ~/ size;
    final col = posHueco % size;
    return [
      if (fila > 0) Direccion.arriba,
      if (fila < size - 1) Direccion.abajo,
      if (col > 0) Direccion.izquierda,
      if (col < size - 1) Direccion.derecha,
    ];
  }

  /// Intercambia el hueco en [posHueco] con la ficha vecina en [dir].
  static List<int> _moverHueco(
      List<int> tablero, int posHueco, Direccion dir, int size) {
    final destino = posHueco + _desplazamiento(dir, size);
    final nuevo = List<int>.from(tablero);
    nuevo[posHueco] = nuevo[destino];
    nuevo[destino] = 0;
    return nuevo;
  }

  /// Desplazamiento (en índices) que produce cada dirección sobre el hueco.
  static int _desplazamiento(Direccion dir, int size) => switch (dir) {
        Direccion.arriba => -size,
        Direccion.abajo => size,
        Direccion.izquierda => -1,
        Direccion.derecha => 1,
      };

  /// Dirección opuesta a [dir]; `null` si no hay una dirección previa.
  static Direccion? _opuesta(Direccion? dir) => switch (dir) {
        null => null,
        Direccion.arriba => Direccion.abajo,
        Direccion.abajo => Direccion.arriba,
        Direccion.izquierda => Direccion.derecha,
        Direccion.derecha => Direccion.izquierda,
      };
}
