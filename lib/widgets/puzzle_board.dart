import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:sliding_puzzle/logic/puzzle_logic.dart';
import '../theme/app_theme.dart';
import '../theme/kenney_ui.dart';
import 'puzzle_tile.dart';

/// Tablero del puzzle con fichas que se deslizan hacia el hueco.
///
/// Reemplaza al `GridView`: un `Stack` con `clipBehavior: Clip.none` (para que
/// las sombras de la última fila no se recorten) donde cada ficha es un
/// `AnimatedPositioned` keyed por su número. Al reordenarse el tablero, la
/// ficha anima su posición y se ve el deslizamiento real.
///
/// Optimizado para Impeller (sin raster cache de capas):
/// - Los `n²` sockets de fondo se dibujan y hornean **una sola vez** a una
///   textura [ui.Image] en [_CapaSockets], pasando de `n²` subárboles de
///   widgets y `9 × n²` quads por frame a un único `drawImageRect` por frame.
/// - Las instancias de [PuzzleTile] se cachean por `(numero, activa)` y se
///   graban directamente en la display list del tablero (sin 24 `OffsetLayer`
///   intermedias por ficha que Impeller tenga que recorrer en cada frame).
class PuzzleBoard extends StatefulWidget {
  final List<int> tablero;
  final int size;
  final void Function(int indice) onTileTap;

  /// Si no es `null`, las fichas muestran porciones de esta imagen en vez de
  /// números. No afecta en nada la mecánica: el deslizamiento, los huecos y las
  /// pistas de "movible" dependen del [tablero], no de cómo se dibuje la ficha.
  final ImageProvider? imagen;

  /// Imagen a la que caer si [imagen] no carga. Ver `ImageTile.respaldo`.
  final ImageProvider? imagenRespaldo;

  const PuzzleBoard({
    super.key,
    required this.tablero,
    required this.size,
    required this.onTileTap,
    this.imagen,
    this.imagenRespaldo,
  });

  @override
  State<PuzzleBoard> createState() => _PuzzleBoardState();
}

class _PuzzleBoardState extends State<PuzzleBoard> {
  static const double _espaciado = 4.0;

  /// Instancias cacheadas de [PuzzleTile] por número de ficha (`1..n²-1`).
  final Map<int, Widget> _fichasCacheadas = <int, Widget>{};

  /// Último valor de `activa` con el que se construyó cada ficha cacheada.
  final Map<int, bool> _activaCacheada = <int, bool>{};

  /// Subárbol memoizado de la capa de sockets para el `(size, ladoCelda)` actual.
  Widget? _socketsCacheados;
  int? _sizeSockets;
  double? _ladoSockets;

