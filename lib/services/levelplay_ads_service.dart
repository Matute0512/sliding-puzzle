import 'package:flutter/foundation.dart';
import 'package:unity_levelplay_mediation/unity_levelplay_mediation.dart';

/// Monetización con Unity LevelPlay (la plataforma de mediación de
/// Unity/ironSource).
///
/// Se eligió LevelPlay y no el SDK de Unity Ads directo porque Unity discontinuó
/// esa integración el 31/01/2026: la red pasó a in-app bidding y este es el
/// camino soportado. Un plugin sobre el SDK legacy seguiría sirviendo anuncios,
/// pero sin actualizaciones y con performance degradada.
///
/// Sigue el mismo patrón que `SoundService` y `RecordsService`: clase con todo
/// estático, sin Provider. No hay estado que notificar a la UI todavía; cuando
/// haya que *mostrar* algo según si el anuncio cargó, ahí sí conviene un
/// ChangeNotifier.
///
/// ## ⚠️ Acá NO hay `testMode`
///
/// En el SDK legacy existía un flag `testMode: true` en código. LevelPlay **no
/// tiene equivalente**: los anuncios de prueba se activan por *dispositivo* en
/// el dashboard (Settings → Test devices, cargando el GAID/IDFA del teléfono).
/// No hay forma de forzarlo desde Dart, así que la protección contra tráfico
/// inválido pasa a ser un paso de configuración, no una línea de código.
///
/// Para eso está [launchTestSuite], que abre la herramienta oficial de
/// verificación en el dispositivo.
///
/// ## Configuración pendiente
///
/// Reemplazar los IDs de abajo por los reales del dashboard. Mientras sigan
/// siendo los placeholders del repo, [init] no llama al SDK y la app arranca
/// igual, sin anuncios (ver [_esPlaceholder]).
class LevelPlayAdsService {
  // ─────────────────────────────────────────────────────────────────────
  // IDs de LevelPlay — PEGAR ACÁ LOS REALES
  //
  // LevelPlay usa un *app key* por app y plataforma (donde el SDK legacy usaba
  // el game ID), más un *ad unit* por formato. Los dos son necesarios: el app
  // key inicializa el SDK, el ad unit carga y muestra.
  // ─────────────────────────────────────────────────────────────────────

  /// App key de la app en LevelPlay, para Android.
  static const String _appKeyAndroid = 'AQUI_ANDROID_APP_KEY';

  /// App key de la app en LevelPlay, para iOS.
  static const String _appKeyIos = 'AQUI_IOS_APP_KEY';

  /// Ad unit del interstitial, para Android.
  static const String _adUnitInterstitialAndroid = 'AQUI_ANDROID_INTERSTITIAL';

  /// Ad unit del interstitial, para iOS.
  static const String _adUnitInterstitialIos = 'AQUI_IOS_INTERSTITIAL';

  static bool _inicializado = false;
  static bool _initLanzada = false;
  static LevelPlayInterstitialAd? _interstitial;

  /// El SDK solo tiene implementación nativa en Android e iOS.
  ///
  /// `defaultTargetPlatform` en vez de `dart:io Platform` a propósito: el
  /// proyecto tiene carpeta `web/` y `Platform` ni siquiera compila ahí.
  static bool get _plataformaSoportada =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  /// El SDK quedó inicializado y la plataforma lo soporta.
  static bool get _sdkDisponible => _inicializado && _plataformaSoportada;

  static String get _appKey => defaultTargetPlatform == TargetPlatform.iOS
      ? _appKeyIos
      : _appKeyAndroid;

  static String get _adUnitInterstitial =>
      defaultTargetPlatform == TargetPlatform.iOS
      ? _adUnitInterstitialIos
      : _adUnitInterstitialAndroid;

  /// `true` mientras el ID siga siendo un placeholder sin reemplazar.
  ///
  /// Corta la init antes de llegar al SDK: un app key inválido falla del lado
  /// nativo con un error opaco, y este chequeo lo convierte en un log que dice
  /// exactamente qué falta.
  static bool _esPlaceholder(String id) => id.isEmpty || id.startsWith('AQUI_');

