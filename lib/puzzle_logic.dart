import 'dart:math';

/// Contiene toda la lógica del tablero, sin tocar la UI.
class PuzzleLogic {
  /// Genera un tablero mezclado que siempre tiene solución.
  static List<int> generarTablero(int size) {
    List<int> tablero;
    // Repetimos hasta generar uno que tenga solución
    do {
      tablero = List.generate(size * size, (i) => i); // [0,1,2,3,4,5,6,7,8]
      tablero.shuffle(Random());
    } while (!tieneSolucion(tablero, size));
    return tablero;
  }

  static bool puedeMover(List<int> tablero, int indice,int size){
    int posVacio = tablero.indexOf(0);

    int filaFicha = indice ~/ size;
    int colFicha = indice % size;
    int filaVacio = posVacio ~/size;
    int colVacio = posVacio % size;

    bool mismaFila = filaFicha == filaVacio && (colFicha - colVacio).abs() == 1;
    bool mismaColumna = colFicha == colVacio && (filaFicha - filaVacio).abs() == 1;

    return mismaFila || mismaColumna;
  }

  /// Mueve la ficha en [indice] intercambiandola con el espacio vacio
  /// Devuelve una nueva lista (no modifica la original)
  static List<int> mover(List<int> tablero, int indice){
    int posVacio = tablero.indexOf(0);
    List<int> nuevo = List.from(tablero);
    nuevo[posVacio] = nuevo[indice];
    nuevo[indice] = 0;

    return nuevo;
  }

  /// Verifica si el tablero está resuelto: [1,2,3,4,5,6,7,8,0]
  static bool estaResuelto(List<int> tablero) {
    for (int i = 0; i < tablero.length - 1; i++) {
      if (tablero[i] != i + 1) return false;
    }
    return true;
  }

  /// Verifica si el tablero tiene solucion usando el conteo de inversiones.
  /// No todos los tableros mezclados son resolubles, esto lo garantiza.
  static bool tieneSolucion(List<int> tablero, int size){
    int inversiones = 0;
    List<int> sinCero = tablero.where((n) => n != 0).toList();

    for (int i = 0; i< sinCero.length;i++){
      for (int j = 0; j< sinCero.length -1 ; j++){
        if (sinCero[i] > sinCero[j]) inversiones++;
      }
    }

    if (size % 2 != 0){
      // Tablero impar: tiene solución si inversiones es par
      return inversiones % 2 == 0;
    } else{
      int filaVacio = size -(tablero.indexOf(0) ~/size);
      return (filaVacio % 2 == 0) == (inversiones % 2 != 0);
    }
  }

}