  @override
  void didUpdateWidget(covariant PuzzleBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.size != widget.size ||
        oldWidget.imagen != widget.imagen ||
        oldWidget.imagenRespaldo != widget.imagenRespaldo) {
      _fichasCacheadas.clear();
      _activaCacheada.clear();
    }
    if (oldWidget.size != widget.size) {
      _socketsCacheados = null;
      _sizeSockets = null;
      _ladoSockets = null;
    }
  }

  /// Resuelve el índice actual de la ficha [numero] al momento del toque.
  ///
  /// Pasar el callback por número (y no por índice de celda) es lo que permite
  /// que la instancia de `PuzzleTile` no dependa de su posición en el tablero y
  /// pueda reutilizarse sin reconstruirse cuando otra ficha se mueve.
  void _onTapNumero(int numero) {
    final indice = widget.tablero.indexOf(numero);
    if (indice < 0) return;
    widget.onTileTap(indice);
  }

  /// Mueve la ficha [numero] únicamente si el deslizamiento va en dirección al
  /// espacio vacío. Los swipes en cualquier otra dirección se ignoran.
  void _deslizarNumero(int numero, Direccion direccion) {
    final indice = widget.tablero.indexOf(numero);
    if (indice < 0) return;
    if (PuzzleLogic.direccionHaciaVacio(widget.tablero, indice, widget.size) !=
        direccion) {
      return;
    }
    widget.onTileTap(indice);
  }

  Widget _obtenerCapaSockets(int n, double ladoCelda) {
    if (_socketsCacheados != null &&
        _sizeSockets == n &&
        _ladoSockets == ladoCelda) {
      return _socketsCacheados!;
    }
    _sizeSockets = n;
    _ladoSockets = ladoCelda;
    _socketsCacheados = Positioned.fill(
      child: RepaintBoundary(
        child: _CapaSockets(
          size: n,
          ladoCelda: ladoCelda,
          espaciado: _espaciado,
        ),
      ),
    );
    return _socketsCacheados!;
  }

  Widget _obtenerFicha(int numero, bool activa) {
    final existente = _fichasCacheadas[numero];
    if (existente != null && _activaCacheada[numero] == activa) {
      return existente;
    }
    final nueva = PuzzleTile(
      numero: numero,
      size: widget.size,
      imagen: widget.imagen,
      imagenRespaldo: widget.imagenRespaldo,
      activa: activa,
      onTap: () => _onTapNumero(numero),
      onSwipe: (direccion) => _deslizarNumero(numero, direccion),
    );
    _activaCacheada[numero] = activa;
    _fichasCacheadas[numero] = nueva;
    return nueva;
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.size;
    final tablero = widget.tablero;
    final movibles = PuzzleLogic.movibles(tablero, n).toSet();

    // La capa de repintado va **por fuera del `LayoutBuilder`**, y ése es el
    // detalle que decide si el deslizamiento repinta sólo el tablero o la
    // pantalla entera.
    //
    // El `LayoutBuilder` es el boundary de *relayout* del tablero, y el
    // framework cierra todo layout con `markNeedsPaint()` (`RenderObject.layout`
    // y `_layoutWithoutResize`, ver `rendering/object.dart`): al cambiar el
    // `left`/`top` de una ficha, la invalidación de pintado nace en el
    // `LayoutBuilder` y sube hasta la primera capa de repintado que encuentre.
    // Con el `RepaintBoundary` **adentro** del `LayoutBuilder` esa capa es el
    // viewport del `SingleChildScrollView` de `GameScreen`
    // (`_RenderSingleChildViewport` es repaint boundary), que envuelve el HUD,
    // la consigna, el pozo con su halo y la botonera: todo eso se volvía a
    // registrar y a rasterizar en cada uno de los ~10 frames de los 160 ms del
    // deslizamiento. Con la capa acá, la propagación se corta antes de salir
    // del tablero.
    //
    // `RenderRepaintBoundary` es un `RenderProxyBox`: no recorta ni cambia el
    // layout, así que la sombra de la fila inferior sigue desbordando
    // (`Clip.none`) y la geometría que lee `test/helpers/puzzle_solver.dart` no
    // se corre.
    //
    // Lo vigila `test/widget/game_screen_repaint_test.dart`: no alcanza con que
    // la capa exista y mida lo que mide el tablero, también tiene que quedar
    // *por encima* del `LayoutBuilder`. Si vuelve a meterse adentro, el
    // deslizamiento repinta otra vez el HUD, el pozo y la botonera.
    return RepaintBoundary(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final ladoCelda = (constraints.maxWidth - (n - 1) * _espaciado) / n;
          double left(int i) => (i % n) * (ladoCelda + _espaciado);
          double top(int i) => (i ~/ n) * (ladoCelda + _espaciado);

          return Stack(
            clipBehavior: Clip.none,
            children: [
              // Sockets: el fondo de todas las celdas, horneado en una sola
              // textura `ui.Image` para que el hilo Raster pinte un único quad
              // en vez de n² nine-patch + n² bordes por frame.
              _obtenerCapaSockets(n, ladoCelda),
              // Fichas numeradas: al cambiar su índice, `AnimatedPositioned`
              // las desliza desde su posición anterior. Su subárbol se
              // reutiliza desde `_fichasCacheadas` mientras no cambie `activa`.
              for (var i = 0; i < tablero.length; i++)
                if (tablero[i] != 0)
                  AnimatedPositioned(
                    key: ValueKey(tablero[i]),
                    duration: const Duration(milliseconds: 160),
                    curve: Curves.easeOutCubic,
                    left: left(i),
                    top: top(i),
                    width: ladoCelda,
                    height: ladoCelda,
                    child: _obtenerFicha(tablero[i], movibles.contains(i)),
                  ),
            ],
          );
        },
      ),
    );
  }
}

/// Capa estática que dibuja los `n²` sockets de fondo y los hornea en una sola
/// textura [ui.Image] (`PictureRecorder` -> `toImageSync`).
///
/// Bajo Impeller no existe caché de rasterizado para `RepaintBoundary`: aunque
/// la display list de los sockets no se re-grabe en el hilo UI, la GPU volvía a
/// ejecutar los 25 `drawImageNine` (225 quads) y los 25 bordes redondeados en
/// cada frame del deslizamiento. Al rasterizarlos una sola vez a una textura
/// del tamaño del tablero, cada frame del deslizamiento ejecuta un único
/// `canvas.drawImageRect`.
class _CapaSockets extends StatefulWidget {
  final int size;
  final double ladoCelda;
  final double espaciado;

  const _CapaSockets({
    required this.size,
    required this.ladoCelda,
    required this.espaciado,
  });

  @override
  State<_CapaSockets> createState() => _CapaSocketsState();
}