  /// Inicializa el SDK de LevelPlay. Se llama una vez, al arrancar la app.
  ///
  /// No lanza: si la plataforma no está soportada, faltan los IDs o el SDK
  /// falla, lo reporta por consola y la app sigue funcionando sin anuncios.
  /// El juego es jugable sin monetización, así que un fallo acá nunca debe
  /// impedir el arranque.
  static Future<void> init() async {
    // Idempotente: si ya se lanzó o ya está listo, no hace nada.
    if (_inicializado || _initLanzada) return;

    if (!_plataformaSoportada) {
      debugPrint('LevelPlay: plataforma no soportada, se omite la init.');
      return;
    }

    if (_esPlaceholder(_appKey)) {
      debugPrint(
        'LevelPlay: falta pegar el app key de ${defaultTargetPlatform.name} '
        'en lib/services/levelplay_ads_service.dart. La app arranca sin '
        'anuncios.',
      );
      return;
    }

    _initLanzada = true;
    try {
      if (kDebugMode) {
        // No activa anuncios de prueba (eso es del dashboard): solo sube el
        // detalle de los logs de los adapters, que es lo que sirve mientras se
        // integra. En release queda apagado.
        await LevelPlay.setAdaptersDebug(true);
      }

      // Igual que con el SDK anterior: esta Future resuelve apenas el canal
      // nativo acepta el pedido, NO cuando el SDK termina de inicializar. El
      // resultado real llega por el listener, que dispara después. El timeout
      // es solo por si el canal nativo no responde nunca y dejaría colgado el
      // arranque.
      await LevelPlay.init(
        initRequest: LevelPlayInitRequest(appKey: _appKey),
        initListener: _InitListener(),
      ).timeout(const Duration(seconds: 15));
    } catch (e) {
      _initLanzada = false;
      // MissingPluginException en plataformas sin implementación nativa,
      // TimeoutException si el SDK no contesta, o un error de plataforma.
      debugPrint('LevelPlay: excepción inicializando — $e');
    }
  }

  /// Precarga el interstitial de la plataforma actual.
  ///
  /// LevelPlay tarda unos segundos en tenerlo listo, así que conviene llamarlo
  /// *antes* del momento en que se quiere mostrar (por ejemplo al entrar a una
  /// pantalla) y no justo cuando el jugador termina la partida: si se pide en
  /// el momento, el anuncio llega tarde o directamente no llega.
  static Future<void> loadInterstitial() async {
    if (!_sdkDisponible) {
      debugPrint('LevelPlay: se omite loadInterstitial (SDK no inicializado).');
      return;
    }

    try {
      // El objeto de anuncio se crea una sola vez y se reutiliza. LevelPlay lo
      // registra en un mapa interno por `adId`, y `showAd` sobre un `adId` que
      // ya no está en ese mapa no hace nada **en silencio**. Crear uno nuevo
      // por carga, o llamar a `dispose()`, dejaría ese mapa apuntando a un
      // objeto muerto.
      final ad = _interstitial ??= _crearInterstitial();

      await ad.loadAd();
    } catch (e) {
      debugPrint('LevelPlay: excepción cargando el interstitial — $e');
    }
  }

  /// Muestra el interstitial ya precargado.
  ///
  /// No recibe el ad unit a propósito: en LevelPlay el ad unit se fija al
  /// **construir** el objeto de anuncio, no al mostrarlo, así que un parámetro
  /// acá o se ignoraría o mostraría un anuncio distinto del que se cargó. Si
  /// más adelante hacen falta dos interstitials distintos, el cambio es
  /// guardar los objetos en un `Map` con el ad unit como clave.
  ///
  /// Un anuncio mostrado se consume: después de cerrarlo hay que volver a
  /// llamar a [loadInterstitial] antes de poder mostrarlo otra vez.
  static Future<void> showInterstitial() async {
    if (!_sdkDisponible) {
      debugPrint('LevelPlay: se omite showInterstitial (SDK no inicializado).');
      return;
    }

    final ad = _interstitial;
    if (ad == null) {
      debugPrint(
        'LevelPlay: showInterstitial sin haber llamado a loadInterstitial().',
      );
      return;
    }

    try {
      // `isAdReady()` es la fuente de verdad, así que se consulta en vez de
      // confiar en el flag local: mostrar un anuncio que no está listo solo
      // dispara un `onAdDisplayFailed` evitable.
      if (!await ad.isAdReady()) {
        debugPrint(
          'LevelPlay: el interstitial todavía no está listo — se omite el '
          'show. Llamá a loadInterstitial() y esperá el onAdLoaded.',
        );
        return;
      }

      await ad.showAd();
    } catch (e) {
      debugPrint('LevelPlay: excepción mostrando el interstitial — $e');
    }
  }

