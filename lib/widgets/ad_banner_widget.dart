import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../services/admob_service.dart';
import '../theme/app_theme.dart';

/// Banner adaptativo anclado (*Anchored Adaptive Banner*) persistente en el
/// pie de la aplicación.
///
/// ## Aislamiento de rendimiento y cero retraso entre pantallas
/// - Se monta una única vez en `MaterialApp.builder` (por fuera del
///   `Navigator`), de modo que cuando el jugador entra a un nivel o cambia de
///   pantalla el banner **ya está cargado y visible al instante** sin volver a
///   pedir ni recrear el `PlatformView` nativo.
/// - Si los anuncios no están habilitados (Web, escritorio o tests de widgets)
///   o mientras el anuncio no haya terminado de cargar, devuelve
///   `const SizedBox.shrink()` sin reservar espacio ni alterar la geometría.
/// - Envuelve el `AdWidget` en su propio [RepaintBoundary] para contener el
///   repintado de la superficie nativa.
class AdBannerWidget extends StatefulWidget {
  const AdBannerWidget({super.key});

  @override
  State<AdBannerWidget> createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends State<AdBannerWidget> {
  BannerAd? _bannerAd;
  AdSize? _adSize;
  bool _cargado = false;
  bool _solicitudIniciada = false;

  @override
  void initState() {
    super.initState();
    AdMobService.inicializadoListenable.addListener(_onSdkInicializado);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _intentarProgramarCarga();
  }

  void _onSdkInicializado() {
    _intentarProgramarCarga();
  }

  void _intentarProgramarCarga() {
    if (!_solicitudIniciada && AdMobService.anunciosHabilitados) {
      _solicitudIniciada = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _cargarBanner();
      });
    }
  }

  Future<void> _cargarBanner() async {
    if (!mounted || !AdMobService.anunciosHabilitados) return;

    final ancho = MediaQuery.sizeOf(context).width.truncate();
    if (ancho <= 0) {
      _solicitudIniciada = false;
      return;
    }

    final size =
        await AdSize.getLargeAnchoredAdaptiveBannerAdSize(ancho) ??
        AdSize.banner;
    if (!mounted) return;

    final banner = BannerAd(
      adUnitId: AdMobService.adUnitIdBanner,
      request: const AdRequest(),
      size: size,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          debugPrint('AdMob: banner cargado (${size.width}x${size.height}).');
          setState(() {
            _bannerAd = ad as BannerAd;
            _adSize = size;
            _cargado = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('AdMob: falló la carga del banner — $error');
          ad.dispose();
          if (mounted) {
            setState(() {
              _bannerAd = null;
              _cargado = false;
            });
            _solicitudIniciada = false;
            Future.delayed(const Duration(seconds: 30), () {
              if (mounted && !_cargado && !_solicitudIniciada) {
                _intentarProgramarCarga();
              }
            });
          }
        },
      ),
    );

    try {
      await banner.load();
    } catch (e) {
      debugPrint('AdMob: excepción al cargar banner: $e');
      _solicitudIniciada = false;
    }
  }

  @override
  void dispose() {
    AdMobService.inicializadoListenable.removeListener(_onSdkInicializado);
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final banner = _bannerAd;
    final size = _adSize;
    if (!_cargado || banner == null || size == null) {
      return const SizedBox.shrink();
    }

    return SafeArea(
      top: false,
      child: RepaintBoundary(
        child: Container(
          width: double.infinity,
          height: size.height.toDouble() + 2,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppTheme.arcadeSurface,
            border: Border(
              top: BorderSide(color: AppTheme.arcadeBorder, width: 1),
            ),
          ),
          child: SizedBox(
            width: size.width.toDouble(),
            height: size.height.toDouble(),
            child: AdWidget(ad: banner),
          ),
        ),
      ),
    );
  }
}
