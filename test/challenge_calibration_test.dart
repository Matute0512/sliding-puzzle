import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_test/flutter_test.dart';
import 'package:sliding_puzzle/logic/puzzle_logic.dart';

/// Resolutor IDA* (Manhattan + conflicto lineal) usado **solo** para verificar
/// la calibración del Modo Desafío: comprueba contra el óptimo real que las 3
/// estrellas de cada nivel sean alcanzables y que los 4x4 dejen margen.
///
/// No es código de la app: vive en los tests porque resolver el 15-puzzle no es
/// algo que el juego necesite hacer en tiempo de ejecución. Los tableros son
/// deterministas (semilla = nivel), así que este test no es aleatorio.
class _Resolutor {
  /// Tope de nodos explorados. Los niveles generados se resuelven muy por
  /// debajo, así que si se alcanza es que la calibración cambió mucho.
  static const int _topeNodos = 4000000;

  int _nodos = 0;
  int? _hallado;

  static int _manhattan(List<int> b, int n) {
    var d = 0;
    for (var i = 0; i < b.length; i++) {
      final v = b[i];
      if (v == 0) continue;
      final meta = v - 1;
      d += ((i ~/ n) - (meta ~/ n)).abs() + ((i % n) - (meta % n)).abs();
    }
    return d;
  }

  /// Pares de fichas en su fila/columna destino pero invertidos: cada conflicto
  /// obliga a desviarse al menos 2 movimientos extra.
  static int _conflictosLineales(List<int> b, int n) {
    var c = 0;
    for (var f = 0; f < n; f++) {
      for (var i = 0; i < n; i++) {
        for (var j = i + 1; j < n; j++) {
          final a = b[f * n + i];
          final d = b[f * n + j];
          if (a == 0 || d == 0) continue;
          if ((a - 1) ~/ n != f || (d - 1) ~/ n != f) continue;
          if ((a - 1) % n > (d - 1) % n) c++;
        }
      }
    }
    for (var col = 0; col < n; col++) {
      for (var i = 0; i < n; i++) {
        for (var j = i + 1; j < n; j++) {
          final a = b[i * n + col];
          final d = b[j * n + col];
          if (a == 0 || d == 0) continue;
          if ((a - 1) % n != col || (d - 1) % n != col) continue;
          if ((a - 1) ~/ n > (d - 1) ~/ n) c++;
        }
      }
    }
    return c;
  }

  static int _h(List<int> b, int n) =>
      _manhattan(b, n) + 2 * _conflictosLineales(b, n);

  static bool _adyacente(int hueco, int destino, int n) {
    if (destino < 0 || destino >= n * n) return false;
    final d = destino - hueco;
    if (d == n || d == -n) return true;
    if (d == 1 || d == -1) return (hueco ~/ n) == (destino ~/ n);
    return false;
  }

  /// Devuelve la cota inferior del próximo intento, o -1 si encontró solución.
  int _buscar(List<int> b, int n, int g, int limite, int huecoAnterior) {
    _nodos++;
    if (_nodos > _topeNodos) return -2;
    final h = _h(b, n);
    if (g + h > limite) return g + h;
    if (h == 0) {
      _hallado = g;
      return -1;
    }

    var minimo = 1 << 30;
    final hueco = b.indexOf(0);
    for (final delta in [-n, n, -1, 1]) {
      final destino = hueco + delta;
      if (!_adyacente(hueco, destino, n)) continue;
      if (destino == huecoAnterior) continue;
      final siguiente = List<int>.from(b);
      siguiente[hueco] = siguiente[destino];
      siguiente[destino] = 0;
      final t = _buscar(siguiente, n, g + 1, limite, hueco);
      if (t == -1) return -1;
      if (t == -2) return -2;
      if (t < minimo) minimo = t;
    }
    return minimo;
  }

  /// Longitud de la solución óptima, o `null` si se agotó el tope de nodos.
  int? optimo(List<int> inicio, int n) {
    _nodos = 0;
    _hallado = null;
    var limite = _h(inicio, n);
    while (limite <= 100) {
      final t = _buscar(inicio, n, 0, limite, -1);
      if (t == -1) return _hallado;
      if (t == -2) return null;
      limite = t;
    }
    return null;
  }
}

void main() {
  group('calibración del Modo Desafío', () {
    test('las 3 estrellas son alcanzables en los 20 niveles', () {
      final resolutor = _Resolutor();

      debugPrint('nivel | size | prof | objetivo | optimo | holgura');
      for (var nivel = 1; nivel <= 20; nivel++) {
        final config = PuzzleLogic.configuracionNivel(nivel);
        final tablero = PuzzleLogic.generarTableroDesafio(nivel);
        final optimo = resolutor.optimo(tablero, config.size);

        expect(optimo, isNotNull,
            reason: 'nivel $nivel: el resolutor agotó el tope de nodos');
        expect(
          optimo!,
          lessThanOrEqualTo(config.objetivo),
          reason: 'nivel $nivel: el óptimo ($optimo) supera el objetivo '
              '(${config.objetivo}), o sea que las 3 estrellas son imposibles',
        );

        debugPrint('${nivel.toString().padLeft(5)} |'
            '${config.size.toString().padLeft(6)} |'
            '${config.profundidad.toString().padLeft(5)} |'
            '${config.objetivo.toString().padLeft(9)} |'
            '${optimo.toString().padLeft(6)} |'
            '${(config.objetivo - optimo).toString().padLeft(7)}');
      }
    });

    test('los niveles 4x4 conservan margen de error humano', () {
      // Regresión: con `objetivo == profundidad` la holgura medida era 0, así
      // que las 3 estrellas exigían la solución óptima exacta. Se exige margen
      // real para que el 4x4 sea un desafío y no un castigo matemático.
      final resolutor = _Resolutor();

      for (var nivel = 11; nivel <= 20; nivel++) {
        final config = PuzzleLogic.configuracionNivel(nivel);
        final optimo =
            resolutor.optimo(PuzzleLogic.generarTableroDesafio(nivel), 4)!;
        final holgura = config.objetivo - optimo;

        expect(holgura, greaterThanOrEqualTo(4),
            reason: 'nivel $nivel: holgura $holgura, demasiado ajustado para '
                'pedir 3 estrellas a un humano');
      }
    });
  });
}