  /// Abre la Test Suite de LevelPlay en el dispositivo.
  ///
  /// Es la herramienta oficial para verificar la integración: muestra qué redes
  /// quedaron configuradas y si cada una carga y muestra correctamente. Como
  /// LevelPlay no tiene `testMode` en código, esto más la lista de *test
  /// devices* del dashboard es todo el flujo de prueba.
  ///
  /// Pensada para dispararse desde un botón oculto en debug, no para producción.
  static Future<void> launchTestSuite() async {
    if (!_sdkDisponible) {
      debugPrint('LevelPlay: se omite launchTestSuite (SDK no inicializado).');
      return;
    }

    try {
      await LevelPlay.launchTestSuite();
    } catch (e) {
      debugPrint('LevelPlay: excepción abriendo la Test Suite — $e');
    }
  }

  static LevelPlayInterstitialAd _crearInterstitial() {
    final ad = LevelPlayInterstitialAd(adUnitId: _adUnitInterstitial);
    ad.setListener(_InterstitialListener());
    return ad;
  }
}

/// Listener de la init del SDK.
class _InitListener extends LevelPlayInitListener {
  @override
  void onInitSuccess(LevelPlayConfiguration configuration) {
    LevelPlayAdsService._inicializado = true;
    debugPrint(
      'LevelPlay: SDK inicializado (ad quality: '
      '${configuration.isAdQualityEnabled}).',
    );
  }

  @override
  void onInitFailed(LevelPlayInitError error) {
    // Se libera el flag para permitir un reintento posterior.
    LevelPlayAdsService._initLanzada = false;
    debugPrint('LevelPlay: falló la init — $error');
  }
}

/// Listener del interstitial.
///
/// `LevelPlayInterstitialAdListener` es una clase abstracta sin
/// implementaciones por defecto, así que hay que definir los 7 métodos aunque
/// la mayoría solo loguee.
class _InterstitialListener extends LevelPlayInterstitialAdListener {
  @override
  void onAdLoaded(LevelPlayAdInfo adInfo) {
    debugPrint('LevelPlay: interstitial listo (red: ${adInfo.adNetwork}).');
  }

  @override
  void onAdLoadFailed(LevelPlayAdError error) {
    // El caso más común es falta de fill, y no es un bug: simplemente no había
    // un anuncio para servir en ese momento.
    debugPrint('LevelPlay: falló la carga — $error');
  }

  @override
  void onAdInfoChanged(LevelPlayAdInfo adInfo) {
    debugPrint('LevelPlay: cambió la info del anuncio (${adInfo.adNetwork}).');
  }

  @override
  void onAdDisplayed(LevelPlayAdInfo adInfo) {
    debugPrint('LevelPlay: interstitial mostrado (red: ${adInfo.adNetwork}).');
  }

  @override
  void onAdDisplayFailed(LevelPlayAdError error, LevelPlayAdInfo adInfo) {
    debugPrint('LevelPlay: falló el show — $error');
  }

  @override
  void onAdClicked(LevelPlayAdInfo adInfo) {
    debugPrint('LevelPlay: click en el interstitial.');
  }

  @override
  void onAdClosed(LevelPlayAdInfo adInfo) {
    debugPrint('LevelPlay: interstitial cerrado.');
  }
}
