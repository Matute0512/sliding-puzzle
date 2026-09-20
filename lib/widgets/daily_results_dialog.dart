import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_info.dart';
import '../l10n/app_localizations.dart';
import '../services/daily_challenge_service.dart';
import '../services/daily_leaderboard_service.dart';
import '../theme/app_theme.dart';

/// Resultados del Desafío Diario: el Top 5 del día y el resultado propio, con
/// un botón para compartir.
///
/// Se abre desde el menú cuando el candado del día ya está cerrado. Consulta
/// `DailyLeaderboardService` (ruta `daily_leaderboards/{semilla}/scores`), que
/// es una tabla aparte del Top 5 de las partidas clásicas: distinta ruta,
/// distinto orden (acá manda el tiempo), y se escribe siempre en vez de solo si
/// se clasifica.
class DailyResultsDialog extends StatefulWidget {
  /// Semilla (YYYYMMDD) del día a mostrar.
  final int semilla;

  const DailyResultsDialog({super.key, required this.semilla});

  static Future<void> mostrar(BuildContext context, {required int semilla}) {
    return showDialog<void>(
      context: context,
      builder: (_) => DailyResultsDialog(semilla: semilla),
    );
  }

  @override
  State<DailyResultsDialog> createState() => _DailyResultsDialogState();
}

class _DailyResultsDialogState extends State<DailyResultsDialog> {
  late Future<({List<PuntajeDiario> top, ResultadoDiario? mio})> _consulta;

  @override
  void initState() {
    super.initState();
    _consulta = _cargar();
  }

  /// Una sola `Future` para las dos cosas que necesita el diálogo: así hay un
  /// único estado de carga y un único botón de reintento.
  Future<({List<PuntajeDiario> top, ResultadoDiario? mio})> _cargar() async {
    final top = await DailyLeaderboardService.obtenerTopDia(widget.semilla);
    final mio = await DailyChallengeService.resultadoDe(widget.semilla);
    return (top: top, mio: mio);
  }

  void _reintentar() {
    setState(() => _consulta = _cargar());
  }

  /// Copia al portapapeles el texto para compartir. Estilo Wordle: el resultado
  /// del día en dos líneas y el link para que otro pueda jugar.
  Future<void> _compartir(ResultadoDiario mio) async {
    final l10n = AppLocalizations.of(context)!;
    final texto = l10n.dailyShareText(
      // Como String a propósito: si fuera `int`, ICU le pondría separador de
      // miles y la semilla se vería "20.260.919" en vez de "20260919".
      '${widget.semilla}',
      l10n.secondsShort(mio.segundos),
      mio.movimientos,
      urlPlayStore,
    );

    await Clipboard.setData(ClipboardData(text: texto));
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(l10n.dailyShareCopied),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Column(
        children: [
          Text(
            l10n.dailyResultsTitle,
            style: const TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            l10n.dailyResultsDay('${widget.semilla}'),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.normal,
              color: colors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      // Scrolleable: con 5 filas más el resultado propio, en pantallas cortas o
      // con fuente grande el contenido no entra.
      content: SingleChildScrollView(
        child: FutureBuilder<({List<PuntajeDiario> top, ResultadoDiario? mio})>(
          future: _consulta,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (snapshot.hasError) {
              return _Estado(
                icono: Icons.cloud_off_rounded,
                mensaje: l10n.dailyResultsError,
                colors: colors,
                accion: TextButton(
                  onPressed: _reintentar,
                  child: Text(l10n.dailyResultsRetry),
                ),
              );
            }

            final datos = snapshot.data!;
            if (datos.top.isEmpty) {
              return _Estado(
                icono: Icons.hourglass_empty_rounded,
                mensaje: l10n.dailyResultsEmpty,
                colors: colors,
              );
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < datos.top.length; i++)
                  _FilaPuntaje(
                    puesto: i + 1,
                    puntaje: datos.top[i],
                    colors: colors,
                  ),
                if (datos.mio case final mio?) ...[
                  const SizedBox(height: 12),
                  Divider(color: colors.emptyTile, height: 1),
                  const SizedBox(height: 12),
                  Text(
                    l10n.dailyResultsYou,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colors.textSecondary,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _FilaPuntaje(
                    puntaje: PuntajeDiario(
                      alias: '',
                      movimientos: mio.movimientos,
                      tiempoSegundos: mio.segundos,
                      fecha: DateTime(0),
                    ),
                    colors: colors,
                  ),
                ],
              ],
            );
          },
        ),
      ),
      actions: [
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // El botón de compartir depende del resultado local, que se resuelve
            // junto con la consulta: por eso vive dentro de otro `FutureBuilder`
            // en vez de leer `snapshot` acá afuera.
            FutureBuilder<({List<PuntajeDiario> top, ResultadoDiario? mio})>(
              future: _consulta,
              builder: (context, snapshot) {
                final mio = snapshot.data?.mio;
                // Sin resultado propio no hay nada que compartir. Solo puede
                // pasar si el desafío se completó con una versión anterior de
                // la app, que no guardaba el resultado en disco.
                if (mio == null) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.seedColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => _compartir(mio),
                    icon: const Icon(Icons.share_rounded, size: 18),
                    label: Text(
                      l10n.dailyShare,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              },
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                l10n.backToMenu,
                style: TextStyle(color: colors.textSecondary),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Fila del ranking: puesto, alias, tiempo y movimientos.
class _FilaPuntaje extends StatelessWidget {
  /// `null` en la fila del resultado propio, que no compite en la tabla.
  final int? puesto;
  final PuntajeDiario puntaje;
  final AppColors colors;

  const _FilaPuntaje({
    this.puesto,
    required this.puntaje,
    required this.colors,
  });

  /// Dorado, plata y bronce para el podio; el resto queda en gris.
  Color get _colorPuesto => switch (puesto) {
        1 => const Color(0xFFF59E0B),
        2 => const Color(0xFF94A3B8),
        3 => const Color(0xFFB45309),
        _ => colors.textSecondary,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: puesto == null
                ? Icon(Icons.person_rounded, size: 20, color: colors.textSecondary)
                : Text(
                    '$puesto',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _colorPuesto,
                    ),
                  ),
          ),
          const SizedBox(width: 8),
          if (puesto != null)
            Expanded(
              child: Text(
                puntaje.alias,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
            )
          else
            const Spacer(),
          const SizedBox(width: 8),
          Text(
            l10n.secondsShort(puntaje.tiempoSegundos),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 44,
            child: Text(
              '${puntaje.movimientos}',
              textAlign: TextAlign.end,
              style: TextStyle(fontSize: 13, color: colors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

/// Mensaje centrado con ícono para los estados vacío y de error.
class _Estado extends StatelessWidget {
  final IconData icono;
  final String mensaje;
  final AppColors colors;
  final Widget? accion;

  const _Estado({
    required this.icono,
    required this.mensaje,
    required this.colors,
    this.accion,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 40, color: colors.textSecondary),
          const SizedBox(height: 12),
          Text(
            mensaje,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: colors.textSecondary),
          ),
          if (accion case final accion?) ...[
            const SizedBox(height: 4),
            accion,
          ],
        ],
      ),
    );
  }
}