class _CapaSocketsState extends State<_CapaSockets> {
  ImageStream? _stream;
  ImageStreamListener? _listener;
  ui.Image? _sprite;
  final _CacheTexturaSockets _cacheTextura = _CacheTexturaSockets();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolverSprite();
  }

  void _resolverSprite() {
    final nuevoStream = AssetImage(
      KenneySlices.flatSquare.asset,
    ).resolve(createLocalImageConfiguration(context));
    if (nuevoStream.key == _stream?.key) return;

    if (_listener != null) {
      _stream?.removeListener(_listener!);
    }
    _stream = nuevoStream;
    _listener = ImageStreamListener(
      (info, synchronousCall) {
        if (!mounted) return;
        setState(() {
          _sprite = info.image;
        });
      },
      onError: (_, _) {},
    );
    _stream!.addListener(_listener!);
  }

  @override
  void dispose() {
    if (_listener != null) {
      _stream?.removeListener(_listener!);
    }
    _cacheTextura.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return ExcludeSemantics(
      child: CustomPaint(
        painter: _SocketsPainter(
          n: widget.size,
          ladoCelda: widget.ladoCelda,
          espaciado: widget.espaciado,
          dpr: dpr,
          sprite: _sprite,
          cache: _cacheTextura,
        ),
      ),
    );
  }
}

class _CacheTexturaSockets {
  ui.Image? textura;
  int? n;
  double? ladoCelda;
  double? dpr;
  ui.Image? sprite;

  ui.Image? obtenerOGenerar({
    required int n,
    required double ladoCelda,
    required double espaciado,
    required double dpr,
    required ui.Image sprite,
    required Size size,
  }) {
    if (textura != null &&
        this.n == n &&
        this.ladoCelda == ladoCelda &&
        this.dpr == dpr &&
        identical(this.sprite, sprite)) {
      return textura;
    }

    final anchoPx = (size.width * dpr).round();
    final altoPx = (size.height * dpr).round();
    if (anchoPx <= 0 || altoPx <= 0) return null;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)..scale(dpr, dpr);
    _SocketsPainter.dibujarCeldas(
      canvas: canvas,
      n: n,
      ladoCelda: ladoCelda,
      espaciado: espaciado,
      sprite: sprite,
    );
    final picture = recorder.endRecording();
    textura?.dispose();
    textura = picture.toImageSync(anchoPx, altoPx);
    picture.dispose();

    this.n = n;
    this.ladoCelda = ladoCelda;
    this.dpr = dpr;
    this.sprite = sprite;
    return textura;
  }

  void dispose() {
    textura?.dispose();
    textura = null;
  }
}

class _SocketsPainter extends CustomPainter {
  final int n;
  final double ladoCelda;
  final double espaciado;
  final double dpr;
  final ui.Image? sprite;
  final _CacheTexturaSockets cache;

  const _SocketsPainter({
    required this.n,
    required this.ladoCelda,
    required this.espaciado,
    required this.dpr,
    required this.sprite,
    required this.cache,
  });

  static void dibujarCeldas({
    required Canvas canvas,
    required int n,
    required double ladoCelda,
    required double espaciado,
    required ui.Image? sprite,
  }) {
    final paintSprite = Paint()..filterQuality = FilterQuality.low;
    final paintBorde = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = AppTheme.emptySlotBorder;
    const radio = Radius.circular(8);
    final centerSlice = KenneySlices.flatSquare.centerSlice;

    for (var i = 0; i < n * n; i++) {
      final left = (i % n) * (ladoCelda + espaciado);
      final top = (i ~/ n) * (ladoCelda + espaciado);
      final rect = Rect.fromLTWH(left, top, ladoCelda, ladoCelda);
      if (sprite != null) {
        canvas.drawImageNine(sprite, centerSlice, rect, paintSprite);
      }
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect.deflate(0.5), radio),
        paintBorde,
      );
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final spriteActual = sprite;
    if (spriteActual != null) {
      final horneada = cache.obtenerOGenerar(
        n: n,
        ladoCelda: ladoCelda,
        espaciado: espaciado,
        dpr: dpr,
        sprite: spriteActual,
        size: size,
      );
      if (horneada != null) {
        canvas.drawImageRect(
          horneada,
          Rect.fromLTWH(
            0,
            0,
            horneada.width.toDouble(),
            horneada.height.toDouble(),
          ),
          Offset.zero & size,
          Paint()..filterQuality = FilterQuality.low,
        );
        return;
      }
    }

    dibujarCeldas(
      canvas: canvas,
      n: n,
      ladoCelda: ladoCelda,
      espaciado: espaciado,
      sprite: null,
    );
  }

  @override
  bool shouldRepaint(_SocketsPainter oldDelegate) {
    return oldDelegate.n != n ||
        oldDelegate.ladoCelda != ladoCelda ||
        oldDelegate.espaciado != espaciado ||
        oldDelegate.dpr != dpr ||
        !identical(oldDelegate.sprite, sprite);
  }
}
