/// Los niveles de dificultad de la partida libre.
///
/// El tamaño del tablero es lo único que los distingue: de ahí salen la
/// cantidad de fichas, la colección del Top 5 (`leaderboard_NxN`) y el récord
/// personal. Por eso el enum guarda solo [tamano]: los colores y los íconos son
/// presentación y viven en `AppTheme` y en `DifficultyButton`, igual que el
/// color del podio en los récords.
///
/// `GameScreen` sigue recibiendo un `int size` y no un `Dificultad`: el enum es
/// el vocabulario del menú, no una capa nueva del motor.
enum Dificultad {
  facil(3),
  medio(4),
  dificil(5),

  /// Tablero 6×6. **Todavía no tiene botón en el menú**: ver [jugables].
  ///
  /// El motor ya lo soporta —`PuzzleLogic.tieneSolucion` contempla los tableros
  /// pares a propósito, con un comentario que menciona 6×6—, pero habilitarlo no
  /// es solo agregar el botón:
  ///
  /// - `records_screen.dart` tiene los tamaños hardcodeados en `_tamanos` y en
  ///   `_dificultades`, así que un 6×6 no aparecería en la pantalla de récords.
  /// - La colección `leaderboard_6x6` no existe en Firestore, con sus reglas.
  /// - `challenge_calibration_test.dart` no podría verificar el óptimo de un
  ///   6×6: su solver tiene un tope de 4M nodos y solo resuelve 3×3 y 4×4, así
  ///   que la calibración quedaría sin red de seguridad.
  experto(6);

  const Dificultad(this.tamano);

  /// Lado del tablero: 3 para 3×3, 4 para 4×4, etc.
  final int tamano;

  /// Las dificultades que hoy tienen botón en el menú.
  ///
  /// La UI recorre esta lista en vez de `Dificultad.values` para no ofrecer un
  /// tablero que todavía no tiene récords ni ranking. Ver [experto].
  static const List<Dificultad> jugables = [facil, medio, dificil];

  /// La dificultad de un tablero de [tamano], o `null` si el enum no la cubre.
  ///
  /// La pantalla de juego recibe un `int size`, no un [Dificultad], y el header
  /// necesita el nombre para la bajada ("Modo Difícil"). El mapeo vive acá y no
  /// en el widget para que no se desincronice del enum.
  static Dificultad? paraTamano(int tamano) {
    for (final dificultad in values) {
      if (dificultad.tamano == tamano) return dificultad;
    }
    return null;
  }
}
