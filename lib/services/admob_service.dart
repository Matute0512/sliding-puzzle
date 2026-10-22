import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'sound_service.dart';

/// Servicio centralizado de monetización con **Google AdMob**
/// (`google_mobile_ads`).
///
/// ## Seguridad de IDs (fuera del repositorio)
/// Los Ad Unit IDs de producción **no** están hardcodeados en el código fuente:
/// se inyectan en tiempo de compilación mediante
/// `--dart-define-from-file=dart_defines.json` (ignorado en `.gitignore`) o
/// desde GitHub Secrets en CI.
///
/// En `kDebugMode` —o cuando las variables de entorno están vacías— el servicio
/// devuelve automáticamente los **Ad Unit IDs de prueba oficiales de Google**,
/// evitando cualquier riesgo de tráfico inválido durante el desarrollo.
class AdMobService {
  // ─────────────────────────────────────────────────────────────────────
  // IDs de Producción inyectados por --dart-define-from-file=dart_defines.json
  // ─────────────────────────────────────────────────────────────────────

  static const String _prodBannerAndroid = String.fromEnvironment(
    'ADMOB_BANNER_ANDROID',
  );
  static const String _prodBannerIos = String.fromEnvironment(
    'ADMOB_BANNER_IOS',
  );

  static const String _prodInterstitialAndroid = String.fromEnvironment(
    'ADMOB_INTERSTITIAL_ANDROID',
  );
  static const String _prodInterstitialIos = String.fromEnvironment(
    'ADMOB_INTERSTITIAL_IOS',
  );

  // ─────────────────────────────────────────────────────────────────────
  // IDs de Prueba Oficiales de Google AdMob
  // https://developers.google.com/admob/flutter/test-ads
  // ─────────────────────────────────────────────────────────────────────

  static const String _testBannerAndroid =
      'ca-app-pub-3940256099942544/6300978111';
  static const String _testBannerIos = 'ca-app-pub-3940256099942544/2934735716';

  static const String _testInterstitialAndroid =
      'ca-app-pub-3940256099942544/1033173712';
  static const String _testInterstitialIos =
      'ca-app-pub-3940256099942544/4411468910';

  // ─────────────────────────────────────────────────────────────────────
  // Parámetros de Política de Frecuencia (Frequency Capping)
  // ─────────────────────────────────────────────────────────────────────

  /// Tiempo mínimo obligatorio entre dos anuncios interstitials consecutivos.
  static const Duration cooldownMinimo = Duration(seconds: 90);

  /// Cantidad de victorias acumuladas para disparar un interstitial.
  static const int victoriasPorAnuncio = 2;

  /// Cantidad de abandonos/reinicios calificados para disparar un interstitial.
  static const int salidasPorAnuncio = 2;

  /// Movimientos mínimos realizados en la partida para que un reinicio o
  /// abandono cuente hacia la frecuencia de anuncios.
  static const int movimientosMinimosParaSalida = 12;

  // ─────────────────────────────────────────────────────────────────────
  // Estado interno
  // ─────────────────────────────────────────────────────────────────────

  static bool _inicializado = false;
  static bool _initEnCurso = false;

  /// Notificador reactivo que pasa a `true` apenas [init] completa la
  /// inicialización nativa del SDK, permitiendo que widgets ya montados (como
  /// el [AdBannerWidget] de `HomeScreen`) inicien su carga sin condiciones de
  /// carrera frente a `unawaited(AdMobService.init())`.
  static final ValueNotifier<bool> inicializadoListenable =
      ValueNotifier<bool>(false);

  static InterstitialAd? _interstitial;
  static bool _cargandoInterstitial = false;
  static int _intentosFallidos = 0;

  static int _victoriasDesdeUltimoAnuncio = 0;
  static int _salidasDesdeUltimoAnuncio = 0;
  static DateTime? _ultimoAnuncioMostrado;

