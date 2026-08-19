import 'dart:math';

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
}
