/// Duración en formato cronómetro: `mm:ss`, como el `00:37` de los frames.
///
/// Ojo: el resto de la app muestra los tiempos con `l10n.secondsShort` ("37s").
/// El formato de cronómetro se reserva para las **marcas** —el récord del menú y
/// el de la partida—, que se leen mejor como marca que como cantidad de
/// segundos. Quedan dos formatos de tiempo conviviendo a propósito: si algún día
/// se unifican, el que debería ceder es este, no `secondsShort`, que está en la
/// mitad de las pantallas.
///
/// Los minutos no tienen tope: 75 minutos se muestran `75:00`, no `15:00` sobre
/// una hora.
String duracionMmSs(int segundos) {
  final minutos = (segundos ~/ 60).toString().padLeft(2, '0');
  final resto = (segundos % 60).toString().padLeft(2, '0');
  return '$minutos:$resto';
}