  /// Reloj inyectable para pruebas deterministas de cooldown.
  @visibleForTesting
  static DateTime Function() reloj = DateTime.now;

  /// Hook opcional para simular en tests la exhibición de un interstitial sin
  /// invocar el canal nativo de `google_mobile_ads`.
  @visibleForTesting
  static Future<bool> Function()? mostrarInterstitialOverride;

  /// `true` únicamente en Android e iOS (nunca en Web ni escritorio).
  static bool get plataformaSoportada =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  /// `true` cuando el SDK ya fue inicializado en una plataforma móvil
  /// soportada. En widget tests (donde `init()` no se llama) vale `false` y
  /// todos los widgets/llamadas operan como *no-op*.
  static bool get anunciosHabilitados => _inicializado && plataformaSoportada;

  static bool _esPlaceholder(String id) => id.isEmpty || id.startsWith('AQUI_');

  /// Devuelve el Ad Unit ID de Banner correspondiente a la plataforma actual,
  /// usando el de prueba oficial en debug o si no se inyectó el ID de
  /// producción.
  static String get adUnitIdBanner {
    final esIos = defaultTargetPlatform == TargetPlatform.iOS;
    final prod = esIos ? _prodBannerIos : _prodBannerAndroid;
    if (kDebugMode || _esPlaceholder(prod)) {
      return esIos ? _testBannerIos : _testBannerAndroid;
    }
    return prod;
  }

  /// Devuelve el Ad Unit ID de Interstitial correspondiente a la plataforma
  /// actual, usando el de prueba oficial en debug o si no se inyectó el ID de
  /// producción.
  static String get adUnitIdInterstitial {
    final esIos = defaultTargetPlatform == TargetPlatform.iOS;
    final prod = esIos ? _prodInterstitialIos : _prodInterstitialAndroid;
    if (kDebugMode || _esPlaceholder(prod)) {
      return esIos ? _testInterstitialIos : _testInterstitialAndroid;
    }
    return prod;
  }

  /// Inicializa el SDK de Google Mobile Ads y precarga el primer interstitial.
  ///
  /// Nunca lanza: si la plataforma no está soportada o el SDK falla, la app
  /// continúa funcionando con normalidad sin anuncios.
  static Future<void> init() async {
    if (_inicializado || _initEnCurso || !plataformaSoportada) return;
    _initEnCurso = true;
    try {
      await MobileAds.instance.initialize();
      _inicializado = true;
      inicializadoListenable.value = true;
      debugPrint('AdMob: SDK inicializado correctamente.');
      loadInterstitial();
    } catch (e) {
      debugPrint('AdMob: error inicializando el SDK — $e');
    } finally {
      _initEnCurso = false;
    }
  }

