import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Ficha que muestra **una porción** de una imagen: la que le corresponde a su
/// posición en el tablero resuelto.
///
/// Es la pieza clave del rompecabezas con fotos. La ficha con [numero] `k`
/// muestra siempre el mismo recorte —el del orden de lectura del tablero
/// resuelto— sin importar dónde esté ubicada hoy. Al deslizarse, las piezas se
/// reacomodan solas y armar el puzzle reconstruye la imagen completa.
///
/// ## Cómo recorta y por qué se hornea por ficha
///
/// En vez de montar por cada celda un árbol `ClipRRect -> LayoutBuilder ->
/// ClipRect -> OverflowBox -> Image` (que en Impeller ejecuta dos clips de
/// stencil y muestrea la foto entera a `n×` el tamaño de la celda en cada frame
/// del deslizamiento), [ImageTile] resuelve el [ui.Image] una vez, calcula el
/// rectángulo fuente exacto con [recorteDe] y hornea la porción ya recortada y
/// con sus esquinas redondeadas en una pequeña textura [ui.Image] del tamaño de
/// la celda (`PictureRecorder` -> `toImageSync`). Así, durante el deslizamiento
/// la GPU dibuja un único quad (`drawImageRect`) por ficha, sin stencil clips
/// ni overdraw.
class ImageTile extends StatefulWidget {
  /// Imagen completa del rompecabezas.
  final ImageProvider imagen;

  /// Imagen que se muestra si [imagen] no llega a cargar.
  ///
  /// Pensado para la foto del día, que se descarga: si no hay red o el archivo
  /// todavía no se subió, el tablero cae a una foto empaquetada en vez de
  /// quedar en blanco. `null` deja el comportamiento anterior (celda vacía).
  final ImageProvider? respaldo;

  /// Número de ficha (1..n²-1). Determina qué porción se muestra.
  final int numero;

  /// Lado del tablero (3, 4, 5...).
  final int size;

  /// Radio de las esquinas. Se pasa desde afuera para que coincida con el del
  /// contenedor de la ficha y no queden dos valores que se puedan desincronizar.
  final BorderRadius borderRadius;

  const ImageTile({
    super.key,
    required this.imagen,
    required this.numero,
    required this.size,
    this.respaldo,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
  });

  /// Posición (fila, col) que le toca a [numero] en el tablero resuelto.
  ///
  /// En el tablero resuelto la ficha `k` vive en el índice `k - 1` (ver
  /// `PuzzleLogic.estaResuelto`), así que fila y columna salen de ese índice en
  /// orden de lectura.
  static ({int fila, int col}) posicionDe(int numero, int size) =>
      (fila: (numero - 1) ~/ size, col: (numero - 1) % size);

  /// Alineación equivalente en coordenadas `0..1` para la porción de [numero].
  static FractionalOffset alineacionDe(int numero, int size) {
    final (:fila, :col) = posicionDe(numero, size);
    final divisor = size - 1;
    return FractionalOffset(col / divisor, fila / divisor);
  }

  /// Rectángulo fuente (en píxeles de la imagen) que le toca a la ficha
  /// [numero] en un tablero de [size] × [size].
  ///
  /// Si la imagen no es cuadrada, recorta primero al cuadrado central
  /// (`BoxFit.cover`) sin deformarla, y luego toma la celda `(fila, col)`.
  static Rect recorteDe(int numero, int size, Size tamanoImagen) {
    final lado = math.min(tamanoImagen.width, tamanoImagen.height);
    final ox = (tamanoImagen.width - lado) / 2;
    final oy = (tamanoImagen.height - lado) / 2;
    final paso = lado / size;
    final (:fila, :col) = posicionDe(numero, size);
    return Rect.fromLTWH(ox + col * paso, oy + fila * paso, paso, paso);
  }

  /// Imágenes que ya avisaron que no se pudieron dibujar.
  ///
  /// El listener de error corre una vez **por ficha** —ocho en el diario 3x3—,
  /// así que sin esto un solo fallo de descarga imprimiría ocho líneas
  /// idénticas.
  static final Set<ImageProvider> _avisadas = <ImageProvider>{};

  @override
  State<ImageTile> createState() => ImageTileState();
}

@visibleForTesting
class ImageTileState extends State<ImageTile> {
  ImageStream? _stream;
  ImageStreamListener? _listener;
  ui.Image? _imagen;
  ImageProvider? _proveedorActivo;
  final _CacheTexturaFicha _cacheTextura = _CacheTexturaFicha();