  /// Precarga un anuncio interstitial en segundo plano si no hay uno listo.
  static void loadInterstitial() {
    if (!anunciosHabilitados ||
        _interstitial != null ||
        _cargandoInterstitial) {
      return;
    }
    _cargandoInterstitial = true;

    InterstitialAd.load(
      adUnitId: adUnitIdInterstitial,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _cargandoInterstitial = false;
          _intentosFallidos = 0;
          _interstitial = ad;
          debugPrint('AdMob: interstitial precargado y listo.');
        },
        onAdFailedToLoad: (error) {
          _cargandoInterstitial = false;
          _interstitial = null;
          _intentosFallidos++;
          debugPrint('AdMob: falló la precarga del interstitial — $error');
          if (_intentosFallidos <= 3) {
            final espera = Duration(seconds: 15 * _intentosFallidos);
            Timer(espera, loadInterstitial);
          }
        },
      ),
    );
  }

  /// Verifica si transcurrió el [cooldownMinimo] desde el último anuncio.
  @visibleForTesting
  static bool cumpleCooldown() {
    final ultimo = _ultimoAnuncioMostrado;
    if (ultimo == null) return true;
    return reloj().difference(ultimo) >= cooldownMinimo;
  }

  /// Registra una partida ganada y muestra un interstitial si se alcanzó la
  /// frecuencia ([victoriasPorAnuncio]) y se cumple el [cooldownMinimo].
  ///
  /// Devuelve `true` si efectivamente se mostró un anuncio.
  static Future<bool> registrarVictoriaYMostrarSiCorresponde() async {
    _victoriasDesdeUltimoAnuncio++;
    debugPrint(
      'AdMob: victoria registrada ($_victoriasDesdeUltimoAnuncio/$victoriasPorAnuncio).',
    );
    if (_victoriasDesdeUltimoAnuncio < victoriasPorAnuncio) {
      return false;
    }
    if (!cumpleCooldown()) {
      debugPrint('AdMob: interstitial omitido por cooldown activo.');
      return false;
    }
    final mostrado = await _mostrarInterstitialDisponible();
    if (mostrado) {
      _victoriasDesdeUltimoAnuncio = 0;
      _salidasDesdeUltimoAnuncio = 0;
      _ultimoAnuncioMostrado = reloj();
    }
    return mostrado;
  }

  /// Registra el reinicio o abandono de una partida en curso y muestra un
  /// interstitial si la partida tuvo al menos [movimientosMinimosParaSalida]
  /// jugadas, alcanzó [salidasPorAnuncio] y cumple el [cooldownMinimo].
  ///
  /// Devuelve `true` si efectivamente se mostró un anuncio.
  static Future<bool> registrarSalidaYMostrarSiCorresponde({
    required int movimientos,
  }) async {
    if (movimientos < movimientosMinimosParaSalida) {
      return false;
    }
    _salidasDesdeUltimoAnuncio++;
    debugPrint(
      'AdMob: salida calificada ($_salidasDesdeUltimoAnuncio/$salidasPorAnuncio con $movimientos movs).',
    );
    if (_salidasDesdeUltimoAnuncio < salidasPorAnuncio) {
      return false;
    }
    if (!cumpleCooldown()) {
      debugPrint('AdMob: interstitial omitido por cooldown activo.');
      return false;
    }
    final mostrado = await _mostrarInterstitialDisponible();
    if (mostrado) {
      _salidasDesdeUltimoAnuncio = 0;
      _victoriasDesdeUltimoAnuncio = 0;
      _ultimoAnuncioMostrado = reloj();
    }
    return mostrado;
  }

  static Future<bool> _mostrarInterstitialDisponible() async {
    final override = mostrarInterstitialOverride;
    if (override != null) {
      return override();
    }

    if (!anunciosHabilitados) return false;
    final ad = _interstitial;
    if (ad == null) {
      loadInterstitial();
      return false;
    }

    _interstitial = null;
    final completer = Completer<bool>();

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (_) {
        unawaited(SoundService.pausarMusica());
      },
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        unawaited(SoundService.reanudarMusica());
        loadInterstitial();
        if (!completer.isCompleted) completer.complete(true);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('AdMob: falló mostrar el interstitial — $error');
        ad.dispose();
        unawaited(SoundService.reanudarMusica());
        loadInterstitial();
        if (!completer.isCompleted) completer.complete(false);
      },
    );

    try {
      await ad.show();
      return await completer.future;
    } catch (e) {
      debugPrint('AdMob: excepción mostrando el interstitial — $e');
      ad.dispose();
      unawaited(SoundService.reanudarMusica());
      loadInterstitial();
      return false;
    }
  }

  /// Restaura contadores y estado interno para pruebas unitarias.
  @visibleForTesting
  static void reiniciarEstadoParaTests() {
    _victoriasDesdeUltimoAnuncio = 0;
    _salidasDesdeUltimoAnuncio = 0;
    _ultimoAnuncioMostrado = null;
    reloj = DateTime.now;
    mostrarInterstitialOverride = null;
  }
}