  /// Proveedor que está alimentando actualmente a la ficha ([ImageTile.imagen]
  /// o [ImageTile.respaldo] si el primero falló).
  @visibleForTesting
  ImageProvider? get proveedorActivo => _proveedorActivo;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.numero > 0 && widget.size >= 2) {
      _suscribir(widget.imagen, esRespaldo: false);
    }
  }

  @override
  void didUpdateWidget(covariant ImageTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.numero <= 0 || widget.size < 2) {
      _desuscribir();
      _imagen = null;
      _proveedorActivo = null;
      _cacheTextura.dispose();
      return;
    }
    if (oldWidget.imagen != widget.imagen ||
        oldWidget.respaldo != widget.respaldo) {
      _suscribir(widget.imagen, esRespaldo: false);
    }
  }

  void _suscribir(ImageProvider proveedor, {required bool esRespaldo}) {
    final nuevoStream = proveedor.resolve(
      createLocalImageConfiguration(context),
    );
    if (nuevoStream.key == _stream?.key && _proveedorActivo == proveedor) {
      return;
    }

    _desuscribir();
    _proveedorActivo = proveedor;
    _stream = nuevoStream;
    _listener = ImageStreamListener(
      (info, synchronousCall) {
        if (!mounted) return;
        if (synchronousCall) {
          _imagen = info.image;
        } else {
          setState(() {
            _imagen = info.image;
          });
        }
      },
      onError: (error, stackTrace) {
        final respaldo = widget.respaldo;
        if (!esRespaldo && respaldo != null) {
          if (ImageTile._avisadas.add(widget.imagen)) {
            debugPrint(
              'ImageTile: no se pudo descargar la imagen del tablero '
              '($error). Se usa la de respaldo.',
            );
          }
          if (!mounted) return;
          setState(() {
            _suscribir(respaldo, esRespaldo: true);
          });
          return;
        }
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: error,
            stack: stackTrace,
            library: 'image_tile',
            context: ErrorDescription('mientras se resolvía ImageTile'),
          ),
        );
      },
    );
    _stream!.addListener(_listener!);
  }

  void _desuscribir() {
    if (_listener != null) {
      _stream?.removeListener(_listener!);
      _listener = null;
    }
    _stream = null;
  }

  @override
  void dispose() {
    _desuscribir();
    _cacheTextura.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.numero <= 0 || widget.size < 2) {
      return const SizedBox.shrink();
    }

    final dpr = MediaQuery.devicePixelRatioOf(context);
    return CustomPaint(
      painter: _RecorteFichaPainter(
        imagen: _imagen,
        numero: widget.numero,
        tableroSize: widget.size,
        borderRadius: widget.borderRadius,
        dpr: dpr,
        cache: _cacheTextura,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _CacheTexturaFicha {
  ui.Image? textura;
  ui.Image? fuente;
  int? numero;
  int? tableroSize;
  BorderRadius? borderRadius;
  Size? celdaSize;
  double? dpr;

  ui.Image? obtenerOGenerar({
    required ui.Image fuente,
    required int numero,
    required int tableroSize,
    required BorderRadius borderRadius,
    required Size celdaSize,
    required double dpr,
  }) {
    if (textura != null &&
        identical(this.fuente, fuente) &&
        this.numero == numero &&
        this.tableroSize == tableroSize &&
        this.borderRadius == borderRadius &&
        this.celdaSize == celdaSize &&
        this.dpr == dpr) {
      return textura;
    }

    final anchoPx = (celdaSize.width * dpr).round();
    final altoPx = (celdaSize.height * dpr).round();
    if (anchoPx <= 0 || altoPx <= 0) return null;

    final src = ImageTile.recorteDe(
      numero,
      tableroSize,
      Size(fuente.width.toDouble(), fuente.height.toDouble()),
    );
    final dst = Offset.zero & celdaSize;

    final recorder = ui.PictureRecorder();
    Canvas(recorder)
      ..scale(dpr, dpr)
      ..clipRRect(borderRadius.toRRect(dst))
      ..drawImageRect(
        fuente,
        src,
        dst,
        Paint()..filterQuality = FilterQuality.low,
      );
    final picture = recorder.endRecording();
    textura?.dispose();
    textura = picture.toImageSync(anchoPx, altoPx);
    picture.dispose();

    this.fuente = fuente;
    this.numero = numero;
    this.tableroSize = tableroSize;
    this.borderRadius = borderRadius;
    this.celdaSize = celdaSize;
    this.dpr = dpr;
    return textura;
  }

  void dispose() {
    textura?.dispose();
    textura = null;
  }
}

class _RecorteFichaPainter extends CustomPainter {
  final ui.Image? imagen;
  final int numero;
  final int tableroSize;
  final BorderRadius borderRadius;
  final double dpr;
  final _CacheTexturaFicha cache;

  const _RecorteFichaPainter({
    required this.imagen,
    required this.numero,
    required this.tableroSize,
    required this.borderRadius,
    required this.dpr,
    required this.cache,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final fuente = imagen;
    if (fuente == null || size.isEmpty) return;

    final horneada = cache.obtenerOGenerar(
      fuente: fuente,
      numero: numero,
      tableroSize: tableroSize,
      borderRadius: borderRadius,
      celdaSize: size,
      dpr: dpr,
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

    final src = ImageTile.recorteDe(
      numero,
      tableroSize,
      Size(fuente.width.toDouble(), fuente.height.toDouble()),
    );
    final dst = Offset.zero & size;
    canvas
      ..save()
      ..clipRRect(borderRadius.toRRect(dst))
      ..drawImageRect(
        fuente,
        src,
        dst,
        Paint()..filterQuality = FilterQuality.low,
      )
      ..restore();
  }

  @override
  bool shouldRepaint(_RecorteFichaPainter oldDelegate) {
    return !identical(oldDelegate.imagen, imagen) ||
        oldDelegate.numero != numero ||
        oldDelegate.tableroSize != tableroSize ||
        oldDelegate.borderRadius != borderRadius ||
        oldDelegate.dpr != dpr;
  }
}
